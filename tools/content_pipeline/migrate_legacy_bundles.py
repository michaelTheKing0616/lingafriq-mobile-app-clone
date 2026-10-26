"""Migrate four legacy curriculum bundles into v2 signed packs (P4-107)."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator, Mapping, Sequence

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.ci.placeholder_linter import find_placeholder_patterns  # noqa: E402
from tools.content_pipeline.pack_builder import (  # noqa: E402
    LEGACY_BUNDLE_DIRS,
    PackObjectInput,
    build_pack,
)
from tools.content_pipeline.schema_loader import (  # noqa: E402
    CommonSchemaError,
    validate_content_envelope,
)
from tools.content_pipeline.validate_content import (  # noqa: E402
    ValidationFinding,
    has_tone_mark,
    validate_content_tree,
)

CARD_ID = "P4-107"
_TONAL_KITS = frozenset({"yo", "ig", "ha"})
_SUPPORTED_KITS = frozenset({"yo", "ig", "ha", "pcm", "sw", "zu", "xh"})
_LANG_KEY_TO_KIT: dict[str, str] = {
    "yoruba": "yo",
    "hausa": "ha",
    "igbo": "ig",
    "swahili": "sw",
    "zulu": "zu",
    "xhosa": "xh",
    "nigerian_pidgin": "pcm",
    "pidgin": "pcm",
    "pcm": "pcm",
}
_SLUG_RE = re.compile(r"[^a-z0-9]+")
_V2_PACKS_REL = Path("assets/data/content_packs/v2")


@dataclass(frozen=True)
class LegacySource:
    bundle: str
    relpath: str
    pointer: str
    kind: str


@dataclass(frozen=True)
class MigrationReject:
    source: LegacySource
    reason: str


@dataclass
class MigrationResult:
    migrated: list[dict[str, Any]] = field(default_factory=list)
    rejects: list[MigrationReject] = field(default_factory=list)
    packs_written: list[Path] = field(default_factory=list)
    validation_report_path: Path | None = None


def repo_root(explicit: Path | None = None) -> Path:
    return (explicit or _REPO_ROOT).resolve()


def default_v2_output(root: Path | None = None) -> Path:
    return repo_root(root) / _V2_PACKS_REL


def bundle_roots(root: Path | None = None) -> list[tuple[str, Path]]:
    base = repo_root(root)
    found: list[tuple[str, Path]] = []
    for name in LEGACY_BUNDLE_DIRS:
        path = base / name
        if path.is_dir():
            found.append((name, path))
    return found


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def _ascii_fallback(text: str) -> str:
    folded = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in folded if not unicodedata.combining(ch) and ord(ch) < 128) or text


def _slug_token(text: str, pointer: str) -> str:
    base = _SLUG_RE.sub("_", _ascii_fallback(text).lower()).strip("_")
    if base:
        return base[:48]
    digest = hashlib.sha256(pointer.encode("utf-8")).hexdigest()[:12]
    return f"legacy_{digest}"


def legacy_is_placeholder(*parts: str) -> bool:
    joined = " ".join(p for p in parts if p)
    if not joined.strip():
        return True
    if find_placeholder_patterns(joined):
        return True
    return False


def resolve_kit_lang(meta: Mapping[str, Any] | None, path: Path) -> str | None:
    if meta:
        code = meta.get("code")
        if isinstance(code, str):
            key = code.lower().replace("-", "_")
            if key in _LANG_KEY_TO_KIT:
                return _LANG_KEY_TO_KIT[key]
        language = meta.get("language")
        if isinstance(language, str):
            key = language.lower().replace("-", "_").replace(" ", "_")
            if key in _LANG_KEY_TO_KIT:
                return _LANG_KEY_TO_KIT[key]
    stem = path.stem.lower()
    for token in stem.split("_"):
        if token in _LANG_KEY_TO_KIT:
            return _LANG_KEY_TO_KIT[token]
    return None


def infer_cefr(meta: Mapping[str, Any] | None, pointer: str) -> str:
    if meta and isinstance(meta.get("level"), str):
        level = meta["level"].strip().upper()
        if level in {"A1", "A2", "B1", "B2", "C1", "C2"}:
            return level
    for level in ("A1", "A2", "B1", "B2", "C1", "C2"):
        if level in pointer.upper():
            return level
    return "A1"


def legacy_ai_assisted(meta: Mapping[str, Any] | None) -> bool:
    if not meta:
        return True
    fmt = meta.get("format")
    if isinstance(fmt, str) and "sample" in fmt.lower():
        return True
    generated = meta.get("generated_at")
    return isinstance(generated, str) and bool(generated.strip())


def provenance_for_legacy(
    source: LegacySource,
    *,
    ai_assisted: bool,
) -> dict[str, Any]:
    citation = f"legacy:{source.bundle}/{source.relpath}#{source.pointer}"
    body: dict[str, Any] = {
        "author": "legacy-bundle-migration",
        "created_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "ai_assisted": ai_assisted,
        "sources": [
            {
                "name": f"{source.bundle} vocabulary",
                "licence": "internal-legacy-unverified",
                "uri_or_citation": citation,
                "retrieved_at": datetime.now(timezone.utc).date().isoformat(),
            }
        ],
    }
    if ai_assisted:
        body["model_id"] = "legacy-curriculum-generator"
        body["prompt_id"] = f"{CARD_ID}-migration"
    return body


def build_lexeme_from_vocab(
    source: LegacySource,
    *,
    kit_lang: str,
    word: str,
    meaning: str,
    cefr: str,
    ai_assisted: bool,
) -> dict[str, Any] | MigrationReject:
    lemma = nfc(word)
    gloss = nfc(meaning)
    if legacy_is_placeholder(lemma, gloss):
        return MigrationReject(source, "LEGACY_PLACEHOLDER")
    if kit_lang not in _SUPPORTED_KITS:
        return MigrationReject(source, "UNSUPPORTED_LANGUAGE")
    if kit_lang in _TONAL_KITS and not has_tone_mark(lemma):
        return MigrationReject(source, "MISSING_TONE_MARKS")
    slug = _slug_token(lemma, source.pointer)
    stable_id = f"{kit_lang}.lex.{slug}.legacy"
    payload: dict[str, Any] = {
        "id": stable_id,
        "language": kit_lang,
        "lemma": lemma,
        "orthography": {
            "standard": lemma,
            "ascii_fallback": _ascii_fallback(lemma),
            "script": "Latn",
        },
        "senses": [
            {
                "gloss_en": gloss,
                "gloss_fr": gloss,
                "domain": "general",
                "register": "neutral",
            }
        ],
        "cefr": cefr,
        "frequency_rank": 50_000,
        "label": "beta",
        "provenance": provenance_for_legacy(source, ai_assisted=ai_assisted),
        "claims": [{"kind": "linguistic", "source_ref": f"legacy:{source.pointer}"}],
        "confidence": 0.35,
        "risk_tags": [],
        "audio": [],
    }
    if payload["label"] not in {"beta"}:
        return MigrationReject(source, "FORBIDDEN_LABEL")
    try:
        validate_content_envelope(payload)
    except CommonSchemaError as exc:
        return MigrationReject(source, exc.code)
    return payload


def _yield_vocab_rows(
    items: object,
    *,
    bundle: str,
    relpath: str,
    pointer_prefix: str,
    kit_lang: str,
    cefr: str,
    ai_assisted: bool,
) -> Iterator[tuple[LegacySource, str, str, str, str, bool]]:
    if not isinstance(items, list):
        return
    for index, row in enumerate(items):
        if not isinstance(row, Mapping):
            continue
        word = row.get("word")
        meaning = row.get("meaning")
        if not isinstance(word, str) or not isinstance(meaning, str):
            continue
        pointer = f"{pointer_prefix}/vocab[{index}]"
        source = LegacySource(bundle, relpath, pointer, "vocab")
        yield (source, word, meaning, kit_lang, cefr, ai_assisted)


def iter_legacy_vocab_sources(
    bundle: str,
    relpath: str,
    document: Mapping[str, Any],
) -> Iterator[tuple[LegacySource, str, str, str, str, bool]]:
    meta = document.get("meta") if isinstance(document.get("meta"), Mapping) else {}
    kit_lang = resolve_kit_lang(meta, Path(relpath)) or "unknown"
    ai_assisted = legacy_ai_assisted(meta)
    cefr_default = infer_cefr(meta, relpath)

    units = document.get("units")
    if isinstance(units, list):
        for u_index, unit in enumerate(units):
            if not isinstance(unit, Mapping):
                continue
            prefix = f"units[{u_index}]"
            yield from _yield_vocab_rows(
                unit.get("vocab"),
                bundle=bundle,
                relpath=relpath,
                pointer_prefix=prefix,
                kit_lang=kit_lang,
                cefr=cefr_default,
                ai_assisted=ai_assisted,
            )
            lessons = unit.get("lessons")
            if isinstance(lessons, list):
                for l_index, lesson in enumerate(lessons):
                    if not isinstance(lesson, Mapping):
                        continue
                    lesson_prefix = f"{prefix}/lessons[{l_index}]"
                    lesson_cefr = infer_cefr(meta, f"{relpath}/{lesson_prefix}")
                    yield from _yield_vocab_rows(
                        lesson.get("vocab"),
                        bundle=bundle,
                        relpath=relpath,
                        pointer_prefix=lesson_prefix,
                        kit_lang=kit_lang,
                        cefr=lesson_cefr,
                        ai_assisted=ai_assisted,
                    )

    languages = document.get("languages")
    if isinstance(languages, Mapping):
        for lang_key, block in languages.items():
            if not isinstance(block, Mapping):
                continue
            kit = _LANG_KEY_TO_KIT.get(str(lang_key).lower().replace(" ", "_"), kit_lang)
            if not kit or kit == "unknown":
                continue
            for level_key, units_block in block.items():
                if not isinstance(units_block, list):
                    continue
                level = str(level_key).upper()
                cefr = level if level in {"A1", "A2", "B1", "B2", "C1", "C2"} else cefr_default
                for u_index, unit in enumerate(units_block):
                    if not isinstance(unit, Mapping):
                        continue
                    yield from _yield_vocab_rows(
                        unit.get("vocab"),
                        bundle=bundle,
                        relpath=relpath,
                        pointer_prefix=f"languages/{lang_key}/{level_key}[{u_index}]",
                        kit_lang=kit,
                        cefr=cefr,
                        ai_assisted=ai_assisted,
                    )


def iter_json_files(root: Path) -> Iterator[Path]:
    if root.is_file() and root.suffix.lower() == ".json":
        yield root
        return
    for path in sorted(root.rglob("*.json")):
        if path.is_file() and ".git" not in path.parts:
            yield path


def migrate_document(
    bundle: str,
    path: Path,
    document: Mapping[str, Any],
    *,
    seen_ids: set[str],
) -> tuple[list[dict[str, Any]], list[MigrationReject]]:
    base = repo_root()
    try:
        relpath = path.resolve().relative_to(base).as_posix()
    except ValueError:
        relpath = path.as_posix()

    migrated: list[dict[str, Any]] = []
    rejects: list[MigrationReject] = []

    for source, word, meaning, kit_lang, cefr, ai_assisted in iter_legacy_vocab_sources(
        bundle, relpath, document
    ):
        if kit_lang == "unknown" or kit_lang not in _SUPPORTED_KITS:
            rejects.append(MigrationReject(source, "UNSUPPORTED_LANGUAGE"))
            continue
        outcome = build_lexeme_from_vocab(
            source,
            kit_lang=kit_lang,
            word=word,
            meaning=meaning,
            cefr=cefr,
            ai_assisted=ai_assisted,
        )
        if isinstance(outcome, MigrationReject):
            rejects.append(outcome)
            continue
        stable_id = str(outcome["id"])
        if stable_id in seen_ids:
            rejects.append(MigrationReject(source, "DUPLICATE_STABLE_ID"))
            continue
        if outcome.get("label") != "beta":
            rejects.append(MigrationReject(source, "FORBIDDEN_LABEL"))
            continue
        prov = outcome.get("provenance")
        if not isinstance(prov, Mapping) or prov.get("ai_assisted") is None:
            rejects.append(MigrationReject(source, "AI_FLAG_MISSING"))
            continue
        seen_ids.add(stable_id)
        migrated.append(outcome)

    return migrated, rejects


def write_rejects(path: Path, rejects: Sequence[MigrationReject]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    for row in rejects:
        lines.append(
            json.dumps(
                {
                    "bundle": row.source.bundle,
                    "relpath": row.source.relpath,
                    "pointer": row.source.pointer,
                    "kind": row.source.kind,
                    "reason": row.reason,
                },
                ensure_ascii=False,
            )
        )
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def group_by_language(objects: Sequence[Mapping[str, Any]]) -> dict[str, list[Mapping[str, Any]]]:
    grouped: dict[str, list[Mapping[str, Any]]] = {}
    for obj in objects:
        lang = obj.get("language")
        if not isinstance(lang, str):
            ident = obj.get("id")
            lang = str(ident).split(".", 1)[0] if isinstance(ident, str) else "unknown"
        grouped.setdefault(lang, []).append(obj)
    return grouped


def write_v2_packs(
    objects: Sequence[Mapping[str, Any]],
    output_dir: Path,
    *,
    signing_seed_hex: str | None,
    built_at: str,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for lang, rows in sorted(group_by_language(objects).items()):
        pack_objects = [
            PackObjectInput(str(row["id"]), "lexeme", dict(row)) for row in rows if "id" in row
        ]
        if not pack_objects:
            continue
        pack = build_pack(
            "0.1.0",
            pack_objects,
            [],
            built_at=built_at,
            signing_seed_hex=signing_seed_hex,
        )
        lang_dir = output_dir / lang
        lang_dir.mkdir(parents=True, exist_ok=True)
        for rel, data in pack.files.items():
            target = lang_dir / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        written.append(lang_dir)
    return written


def validation_report(
    pack_dirs: Sequence[Path],
    report_path: Path,
) -> dict[str, int]:
    findings: list[ValidationFinding] = []
    for pack_dir in pack_dirs:
        findings.extend(validate_content_tree(pack_dir, scan_placeholders=True))

    by_code: dict[str, int] = {}
    by_object: dict[str, list[ValidationFinding]] = {}
    for row in findings:
        by_code[row.code] = by_code.get(row.code, 0) + 1
        by_object.setdefault(row.object_id, []).append(row)

    report_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "card": CARD_ID,
        "finding_counts_by_rule": by_code,
        "objects_with_findings": len(by_object),
        "total_findings": len(findings),
        "findings": [
            {
                "code": f.code,
                "object_id": f.object_id,
                "location": f.location,
                "message": f.message,
            }
            for f in findings
        ],
    }
    report_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return by_code


def run_migration(
    *,
    root: Path | None = None,
    output_dir: Path | None = None,
    signing_seed_hex: str | None = None,
    bundles: Sequence[str] | None = None,
) -> MigrationResult:
    base = repo_root(root)
    out = output_dir or default_v2_output(base)
    rejects_path = out / "migration_rejects.jsonl"
    validation_path = out / "migration_validation_report.json"

    roots = bundle_roots(base)
    if bundles:
        allow = set(bundles)
        roots = [(name, path) for name, path in roots if name in allow]

    result = MigrationResult()
    seen_ids: set[str] = set()
    all_migrated: list[dict[str, Any]] = []

    for bundle_name, bundle_path in roots:
        for json_path in iter_json_files(bundle_path):
            raw, err = _load_json(json_path)
            if err is not None or not isinstance(raw, Mapping):
                source = LegacySource(
                    bundle_name,
                    json_path.as_posix(),
                    "/",
                    "file",
                )
                result.rejects.append(MigrationReject(source, f"JSON_INVALID:{err}"))
                continue
            migrated, rejects = migrate_document(bundle_name, json_path, raw, seen_ids=seen_ids)
            all_migrated.extend(migrated)
            result.rejects.extend(rejects)

    result.migrated = all_migrated
    write_rejects(rejects_path, result.rejects)

    built_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    if all_migrated:
        result.packs_written = write_v2_packs(
            all_migrated,
            out,
            signing_seed_hex=signing_seed_hex,
            built_at=built_at,
        )
        result.validation_report_path = validation_path
        validation_report(result.packs_written, validation_path)

    summary_path = out / "migration_summary.json"
    summary_path.write_text(
        json.dumps(
            {
                "card": CARD_ID,
                "migrated": len(all_migrated),
                "rejected": len(result.rejects),
                "packs": [str(p.relative_to(base)) for p in result.packs_written],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return result


def _load_json(path: Path) -> tuple[Any | None, str | None]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        return None, str(exc)


def assert_no_legacy_bundle_references(text: str) -> None:
    for name in LEGACY_BUNDLE_DIRS:
        if name in text:
            raise ValueError(f"legacy bundle path {name!r} must not appear in v2 export tooling")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Migrate legacy curriculum bundles to v2 packs.")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help=f"Output directory (default: {_V2_PACKS_REL})",
    )
    parser.add_argument(
        "--bundle",
        action="append",
        dest="bundles",
        help="Migrate only named bundle (repeatable)",
    )
    args = parser.parse_args(argv)
    missing = [name for name in LEGACY_BUNDLE_DIRS if not (repo_root() / name).is_dir()]
    if missing and not args.bundles:
        print(f"missing legacy bundle dirs: {', '.join(missing)}", file=sys.stderr)
        return 2
    result = run_migration(output_dir=args.output, bundles=args.bundles)
    print(
        f"{CARD_ID}: migrated {len(result.migrated)} lexemes, "
        f"rejected {len(result.rejects)}, packs {len(result.packs_written)}"
    )
    if result.validation_report_path and result.validation_report_path.is_file():
        report = json.loads(result.validation_report_path.read_text(encoding="utf-8"))
        counts = report.get("finding_counts_by_rule", {})
        if counts:
            print(f"validation findings by rule: {counts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
