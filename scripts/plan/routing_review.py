#!/usr/bin/env python3
"""Gate-time LEDGER review: per-tier stats, overruns, unmeasured tokens (charter: v2)."""
from __future__ import annotations

import argparse
import csv
import sys
import tempfile
import unittest
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
LEDGER_HEADER = (
    "card_id,role,model_tier,model_slug,tokens_in,tokens_out,attempts,outcome,note"
)
TIER_ORDER = ("T0", "T1", "T2", "T3", "T4")


@dataclass
class LedgerRow:
    card_id: str
    role: str
    model_tier: str
    model_slug: str
    tokens_in: str
    tokens_out: str
    attempts: int
    outcome: str
    note: str

    @property
    def unmeasured(self) -> bool:
        return self.tokens_in.strip().lower() == "n/a" or self.tokens_out.strip().lower() == "n/a"

    def token_sum(self) -> int | None:
        if self.unmeasured:
            return None
        return int(self.tokens_in) + int(self.tokens_out)


@dataclass
class TierStats:
    card_ids: set[str] = field(default_factory=set)
    retries: int = 0
    escalations: int = 0
    tokens: int = 0
    unmeasured_rows: int = 0
    budget: int = 0


def load_card_meta(cards_dir: Path) -> dict[str, dict]:
    meta: dict[str, dict] = {}
    for p in sorted(cards_dir.rglob("*.yaml")):
        c = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        cid = c.get("id", p.stem)
        meta[cid] = c
    return meta


def gate_for_card(card_id: str, meta: dict[str, dict]) -> str | None:
    c = meta.get(card_id)
    if c and c.get("gate"):
        return str(c["gate"])
    if card_id.startswith("P0-INT-") or card_id.startswith("ADR-"):
        return "G0"
    return None


def read_ledger(path: Path) -> list[LedgerRow]:
    text = path.read_text(encoding="utf-8")
    first = text.splitlines()[0].strip()
    if first != LEDGER_HEADER:
        raise ValueError(f"LEDGER header mismatch: expected {LEDGER_HEADER!r}, got {first!r}")
    rows: list[LedgerRow] = []
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(
                LedgerRow(
                    card_id=r["card_id"],
                    role=r["role"],
                    model_tier=r["model_tier"],
                    model_slug=r["model_slug"],
                    tokens_in=r["tokens_in"],
                    tokens_out=r["tokens_out"],
                    attempts=int(r["attempts"]),
                    outcome=r["outcome"],
                    note=r.get("note", ""),
                )
            )
    return rows


def card_tokens(rows: list[LedgerRow]) -> dict[str, int | None]:
    by_card: dict[str, list[LedgerRow]] = defaultdict(list)
    for row in rows:
        by_card[row.card_id].append(row)
    totals: dict[str, int | None] = {}
    for cid, crs in by_card.items():
        if any(r.unmeasured for r in crs):
            totals[cid] = None
            continue
        totals[cid] = sum(r.token_sum() or 0 for r in crs)
    return totals


def review(
    gate: str,
    ledger_path: Path,
    cards_dir: Path,
) -> tuple[str, list[str], int]:
    """Return (report text, overrun card ids, exit code)."""
    meta = load_card_meta(cards_dir)
    all_rows = read_ledger(ledger_path)
    rows = [r for r in all_rows if gate_for_card(r.card_id, meta) == gate]

    tier_stats: dict[str, TierStats] = {t: TierStats() for t in TIER_ORDER}
    budgets_seen: dict[str, int] = {}
    for row in rows:
        ts = tier_stats.get(row.model_tier)
        if ts is None:
            ts = TierStats()
            tier_stats[row.model_tier] = ts
        ts.card_ids.add(row.card_id)
        if row.attempts > 1:
            ts.retries += 1
        if row.attempts > 1 or row.outcome.strip().lower() in {"escalate", "escalated", "blocked"}:
            ts.escalations += 1
        if row.unmeasured:
            ts.unmeasured_rows += 1
        else:
            ts.tokens += row.token_sum() or 0
        c = meta.get(row.card_id)
        if c and "token_budget" in c:
            budgets_seen[row.card_id] = int(c["token_budget"])

    for cid in {r.card_id for r in rows}:
        c = meta.get(cid)
        if not c or "token_budget" not in c:
            continue
        tier = next((r.model_tier for r in rows if r.card_id == cid), None)
        if tier and tier in tier_stats:
            tier_stats[tier].budget += int(c["token_budget"])

    totals = card_tokens(rows)
    overruns: list[str] = []
    for cid, tok in totals.items():
        c = meta.get(cid)
        if not c or tok is None:
            continue
        budget = int(c.get("token_budget", 0))
        if budget and tok > budget:
            overruns.append(cid)

    lines = [f"routing_review: gate {gate}", f"ledger_rows: {len(rows)}", ""]
    lines.append("tier | cards | attempts>1 | escalations | tokens | budget | unmeasured_rows")
    for tier in sorted(tier_stats.keys(), key=lambda t: (TIER_ORDER.index(t) if t in TIER_ORDER else 99, t)):
        ts = tier_stats[tier]
        lines.append(
            f"{tier} | {len(ts.card_ids)} | {ts.retries} | {ts.escalations} | {ts.tokens} | {ts.budget} | {ts.unmeasured_rows}"
        )
    if overruns:
        lines.append("")
        lines.append("OVERRUN:")
        for cid in sorted(overruns):
            c = meta[cid]
            lines.append(f"  {cid}: {totals[cid]} > {c['token_budget']}")
    exit_code = 1 if overruns else 0
    return "\n".join(lines), overruns, exit_code


def append_routing_notes(routing_path: Path, gate: str, report: str) -> None:
    subsection = (
        f"### {gate} — {date.today().isoformat()}\n\n"
        f"```\n{report}\n```\n"
    )
    text = routing_path.read_text(encoding="utf-8")
    marker = "## Routing notes\n"
    if marker in text:
        routing_path.write_text(text.rstrip() + "\n\n" + subsection, encoding="utf-8")
    else:
        routing_path.write_text(text.rstrip() + f"\n\n{marker}\n{subsection}", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Review LEDGER.csv for a gate close")
    p.add_argument("--gate", required=True, help="Gate id, e.g. G0")
    p.add_argument("--ledger", type=Path, default=ROOT / "docs/build/LEDGER.csv")
    p.add_argument("--cards", type=Path, default=ROOT / "docs/build/cards")
    p.add_argument("--routing", type=Path, default=ROOT / "docs/build/04_ROUTING.md")
    p.add_argument("--append-notes", action="store_true", help="Append dated block to 04_ROUTING.md")
    args = p.parse_args(argv)

    report, _, code = review(args.gate.upper(), args.ledger, args.cards)
    print(report)
    if args.append_notes:
        append_routing_notes(args.routing, args.gate.upper(), report)
    return code


class RoutingReviewTests(unittest.TestCase):
    FIXTURE = """card_id,role,model_tier,model_slug,tokens_in,tokens_out,attempts,outcome,note
T-CARD-A,build,T1,test-model,10000,10000,1,pass,ok
T-CARD-B,build,T1,test-model,n/a,n/a,2,pass,retry
T-CARD-C,build,T2,test-model,50000,50000,1,pass,big
"""

    def _run(self, ledger: str, gate: str = "G9") -> tuple[str, int]:
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            ledger_path = td_path / "LEDGER.csv"
            ledger_path.write_text(ledger, encoding="utf-8")
            cards_dir = td_path / "cards"
            cards_dir.mkdir()
            (cards_dir / "T-CARD-A.yaml").write_text(
                "id: T-CARD-A\ngate: G9\ntoken_budget: 25000\n", encoding="utf-8"
            )
            (cards_dir / "T-CARD-B.yaml").write_text(
                "id: T-CARD-B\ngate: G9\ntoken_budget: 25000\n", encoding="utf-8"
            )
            (cards_dir / "T-CARD-C.yaml").write_text(
                "id: T-CARD-C\ngate: G9\ntoken_budget: 40000\n", encoding="utf-8"
            )
            report, overruns, code = review(gate, ledger_path, cards_dir)
            return report, code

    def test_header_required(self) -> None:
        with tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False) as f:
            f.write("wrong,header\n")
            path = Path(f.name)
        try:
            with self.assertRaises(ValueError):
                read_ledger(path)
        finally:
            path.unlink()

    def test_overrun_and_na(self) -> None:
        report, code = self._run(self.FIXTURE)
        self.assertIn("OVERRUN", report)
        self.assertIn("T-CARD-C", report)
        self.assertEqual(code, 1)
        self.assertIn("unmeasured_rows", report)
        self.assertIn("| 1 |", report)  # T-CARD-B retry

    def test_no_overrun_small_usage(self) -> None:
        ledger = """card_id,role,model_tier,model_slug,tokens_in,tokens_out,attempts,outcome,note
T-CARD-A,build,T1,test-model,100,200,1,pass,ok
"""
        report, code = self._run(ledger)
        self.assertNotIn("OVERRUN", report)
        self.assertEqual(code, 0)


if __name__ == "__main__":
    if "--run-tests" in sys.argv:
        ok = unittest.main(module=__name__, argv=[sys.argv[0]], exit=False).result.wasSuccessful()
        raise SystemExit(0 if ok else 1)
    raise SystemExit(main())
