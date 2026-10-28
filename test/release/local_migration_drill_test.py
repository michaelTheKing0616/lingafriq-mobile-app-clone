#!/usr/bin/env python3
"""P12-020 local migration drill CLI tests."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DRILL = ROOT / "scripts" / "release" / "local_migration_drill.py"

_spec = importlib.util.spec_from_file_location("local_migration_drill", DRILL)
assert _spec and _spec.loader
drill = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = drill
_spec.loader.exec_module(drill)


class LocalMigrationDrillCliTest(unittest.TestCase):
    def test_report_shape_from_fixture(self) -> None:
        sample = {
            "card": "P12-020",
            "passed": True,
            "latest_schema": 5,
            "versions": [{"schema_version": 1, "label": "0→5", "passed": True}],
        }
        with tempfile.TemporaryDirectory() as tmp:
            report_path = Path(tmp) / "report.json"
            report_path.write_text(json.dumps(sample) + "\n")
            payload = json.loads(report_path.read_text())
            self.assertTrue(payload["passed"])
            self.assertEqual(payload["latest_schema"], 5)


if __name__ == "__main__":
    unittest.main()
