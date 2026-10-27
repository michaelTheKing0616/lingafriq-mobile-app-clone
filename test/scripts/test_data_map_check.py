"""P10-920: data map checker tests."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "privacy" / "data_map_check.py"


def test_gate_passes_on_repo_retention():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--gate"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout


def test_self_test():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--self-test"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout
