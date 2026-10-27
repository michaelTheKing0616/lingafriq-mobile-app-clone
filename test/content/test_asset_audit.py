# charter: v2
"""Unit tests for scripts/ci/asset_audit.py (P12-002)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/asset_audit.py"


def _run(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root)],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_live_repo_passes_asset_audit() -> None:
    result = _run(REPO_ROOT)
    assert result.returncode == 0, result.stderr + result.stdout


def test_forbidden_dart_in_assets_fails(tmp_path: Path) -> None:
    assets = tmp_path / "assets" / "data"
    assets.mkdir(parents=True)
    (assets / "evil.dart").write_text("// bad\n", encoding="utf-8")
    (tmp_path / "pubspec.yaml").write_text(
        "name: x\nflutter:\n  assets:\n    - assets/data/\n",
        encoding="utf-8",
    )
    (tmp_path / "dev" / "examples").mkdir(parents=True)
    for name in (
        "integrated_screen_example.dart",
        "errorhandler_integration_example.dart",
        "performance_utilities_example.dart",
    ):
        (tmp_path / "dev" / "examples" / name).write_text("// ok\n", encoding="utf-8")
    result = _run(tmp_path)
    assert result.returncode == 1
    assert "FORBIDDEN_ASSET_CODE" in result.stderr


def test_lib_examples_dir_fails(tmp_path: Path) -> None:
    (tmp_path / "lib" / "examples").mkdir(parents=True)
    (tmp_path / "lib" / "examples" / "leftover.dart").write_text("// x\n", encoding="utf-8")
    (tmp_path / "pubspec.yaml").write_text("name: x\nflutter:\n  assets:\n", encoding="utf-8")
    (tmp_path / "dev" / "examples").mkdir(parents=True)
    for name in (
        "integrated_screen_example.dart",
        "errorhandler_integration_example.dart",
        "performance_utilities_example.dart",
    ):
        (tmp_path / "dev" / "examples" / name).write_text("// ok\n", encoding="utf-8")
    result = _run(tmp_path)
    assert result.returncode == 1
    assert "DEV_EXAMPLE_STILL_IN_LIB" in result.stderr


def test_unreferenced_font_fails(tmp_path: Path) -> None:
    fonts = tmp_path / "assets" / "fonts"
    fonts.mkdir(parents=True)
    (fonts / "Dosis-Regular.ttf").write_bytes(b"\x00")
    (fonts / "Orphan.ttf").write_bytes(b"\x00")
    (tmp_path / "pubspec.yaml").write_text(
        "name: x\nflutter:\n  assets:\n    - assets/fonts/\n  fonts:\n"
        "    - family: dosis\n      fonts:\n"
        "        - asset: assets/fonts/Dosis-Regular.ttf\n"
        "          weight: 400\n"
        "        - asset: assets/fonts/Orphan.ttf\n"
        "          weight: 500\n",
        encoding="utf-8",
    )
    (tmp_path / "lib").mkdir()
    (tmp_path / "lib" / "main.dart").write_text(
        "const x = 'assets/fonts/Dosis-Regular.ttf';\n",
        encoding="utf-8",
    )
    (tmp_path / "dev" / "examples").mkdir(parents=True)
    for name in (
        "integrated_screen_example.dart",
        "errorhandler_integration_example.dart",
        "performance_utilities_example.dart",
    ):
        (tmp_path / "dev" / "examples" / name).write_text("// ok\n", encoding="utf-8")
    result = _run(tmp_path)
    assert result.returncode == 1
    assert "FONT_UNREFERENCED" in result.stderr
