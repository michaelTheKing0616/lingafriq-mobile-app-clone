# charter: v2
"""Unit tests for scripts/ci/apk_size_gate.sh (P12-004)."""

from __future__ import annotations

import subprocess
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/apk_size_gate.sh"


def _run(*args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    import os

    merged = os.environ.copy()
    if env:
        merged.update(env)
    return subprocess.run(
        ["bash", str(SCRIPT), *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
        env=merged,
    )


def test_self_test_passes() -> None:
    result = _run("--self-test")
    assert result.returncode == 0, result.stderr + result.stdout
    assert "self-test ok" in result.stdout


def test_threshold_logic_under_and_over(tmp_path: Path) -> None:
    small_apk = tmp_path / "app-arm64-v8a-release.apk"
    with zipfile.ZipFile(small_apk, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("assets/tiny.txt", b"a" * 512)

    ok = _run("--apk-dir", str(tmp_path), env={"APK_SIZE_GATE_MAX_BYTES": "40000000"})
    assert ok.returncode == 0, ok.stderr + ok.stdout

    big_apk = tmp_path / "app-x86_64-release.apk"
    with zipfile.ZipFile(big_apk, "w", compression=zipfile.ZIP_STORED) as zf:
        zf.writestr("assets/large.bin", b"\0" * (41 * 1024 * 1024))

    bad = _run("--apk-dir", str(tmp_path), env={"APK_SIZE_GATE_MAX_BYTES": "40000000"})
    assert bad.returncode == 1, bad.stderr + bad.stdout
    assert "five largest entries" in bad.stdout
    assert "delta" in bad.stdout or "baseline" in bad.stdout
