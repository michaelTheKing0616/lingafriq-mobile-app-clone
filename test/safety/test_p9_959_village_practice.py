"""P9-959 village practice audit checker."""
from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "safety" / "village_practice_audit_check.py"
AUDIT = ROOT / "docs" / "build" / "external" / "village_practice_audit.md"


def test_audit_file_exists() -> None:
    assert AUDIT.is_file(), "village_practice_audit.md must exist"


def test_checker_passes() -> None:
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout


def test_checker_module_import() -> None:
    spec = importlib.util.spec_from_file_location("village_practice_audit_check", SCRIPT)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    meta, body = mod.load_audit()
    assert meta["card_id"] == "P9-959"
