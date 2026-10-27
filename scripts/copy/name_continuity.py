#!/usr/bin/env python3
"""P10-939: Action → past-tense name continuity for paired UI strings."""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.copy.lint_ui_strings import parse_arb  # noqa: E402
DEFAULT_ARB = ROOT / "lib" / "l10n" / "app_en.arb"

WORD_BOUNDARY = r"(?<![A-Za-z]){token}(?![A-Za-z])"


@dataclass(frozen=True)
class ContinuityPair:
    action_key: str
    result_key: str
    verb: str
    past: str


# Pairs apply only when both keys exist in the ARB (no invented flows).
CONTINUITY_PAIRS: tuple[ContinuityPair, ...] = (
    ContinuityPair("polieTutorSaveCard", "polieTutorSavedCards", "Save", "Saved"),
    ContinuityPair("contentPublishAction", "contentPublishDone", "Publish", "Published"),
)


@dataclass(frozen=True)
class ContinuityFinding:
    key: str
    rule: str
    message: str


def _contains_token(text: str, token: str) -> bool:
    return bool(re.search(WORD_BOUNDARY.format(token=re.escape(token)), text, re.IGNORECASE))


def check_pair(pair: ContinuityPair, strings: dict[str, str]) -> list[ContinuityFinding]:
    action = strings.get(pair.action_key)
    result = strings.get(pair.result_key)
    if action is None or result is None:
        return []
    findings: list[ContinuityFinding] = []
    if not _contains_token(action, pair.verb):
        findings.append(
            ContinuityFinding(
                pair.action_key,
                "CONTINUITY_VERB",
                f"{pair.action_key}: expected action copy to include '{pair.verb}'",
            )
        )
    if not _contains_token(result, pair.past):
        findings.append(
            ContinuityFinding(
                pair.result_key,
                "CONTINUITY_PAST",
                f"{pair.result_key}: result must use past form '{pair.past}' (action '{pair.verb}')",
            )
        )
    return findings


def check_arb(arb_path: Path) -> list[ContinuityFinding]:
    strings, _meta = parse_arb(arb_path)
    findings: list[ContinuityFinding] = []
    for pair in CONTINUITY_PAIRS:
        findings.extend(check_pair(pair, strings))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description="UI name continuity gate (P10-939)")
    parser.add_argument("--arb", type=Path, default=DEFAULT_ARB)
    args = parser.parse_args()

    if not args.arb.is_file():
        print(f"ARB file missing: {args.arb}", file=sys.stderr)
        return 1

    findings = check_arb(args.arb)
    if findings:
        for f in findings:
            print(f"{f.rule}: {f.message}", file=sys.stderr)
        return 1
    print(f"OK: name continuity ({len(CONTINUITY_PAIRS)} pair specs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
