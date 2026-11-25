"""P8-907: GameKit dark-pattern lint — fixtures and integration."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
_LINT = _REPO / "scripts" / "lint_dark_patterns.py"


def test_self_test_passes() -> None:
    proc = subprocess.run(
        [sys.executable, str(_LINT), "--self-test"],
        cwd=_REPO,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout


def test_gamekit_tree_passes_lint() -> None:
    proc = subprocess.run(
        [sys.executable, str(_LINT)],
        cwd=_REPO,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout


def test_bad_fixture_fails_ci_red() -> None:
    import tempfile

    from scripts.lint_dark_patterns import lint_file

    with tempfile.NamedTemporaryFile("w", suffix=".dart", delete=False) as f:
        f.write("final x = heartsProvider;\n")
        path = Path(f.name)
    hits = lint_file(path)
    path.unlink(missing_ok=True)
    assert any(h.rule == "HEART_OR_ENERGY_GATE" for h in hits)
