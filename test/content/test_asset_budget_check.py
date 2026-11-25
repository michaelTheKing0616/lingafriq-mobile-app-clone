# charter: v2
"""Unit tests for scripts/ci/asset_budget_check.py (P12-009)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/asset_budget_check.py"
CONFIG = REPO_ROOT / "assets/images/asset_budget_config.json"


def _run(*args: str, root: Path | None = None) -> subprocess.CompletedProcess[str]:
    cmd = [sys.executable, str(SCRIPT), "--root", str(root or REPO_ROOT), *args]
    return subprocess.run(
        cmd,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_live_repo_passes_asset_budget_gate() -> None:
    assert CONFIG.is_file(), "budget config must exist (AC2)"
    result = _run("--config", str(CONFIG))
    assert result.returncode == 0, result.stderr + result.stdout


def test_missing_config_fails_loud(tmp_path: Path) -> None:
    result = _run("--config", str(tmp_path / "missing.json"), root=tmp_path)
    assert result.returncode == 2
    assert "ASSET_BUDGET_CONFIG_MISSING" in result.stderr


def test_rive_character_budget_300kb(tmp_path: Path) -> None:
    cfg = {
        "scan_roots": ["assets/rive"],
        "rive_character_file_max_bytes": 307200,
        "rive_character_basenames": ["lingafriq_cast.riv"],
        "rive_default_max_bytes": 1024,
        "extension_max_bytes": {},
        "path_overrides": {},
    }
    (tmp_path / "assets" / "rive").mkdir(parents=True)
    cfg_path = tmp_path / "assets" / "images" / "asset_budget_config.json"
    cfg_path.parent.mkdir(parents=True)
    cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
    cast = tmp_path / "assets" / "rive" / "lingafriq_cast.riv"
    cast.write_bytes(b"0" * 307201)
    result = _run("--config", str(cfg_path), root=tmp_path)
    assert result.returncode == 1
    assert "lingafriq_cast.riv" in result.stderr
    assert "rive_character" in result.stderr


def test_self_test_subcommand() -> None:
    result = _run("--self-test")
    assert result.returncode == 0, result.stderr
    assert "self-test ok" in result.stdout
