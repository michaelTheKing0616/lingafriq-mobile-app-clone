#!/usr/bin/env python3
"""Staged store rollout: 1% → 10% → 50% → 100% with crash-free and ANR gates."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

DEFAULT_GATES = Path(__file__).resolve().parents[2] / "release" / "gates.yaml"


@dataclass(frozen=True)
class GatesConfig:
    stages_percent: tuple[int, ...]
    soak_hours_per_stage: float
    min_crash_free_users: float
    max_anr_rate: float
    max_age_hours: float


def load_gates(path: Path) -> GatesConfig:
    raw = yaml.safe_load(path.read_text())
    stages = tuple(int(x) for x in raw["stages_percent"])
    if stages != (1, 10, 50, 100):
        raise ValueError(f"stages_percent must be [1, 10, 50, 100], got {list(stages)}")
    metrics = raw["metrics"]
    return GatesConfig(
        stages_percent=stages,
        soak_hours_per_stage=float(raw["soak_hours_per_stage"]),
        min_crash_free_users=float(metrics["min_crash_free_users"]),
        max_anr_rate=float(metrics["max_anr_rate"]),
        max_age_hours=float(metrics["max_age_hours"]),
    )


def metric_gate_reasons(
    crash_free_users: float,
    anr_rate: float,
    gates: GatesConfig,
) -> list[str]:
    reasons: list[str] = []
    if crash_free_users < gates.min_crash_free_users:
        reasons.append(
            f"crash-free users {crash_free_users:.4f} are below "
            f"{gates.min_crash_free_users:.4f}"
        )
    if anr_rate > gates.max_anr_rate:
        reasons.append(f"ANR rate {anr_rate:.4f} is above {gates.max_anr_rate:.4f}")
    return reasons


def parse_metric_time(value: str) -> datetime:
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def metric_freshness_reason(
    collected_at: str | None,
    now: datetime,
    gates: GatesConfig,
) -> str | None:
    if not collected_at:
        return "metrics missing collected_at; promotion halted"
    try:
        at = parse_metric_time(collected_at)
    except ValueError:
        return f"metrics collected_at is not ISO-8601: {collected_at!r}"
    age_hours = (now - at).total_seconds() / 3600.0
    if age_hours > gates.max_age_hours:
        return (
            f"metrics are stale ({age_hours:.1f}h old; max {gates.max_age_hours:.1f}h)"
        )
    return None


def soak_elapsed(
    stage_started_at: str | None,
    now: datetime,
    gates: GatesConfig,
) -> tuple[bool, str | None]:
    if not stage_started_at:
        return False, "stage_started_at missing; promotion halted"
    try:
        started = parse_metric_time(stage_started_at)
    except ValueError:
        return False, f"stage_started_at is not ISO-8601: {stage_started_at!r}"
    elapsed_hours = (now - started).total_seconds() / 3600.0
    if elapsed_hours < gates.soak_hours_per_stage:
        need = gates.soak_hours_per_stage - elapsed_hours
        return False, f"soak incomplete ({need:.1f}h remaining for this stage)"
    return True, None


def evaluate_promotion(
    state: dict[str, Any],
    metrics: dict[str, Any],
    gates: GatesConfig,
    now: datetime | None = None,
) -> tuple[bool, list[str]]:
    """Return (may_promote, reasons). False with reasons when halted or gates fail."""
    now = now or datetime.now(timezone.utc)
    reasons: list[str] = []

    if state.get("halted"):
        reasons.append(state.get("halt_reason") or "rollout is halted")

    stage_index = int(state.get("stage_index", -1))
    if stage_index < 0:
        reasons.append("rollout has not started (stage_index < 0)")
        return False, reasons

    if stage_index >= len(gates.stages_percent) - 1:
        reasons.append("rollout already at final stage (100%)")
        return False, reasons

    ok_soak, soak_reason = soak_elapsed(state.get("stage_started_at"), now, gates)
    if not ok_soak and soak_reason:
        reasons.append(soak_reason)

    stale = metric_freshness_reason(metrics.get("collected_at"), now, gates)
    if stale:
        reasons.append(stale)

    for key in ("crash_free_users", "anr_rate"):
        if key not in metrics:
            reasons.append(f"metrics missing {key}; promotion halted")
            return False, reasons

    reasons.extend(
        metric_gate_reasons(
            float(metrics["crash_free_users"]),
            float(metrics["anr_rate"]),
            gates,
        )
    )

    if reasons:
        return False, reasons
    return True, []


def start_rollout(release: str, gates: GatesConfig) -> dict[str, Any]:
    now = datetime.now(timezone.utc).isoformat()
    return {
        "release": release,
        "stage_index": 0,
        "rollout_percent": gates.stages_percent[0],
        "stage_started_at": now,
        "halted": False,
        "halt_reason": None,
        "audit": [{"action": "start", "at": now, "percent": gates.stages_percent[0]}],
    }


def advance_stage(state: dict[str, Any], gates: GatesConfig) -> dict[str, Any]:
    stage_index = int(state["stage_index"])
    next_index = stage_index + 1
    if next_index >= len(gates.stages_percent):
        raise ValueError("cannot advance past 100%")
    if next_index != stage_index + 1:
        raise ValueError("stage skip forbidden")
    now = datetime.now(timezone.utc).isoformat()
    percent = gates.stages_percent[next_index]
    state = dict(state)
    state["stage_index"] = next_index
    state["rollout_percent"] = percent
    state["stage_started_at"] = now
    state["halted"] = False
    state["halt_reason"] = None
    audit = list(state.get("audit") or [])
    audit.append({"action": "advance", "at": now, "percent": percent})
    state["audit"] = audit
    return state


def halt_rollout(state: dict[str, Any], reason: str) -> dict[str, Any]:
    now = datetime.now(timezone.utc).isoformat()
    state = dict(state)
    state["halted"] = True
    state["halt_reason"] = reason
    audit = list(state.get("audit") or [])
    audit.append({"action": "halt", "at": now, "reason": reason})
    state["audit"] = audit
    return state


def cmd_start(args: argparse.Namespace, gates: GatesConfig) -> int:
    state = start_rollout(args.release, gates)
    args.state.write_text(json.dumps(state, indent=2) + "\n")
    print(f"rollout started at {state['rollout_percent']}% for {args.release}")
    return 0


def cmd_evaluate(args: argparse.Namespace, gates: GatesConfig) -> int:
    state = json.loads(args.state.read_text())
    metrics = json.loads(args.metrics.read_text())
    may, reasons = evaluate_promotion(state, metrics, gates)
    if may:
        print("promotion allowed")
        return 0
    for reason in reasons:
        print(reason, file=sys.stderr)
    return 1


def cmd_promote(args: argparse.Namespace, gates: GatesConfig) -> int:
    state = json.loads(args.state.read_text())
    metrics = json.loads(args.metrics.read_text())
    may, reasons = evaluate_promotion(state, metrics, gates)
    if not may:
        state = halt_rollout(state, "; ".join(reasons))
        if not args.dry_run:
            args.state.write_text(json.dumps(state, indent=2) + "\n")
        for reason in reasons:
            print(f"ALERT rollout halted: {reason}", file=sys.stderr)
        return 1
    next_state = advance_stage(state, gates)
    if args.dry_run:
        print(
            json.dumps(
                {
                    "dry_run": True,
                    "from_percent": state["rollout_percent"],
                    "to_percent": next_state["rollout_percent"],
                }
            )
        )
        return 0
    args.state.write_text(json.dumps(next_state, indent=2) + "\n")
    print(f"advanced to {next_state['rollout_percent']}%")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--gates",
        type=Path,
        default=DEFAULT_GATES,
        help="Path to release/gates.yaml",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    start = sub.add_parser("start", help="Begin rollout at 1 percent")
    start.add_argument("--release", required=True, help="Release tag or version")
    start.add_argument("--state", type=Path, required=True, help="Rollout state JSON path")
    start.set_defaults(func=cmd_start)

    evaluate = sub.add_parser("evaluate", help="Check gates without mutating state")
    evaluate.add_argument("--state", type=Path, required=True)
    evaluate.add_argument("--metrics", type=Path, required=True)
    evaluate.set_defaults(func=cmd_evaluate)

    promote = sub.add_parser("promote", help="Evaluate gates and advance one stage")
    promote.add_argument("--state", type=Path, required=True)
    promote.add_argument("--metrics", type=Path, required=True)
    promote.add_argument("--dry-run", action="store_true")
    promote.set_defaults(func=cmd_promote)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    gates = load_gates(args.gates)
    return int(args.func(args, gates))


if __name__ == "__main__":
    raise SystemExit(main())
