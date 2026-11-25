#!/usr/bin/env python3
"""P10-930: Lint analytics event JSON schemas for PII field names and version metadata."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_DIR = ROOT / "schemas" / "analytics"

PII_NAME_RE = re.compile(
    r"(email|e_mail|phone|telephone|mobile_number|full_name|first_name|last_name|"
    r"display_name|free_?text|transcript|audio|voice_recording|password|ssn|"
    r"account_id|user_id|mongo_?id)",
    re.IGNORECASE,
)

ALLOWED_EXCEPTIONS = frozenset({"pseudonymous_user_id"})


def iter_property_paths(node: Any, prefix: str = "") -> Iterable[str]:
    if not isinstance(node, dict):
        return
    props = node.get("properties")
    if isinstance(props, dict):
        for key, child in props.items():
            path = f"{prefix}/{key}" if prefix else key
            yield path
            yield from iter_property_paths(child, path)
    for combiner in ("oneOf", "anyOf", "allOf"):
        items = node.get(combiner)
        if isinstance(items, list):
            for child in items:
                yield from iter_property_paths(child, prefix)
    defs = node.get("$defs") or node.get("definitions")
    if isinstance(defs, dict):
        for child in defs.values():
            yield from iter_property_paths(child, prefix)


def lint_schema_file(path: Path) -> list[str]:
    errors: list[str] = []
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return [f"{path}: root must be an object"]

    schema_id = data.get("$id", "")
    if not schema_id:
        errors.append(f"{path}: missing $id (versioned schema identifier)")

    for prop_path in iter_property_paths(data):
        leaf = prop_path.split("/")[-1]
        if leaf in ALLOWED_EXCEPTIONS:
            continue
        if PII_NAME_RE.search(leaf):
            errors.append(f"{path}: PII-like field name '{prop_path}'")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint LingAfriq analytics JSON schemas")
    parser.add_argument(
        "--schema-dir",
        type=Path,
        default=SCHEMA_DIR,
        help="Directory containing events.v*.json",
    )
    args = parser.parse_args()
    schema_dir: Path = args.schema_dir
    if not schema_dir.is_dir():
        print(f"analytics schema dir missing: {schema_dir}", file=sys.stderr)
        return 1

    files = sorted(schema_dir.glob("events.v*.json"))
    if not files:
        print(f"no events.v*.json under {schema_dir}", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    for path in files:
        all_errors.extend(lint_schema_file(path))

    if all_errors:
        for err in all_errors:
            print(err, file=sys.stderr)
        return 1

    print(f"ok: {len(files)} analytics schema file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
