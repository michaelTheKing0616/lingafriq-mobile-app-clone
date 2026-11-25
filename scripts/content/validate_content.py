#!/usr/bin/env python3
"""Validate LingAfriq content packs against content/schema/v1.json.

Usage:
  python3 scripts/content/validate_content.py pack.json [pack.json ...]
  python3 scripts/content/validate_content.py --legacy-report REPORT bundle [bundle ...]

A pack failure prints the item id and a JSON pointer. Text that is not NFC
names the field. A tonal-language lemma with no tone mark fails. Legacy
bundles are rejected and written to the migration report. The legacy run
exits 0 only when none of those files is accepted as v1.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_PATH = ROOT / "content" / "schema" / "v1.json"
VERSION = "lingafriq.content.v1"
REQUIRED_PROPERTY = re.compile(r"^'([^']+)' is a required property$")
TONAL = frozenset({"yo", "ig", "ha", "tw", "zu", "xh"})
TONE_MARKS = frozenset("\u0300\u0301\u0304\u0302\u030c\u030b\u030f")
LEGACY_DIRS = (
    "curriculum_bundle",
    "curriculum_expanded_bundle",
    "lingafriq_FINAL_curriculum",
    "lingafriq_full_curriculum_bundle",
)


def load_validator() -> Draft202012Validator:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def pointer(error: ValidationError) -> str:
    parts: list[str] = []
    for bit in error.absolute_path:
        text = str(bit).replace("~", "~0").replace("/", "~1")
        parts.append(text)
    base = "/" + "/".join(parts) if parts else "/"
    # if/then reports a missing field on the object, not on the field.
    match = REQUIRED_PROPERTY.match(error.message)
    if match:
        name = match.group(1).replace("~", "~0").replace("/", "~1")
        suffix = "/" + name
        if not base.endswith(suffix):
            return suffix if base == "/" else base + suffix
    return base


def item_id(document: object, error: ValidationError) -> str:
    path = list(error.absolute_path)
    if len(path) >= 2 and path[0] == "items" and isinstance(path[1], int):
        items = document.get("items") if isinstance(document, dict) else None
        if isinstance(items, list) and path[1] < len(items):
            item = items[path[1]]
            if isinstance(item, dict) and isinstance(item.get("id"), str) and item["id"]:
                return item["id"]
    return "-"


def schema_failures(validator: Draft202012Validator, document: object) -> list[str]:
    lines: list[str] = []
    for error in sorted(validator.iter_errors(document), key=lambda err: list(err.absolute_path)):
        lines.append(f"{item_id(document, error)} {pointer(error)} {error.message}")
    return lines


def walk_strings(node: object, path: list[str], found: list[tuple[str, str, str]]):
    if isinstance(node, str):
        field = path[-1] if path else "/"
        found.append(("/" + "/".join(path) if path else "/", field, node))
        return
    if isinstance(node, list):
        for index, child in enumerate(node):
            walk_strings(child, [*path, str(index)], found)
        return
    if isinstance(node, dict):
        for key, child in node.items():
            walk_strings(child, [*path, str(key).replace("~", "~0").replace("/", "~1")], found)


def nfc_failures(document: dict) -> list[str]:
    lines: list[str] = []
    strings: list[tuple[str, str, str]] = []
    walk_strings(document, [], strings)
    for ptr, field, value in strings:
        if unicodedata.normalize("NFC", value) != value:
            lines.append(f"- {ptr} field {field} is not NFC")
    return lines


def has_tone_mark(text: str) -> bool:
    decomposed = unicodedata.normalize("NFD", text)
    return any(ch in TONE_MARKS for ch in decomposed)


def tone_failures(document: dict) -> list[str]:
    lines: list[str] = []
    items = document.get("items")
    if not isinstance(items, list):
        return lines
    for index, item in enumerate(items):
        if not isinstance(item, dict) or item.get("kind") != "lexeme":
            continue
        language = item.get("language")
        lemma = item.get("lemma")
        if language not in TONAL or not isinstance(lemma, str):
            continue
        if has_tone_mark(lemma):
            continue
        ident = item.get("id") if isinstance(item.get("id"), str) else "-"
        lines.append(f"{ident} /items/{index}/lemma field lemma missing tone mark")
    return lines


def validate_document(validator: Draft202012Validator, document: object) -> list[str]:
    failures = schema_failures(validator, document)
    if not isinstance(document, dict):
        return failures
    if document.get("schema_version") != VERSION:
        return failures
    return failures + nfc_failures(document) + tone_failures(document)


def iter_json(root: Path):
    if root.is_file():
        yield root
        return
    for path in sorted(root.rglob("*.json")):
        if path.is_file() and ".git" not in path.parts:
            yield path


def read_json(path: Path) -> tuple[object | None, str | None]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        return None, str(exc)


def legacy_report(validator: Draft202012Validator, roots: list[Path], report: Path) -> int:
    rows: list[str] = ["# migration report"]
    accepted = 0
    rejected = 0
    for root in roots:
        if not root.exists():
            print(f"missing bundle: {root}", file=sys.stderr)
            return 2
        for path in iter_json(root):
            rel = path.resolve().relative_to(ROOT).as_posix() if path.resolve().is_relative_to(ROOT) else path.as_posix()
            document, error = read_json(path)
            if error is not None:
                rejected += 1
                rows.append(f"{rel}\trejected\t{error}")
                continue
            failures = validate_document(validator, document)
            if failures:
                rejected += 1
                rows.append(f"{rel}\trejected\t{failures[0]}")
            else:
                accepted += 1
                rows.append(f"{rel}\taccepted")
    rows.append(f"accepted {accepted}")
    rows.append(f"rejected {rejected}")
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"migration report {report} accepted {accepted} rejected {rejected}")
    return 1 if accepted else 0


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[0] == "--legacy-report":
        if len(argv) < 3:
            print("usage: validate_content.py --legacy-report REPORT bundle [bundle ...]", file=sys.stderr)
            return 2
        validator = load_validator()
        return legacy_report(validator, [Path(p) for p in argv[2:]], Path(argv[1]))
    if not argv:
        print("usage: validate_content.py pack.json [pack.json ...]", file=sys.stderr)
        return 2
    validator = load_validator()
    failed = False
    for raw in argv:
        root = Path(raw)
        if not root.exists():
            print(f"missing path: {root}", file=sys.stderr)
            return 2
        for path in iter_json(root):
            document, error = read_json(path)
            if error is not None:
                print(f"- / {error}")
                failed = True
                continue
            failures = validate_document(validator, document)
            if failures:
                failed = True
                print("\n".join(failures))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
