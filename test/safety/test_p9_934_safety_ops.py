"""P9-934: safety lead, IR plan, and moderator training gate."""
from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "safety" / "safety_ops_check.py"


def _load_gate():
    spec = importlib.util.spec_from_file_location("safety_ops_check", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def test_safety_ops_gate_passes():
    mod = _load_gate()
    errors = mod.run_gate()
    assert errors == [], errors


def test_safety_ops_cli_exit_zero():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout
