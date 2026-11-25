#!/usr/bin/env python3
"""T0: every RTM row must map to ≥1 card, an EXTERNAL.md item or a DECISIONS.md line (charter: v2).

Usage: python3 scripts/plan/check_rtm_coverage.py [--write]
  --write  fills RTM.csv column card_ids from the cards (idempotent) and sets status
           Mapped / Blocked-External / Waived-by-Tope for Open rows.
Exit 1 and list unmapped req_ids otherwise. Also asserts P0-1…27 and F-001…151 all mapped.
"""
from __future__ import annotations

import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "docs" / "build"
RTM = BUILD / "RTM.csv"
CARDS = BUILD / "cards"
EXTERNAL = BUILD / "EXTERNAL.md"
DECISIONS = BUILD / "DECISIONS.md"
ID_RE = re.compile(r"\b(P0-\d+|F-\d{3}(?:\.[DEUL])?|EP-§[\d.]+-[\w-]+|CP-§[\w.]+-[\w-]+|AV-step\d|OB-step\d[\w-]*|REV-\d+|CON-\d+|DEV-\d+|RM-(?:P0|P1|P2|MS|STOP)-\d+|D[1-5]|UNV-[EC]\d+)\b")
FIELDS = ["req_id", "source_doc", "anchor", "type", "verbatim_hook", "priority", "owner", "card_ids", "status"]


def main(argv: list[str]) -> int:
    with RTM.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    ids = {r["req_id"] for r in rows}
    mapped: dict[str, set[str]] = defaultdict(set)
    blocked: set[str] = set()
    for p in sorted(CARDS.rglob("*.yaml")):
        card = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        for rid in card.get("req_ids") or []:
            mapped[rid].add(card.get("id", p.stem))
            if card.get("kind") == "external":
                blocked.add(rid)
    ext_ids = set(ID_RE.findall(EXTERNAL.read_text(encoding="utf-8"))) if EXTERNAL.exists() else set()
    dec_ids = set(ID_RE.findall(DECISIONS.read_text(encoding="utf-8"))) if DECISIONS.exists() else set()
    unmapped = [r for r in rows if r["req_id"] not in mapped and r["req_id"] not in ext_ids and r["req_id"] not in dec_ids]
    must = [f"P0-{n}" for n in range(1, 28)] + [f"F-{n:03d}" for n in range(1, 152)]
    missing_must = [m for m in must if m not in mapped]
    if "--write" in argv:
        for r in rows:
            cards = sorted(mapped.get(r["req_id"], set()))
            r["card_ids"] = ";".join(cards)
            if r["status"] in {"Open", "Mapped", "Blocked-External", "Waived-by-Tope"}:
                if r["req_id"] in blocked and len(cards) == 1:
                    r["status"] = "Blocked-External"
                elif cards:
                    r["status"] = "Mapped"
                elif r["req_id"] in dec_ids:
                    r["status"] = "Decision"
                elif r["req_id"] in ext_ids:
                    r["status"] = "Blocked-External"
        with RTM.open("w", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=FIELDS)
            w.writeheader()
            w.writerows(rows)
    by_card_count = sum(len(v) for v in mapped.values())
    print(f"rtm rows {len(rows)} · mapped by cards {sum(1 for r in rows if r['req_id'] in mapped)} · by EXTERNAL only "
          f"{sum(1 for r in rows if r['req_id'] not in mapped and r['req_id'] in ext_ids)} · by DECISIONS only "
          f"{sum(1 for r in rows if r['req_id'] not in mapped and r['req_id'] not in ext_ids and r['req_id'] in dec_ids)} · "
          f"unmapped {len(unmapped)} · card→req links {by_card_count}")
    if missing_must:
        print(f"MUST-MAP missing: {missing_must}", file=sys.stderr)
    if unmapped:
        for r in unmapped:
            print(f"UNMAPPED {r['req_id']}\t{r['anchor']}\t{r['type']}\t{r['verbatim_hook']}", file=sys.stderr)
    return 1 if unmapped or missing_must else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
