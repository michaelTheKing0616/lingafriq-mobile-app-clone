"""P9-936: G9 guardian and moderation gate verification."""
from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "safety" / "g9_gate_check.py"


def _load_gate():
    spec = importlib.util.spec_from_file_location("g9_gate_check", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def test_g9_packet_integrity():
    mod = _load_gate()
    errors = mod.run_gate(run_tests=False)
    assert errors == [], errors


def test_g9_policy_matrix_integration():
    mod = _load_gate()
    errors = mod.run_gate(run_tests=True)
    assert errors == [], errors


def test_g9_cli_check_exit_zero():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout
