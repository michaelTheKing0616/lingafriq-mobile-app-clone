#!/usr/bin/env python3
"""T0: card dependency graph is acyclic, phase-monotone and respects hard stops H1–H10 (charter: v2).

Hard stops are expressed with card tags:
  provider tags : scorer_real, content_real, guardian_moderation, ai_disclosure,
                  native_verified_rule, licence_register, tone_accuracy_gate, placeholder_linter
  consumer tags : shows_score→scorer_real · issues_credential→{scorer_real, content_real} ·
                  under18_social→guardian_moderation · enables_persona→ai_disclosure ·
                  tts_tonal→tone_accuracy_gate · uses_source→licence_register
A consumer card must transitively depend on at least one card carrying the provider tag.
H5 (no Beta in restricted surfaces), H6 and H8 are enforced by linters/content cards, so they
appear here only as provider tags for traceability.
Exit 1 on cycle, backward phase dependency, or missing hard-stop dependency.
"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "docs" / "build" / "cards"
HARD_STOPS = {
    "shows_score": {"scorer_real"},
    "issues_credential": {"scorer_real", "content_real"},
    "under18_social": {"guardian_moderation"},
    "enables_persona": {"ai_disclosure"},
    "tts_tonal": {"tone_accuracy_gate"},
    "uses_source": {"licence_register"},
}
PROVIDER_TAGS = {t for ts in HARD_STOPS.values() for t in ts} | {"native_verified_rule", "placeholder_linter"}


def load() -> dict[str, dict]:
    cards = {}
    for p in sorted(CARDS.rglob("*.yaml")):
        c = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        cards[c.get("id", p.stem)] = c
    return cards


def ancestors(cid: str, cards: dict[str, dict], memo: dict[str, set[str]], stack: tuple = ()) -> set[str]:
    if cid in memo:
        return memo[cid]
    if cid in stack:
        raise ValueError(" -> ".join(stack + (cid,)))
    acc: set[str] = set()
    for dep in cards.get(cid, {}).get("depends_on") or []:
        acc.add(dep)
        acc |= ancestors(dep, cards, memo, stack + (cid,))
    memo[cid] = acc
    return acc


def main() -> int:
    cards = load()
    errors: list[str] = []
    memo: dict[str, set[str]] = {}
    for cid, c in cards.items():
        try:
            anc = ancestors(cid, cards, memo)
        except ValueError as cyc:
            errors.append(f"cycle: {cyc}")
            continue
        phase = int(str(c.get("phase", "P0"))[1:])
        for dep in c.get("depends_on") or []:
            dp = cards.get(dep)
            if dp and int(str(dp.get("phase", "P0"))[1:]) > phase:
                # A later-phase *epic* is a legitimate "ships-after" gate (e.g. a P7 social
                # feature waits for G9; a wardrobe waits for avatar art). A later-phase build card is a planning error.
                if dp.get("kind") != "epic":
                    errors.append(f"{cid} ({c.get('phase')}) depends on later-phase card {dep} ({dp.get('phase')})")
        tags = set(c.get("tags") or [])
        for consumer, providers in HARD_STOPS.items():
            if consumer in tags:
                provided = {t for a in anc for t in (cards.get(a, {}).get("tags") or [])}
                missing = providers - provided
                if missing:
                    errors.append(f"{cid}: hard-stop {consumer} needs a dependency tagged {sorted(missing)}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        print(f"check_dependencies: {len(errors)} violation(s)", file=sys.stderr)
        return 1
    print(f"check_dependencies: OK ({len(cards)} cards, acyclic, hard stops satisfied)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
