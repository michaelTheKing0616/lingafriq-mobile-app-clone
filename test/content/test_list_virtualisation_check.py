# charter: v2
"""Unit tests for scripts/ci/list_virtualisation_check.py (P12-010)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/list_virtualisation_check.py"
BASELINE = REPO_ROOT / "scripts/ci/p12_010_prefer_const_baseline.tsv"


def _run(*args: str) -> subprocess.CompletedProcess[str]:
    cmd = [sys.executable, str(SCRIPT), *args]
    return subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True, check=False)


def test_live_screens_pass_list_virtualisation_gate() -> None:
    result = _run()
    assert result.returncode == 0, result.stderr + result.stdout


def test_const_baseline_present_and_passes() -> None:
    assert BASELINE.is_file(), "prefer_const baseline must exist (AC3)"
    result = _run("--check-const-baseline")
    assert result.returncode == 0, result.stderr + result.stdout


def test_self_test_subcommand() -> None:
    result = _run("--self-test")
    assert result.returncode == 0, result.stderr
    assert "self-test ok" in result.stdout
