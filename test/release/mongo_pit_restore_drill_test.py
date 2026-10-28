#!/usr/bin/env python3
"""P12-018 MongoDB PIT restore drill acceptance tests."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DRILL = ROOT / "scripts" / "release" / "mongo_pit_restore_drill.py"
CONFIG = ROOT / "release" / "mongo_pit_restore_config.json"

_spec = importlib.util.spec_from_file_location("mongo_pit_restore_drill", DRILL)
assert _spec and _spec.loader
drill = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = drill
_spec.loader.exec_module(drill)

T0 = datetime(2026, 10, 28, 12, 0, tzinfo=timezone.utc)


class MongoPitRestoreDrillTest(unittest.TestCase):
    def test_ac1_matching_counts_pass(self) -> None:
        config = drill.load_config(CONFIG)
        report = drill.run_drill(config, mode="simulate", now_fn=lambda: T0)
        self.assertTrue(report.passed)
        self.assertEqual(len(report.collections), 3)
        self.assertTrue(all(c.matched for c in report.collections))

    def test_ac2_report_schedules_next_quarter(self) -> None:
        config = drill.load_config(CONFIG)
        report = drill.run_drill(config, mode="simulate", now_fn=lambda: T0)
        self.assertIsNotNone(report.restore_duration_ms)
        self.assertEqual(report.tested_at, T0)
        self.assertEqual(report.next_test_due, T0 + timedelta(days=90))

    def test_ac3_mismatch_is_p0_never_passed(self) -> None:
        config = drill.load_config(CONFIG)
        report = drill.run_drill(
            config,
            mode="simulate",
            source_count_fn=lambda c: 10,
            restored_count_fn=lambda c: 9 if c == "user" else 10,
        )
        self.assertFalse(report.passed)
        self.assertTrue(report.p0_incident)

    def test_restore_failure_is_p0(self) -> None:
        config = drill.load_config(CONFIG)

        def boom() -> None:
            raise RuntimeError("atlas restore exploded")

        report = drill.run_drill(
            config,
            mode="live",
            restore_fn=boom,
            source_count_fn=lambda c: 1,
            restored_count_fn=lambda c: 1,
        )
        self.assertFalse(report.passed)
        self.assertTrue(report.p0_incident)

    def test_cli_writes_report_and_ledger(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            report_path = Path(tmp) / "report.json"
            ledger_path = Path(tmp) / "ledger.json"
            rc = drill.main(
                [
                    "run",
                    "--mode",
                    "simulate",
                    "--config",
                    str(CONFIG),
                    "--report",
                    str(report_path),
                    "--ledger",
                    str(ledger_path),
                ]
            )
            self.assertEqual(rc, 0)
            payload = json.loads(report_path.read_text())
            self.assertTrue(payload["passed"])
            self.assertIn("next_test_due", payload)
            ledger = json.loads(ledger_path.read_text())
            self.assertEqual(len(ledger), 1)
            self.assertTrue(ledger[0]["passed"])


if __name__ == "__main__":
    unittest.main()
