#!/usr/bin/env python3
"""P10-919: Validate DPIA draft structure and draft status (counsel sign-off via EXT-18)."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
DPIA_PATH = ROOT / "docs" / "privacy" / "DPIA.md"

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
SECTIONS_BLOCK_RE = re.compile(
    r"dpia_required_sections:\s*\n((?:\s+-\s+\".+\"\s*\n)+)",
    re.MULTILINE,
)
SECTION_ITEM_RE = re.compile(r'^\s*-\s*"(.+)"\s*$', re.MULTILINE)
HEADING_RE = re.compile(r"^## (.+)$", re.MULTILINE)


def load_dpia() -> tuple[dict, str]:
    text = DPIA_PATH.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    if not m:
        raise ValueError("DPIA.md: missing YAML front matter")
    meta = yaml.safe_load(m.group(1)) or {}
    body = text[m.end() :]
    return meta, body


def required_sections(body: str) -> list[str]:
    m = SECTIONS_BLOCK_RE.search(body)
    if not m:
        raise ValueError("DPIA.md: missing dpia_required_sections yaml block")
    return [g.strip() for g in SECTION_ITEM_RE.findall(m.group(1))]


def run_gate() -> list[str]:
    errors: list[str] = []
    if not DPIA_PATH.is_file():
        return ["DPIA.md missing"]
    try:
        meta, body = load_dpia()
    except ValueError as exc:
        return [str(exc)]

    if meta.get("status") != "draft":
        errors.append("status must remain draft until counsel signs (EXT-18)")
    if meta.get("counsel_signoff") != "pending":
        errors.append("counsel_signoff must be pending until EXT-18 closes")
    if meta.get("ext18_open") is not True:
        errors.append("ext18_open must be true while EXT-18 is open")
    for key in ("version", "effective_date"):
        if not meta.get(key):
            errors.append(f"front matter missing {key}")

    headings = {h.strip() for h in HEADING_RE.findall(body)}
    for section in required_sections(body):
        if section not in headings:
            errors.append(f"missing section heading: {section}")

    for phrase in (
        "delete raw audio after scoring",
        "guardian",
        "EXT-18",
        "minors not offered",
    ):
        if phrase.lower() not in body.lower():
            errors.append(f"missing required phrase: {phrase}")

    if "| V-01 |" not in body or "| M-02 |" not in body:
        errors.append("processing table must include V-01 and M-02 rows")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gate", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        errs = run_gate()
        return 1 if errs else 0

    if args.gate:
        errs = run_gate()
        if errs:
            for e in errs:
                print(e, file=sys.stderr)
            return 1
        print("dpia_check: OK (draft, EXT-18 open items present)")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
