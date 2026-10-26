"""P0-INT-02: pre-commit charter check on staged agent-facing files."""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECK = ROOT / "scripts" / "check_agent_files.py"
INSTALL = ROOT / "scripts" / "install_hooks.sh"


def _run(cmd: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    merged = os.environ.copy()
    if env:
        merged.update(env)
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=merged, check=False)


def test_staged_file_without_marker_fails() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        _run(["git", "init", "-q"], cwd=repo)
        _run(["git", "config", "user.email", "test@example.com"], cwd=repo)
        _run(["git", "config", "user.name", "Test"], cwd=repo)
        shutil_copy_tree(ROOT / "scripts", repo / "scripts")
        bad = repo / "docs" / "build" / "cards" / "P0" / "BAD.yaml"
        bad.parent.mkdir(parents=True)
        bad.write_text("id: BAD\n", encoding="utf-8")
        _run(["git", "add", bad.relative_to(repo).as_posix()], cwd=repo)
        proc = _run(["python3", "scripts/check_agent_files.py", "--staged"], cwd=repo)
        assert proc.returncode == 1
        assert "missing `charter: v2`" in proc.stderr


def test_install_hooks_sets_hooks_path_idempotent() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        _run(["git", "init", "-q"], cwd=repo)
        shutil_copy_tree(ROOT / "scripts", repo / "scripts")
        shutil_copy_tree(ROOT / ".githooks", repo / ".githooks")
        first = _run(["bash", "scripts/install_hooks.sh"], cwd=repo)
        assert first.returncode == 0
        assert _run(["git", "config", "core.hooksPath"], cwd=repo).stdout.strip() == ".githooks"
        second = _run(["bash", "scripts/install_hooks.sh"], cwd=repo)
        assert second.returncode == 0
        assert _run(["git", "config", "core.hooksPath"], cwd=repo).stdout.strip() == ".githooks"


def shutil_copy_tree(src: Path, dst: Path) -> None:
    shutil.copytree(src, dst, dirs_exist_ok=True)
