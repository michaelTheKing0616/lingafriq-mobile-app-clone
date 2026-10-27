#!/usr/bin/env python3
"""P8-907: CI lint — ban energy/heart gates, loot boxes, and random reward tables in GameKit."""
from __future__ import annotations

import argparse
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOW_TAG = "dark-pattern-lint: allow"

GAMEKIT_DIR = ROOT / "lib" / "games" / "gamekit"
EXTRA_DART = (
    ROOT / "lib" / "games" / "gamekit" / "game_meta_layer.dart",
    ROOT / "lib" / "games" / "gamekit" / "game_scoring.dart",
    ROOT / "lib" / "providers" / "gamification_provider.dart",
)

RULES: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "HEART_OR_ENERGY_GATE",
        re.compile(
            r"heartsProvider|HeartsState|heartsApply|GamificationIntegrationHelper|"
            r"onMistake|outOfHearts|showHeartsUi|EnergySystem|energyGate|consumeEnergy|"
            r"refillHearts|hasHearts\b",
            re.IGNORECASE,
        ),
    ),
    (
        "LOOT_OR_RANDOM_REWARD",
        re.compile(
            r"loot\s*box|lootbox|LootBox|gacha|mysteryBox|mystery_box|"
            r"randomReward|random_reward|RandomReward|loot_table|LootTable",
            re.IGNORECASE,
        ),
    ),
    (
        "TIMER_BLOCKS_SESSION",
        re.compile(
            r"blockSessionUntilTimer|sessionTimerGate|timeGateBlocksPlay|"
            r"waitForEnergyRefill",
            re.IGNORECASE,
        ),
    ),
)


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    rule: str
    snippet: str


def _dart_files() -> list[Path]:
    paths: list[Path] = []
    if GAMEKIT_DIR.is_dir():
        paths.extend(sorted(GAMEKIT_DIR.rglob("*.dart")))
    for p in EXTRA_DART:
        if p.is_file() and p not in paths:
            paths.append(p)
    return paths


def _display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return path.as_posix()


def lint_file(path: Path) -> list[Finding]:
    findings: list[Finding] = []
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return findings
    for i, line in enumerate(text.splitlines(), start=1):
        if ALLOW_TAG in line:
            continue
        for rule_id, pattern in RULES:
            if pattern.search(line):
                findings.append(
                    Finding(
                        path=_display_path(path),
                        line=i,
                        rule=rule_id,
                        snippet=line.strip()[:120],
                    )
                )
                break
    return findings


def lint_tree() -> list[Finding]:
    out: list[Finding] = []
    for dart in _dart_files():
        out.extend(lint_file(dart))
    return out


def _self_test() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        bad = Path(tmp) / "bad.dart"
        bad.write_text(
            "import heartsProvider;\nclass LootBox {} // dark-pattern-lint: allow\n",
            encoding="utf-8",
        )
        hits = lint_file(bad)
        rules = {h.rule for h in hits}
        assert "HEART_OR_ENERGY_GATE" in rules
        assert "LOOT_OR_RANDOM_REWARD" not in rules
        assert lint_tree() == [] or all(
            "lib/games/gamekit" in h.path for h in lint_tree()
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="Run built-in fixture checks")
    args = parser.parse_args(argv)
    if args.self_test:
        _self_test()
        print("lint_dark_patterns: self-test ok")
        return 0

    findings = lint_tree()
    if findings:
        for f in findings:
            print(f"{f.path}:{f.line}: [{f.rule}] {f.snippet}")
        print(f"lint_dark_patterns: {len(findings)} violation(s)", file=sys.stderr)
        return 1
    print("lint_dark_patterns: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
