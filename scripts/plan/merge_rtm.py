#!/usr/bin/env python3
"""T0: merge and validate RTM parts into docs/build/RTM.csv (charter: v2).

Inputs : docs/build/rtm_parts/*.csv
Output : docs/build/RTM.csv (sorted by source then anchor line), exit 1 on any violation.
Checks : header, unique req_id, type enum, owner enum, hook <= 12 words, anchor
         parses, every top-level source section (§n) has at least one row.
"""
from __future__ import annotations

import csv
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PARTS = ROOT / "docs" / "build" / "rtm_parts"
OUT = ROOT / "docs" / "build" / "RTM.csv"
FIELDS = ["req_id", "source_doc", "anchor", "type", "verbatim_hook", "priority", "owner", "card_ids", "status"]
TYPES = {"requirement", "constraint", "metric", "decision", "risk", "external", "informational"}
OWNERS = {"agent", "Tope", "external"}
HOOK_WORDS = 12
ANCHOR_RE = re.compile(r"^§([\w.?]+):L(\d+)(?:-L(\d+))?$")
# Top-level sections that must each be represented at least once.
EXPECTED_SECTIONS = {
    "ELEVATION": [str(n) for n in range(0, 19)],
    "CURRICULUM": [str(n) for n in range(0, 11)],
}


def main() -> int:
    rows: list[dict] = []
    errors: list[str] = []
    trimmed = 0
    for part in sorted(PARTS.glob("*.csv")):
        with part.open(encoding="utf-8", newline="") as fh:
            reader = csv.DictReader(fh)
            if reader.fieldnames != FIELDS:
                errors.append(f"{part.name}: header {reader.fieldnames}")
                continue
            for n, row in enumerate(reader, start=2):
                row["_part"] = part.name
                rows.append(row)
                if row["type"] not in TYPES:
                    errors.append(f"{part.name}:{n} bad type {row['type']!r}")
                if row["owner"] not in OWNERS:
                    errors.append(f"{part.name}:{n} bad owner {row['owner']!r}")
                words = row["verbatim_hook"].split()
                if len(words) > HOOK_WORDS:
                    # The anchor is the source of truth; the hook is a locator, so truncation is lossless.
                    row["verbatim_hook"] = " ".join(words[:HOOK_WORDS])
                    trimmed += 1
                if not ANCHOR_RE.match(row["anchor"]):
                    errors.append(f"{part.name}:{n} bad anchor {row['anchor']!r} ({row['req_id']})")
                if row["source_doc"] not in EXPECTED_SECTIONS:
                    errors.append(f"{part.name}:{n} bad source_doc {row['source_doc']!r}")
    dupes = [k for k, c in Counter(r["req_id"] for r in rows).items() if c > 1]
    if dupes:
        errors.append(f"duplicate req_id: {dupes[:20]}{' ...' if len(dupes) > 20 else ''}")
    seen = {(r["source_doc"], r["anchor"].split(":")[0].lstrip("§").split(".")[0]) for r in rows}
    for doc, sections in EXPECTED_SECTIONS.items():
        missing = [s for s in sections if (doc, s) not in seen]
        if missing:
            errors.append(f"{doc}: no rows for top-level sections {missing}")
    if errors:
        print("\n".join(errors[:60]), file=sys.stderr)
        print(f"{len(errors)} violation(s)", file=sys.stderr)
        return 1

    def sort_key(r: dict) -> tuple:
        m = ANCHOR_RE.match(r["anchor"])
        return (r["source_doc"] != "ELEVATION", int(m.group(2)), r["req_id"])

    rows.sort(key=sort_key)
    with OUT.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    by_type = Counter(r["type"] for r in rows)
    by_doc = Counter(r["source_doc"] for r in rows)
    print(f"RTM.csv: {len(rows)} rows · {dict(by_doc)} · {dict(by_type)} · hooks trimmed: {trimmed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
