#!/usr/bin/env python3
"""Build docs/build/CONTAINMENT_EVIDENCE.md from RTM defect rows (P0-INT-10)."""
from __future__ import annotations

import argparse
import csv
import re
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RTM = ROOT / "docs/build/RTM.csv"
CARDS = ROOT / "docs/build/cards"
OUT = ROOT / "docs/build/CONTAINMENT_EVIDENCE.md"

EP_DEFECT_RE = re.compile(r"^EP-§0-(0[4-9]|[1-3][0-9]|4[0-4])$")
P0_DEFECT_RE = re.compile(r"^P0-([1-9]|1[0-9]|2[0-7])$")
CP1_RE = re.compile(r"^CP-§1-")
CP_PRE12 = "CP-§pre-12"

SOURCE_CLAIMS: tuple[tuple[str, str, str], ...] = (
    (
        "EP-§0-06",
        "24,234 of 48,847 vocabulary entries (49.6%) across the bundles are placeholders",
        "python3 tools/content_engine/curriculum/placeholder_audit.py --bundles",
    ),
    (
        "EP-§0-09",
        "126 of 126 dialogues per language repeat lines",
        "python3 tools/content_engine/curriculum/dialogue_repeat_audit.py",
    ),
    (
        "EP-§0-10",
        "The same two grammar sentences appear in 1,546 lessons",
        "python3 tools/content_engine/curriculum/grammar_sentence_audit.py",
    ),
)


@dataclass(frozen=True)
class RtmRow:
    req_id: str
    source_doc: str
    anchor: str
    row_type: str
    verbatim_hook: str
    priority: str
    card_ids: str


@dataclass(frozen=True)
class DefectRow:
    req_id: str
    hook: str
    owning_card: str
    evidence: str


def load_rtm(path: Path) -> list[RtmRow]:
    rows: list[RtmRow] = []
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for raw in reader:
            rows.append(
                RtmRow(
                    req_id=raw["req_id"].strip(),
                    source_doc=raw["source_doc"].strip(),
                    anchor=raw["anchor"].strip(),
                    row_type=raw["type"].strip(),
                    verbatim_hook=raw["verbatim_hook"].strip(),
                    priority=raw["priority"].strip(),
                    card_ids=raw["card_ids"].strip(),
                )
            )
    return rows


def split_card_ids(card_ids: str) -> list[str]:
    return [part.strip() for part in card_ids.split(";") if part.strip()]


def primary_owning_card(card_ids: str) -> str:
    parts = split_card_ids(card_ids)
    if not parts:
        return ""
    for pref in ("P1-", "P2-", "P4-", "P5-", "F-", "EXT-", "ADR-", "P0-INT-", "P0-"):
        for cid in parts:
            if cid.startswith(pref):
                return cid
    return parts[0]


def card_yaml_path(card_id: str, cards_dir: Path) -> Path | None:
    if not card_id:
        return None
    for path in cards_dir.rglob("*.yaml"):
        if path.stem == card_id:
            return path
    return None


def evidence_for_owning(_card_id: str, _cards_dir: Path) -> str:
    return "PENDING"


def defect_rows(rtm: list[RtmRow], cards_dir: Path) -> list[DefectRow]:
    out: list[DefectRow] = []
    for row in rtm:
        if not (EP_DEFECT_RE.match(row.req_id) or P0_DEFECT_RE.match(row.req_id)):
            continue
        owner = primary_owning_card(row.card_ids)
        out.append(
            DefectRow(
                req_id=row.req_id,
                hook=row.verbatim_hook,
                owning_card=owner,
                evidence=evidence_for_owning(owner, cards_dir),
            )
        )
    def _sort_key(row: DefectRow) -> tuple[int, int, str]:
        if row.req_id.startswith("EP-§0-"):
            return (0, int(row.req_id.rsplit("-", 1)[-1]), row.req_id)
        if P0_DEFECT_RE.match(row.req_id):
            return (1, int(row.req_id.split("-", 1)[1]), row.req_id)
        return (2, 0, row.req_id)

    out.sort(key=_sort_key)
    return out


def cp1_informational(rtm: list[RtmRow]) -> list[tuple[str, str, str, str]]:
    """Return (req_id, hook, phase, card_ids) for CP-§1 audit rows."""
    rows: list[tuple[str, str, str, str]] = []
    for row in rtm:
        if not CP1_RE.match(row.req_id):
            continue
        phase = "P4"
        for cid in split_card_ids(row.card_ids):
            if cid.startswith("P5-"):
                phase = "P5"
                break
            if cid.startswith("P4-"):
                phase = "P4"
                break
        rows.append((row.req_id, row.verbatim_hook, phase, row.card_ids))
    rows.sort(key=lambda r: r[0])
    return rows


def cp_pre12_row(rtm: list[RtmRow]) -> tuple[str, str] | None:
    for row in rtm:
        if row.req_id == CP_PRE12:
            return row.req_id, row.verbatim_hook
    return None


def validate_cards(defects: list[DefectRow], cards_dir: Path) -> list[str]:
    missing: list[str] = []
    for row in defects:
        if not row.owning_card:
            missing.append(f"{row.req_id}: no owning card in RTM")
            continue
        if card_yaml_path(row.owning_card, cards_dir) is None:
            missing.append(f"{row.req_id}: missing card file for {row.owning_card}")
    return missing


def render_markdown(
    defects: list[DefectRow],
    cp1: list[tuple[str, str, str, str]],
    pre12: tuple[str, str] | None,
) -> str:
    lines = [
        "# Containment evidence index (G1)",
        "",
        "Generated by `scripts/plan/containment_index.py`. Evidence links fill at G1.",
        "",
        "## Defects (EP-§0-04…44, P0-1…27)",
        "",
        "| req_id | defect (hook) | owning_card | evidence |",
        "| --- | --- | --- | --- |",
    ]
    for row in defects:
        hook = row.hook.replace("|", "\\|")
        lines.append(f"| `{row.req_id}` | {hook} | `{row.owning_card}` | {row.evidence} |")
    lines.extend(
        [
            "",
            "## Informational — CP-§1 curriculum audit",
            "",
            "No G1 evidence required; implemented in content-engine phases.",
            "",
            "| req_id | requirement | phase | implementing_cards |",
            "| --- | --- | --- | --- |",
        ]
    )
    for req_id, hook, phase, card_ids in cp1:
        hook = hook.replace("|", "\\|")
        lines.append(f"| `{req_id}` | {hook} | {phase} | {card_ids} |")
    if pre12:
        lines.extend(
            [
                "",
                "## Informational — companion docs",
                "",
                "| req_id | note | evidence |",
                "| --- | --- | --- |",
                f"| `{pre12[0]}` | {pre12[1].replace('|', '\\|')} | `docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` |",
            ]
        )
    lines.extend(
        [
            "",
            "## Source claims (re-measure at G1)",
            "",
            "| req_id | source claim | re-measure command | measured |",
            "| --- | --- | --- | --- |",
        ]
    )
    for req_id, claim, cmd in SOURCE_CLAIMS:
        claim = claim.replace("|", "\\|")
        lines.append(f"| `{req_id}` | {claim} | `{cmd}` | PENDING |")
    lines.append("")
    return "\n".join(lines)


def pending_defects(defects: list[DefectRow]) -> list[DefectRow]:
    return [row for row in defects if row.evidence == "PENDING"]


def build_index(rtm_path: Path, cards_dir: Path, out_path: Path) -> tuple[str, list[str], list[DefectRow]]:
    rtm = load_rtm(rtm_path)
    defects = defect_rows(rtm, cards_dir)
    missing = validate_cards(defects, cards_dir)
    if missing:
        return "", missing, defects
    md = render_markdown(defects, cp1_informational(rtm), cp_pre12_row(rtm))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(md, encoding="utf-8")
    return md, [], defects


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gate", choices=("G1",), help="Fail while defect evidence is PENDING")
    parser.add_argument("--rtm", type=Path, default=RTM)
    parser.add_argument("--cards", type=Path, default=CARDS)
    parser.add_argument("--out", type=Path, default=OUT)
    args = parser.parse_args(argv)

    _, missing, defects = build_index(args.rtm, args.cards, args.out)
    if missing:
        for line in missing:
            print(line, file=sys.stderr)
        return 1

    if args.gate == "G1":
        pending = pending_defects(defects)
        if pending:
            print("G1 gate: defect evidence still PENDING:", file=sys.stderr)
            for row in pending:
                print(f"  {row.req_id} ({row.owning_card})", file=sys.stderr)
            return 1
    return 0


class ContainmentIndexTests(unittest.TestCase):
    FIXTURE_RTM = """req_id,source_doc,anchor,type,verbatim_hook,priority,owner,card_ids,status
EP-§0-04,ELEVATION,§0:L25,informational,curriculum placeholder,P0,agent,P0-INT-10,Mapped
EP-§0-06,ELEVATION,§0:L27,informational,24k placeholders,P0,agent,P0-INT-10,Mapped
P0-1,ELEVATION,§1:L84,requirement,Firebase key,P0,agent,MISSING-CARD-XYZ,Mapped
P0-2,ELEVATION,§1:L104,requirement,Apple p8,P0,agent,P1-001,Mapped
CP-§1-01,CURRICULUM,§1:L60,requirement,CI placeholder linter,P0,agent,P4-106,Mapped
CP-§1-08,CURRICULUM,§1:L84,requirement,grammar linter,P0,agent,P0-INT-10;P2-002,Mapped
CP-§pre-12,CURRICULUM,§pre:L5,external,AI model stack,P1,agent,P0-INT-10,Mapped
"""

    def _fixture(self) -> tuple[Path, Path, Path]:
        td = Path(tempfile.mkdtemp())
        rtm = td / "RTM.csv"
        rtm.write_text(self.FIXTURE_RTM, encoding="utf-8")
        cards = td / "cards"
        cards.mkdir()
        (cards / "P0-INT-10.yaml").write_text("id: P0-INT-10\nstatus: Draft\n", encoding="utf-8")
        (cards / "P1-001.yaml").write_text("id: P1-001\nstatus: Draft\n", encoding="utf-8")
        (cards / "P4-106.yaml").write_text("id: P4-106\nstatus: Done\n", encoding="utf-8")
        out = td / "CONTAINMENT_EVIDENCE.md"
        return rtm, cards, out

    def test_missing_card_exits(self) -> None:
        rtm, cards, out = self._fixture()
        _, missing, _ = build_index(rtm, cards, out)
        self.assertTrue(any("MISSING-CARD-XYZ" in m for m in missing))

    def test_pending_and_informational(self) -> None:
        rtm, cards, out = self._fixture()
        # Fix missing card for a passing build subset
        (cards / "MISSING-CARD-XYZ.yaml").write_text("id: MISSING-CARD-XYZ\n", encoding="utf-8")
        md, missing, defects = build_index(rtm, cards, out)
        self.assertEqual(missing, [])
        self.assertIn("## Informational — CP-§1 curriculum audit", md)
        self.assertIn("| `CP-§1-01` |", md)
        self.assertIn("| P4 |", md)
        self.assertIn("LINGAFRIQ_AI_MODEL_STACK", md)
        self.assertTrue(all(d.evidence == "PENDING" for d in defects))


if __name__ == "__main__":
    if "--run-tests" in sys.argv:
        ok = unittest.main(module=__name__, argv=[sys.argv[0]], exit=False).result.wasSuccessful()
        raise SystemExit(0 if ok else 1)
    raise SystemExit(main())
