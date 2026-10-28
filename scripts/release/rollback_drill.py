#!/usr/bin/env python3
"""P12-017: rehearse store + content-pack rollback after a forced gate failure at 10%."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import importlib.util

ROOT = Path(__file__).resolve().parents[2]
GATE_PATH = Path(__file__).resolve().parent / "rollout_gate.py"

_spec = importlib.util.spec_from_file_location("rollout_gate", GATE_PATH)
assert _spec and _spec.loader
rg = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = rg
_spec.loader.exec_module(rg)

GatesConfig = rg.GatesConfig
advance_stage = rg.advance_stage
evaluate_promotion = rg.evaluate_promotion
halt_rollout = rg.halt_rollout
load_gates = rg.load_gates
start_rollout = rg.start_rollout

DEFAULT_GATES = ROOT / "release" / "gates.yaml"
STAGE_PERCENT = (1, 10, 50, 100)
SAMPLE_USER_IDS = tuple(f"drill-user-{i:03d}" for i in range(100))


def fnv1a_bucket(user_id: str, flag_key: str) -> int:
    """Match node-backend featureFlag.service bucket (0..99)."""
    hash_val = 2166136261
    payload = f"{flag_key}\0{user_id}"
    for ch in payload:
        hash_val ^= ord(ch)
        hash_val = (hash_val * 16777619) & 0xFFFFFFFF
    return hash_val % 100


@dataclass
class PackRolloutState:
    live_version: str | None = None
    rolling_version: str | None = None
    stage_index: int = -1
    rollout_percent: int = 0
    paused: bool = False
    rollback_previous_version: str | None = None
    learner_progress_checksum: str = "00000000"

    def release(self, version: str, previous: str | None) -> None:
        self.rollback_previous_version = previous
        self.live_version = previous
        self.rolling_version = version
        self.stage_index = 0
        self.rollout_percent = STAGE_PERCENT[0]
        self.paused = False

    def advance(self) -> None:
        if self.rolling_version is None:
            raise ValueError("no active pack rollout")
        next_index = self.stage_index + 1
        if next_index >= len(STAGE_PERCENT):
            self.live_version = self.rolling_version
            self.rolling_version = None
            self.stage_index = -1
            self.rollout_percent = 0
            return
        self.stage_index = next_index
        self.rollout_percent = STAGE_PERCENT[next_index]

    def rollback(self) -> None:
        if self.rolling_version is None:
            raise ValueError("no active pack rollout")
        previous = self.rollback_previous_version
        self.live_version = previous
        self.rolling_version = None
        self.stage_index = -1
        self.rollout_percent = 0
        self.paused = False

    def client_pack_version(self, user_id: str) -> str | None:
        if self.paused:
            return self.live_version
        if self.rolling_version is None:
            return self.live_version
        percent = self.rollout_percent
        if percent >= 100:
            return self.rolling_version
        if percent <= 0:
            return self.live_version
        in_rollout = fnv1a_bucket(user_id, self.rolling_version) < percent
        return self.rolling_version if in_rollout else self.live_version


def rollback_store_release(
    state: dict[str, Any],
    previous_release: str,
    reason: str,
) -> dict[str, Any]:
    """Return 100% of cohort to the previous store build (0% staged candidate)."""
    halted = halt_rollout(state, reason)
    halted["active_release"] = previous_release
    halted["candidate_release"] = None
    halted["rollout_percent"] = 0
    halted["stage_index"] = -1
    audit = list(halted.get("audit") or [])
    audit.append(
        {
            "action": "rollback",
            "at": datetime.now(timezone.utc).isoformat(),
            "release": previous_release,
            "reason": reason,
        }
    )
    halted["audit"] = audit
    return halted


def cohort_on_release(
    state: dict[str, Any],
    user_ids: tuple[str, ...],
    flag_key: str,
) -> dict[str, str]:
    active = state.get("active_release") or state.get("release")
    candidate = state.get("candidate_release")
    percent = int(state.get("rollout_percent", 0))
    if candidate is None or percent <= 0:
        return {uid: str(active) for uid in user_ids}
    out: dict[str, str] = {}
    for uid in user_ids:
        if fnv1a_bucket(uid, flag_key) < percent:
            out[uid] = str(candidate)
        else:
            out[uid] = str(active)
    return out


@dataclass
class DrillStep:
    name: str
    started_at: datetime
    ended_at: datetime | None = None
    manual: bool = False
    detail: str = ""

    def finish(self, end: datetime, detail: str = "") -> None:
        self.ended_at = end
        if detail:
            self.detail = detail

    @property
    def duration_ms(self) -> float | None:
        if self.ended_at is None:
            return None
        return (self.ended_at - self.started_at).total_seconds() * 1000.0

    def to_json(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "started_at": self.started_at.isoformat(),
            "ended_at": self.ended_at.isoformat() if self.ended_at else None,
            "duration_ms": self.duration_ms,
            "manual": self.manual,
            "detail": self.detail,
        }


@dataclass
class DrillReport:
    card: str = "P12-017"
    passed: bool = False
    store_rollback_ms: float | None = None
    pack_sync_ms: float | None = None
    steps: list[DrillStep] = field(default_factory=list)
    manual_actions: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def to_json(self) -> dict[str, Any]:
        return {
            "card": self.card,
            "passed": self.passed,
            "store_rollback_ms": self.store_rollback_ms,
            "pack_sync_ms": self.pack_sync_ms,
            "steps": [s.to_json() for s in self.steps],
            "manual_actions": self.manual_actions,
            "notes": self.notes,
        }


def run_drill(
    gates: GatesConfig,
    now_fn: Callable[[], datetime] | None = None,
) -> DrillReport:
    now_fn = now_fn or (lambda: datetime.now(timezone.utc))
    report = DrillReport()
    previous_store = "v1.0.0+100"
    candidate_store = "v1.1.0+101"
    flag_key = candidate_store

    t0 = now_fn()
    step_store = DrillStep("store_rollout_to_10_percent", t0)
    state = start_rollout(candidate_store, gates)
    state["active_release"] = previous_store
    state["candidate_release"] = candidate_store
    state = advance_stage(state, gates)
    if state["rollout_percent"] != 10:
        raise RuntimeError(f"expected 10% stage, got {state['rollout_percent']}")
    t1 = now_fn()
    step_store.finish(t1, f"staged at {state['rollout_percent']}%")
    report.steps.append(step_store)

    t2 = now_fn()
    step_gate = DrillStep("forced_gate_failure", t2)
    bad_metrics = {
        "crash_free_users": 0.98,
        "anr_rate": 0.001,
        "collected_at": t2.isoformat(),
    }
    may, reasons = evaluate_promotion(state, bad_metrics, gates, now=t2)
    if may:
        raise RuntimeError("gate failure expected at 10% with bad crash-free rate")
    state = rollback_store_release(state, previous_store, "; ".join(reasons))
    cohort_before = cohort_on_release(
        {
            "active_release": previous_store,
            "candidate_release": candidate_store,
            "rollout_percent": 10,
        },
        SAMPLE_USER_IDS,
        flag_key,
    )
    cohort_after = cohort_on_release(state, SAMPLE_USER_IDS, flag_key)
    staged_count = sum(1 for v in cohort_before.values() if v == candidate_store)
    if staged_count <= 0:
        raise RuntimeError("drill requires a non-empty staged cohort at 10%")
    if not all(v == previous_store for v in cohort_after.values()):
        raise RuntimeError("not all users returned to previous store build")
    t3 = now_fn()
    step_gate.finish(t3, f"rollback restored {len(cohort_after)} users")
    report.steps.append(step_gate)
    report.store_rollback_ms = step_gate.duration_ms

    t4 = now_fn()
    step_pack = DrillStep("content_pack_rollback_sync", t4)
    pack = PackRolloutState(learner_progress_checksum="deadbeef")
    pack.release("1.1.0", "1.0.0")
    pack.advance()
    if pack.rollout_percent != 10:
        raise RuntimeError(f"pack expected 10%, got {pack.rollout_percent}")
    progress_before = pack.learner_progress_checksum
    in_rollout = [
        uid
        for uid in SAMPLE_USER_IDS
        if pack.client_pack_version(uid) == "1.1.0"
    ]
    if not in_rollout:
        raise RuntimeError("pack drill requires users on rolling version")
    pack.rollback()
    for uid in SAMPLE_USER_IDS:
        if pack.client_pack_version(uid) != "1.0.0":
            raise RuntimeError(f"user {uid} not on rolled-back pack")
    if pack.learner_progress_checksum != progress_before:
        raise RuntimeError("learner progress checksum changed after pack rollback")
    t5 = now_fn()
    step_pack.finish(t5, f"synced {len(SAMPLE_USER_IDS)} clients to 1.0.0")
    report.steps.append(step_pack)
    report.pack_sync_ms = step_pack.duration_ms

    report.passed = True
    report.notes.append(
        f"store: {staged_count} users were on {candidate_store} at 10%; "
        "all returned to previous build"
    )
    report.notes.append(
        f"pack: {len(in_rollout)} users had 1.1.0; all on 1.0.0 after rollback"
    )
    return report


def cmd_run(args: argparse.Namespace) -> int:
    gates = load_gates(args.gates)
    report = run_drill(gates)
    payload = report.to_json()
    args.report.write_text(json.dumps(payload, indent=2) + "\n")
    if args.ledger:
        ledger_path = args.ledger
        rows: list[dict[str, Any]] = []
        if ledger_path.exists():
            rows = json.loads(ledger_path.read_text())
        rows.append(
            {
                "at": datetime.now(timezone.utc).isoformat(),
                "passed": report.passed,
                "store_rollback_ms": report.store_rollback_ms,
                "pack_sync_ms": report.pack_sync_ms,
            }
        )
        ledger_path.write_text(json.dumps(rows, indent=2) + "\n")
    print(json.dumps({"passed": report.passed}))
    return 0 if report.passed else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run", help="Execute rollback drill and write report")
    run.add_argument("--gates", type=Path, default=DEFAULT_GATES)
    run.add_argument(
        "--report",
        type=Path,
        default=ROOT / "release" / "fixtures" / "rollback_drill_report.json",
    )
    run.add_argument(
        "--ledger",
        type=Path,
        default=ROOT / "release" / "rollback_drill_ledger.json",
    )
    run.set_defaults(func=cmd_run)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
