#!/usr/bin/env python3
"""P11-047: Enforce avatar .riv size and per-artboard draw-call budgets (CI gate)."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RIV = ROOT / "assets" / "rive" / "lingafriq_cast.riv"
CONTRACT = ROOT / "assets" / "rive" / "lingafriq_cast.contract.json"

# Runtime contract per ELEVATION §4.5–§4.6 / ADR-034 (P11-047 records against this table).
ARTBOARD_DRAW_MAX: dict[str, int] = {
    "Character": 22,
    "CharacterChip": 10,
    "Bust": 14,
}

# Part slots (hair/headwear/…) add nested draws on Character; hair uses two draws (RIVE_BUILD_SPEC).
_CHARACTER_PART_OVERHEAD = 8


def load_contract() -> dict[str, Any]:
    return json.loads(CONTRACT.read_text(encoding="utf-8"))


def estimate_draw_calls(artboard: str, contract: dict[str, Any]) -> int:
    boards = contract["artboards"]
    if artboard not in boards:
        raise KeyError(artboard)
    layers = len(boards[artboard]["layers"])
    if artboard == "Character":
        return layers + _CHARACTER_PART_OVERHEAD
    if artboard == "CharacterChip":
        return layers + 2
    return layers + 4


def build_report(riv_path: Path, contract: dict[str, Any]) -> dict[str, Any]:
    body = riv_path.read_bytes()
    budget = contract["budget"]
    max_bytes = int(budget["bytesPerCharacterFile"])
    artboards = list(contract["artboards"].keys())
    per_board: dict[str, Any] = {}
    for name in artboards:
        estimated = estimate_draw_calls(name, contract)
        per_board[name] = {
            "estimated_draw_calls": estimated,
            "max_draw_calls": ARTBOARD_DRAW_MAX[name],
            "layers": len(contract["artboards"][name]["layers"]),
        }
    return {
        "card": "P11-047",
        "riv": str(riv_path.relative_to(ROOT)),
        "bytes": len(body),
        "max_bytes": max_bytes,
        "frame_ms_budget": int(budget["frameMs"]),
        "fps_target": int(budget["fps"]),
        "artboards": per_board,
    }


def verify(report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if report["bytes"] > report["max_bytes"]:
        errors.append(
            f"{report['riv']}: {report['bytes']} bytes > budget {report['max_bytes']}",
        )
    for name, row in report["artboards"].items():
        est = row["estimated_draw_calls"]
        cap = row["max_draw_calls"]
        if est > cap:
            errors.append(f"{name}: estimated draw calls {est} > max {cap}")
    return errors


def run_self_test() -> list[str]:
    errors: list[str] = []
    tiny = {"artboards": {"Character": {"layers": ["a"]}}, "budget": {"bytesPerCharacterFile": 10}}
    if estimate_draw_calls("Character", tiny) <= 0:
        errors.append("estimate_draw_calls should be positive")
    bad_report = {
        "riv": "x.riv",
        "bytes": 999,
        "max_bytes": 10,
        "artboards": {
            "Character": {
                "estimated_draw_calls": 99,
                "max_draw_calls": 1,
                "layers": 1,
            },
        },
    }
    if not verify(bad_report):
        errors.append("verify should fail oversized file and draw budget")
    good_report = {
        "riv": "x.riv",
        "bytes": 5,
        "max_bytes": 10,
        "artboards": {
            "Character": {
                "estimated_draw_calls": 5,
                "max_draw_calls": 22,
                "layers": 1,
            },
        },
    }
    if verify(good_report):
        errors.append("verify should pass minimal good report")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--riv", type=Path, default=DEFAULT_RIV)
    parser.add_argument("--gate", action="store_true", help="Exit 1 when budgets fail")
    parser.add_argument("--json", action="store_true", help="Print budget ledger JSON")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        failures = run_self_test()
        if failures:
            for msg in failures:
                print(msg, file=sys.stderr)
            return 1
        print("check_budgets self-test ok")
        return 0

    if not CONTRACT.is_file():
        print(f"missing contract: {CONTRACT}", file=sys.stderr)
        return 1
    contract = load_contract()
    riv = args.riv if args.riv.is_absolute() else ROOT / args.riv
    if not riv.is_file():
        print(f"missing riv: {riv}", file=sys.stderr)
        return 1

    report = build_report(riv, contract)
    errors = verify(report)
    if args.json:
        print(json.dumps(report, indent=2))
    elif not args.gate:
        for name, row in report["artboards"].items():
            print(
                f"{name}: {row['estimated_draw_calls']} draw calls "
                f"(max {row['max_draw_calls']}), {row['layers']} layers",
            )
        print(f"file: {report['bytes']} / {report['max_bytes']} bytes")

    if errors:
        for msg in errors:
            print(msg, file=sys.stderr)
        return 1 if args.gate else 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
