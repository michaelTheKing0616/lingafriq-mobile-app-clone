#!/usr/bin/env python3
"""T0: list req_ids of one RTM slice that no card (and no EXTERNAL/DECISIONS line) covers yet (charter: v2).

Usage: python3 scripts/plan/slice_coverage.py docs/build/rtm_slices/<slice>.csv
Prints `OK` or one `req_id<TAB>anchor<TAB>type<TAB>hook` line per uncovered row.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "docs" / "build"
ID_RE = re.compile(r"\b(P0-\d+|F-\d{3}(?:\.[DEUL])?|EP-§[\d.]+-[\w-]+|CP-§[\w.]+-[\w-]+|AV-step\d|OB-step\d[\w-]*|REV-\d+|CON-\d+|DEV-\d+|RM-(?:P0|P1|P2|MS|STOP)-\d+|D[1-5]|UNV-[EC]\d+)\b")


def main(argv: list[str]) -> int:
    slice_path = Path(argv[0])
    covered: set[str] = set()
    for p in (BUILD / "cards").rglob("*.yaml"):
        try:
            card = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError:
            continue
        covered.update(card.get("req_ids") or [])
    for doc in ("EXTERNAL.md", "DECISIONS.md"):
        f = BUILD / doc
        if f.exists():
            covered.update(ID_RE.findall(f.read_text(encoding="utf-8")))
    with slice_path.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    missing = [r for r in rows if r["req_id"] not in covered]
    for r in missing:
        print(f"{r['req_id']}\t{r['anchor']}\t{r['type']}\t{r['verbatim_hook']}")
    print(f"{'OK' if not missing else 'UNCOVERED'}: {len(rows) - len(missing)}/{len(rows)} covered")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
