#!/usr/bin/env python3
"""P12-017 rollback drill acceptance tests."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DRILL = ROOT / "scripts" / "release" / "rollback_drill.py"
GATES_YAML = ROOT / "release" / "gates.yaml"

_spec = importlib.util.spec_from_file_location("rollback_drill", DRILL)
assert _spec and _spec.loader
drill = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = drill
_spec.loader.exec_module(drill)

T0 = datetime(2026, 10, 28, 14, 0, tzinfo=timezone.utc)
_TICK = 0


def fake_now() -> datetime:
    global _TICK
    _TICK += 1
    return T0.replace(second=min(59, T0.second + _TICK))


class RollbackDrillTest(unittest.TestCase):
    def setUp(self) -> None:
        global _TICK
        _TICK = 0

    def test_drill_passes_ac1_ac2_ac3(self) -> None:
        gates = drill.load_gates(GATES_YAML)
        report = drill.run_drill(gates, now_fn=fake_now)
        self.assertTrue(report.passed)
        self.assertIsNotNone(report.store_rollback_ms)
        self.assertIsNotNone(report.pack_sync_ms)
        self.assertGreaterEqual(len(report.steps), 3)
        for step in report.steps:
            self.assertIsNotNone(step.ended_at)
            self.assertIsNotNone(step.duration_ms)

    def test_cli_writes_report_and_ledger(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            report_path = Path(tmp) / "report.json"
            ledger_path = Path(tmp) / "ledger.json"
            rc = drill.main(
                [
                    "run",
                    "--report",
                    str(report_path),
                    "--ledger",
                    str(ledger_path),
                    "--gates",
                    str(GATES_YAML),
                ]
            )
            self.assertEqual(rc, 0)
            payload = json.loads(report_path.read_text())
            self.assertTrue(payload["passed"])
            self.assertIn("steps", payload)
            ledger = json.loads(ledger_path.read_text())
            self.assertEqual(len(ledger), 1)
            self.assertTrue(ledger[0]["passed"])

    def test_bucket_matches_node_fixture(self) -> None:
        # Stable check against known node-backend implementation.
        self.assertEqual(drill.fnv1a_bucket("u1", "1.1.0"), 55)


if __name__ == "__main__":
    unittest.main()
