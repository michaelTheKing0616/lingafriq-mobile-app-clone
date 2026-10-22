#!/usr/bin/env python3
"""T0: validate every card YAML under docs/build/cards (charter: v2).

Usage: python3 scripts/plan/validate_cards.py [path ...]   (default: all cards)
Exit 1 with one line per violation. No model, no network.

Checks: charter marker · required fields · id matches filename · phase/gate/status
enums · size cap vs token_budget · difficulty components sum to score · tiers match
the routing table for the score (04_ROUTING.md) · req_ids exist in RTM.csv ·
depends_on exist · file_allowlist ≤ 12 · ACs have ids and Given/When/Then · test_plan
present for build cards · ux_spec when user_facing · XL forbidden.
Card kinds: build (default) | feature | epic | external | verification | adr | design.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "docs" / "build" / "cards"
RTM = ROOT / "docs" / "build" / "RTM.csv"
PHASES = {f"P{n}" for n in range(0, 14)}
GATES = {f"G{n}" for n in range(0, 14)} | {"HUB"}
STATUSES = {"Draft", "Ready", "Spec-Tests", "Build", "Test", "Review", "Fix", "Done", "Blocked-External", "Waived"}
KINDS = {"build", "feature", "epic", "external", "verification", "adr", "design"}
SIZE_CAP = {"S": 30_000, "M": 80_000, "L": 200_000}
TIERS = {"T0", "T1", "T2", "T3", "T4"}
MAX_ALLOWLIST = 12
DIFF_PARTS = {"blast": 3, "ambiguity": 2, "coupling": 2, "depth": 2, "size": 1}
REQUIRED = ["charter", "id", "title", "phase", "epic", "req_ids", "size", "difficulty", "tiers", "token_budget",
            "acceptance_criteria", "gate", "status", "kind"]
GWT = re.compile(r"\bgiven\b.*\bwhen\b.*\bthen\b", re.I | re.S)
NO_FILES_KINDS = {"epic", "external", "adr", "design", "verification"}


def allowed_worker_tiers(score: int) -> set[str]:
    if score <= 2:
        return {"T0", "T1"}
    if score <= 4:
        return {"T1", "T2"}
    if score <= 6:
        return {"T2"}
    return {"T3"}


def load_rtm_ids() -> set[str]:
    with RTM.open(encoding="utf-8", newline="") as fh:
        return {row["req_id"] for row in csv.DictReader(fh)}


def validate(path: Path, card: dict, rtm_ids: set[str], all_ids: set[str]) -> list[str]:
    e: list[str] = []
    rel = path.relative_to(ROOT).as_posix()
    kind = card.get("kind", "build")
    for f in REQUIRED:
        if f not in card:
            e.append(f"{rel}: missing field {f}")
    if e:
        return e
    if str(card["charter"]) != "v2":
        e.append(f"{rel}: charter must be v2")
    if card["id"] != path.stem:
        e.append(f"{rel}: id {card['id']} != filename")
    if kind not in KINDS:
        e.append(f"{rel}: bad kind {kind}")
    if card["phase"] not in PHASES:
        e.append(f"{rel}: bad phase {card['phase']}")
    if card["gate"] not in GATES:
        e.append(f"{rel}: bad gate {card['gate']}")
    if card["status"] not in STATUSES:
        e.append(f"{rel}: bad status {card['status']}")
    size = card["size"]
    if size not in SIZE_CAP:
        e.append(f"{rel}: size {size} not in S/M/L (XL forbidden: split)")
    elif int(card["token_budget"]) > SIZE_CAP[size]:
        e.append(f"{rel}: token_budget {card['token_budget']} exceeds {size} cap {SIZE_CAP[size]}")
    d = card["difficulty"] or {}
    if not isinstance(d, dict) or "score" not in d:
        e.append(f"{rel}: difficulty needs score and parts")
    else:
        parts_sum = 0
        for k, cap in DIFF_PARTS.items():
            v = int(d.get(k, -1))
            if v < 0 or v > cap:
                e.append(f"{rel}: difficulty.{k}={v} out of 0..{cap}")
            parts_sum += max(v, 0)
        if parts_sum != int(d["score"]):
            e.append(f"{rel}: difficulty parts sum {parts_sum} != score {d['score']}")
    t = card["tiers"] or {}
    for role in ("worker", "tester", "reviewer"):
        if t.get(role) not in TIERS:
            e.append(f"{rel}: tiers.{role} missing/invalid")
    if not t.get("justification"):
        e.append(f"{rel}: tiers.justification missing")
    if isinstance(d, dict) and "score" in d and t.get("worker") in TIERS and kind in {"build", "feature", "design"}:
        score = int(d["score"])
        if t["worker"] not in allowed_worker_tiers(score):
            e.append(f"{rel}: worker tier {t['worker']} not allowed for score {score}")
        if t.get("tester") in TIERS and t["tester"] > "T2" and not card.get("security_dsp_crypto"):
            e.append(f"{rel}: tester tier above T2 requires security_dsp_crypto: true")
        blast = int(d.get("blast", 0))
        if t.get("reviewer") in TIERS:
            if blast >= 2 and t["reviewer"] < t["worker"]:
                e.append(f"{rel}: reviewer below worker with blast ≥2")
            if card.get("p0_area") and t["reviewer"] < "T2":
                e.append(f"{rel}: reviewer below T2 on P0 area")
    req_ids = card["req_ids"] or []
    if not req_ids:
        e.append(f"{rel}: req_ids empty")
    for r in req_ids:
        if r not in rtm_ids:
            e.append(f"{rel}: req_id {r} not in RTM")
    for dep in card.get("depends_on") or []:
        if dep not in all_ids:
            e.append(f"{rel}: depends_on {dep} is not a card")
    fa = card.get("file_allowlist") or []
    if len(fa) > MAX_ALLOWLIST:
        e.append(f"{rel}: file_allowlist {len(fa)} > {MAX_ALLOWLIST}")
    if kind not in NO_FILES_KINDS and not fa:
        e.append(f"{rel}: build/feature card needs a file_allowlist")
    if kind not in NO_FILES_KINDS and not card.get("context_anchors"):
        e.append(f"{rel}: context_anchors missing")
    acs = card["acceptance_criteria"] or []
    if not acs:
        e.append(f"{rel}: acceptance_criteria empty")
    for ac in acs:
        if not isinstance(ac, dict) or "id" not in ac or "text" not in ac:
            e.append(f"{rel}: AC must be {{id, text}}")
        elif kind in {"build", "feature", "design"} and not GWT.search(str(ac["text"])):
            e.append(f"{rel}: {ac['id']} not Given/When/Then")
    if kind in {"build", "feature"} and not card.get("test_plan"):
        e.append(f"{rel}: test_plan missing")
    if card.get("user_facing") and not card.get("ux_spec"):
        e.append(f"{rel}: user_facing without ux_spec")
    if kind == "external" and card["status"] != "Blocked-External":
        e.append(f"{rel}: external card must be Blocked-External")
    if kind == "external" and not card.get("external_blockers"):
        e.append(f"{rel}: external card needs external_blockers (EXT-nn)")
    return e


def main(argv: list[str]) -> int:
    paths = [Path(a).resolve() for a in argv] if argv else sorted(CARDS.rglob("*.yaml"))
    rtm_ids = load_rtm_ids()
    cards: dict[Path, dict] = {}
    errors: list[str] = []
    for p in paths:
        try:
            cards[p] = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError as exc:
            errors.append(f"{p.relative_to(ROOT)}: YAML error {str(exc).splitlines()[0]}")
    all_ids = {c.get("id") for c in cards.values()} | {q.stem for q in CARDS.rglob("*.yaml")}
    for p, c in cards.items():
        errors.extend(validate(p, c, rtm_ids, all_ids))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        print(f"validate_cards: {len(errors)} violation(s) in {len(cards)} card(s)", file=sys.stderr)
        return 1
    print(f"validate_cards: OK ({len(cards)} cards)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
