#!/usr/bin/env python3
"""Coverage parser fixtures."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "scripts" / "ci" / "coverage_gate.py"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(GATE), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class CoverageGateTest(unittest.TestCase):
    def test_missing_domain_file_drops_the_total_below_70(self) -> None:
        result = run("--self-test")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("domain coverage is below the threshold", result.stdout)
        self.assertIn("elevation_flutter_test_files 64", result.stdout)
        self.assertIn("coverage gate self-test passed", result.stdout)

    def test_repo_config_records_the_elevation_baseline(self) -> None:
        text = (ROOT / "coverage_domain_paths.yaml").read_text(encoding="utf-8")
        self.assertIn("elevation_flutter_test_files: 64", text)
        self.assertIn("lib/learning", text)
        self.assertIn("threshold: 0.70", text)

    def test_missing_report_fails(self) -> None:
        result = run("/tmp/lingafriq-missing-lcov.info")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("coverage report missing", result.stdout)


if __name__ == "__main__":
    unittest.main()
