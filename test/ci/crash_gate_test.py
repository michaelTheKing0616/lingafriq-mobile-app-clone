#!/usr/bin/env python3
"""The rollout gate blocks a bad crash-free rate and a high ANR rate."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "scripts" / "ci" / "crash_gate.py"


def run(payload: dict[str, float]) -> subprocess.CompletedProcess[str]:
    with tempfile.TemporaryDirectory() as directory:
        report = Path(directory) / "report.json"
        report.write_text(json.dumps(payload))
        return subprocess.run(
            [sys.executable, str(GATE), str(report)],
            capture_output=True,
            text=True,
            cwd=ROOT,
        )


class CrashGateTest(unittest.TestCase):
    def test_allows_a_healthy_stage(self) -> None:
        result = run({"crash_free_users": 0.999, "anr_rate": 0.001})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_blocks_when_crash_free_users_fall(self) -> None:
        result = run({"crash_free_users": 0.990, "anr_rate": 0.001})
        self.assertEqual(result.returncode, 1)
        self.assertIn("crash-free users", result.stderr)

    def test_blocks_when_the_anr_rate_rises(self) -> None:
        result = run({"crash_free_users": 0.999, "anr_rate": 0.010})
        self.assertEqual(result.returncode, 1)
        self.assertIn("ANR rate", result.stderr)


if __name__ == "__main__":
    unittest.main()
