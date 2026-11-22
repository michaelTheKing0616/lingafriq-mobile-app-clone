#!/usr/bin/env python3
"""List Draft cards Tope unblocked on 2026-11-22.

Predecessor depends_on do not block a start. External obtain-cards and cards
already marked Blocked-External stay blocked. Moonshot cards stay behind
their own start gate. A listed card is not Done until its acceptance criteria pass.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "docs" / "build" / "cards"
STATUS = ROOT / "docs" / "plan" / "CARD_STATUS.tsv"
WAIVER = ROOT / "docs" / "plan" / "GATE_WAIVER.tsv"
STARTABLE_KINDS = {"build", "feature", "design", "adr", "verification"}
MOONSHOTS = {f"P13-{n:03d}" for n in range(5, 12)}


def _status() -> dict[str, str]:
    rows: dict[str, str] = {}
    with STATUS.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            rows[row["id"]] = row["status"]
    return rows


def _cards() -> dict[str, dict]:
    found: dict[str, dict] = {}
    for path in CARDS.rglob("*.yaml"):
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        if isinstance(data, dict) and data.get("id"):
            found[str(data["id"])] = data
    return found


def ready() -> list[dict]:
    if not WAIVER.is_file():
        raise SystemExit("GATE_WAIVER.tsv is missing")
    text = WAIVER.read_text(encoding="utf-8")
    if "2026-11-22" not in text or "waived unmet depends_on" not in text:
        raise SystemExit("GATE_WAIVER.tsv is missing the 2026-11-22 waiver")
    status = _status()
    cards = _cards()
    out: list[dict] = []
    for cid, card in cards.items():
        kind = card.get("kind")
        ledger = status.get(cid, card.get("status"))
        if kind not in STARTABLE_KINDS or ledger != "Draft":
            continue
        if cid in MOONSHOTS or kind == "external":
            continue
        if card.get("external_blockers"):
            continue
        out.append(card)
    return sorted(out, key=lambda card: str(card["id"]))


def main() -> int:
    rows = ready()
    print(f"{len(rows)} cards can start")
    for card in rows:
        print(f"{card['id']}\t{card.get('kind')}\t{card.get('title')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
