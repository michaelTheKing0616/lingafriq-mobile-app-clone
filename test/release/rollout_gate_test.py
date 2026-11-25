#!/usr/bin/env python3
"""Decision table for staged rollout promotion (P12-016)."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "scripts" / "release" / "rollout_gate.py"
GATES_YAML = ROOT / "release" / "gates.yaml"

import importlib.util

_spec = importlib.util.spec_from_file_location("rollout_gate", GATE)
assert _spec and _spec.loader
rg = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = rg
_spec.loader.exec_module(rg)

GatesConfig = rg.GatesConfig
advance_stage = rg.advance_stage
evaluate_promotion = rg.evaluate_promotion
load_gates = rg.load_gates
start_rollout = rg.start_rollout

NOW = datetime(2026, 10, 28, 12, 0, tzinfo=timezone.utc)
SOAK_OK = (NOW - timedelta(hours=25)).isoformat()
METRICS_OK = {
    "crash_free_users": 0.999,
    "anr_rate": 0.001,
    "collected_at": NOW.isoformat(),
}


class RolloutGateLogicTest(unittest.TestCase):
    def test_stages_are_fixed_order(self) -> None:
        gates = load_gates(GATES_YAML)
        self.assertEqual(gates.stages_percent, (1, 10, 50, 100))

    def test_allows_promotion_when_gates_and_soak_pass(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        state["stage_started_at"] = SOAK_OK
        may, reasons = evaluate_promotion(state, METRICS_OK, gates, now=NOW)
        self.assertTrue(may)
        self.assertEqual(reasons, [])

    def test_blocks_low_crash_free(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        state["stage_started_at"] = SOAK_OK
        metrics = dict(METRICS_OK, crash_free_users=0.99)
        may, reasons = evaluate_promotion(state, metrics, gates, now=NOW)
        self.assertFalse(may)
        self.assertTrue(any("crash-free" in r for r in reasons))

    def test_blocks_high_anr(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        state["stage_started_at"] = SOAK_OK
        metrics = dict(METRICS_OK, anr_rate=0.01)
        may, reasons = evaluate_promotion(state, metrics, gates, now=NOW)
        self.assertFalse(may)
        self.assertTrue(any("ANR" in r for r in reasons))

    def test_blocks_stale_metrics(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        state["stage_started_at"] = SOAK_OK
        stale_at = (NOW - timedelta(hours=48)).isoformat()
        metrics = dict(METRICS_OK, collected_at=stale_at)
        may, reasons = evaluate_promotion(state, metrics, gates, now=NOW)
        self.assertFalse(may)
        self.assertTrue(any("stale" in r for r in reasons))

    def test_blocks_missing_metric_fields(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        state["stage_started_at"] = SOAK_OK
        may, reasons = evaluate_promotion(state, {"collected_at": NOW.isoformat()}, gates, now=NOW)
        self.assertFalse(may)
        self.assertTrue(any("missing" in r for r in reasons))

    def test_advance_never_skips_stage(self) -> None:
        gates = GatesConfig((1, 10, 50, 100), 24, 0.995, 0.0047, 24)
        state = start_rollout("v1.0.0+1", gates)
        next_state = advance_stage(state, gates)
        self.assertEqual(next_state["rollout_percent"], 10)
        again = advance_stage(next_state, gates)
        self.assertEqual(again["rollout_percent"], 50)


class RolloutGateCliTest(unittest.TestCase):
    def test_dry_run_promote_advances_one_stage(self) -> None:
        gates = load_gates(GATES_YAML)
        state = start_rollout("v1.0.0+1", gates)
        soaked = datetime.now(timezone.utc) - timedelta(hours=25)
        state["stage_started_at"] = soaked.isoformat()
        metrics = dict(
            METRICS_OK,
            collected_at=datetime.now(timezone.utc).isoformat(),
        )
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "state.json"
            metrics_path = Path(directory) / "metrics.json"
            state_path.write_text(json.dumps(state))
            metrics_path.write_text(json.dumps(metrics))
            proc = subprocess.run(
                [
                    sys.executable,
                    str(GATE),
                    "promote",
                    "--dry-run",
                    "--state",
                    str(state_path),
                    "--metrics",
                    str(metrics_path),
                ],
                capture_output=True,
                text=True,
                cwd=ROOT,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            payload = json.loads(proc.stdout.strip())
            self.assertEqual(payload["from_percent"], 1)
            self.assertEqual(payload["to_percent"], 10)


if __name__ == "__main__":
    unittest.main()
