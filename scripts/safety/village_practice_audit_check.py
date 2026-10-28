#!/usr/bin/env python3
"""P9-959: Verify Village practice audit artefact (EP-§9.2-01/02)."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / "docs" / "build" / "external" / "village_practice_audit.md"
ELEVATION = ROOT / "docs" / "source" / "ELEVATION.md"

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
TABLE_ROW = re.compile(r"^\|[^|]+\|", re.MULTILINE)
FLAG = re.compile(r"\|\s*Y\s*\|")


def load_audit() -> tuple[dict, str]:
    text = AUDIT.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    if not m:
        raise ValueError("village_practice_audit.md: missing YAML front matter")
    meta = yaml.safe_load(m.group(1)) or {}
    return meta, text[m.end() :]


def parse_table_rows(section: str) -> list[list[str]]:
    lines = [ln.strip() for ln in section.splitlines() if ln.strip().startswith("|")]
    if len(lines) < 3:
        return []
    rows: list[list[str]] = []
    for ln in lines[2:]:
        if re.match(r"^\|\s*---", ln):
            continue
        cells = [c.strip() for c in ln.strip("|").split("|")]
        rows.append(cells)
    return rows


def section(body: str, heading: str) -> str:
    marker = f"## {heading}"
    start = body.find(marker)
    if start < 0:
        return ""
    rest = body[start + len(marker) :]
    nxt = rest.find("\n## ")
    return rest if nxt < 0 else rest[:nxt]


def row_has_dimension(cells: list[str]) -> bool:
    dims = cells[-4:] if len(cells) >= 4 else cells
    return any(c.strip().upper() == "Y" for c in dims)


def check(meta: dict, body: str, errors: list[str]) -> None:
    if meta.get("card_id") != "P9-959":
        errors.append("front matter card_id must be P9-959")
    if meta.get("audit_complete") is not True:
        errors.append("audit_complete must be true")
    if not ELEVATION.is_file():
        errors.append("missing docs/source/ELEVATION.md")
    if "Village practice audit" not in body:
        errors.append("missing title section")
    if "## Defects" not in body:
        errors.append("missing Defects section")

    implemented = parse_table_rows(section(body, "Implemented surfaces (P9 / F Done)"))
    planned = parse_table_rows(section(body, "Planned Village surfaces (F Draft — outcome named, not yet elevated)"))
    defects = parse_table_rows(section(body, "Defects (fail all four: S, V, E, C)"))

    canonical = int(meta.get("canonical_surfaces") or 0)
    if len(implemented) < 8:
        errors.append(f"implemented table needs ≥8 §9.2 rows, got {len(implemented)}")
    if canonical != len(implemented):
        errors.append(
            f"canonical_surfaces ({canonical}) must match implemented row count ({len(implemented)})"
        )

    defect_count = int(meta.get("defect_count") or 0)
    if defect_count != len(defects):
        errors.append(f"defect_count ({defect_count}) != defect rows ({len(defects)})")

    for i, cells in enumerate(implemented + planned, start=1):
        if len(cells) < 5:
            errors.append(f"table row {i} too short")
            continue
        outcome_idx = 3 if len(cells) >= 9 else 2
        outcome = cells[outcome_idx] if len(cells) > outcome_idx else ""
        if not outcome or outcome in ("---", "P / B outcome"):
            errors.append(f"row {i} missing practice/belonging outcome")
        if not row_has_dimension(cells):
            errors.append(f"row {i} must mark at least one of S/V/E/C with Y")

    for cells in defects:
        if len(cells) < 4:
            errors.append("defect row incomplete")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Validate audit artefact")
    args = parser.parse_args()
    if not args.check:
        parser.print_help()
        return 2
    errors: list[str] = []
    try:
        meta, body = load_audit()
        check(meta, body, errors)
    except (OSError, ValueError) as e:
        errors.append(str(e))
    if errors:
        for e in errors:
            print(f"village_practice_audit_check: {e}", file=sys.stderr)
        return 1
    print("village_practice_audit_check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
