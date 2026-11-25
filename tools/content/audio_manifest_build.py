"""Rebuild audio manifest NFC-normalised, hash-keyed, deduplicated (P5-005)."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping, MutableMapping, Sequence

from tools.content_engine.legacy.structure import audio_content_hash

CARD_ID = "P5-005"
RULE_AU001 = "AU-001"
DEFAULT_MANIFEST = "assets/data/audio_manifest.json"
CDN_BASE = "https://cdn.lingafriq.com/audio/v2"
MANIFEST_VERSION = "1.1.0"
_PUBSPEC_AUDIO = re.compile(r"^\s*-\s+assets/audio/", re.MULTILINE)


@dataclass(frozen=True)
class LintFinding:
    rule_id: str
    item_id: str
    field: str
    detail: str


@dataclass(frozen=True)
class DedupReport:
    files_scanned: int
    unique_blobs: int
    duplicate_files: int
    bytes_reclaimed: int


@dataclass(frozen=True)
class RebuildStats:
    entries_in: int
    entries_out: int
    keys_merged_nfc: int


def repo_root(start: Path | None = None) -> Path:
    here = (start or Path(__file__)).resolve()
    for parent in (here, *here.parents):
        if (parent / "pubspec.yaml").is_file():
            return parent
    raise FileNotFoundError("mobile app root (pubspec.yaml) not found")


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def manifest_key(language: str, text: str) -> str:
    return f"{language.strip().lower()}|{nfc(text)}"


def entry_id(language: str, text: str) -> str:
    digest = audio_content_hash(text)
    return f"{language.strip().lower()}-{digest}"


def variant_block(language: str, content_hash: str, speed: str, tts_rate: float) -> dict[str, Any]:
    lang = language.strip().lower()
    filename = f"{content_hash}.mp3"
    return {
        "asset_path": f"assets/audio/{lang}/{speed}/{filename}",
        "cdn_url": f"{CDN_BASE}/{lang}/{speed}/{filename}",
        "tts_rate": tts_rate,
    }


def rebuild_manifest_entry(entry: Mapping[str, Any]) -> dict[str, Any]:
    language = str(entry.get("language", "")).strip()
    text = nfc(str(entry.get("text", "")))
    if not language or not text:
        raise ValueError("manifest entry requires language and text")
    content_hash = audio_content_hash(text)
    out: dict[str, Any] = dict(entry)
    out["id"] = entry_id(language, text)
    out["language"] = language
    out["text"] = text
    out["manifest_key"] = manifest_key(language, text)
    out["content_hash"] = content_hash
    slow = entry.get("slow")
    native = entry.get("native")
    slow_rate = 0.52
    native_rate = 0.95
    if isinstance(slow, Mapping) and isinstance(slow.get("tts_rate"), (int, float)):
        slow_rate = float(slow["tts_rate"])
    if isinstance(native, Mapping) and isinstance(native.get("tts_rate"), (int, float)):
        native_rate = float(native["tts_rate"])
    out["slow"] = variant_block(language, content_hash, "slow", slow_rate)
    out["native"] = variant_block(language, content_hash, "native", native_rate)
    if isinstance(entry.get("english"), Mapping):
        eng = entry["english"]
        eng_rate = float(eng.get("tts_rate", 1.0)) if isinstance(eng.get("tts_rate"), (int, float)) else 1.0
        out["english"] = variant_block(language, content_hash, "english", eng_rate)
    return out


def rebuild_manifest_document(doc: Mapping[str, Any]) -> tuple[dict[str, Any], RebuildStats]:
    raw_entries = doc.get("entries")
    if not isinstance(raw_entries, list):
        raise TypeError("audio manifest entries must be a list")
    merged_nfc = 0
    by_key: dict[str, dict[str, Any]] = {}
    for raw in raw_entries:
        if not isinstance(raw, Mapping):
            continue
        rebuilt = rebuild_manifest_entry(raw)
        key = rebuilt["manifest_key"]
        if key in by_key:
            merged_nfc += 1
            continue
        by_key[key] = rebuilt
    entries = sorted(by_key.values(), key=lambda e: (e["language"], e["text"]))
    meta = dict(doc.get("meta") or {})
    meta["version"] = MANIFEST_VERSION
    meta["entry_count"] = len(entries)
    meta["generated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    meta["keying"] = "nfc_text_plus_sha256_prefix16"
    return {"meta": meta, "entries": entries}, RebuildStats(
        entries_in=len(raw_entries),
        entries_out=len(entries),
        keys_merged_nfc=merged_nfc,
    )


def manifest_lookup_keys(entries: Sequence[Mapping[str, Any]]) -> set[str]:
    keys: set[str] = set()
    for entry in entries:
        mk = entry.get("manifest_key")
        if isinstance(mk, str) and mk:
            keys.add(mk)
        ch = entry.get("content_hash")
        if isinstance(ch, str) and ch:
            keys.add(ch)
        eid = entry.get("id")
        if isinstance(eid, str) and eid:
            keys.add(eid)
        for variant in ("slow", "native", "english", "premium"):
            block = entry.get(variant)
            if isinstance(block, Mapping):
                path = block.get("asset_path")
                if isinstance(path, str) and path.endswith(".mp3"):
                    keys.add(Path(path).name.replace(".mp3", ""))
    return keys


def lint_curriculum_audio_ref(
    item: Mapping[str, Any],
    manifest_keys: set[str],
    *,
    location: str = "payload",
) -> LintFinding | None:
    payload = item.get("payload") if isinstance(item.get("payload"), Mapping) else item
    if not isinstance(payload, Mapping):
        return LintFinding(RULE_AU001, str(item.get("id", "?")), location, "payload missing")
    audio = payload.get("audio")
    item_id = str(payload.get("id") or item.get("item_id") or "?")
    if not isinstance(audio, Sequence) or isinstance(audio, (str, bytes)) or len(audio) == 0:
        return LintFinding(RULE_AU001, item_id, "audio", "no audio reference (legacy zero refs)")
    for idx, clip in enumerate(audio):
        if not isinstance(clip, Mapping):
            return LintFinding(RULE_AU001, item_id, f"audio[{idx}]", "audio clip must be an object")
        kind = clip.get("kind")
        if not isinstance(kind, str) or not kind.strip():
            return LintFinding(RULE_AU001, item_id, f"audio[{idx}].kind", "audio.kind required")
        ref = clip.get("manifest_key")
        if isinstance(ref, str) and ref in manifest_keys:
            continue
        file_name = clip.get("file")
        if isinstance(file_name, str):
            stem = file_name.replace(".mp3", "")
            if stem in manifest_keys:
                continue
        text = payload.get("text")
        if isinstance(text, str):
            lang = str(payload.get("lang") or payload.get("language") or "")
            if manifest_key(lang, text) in manifest_keys:
                continue
            if audio_content_hash(text) in manifest_keys:
                continue
        return LintFinding(
            RULE_AU001,
            item_id,
            f"audio[{idx}]",
            "audio reference does not resolve to a manifest key",
        )
    return None


def lint_au001_batch(
    items: Iterable[Mapping[str, Any]],
    manifest_keys: set[str],
) -> tuple[LintFinding, ...]:
    findings: list[LintFinding] = []
    for item in items:
        if not isinstance(item, Mapping):
            continue
        hit = lint_curriculum_audio_ref(item, manifest_keys)
        if hit is not None:
            findings.append(hit)
    return tuple(findings)


def deduplicate_audio_files(audio_root: Path) -> DedupReport:
    if not audio_root.is_dir():
        return DedupReport(0, 0, 0, 0)
    by_hash: dict[str, Path] = {}
    scanned = 0
    dupes = 0
    reclaimed = 0
    for path in sorted(audio_root.rglob("*.mp3")):
        if not path.is_file():
            continue
        scanned += 1
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        keeper = by_hash.get(digest)
        if keeper is None:
            by_hash[digest] = path
            continue
        dupes += 1
        reclaimed += path.stat().st_size
        path.unlink()
    return DedupReport(scanned, len(by_hash), dupes, reclaimed)


def pubspec_declares_audio(pubspec_path: Path) -> bool:
    text = pubspec_path.read_text(encoding="utf-8")
    return bool(_PUBSPEC_AUDIO.search(text))


def assert_pubspec_audio_declaration(pubspec_path: Path) -> None:
    if not pubspec_declares_audio(pubspec_path):
        raise RuntimeError(
            "AssetUndeclaredError: assets/audio/ is not listed under flutter.assets in pubspec.yaml"
        )


def run_rebuild(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    manifest_path: Path | None = None,
    dedupe_audio: bool = False,
) -> tuple[RebuildStats, DedupReport, Path]:
    base = repo_root(root)
    manifest_file = manifest_path if manifest_path is not None else base / DEFAULT_MANIFEST
    doc = json.loads(manifest_file.read_text(encoding="utf-8"))
    rebuilt, stats = rebuild_manifest_document(doc)
    assert_pubspec_audio_declaration(base / "pubspec.yaml")
    dedup = DedupReport(0, 0, 0, 0)
    if dedupe_audio:
        dedup = deduplicate_audio_files(base / "assets" / "audio")
    if not dry_run:
        manifest_file.write_text(
            json.dumps(rebuilt, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return stats, dedup, manifest_file


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Rebuild hash-keyed audio manifest (P5-005).")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--repo-root", type=Path, default=None)
    parser.add_argument("--manifest", type=Path, default=None)
    parser.add_argument(
        "--dedupe-files",
        action="store_true",
        help="Remove duplicate mp3 blobs under assets/audio by sha256.",
    )
    args = parser.parse_args(argv)
    stats, dedup, path = run_rebuild(
        args.repo_root,
        dry_run=args.dry_run,
        manifest_path=args.manifest,
        dedupe_audio=args.dedupe_files,
    )
    print(
        f"entries_in={stats.entries_in}\tentries_out={stats.entries_out}\t"
        f"nfc_merged={stats.keys_merged_nfc}",
    )
    if args.dedupe_files:
        print(
            f"dedup_scanned={dedup.files_scanned}\tunique={dedup.unique_blobs}\t"
            f"dupes={dedup.duplicate_files}\tbytes_reclaimed={dedup.bytes_reclaimed}",
        )
    if not args.dry_run:
        print(f"manifest\t{path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
