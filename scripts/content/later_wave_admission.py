"""Later-wave language admission template and validator (P13-001, CURRICULUM §2.4)."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Mapping

import yaml

CARD_ID = "P13-001"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_TEMPLATE_PATH = _REPO_ROOT / "content/templates/later_wave_language.yaml"
_DEFAULT_REGISTER_PATH = _REPO_ROOT / "curriculum/sources/licence_register.json"

_REQUIRED_SLOTS = (
    "orthography_authority",
    "lexicon",
    "reference_grammar",
    "corpus",
)

_CORPUS_LICENCE_MARKERS = (
    "cc by",
    "cc-by",
    "public domain",
    "pd",
    "cc0",
)


class LaterWaveAdmissionError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def template_path() -> Path:
    return _TEMPLATE_PATH


def load_template(path: Path | None = None) -> str:
    p = path or _TEMPLATE_PATH
    if not p.is_file():
        raise LaterWaveAdmissionError("TEMPLATE_MISSING", f"admission template not found: {p}")
    return p.read_text(encoding="utf-8")


def materialize_admission_file(
    language_id: str,
    display_name: str,
    *,
    template_text: str | None = None,
) -> str:
    lang = language_id.strip()
    if not re.fullmatch(r"[a-z]{2,3}(-[A-Za-z]{4})?", lang):
        raise LaterWaveAdmissionError("LANGUAGE_ID_INVALID", "language_id must be a BCP-47-style id")
    name = display_name.strip()
    if not name:
        raise LaterWaveAdmissionError("DISPLAY_NAME_MISSING", "display_name is required")
    raw = template_text if template_text is not None else load_template()
    return (
        raw.replace("{{LANGUAGE_ID}}", lang)
        .replace("{{DISPLAY_NAME}}", name)
    )


def parse_admission_yaml(text: str) -> dict[str, Any]:
    data = yaml.safe_load(text)
    if not isinstance(data, dict):
        raise LaterWaveAdmissionError("ADMISSION_INVALID", "admission root must be a mapping")
    return data


def load_admission_file(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise LaterWaveAdmissionError("ADMISSION_MISSING", f"admission file not found: {path}")
    return parse_admission_yaml(path.read_text(encoding="utf-8"))


def load_licence_register(path: Path | None = None) -> list[Mapping[str, Any]]:
    p = path or _DEFAULT_REGISTER_PATH
    if not p.is_file():
        raise LaterWaveAdmissionError("REGISTER_MISSING", f"licence register not found: {p}")
    rows = json.loads(p.read_text(encoding="utf-8"))
    if not isinstance(rows, list):
        raise LaterWaveAdmissionError("REGISTER_INVALID", "licence register must be a JSON array")
    return rows


def _register_ids(rows: list[Mapping[str, Any]]) -> frozenset[str]:
    ids: set[str] = set()
    for row in rows:
        rid = row.get("id")
        if isinstance(rid, str) and rid.strip():
            ids.add(rid.strip())
    return frozenset(ids)


def _slot_label(slot_key: str) -> str:
    return slot_key.replace("_", " ")


def _non_empty_str(value: Any, *, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise LaterWaveAdmissionError("ENTRY_INCOMPLETE", f"{field} must be a non-empty string")
    return value.strip()


def _corpus_licence_ok(licence: str) -> bool:
    lower = licence.lower()
    return any(marker in lower for marker in _CORPUS_LICENCE_MARKERS)


def validate_admission_document(
    doc: Mapping[str, Any],
    *,
    register_rows: list[Mapping[str, Any]] | None = None,
) -> None:
    if doc.get("card_id") != CARD_ID:
        raise LaterWaveAdmissionError("CARD_ID_MISMATCH", f"card_id must be {CARD_ID}")
    lang = doc.get("language_id")
    if not isinstance(lang, str) or not lang.strip() or "{{" in lang:
        raise LaterWaveAdmissionError("LANGUAGE_ID_MISSING", "language_id must be set")
    admission = doc.get("admission")
    if not isinstance(admission, dict):
        raise LaterWaveAdmissionError("ADMISSION_MISSING", "admission object required")

    known_register = _register_ids(register_rows) if register_rows is not None else None

    for slot_key in _REQUIRED_SLOTS:
        entry = admission.get(slot_key)
        if not isinstance(entry, dict):
            raise LaterWaveAdmissionError(
                "ENTRY_MISSING",
                f"missing admission entry: {_slot_label(slot_key)}",
            )
        title = entry.get("title")
        if not isinstance(title, str) or not title.strip():
            raise LaterWaveAdmissionError(
                "ENTRY_INCOMPLETE",
                f"{_slot_label(slot_key)} title is empty",
            )
        try:
            licence = _non_empty_str(entry.get("licence"), field=f"{slot_key}.licence")
            register_id = _non_empty_str(entry.get("register_id"), field=f"{slot_key}.register_id")
        except LaterWaveAdmissionError as exc:
            if exc.code == "ENTRY_INCOMPLETE":
                raise LaterWaveAdmissionError(
                    "ENTRY_INCOMPLETE",
                    f"{_slot_label(slot_key)}: {exc.args[0]}",
                ) from exc
            raise
        if slot_key == "corpus" and not _corpus_licence_ok(licence):
            raise LaterWaveAdmissionError(
                "CORPUS_LICENCE_INVALID",
                f"corpus licence must be CC-BY or public domain, got: {licence}",
            )
        if known_register is not None and register_id not in known_register:
            raise LaterWaveAdmissionError(
                "REGISTER_ID_UNKNOWN",
                f"{slot_key}.register_id {register_id} not in licence register",
            )


def write_admission_file(
    path: Path,
    language_id: str,
    display_name: str,
    *,
    template_path: Path | None = None,
) -> None:
    text = materialize_admission_file(
        language_id,
        display_name,
        template_text=load_template(template_path),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Later-wave language admission (P13-001)")
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("generate", help="Write a new admission file from the template")
    gen.add_argument("language_id")
    gen.add_argument("display_name")
    gen.add_argument("-o", "--output", type=Path, required=True)

    val = sub.add_parser("validate", help="Validate a filled admission YAML file")
    val.add_argument("path", type=Path)
    val.add_argument(
        "--register",
        type=Path,
        default=_DEFAULT_REGISTER_PATH,
        help="licence_register.json for register_id cross-check",
    )

    args = parser.parse_args(argv)
    if args.command == "generate":
        write_admission_file(args.output, args.language_id, args.display_name)
        return 0
    if args.command == "validate":
        doc = load_admission_file(args.path)
        rows = load_licence_register(args.register)
        validate_admission_document(doc, register_rows=rows)
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
