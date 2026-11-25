"""V2 content validator and CI entrypoint (P4-106)."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.structure import audio_content_hash  # noqa: E402
from tools.content_pipeline.placeholder_patterns import scan_tree  # noqa: E402

_TONAL_LANGS = frozenset({"yo", "ig", "ha"})
_TONE_MARKS = frozenset("\u0300\u0301\u0304\u0302\u030c\u030b\u030f")
_LEXEME_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.lex\.")
_AUDIO_URI_RE = re.compile(r"^audio/[a-z]{2,3}/([0-9a-f]{8,64})\.[a-z0-9]+$")
_PACK_FORMAT = "lingafriq.content_pack.v2"


@dataclass(frozen=True)
class ValidationFinding:
    code: str
    object_id: str
    message: str
    location: str = ""


class ContentValidateError(Exception):
    def __init__(self, code: str, message: str, *, object_id: str = "-", location: str = "") -> None:
        self.code = code
        self.object_id = object_id
        self.location = location
        super().__init__(message)


def _object_id(obj: Mapping[str, Any]) -> str:
    ident = obj.get("id")
    return ident if isinstance(ident, str) and ident else "-"


def _lang_from_lexeme(obj: Mapping[str, Any]) -> str | None:
    language = obj.get("language")
    if isinstance(language, str) and language:
        return language
    ident = _object_id(obj)
    match = _LEXEME_ID_RE.match(ident)
    return match.group("lang") if match else None


def has_tone_mark(text: str) -> bool:
    decomposed = unicodedata.normalize("NFD", text)
    return any(ch in _TONE_MARKS for ch in decomposed)


def check_lexeme_tone_marks(obj: Mapping[str, Any]) -> ValidationFinding | None:
    lang = _lang_from_lexeme(obj)
    lemma = obj.get("lemma")
    if lang not in _TONAL_LANGS or not isinstance(lemma, str) or not lemma:
        return None
    if has_tone_mark(lemma):
        return None
    ident = _object_id(obj)
    return ValidationFinding(
        "MISSING_TONE_MARKS",
        ident,
        f"lemma missing tone marks for tonal language {lang}",
        "lemma",
    )


def _blob_sha256_prefix(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def _check_audio_mapping(
    spoken_text: str,
    audio: object,
    *,
    object_id: str,
    location: str,
    blob_root: Path | None,
) -> ValidationFinding | None:
    if audio is None:
        return None
    if not isinstance(audio, Mapping):
        return ValidationFinding("AUDIO_MISMATCH", object_id, "audio must be a mapping", location)
    uri = audio.get("uri")
    if not isinstance(uri, str) or not _AUDIO_URI_RE.match(uri):
        return ValidationFinding("AUDIO_MISMATCH", object_id, "audio.uri must be a content-hash path", location)
    uri_hash = _AUDIO_URI_RE.match(uri).group(1)
    text_hash = audio.get("text_hash")
    expected = audio_content_hash(spoken_text)
    if isinstance(text_hash, str) and text_hash and text_hash != expected:
        return ValidationFinding(
            "AUDIO_MISMATCH",
            object_id,
            "audio text_hash does not match spoken text",
            location,
        )
    if uri_hash != expected and (not isinstance(text_hash, str) or text_hash != expected):
        return ValidationFinding(
            "AUDIO_MISMATCH",
            object_id,
            "audio uri hash does not match spoken text",
            location,
        )
    if blob_root is not None:
        blob_path = blob_root / uri.split("/", 1)[-1]
        if blob_path.is_file():
            prefix = _blob_sha256_prefix(blob_path.read_bytes())
            if prefix != uri_hash:
                return ValidationFinding(
                    "AUDIO_MISMATCH",
                    object_id,
                    "audio file hash does not match uri",
                    location,
                )
        transcript = audio.get("transcript")
        if isinstance(transcript, str) and transcript != spoken_text:
            return ValidationFinding(
                "AUDIO_MISMATCH",
                object_id,
                "audio transcript differs from spoken text",
                location,
            )
    return None


def check_audio_in_object(
    obj: Mapping[str, Any],
    *,
    blob_root: Path | None = None,
) -> list[ValidationFinding]:
    findings: list[ValidationFinding] = []
    ident = _object_id(obj)

    lemma = obj.get("lemma")
    if isinstance(lemma, str):
        audio_list = obj.get("audio")
        if isinstance(audio_list, list):
            for index, entry in enumerate(audio_list):
                hit = _check_audio_mapping(
                    lemma,
                    entry,
                    object_id=ident,
                    location=f"audio[{index}]",
                    blob_root=blob_root,
                )
                if hit is not None:
                    findings.append(hit)

    turns = obj.get("turns")
    if isinstance(turns, list):
        for index, turn in enumerate(turns):
            if not isinstance(turn, Mapping):
                continue
            text = turn.get("text")
            if not isinstance(text, str):
                continue
            hit = _check_audio_mapping(
                text,
                turn.get("audio"),
                object_id=ident,
                location=f"turns[{index}].audio",
                blob_root=blob_root,
            )
            if hit is not None:
                findings.append(hit)
    return findings


def check_release_review(obj: Mapping[str, Any], *, release_pack: bool) -> ValidationFinding | None:
    if not release_pack:
        return None
    review = obj.get("review")
    if not isinstance(review, Mapping):
        return ValidationFinding(
            "UNREVIEWED_ITEM",
            _object_id(obj),
            "review is required in release packs",
            "review",
        )
    status = review.get("status")
    if status != "approved":
        return ValidationFinding(
            "UNREVIEWED_ITEM",
            _object_id(obj),
            f"review.status must be approved for release (got {status!r})",
            "review.status",
        )
    return None


def validate_object(
    obj: Mapping[str, Any],
    *,
    release_pack: bool = False,
    blob_root: Path | None = None,
) -> list[ValidationFinding]:
    findings: list[ValidationFinding] = []
    if _LEXEME_ID_RE.match(_object_id(obj)):
        tone = check_lexeme_tone_marks(obj)
        if tone is not None:
            findings.append(tone)
    findings.extend(check_audio_in_object(obj, blob_root=blob_root))
    review = check_release_review(obj, release_pack=release_pack)
    if review is not None:
        findings.append(review)
    return findings


def _load_json(path: Path) -> tuple[Any | None, str | None]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        return None, str(exc)


def _iter_content_json(root: Path) -> Sequence[Path]:
    if root.is_file():
        return [root]
    return [
        path
        for path in sorted(root.rglob("*.json"))
        if path.is_file() and ".git" not in path.parts
    ]


def validate_content_tree(
    root: Path,
    *,
    release_pack: bool = False,
    blob_root: Path | None = None,
    scan_placeholders: bool = True,
) -> list[ValidationFinding]:
    findings: list[ValidationFinding] = []

    manifest_path = root / "manifest.json" if root.is_dir() else None
    pack_release = release_pack
    if manifest_path is not None and manifest_path.is_file():
        manifest, err = _load_json(manifest_path)
        if err is None and isinstance(manifest, Mapping):
            if manifest.get("format") == _PACK_FORMAT:
                pack_release = pack_release or manifest.get("channel") == "release"
                objects_dir = root / "objects"
                blob_root = blob_root or (root / "blobs")
                for row in manifest.get("objects", []):
                    if not isinstance(row, Mapping):
                        continue
                    sha = row.get("sha256")
                    if not isinstance(sha, str):
                        continue
                    obj_path = objects_dir / f"{sha}.json"
                    if not obj_path.is_file():
                        findings.append(
                            ValidationFinding(
                                "PACK_OBJECT_MISSING",
                                str(row.get("id", "-")),
                                f"missing object file {obj_path.name}",
                            )
                        )
                        continue
                    document, read_err = _load_json(obj_path)
                    if read_err is not None or not isinstance(document, Mapping):
                        continue
                    findings.extend(
                        validate_object(document, release_pack=pack_release, blob_root=blob_root)
                    )
                if scan_placeholders:
                    for hit in scan_tree(root):
                        findings.append(
                            ValidationFinding(
                                "PLACEHOLDER_TEXT",
                                "-",
                                f"placeholder marker {hit.matched!r}",
                                f"{hit.path}:{hit.line}:{hit.column}",
                            )
                        )
                return findings

    for path in _iter_content_json(root):
        document, err = _load_json(path)
        if err is not None:
            findings.append(ValidationFinding("JSON_INVALID", "-", err, str(path)))
            continue
        if isinstance(document, Mapping) and "items" in document:
            items = document.get("items")
            if isinstance(items, list):
                for item in items:
                    if isinstance(item, Mapping):
                        findings.extend(
                            validate_object(item, release_pack=pack_release, blob_root=blob_root)
                        )
            continue
        if isinstance(document, Mapping):
            findings.extend(validate_object(document, release_pack=pack_release, blob_root=blob_root))

    if scan_placeholders:
        for hit in scan_tree(root):
            findings.append(
                ValidationFinding(
                    "PLACEHOLDER_TEXT",
                    "-",
                    f"placeholder marker {hit.matched!r}",
                    f"{hit.path}:{hit.line}:{hit.column}",
                )
            )
    return findings


def format_findings(findings: Sequence[ValidationFinding]) -> str:
    lines: list[str] = []
    for row in findings:
        loc = f" {row.location}" if row.location else ""
        lines.append(f"{row.code} {row.object_id}{loc} {row.message}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    args = list(argv if argv is not None else sys.argv[1:])
    release_pack = False
    if "--release-pack" in args:
        release_pack = True
        args = [a for a in args if a != "--release-pack"]
    if not args:
        print(
            "usage: validate_content.py [--release-pack] path [path ...]",
            file=sys.stderr,
        )
        return 2

    all_findings: list[ValidationFinding] = []
    for raw in args:
        root = Path(raw)
        if not root.is_absolute():
            root = (_REPO_ROOT / root).resolve()
        if not root.exists():
            print(f"missing path: {root}", file=sys.stderr)
            return 2
        all_findings.extend(validate_content_tree(root, release_pack=release_pack))

    if all_findings:
        print(format_findings(all_findings))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
