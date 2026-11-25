# charter: v2
"""Graph tests for scripts/ci/dead_screen_report.py (P12-008)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/dead_screen_report.py"


def _run(*cmd: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(REPO_ROOT), *cmd],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_live_repo_verify_passes_after_deletions() -> None:
    result = _run("verify")
    assert result.returncode == 0, result.stderr + result.stdout


def test_blocked_duplicate_lists_importer(tmp_path: Path) -> None:
    lib = tmp_path / "lib" / "screens" / "chat"
    lib.mkdir(parents=True)
    dup = lib / "global_chat_screen.dart"
    dup.write_text("class GlobalChatScreen {}\n", encoding="utf-8")
    (lib / "global_chat_screen_material3.dart").write_text(
        "class GlobalChatScreenMaterial3 {}\n", encoding="utf-8"
    )
    (tmp_path / "lib" / "other.dart").write_text(
        "import 'package:lingafriq/screens/chat/global_chat_screen.dart';\n",
        encoding="utf-8",
    )
    (tmp_path / "lib" / "my_app.dart").write_text(
        "const routes = {'global_chat': GlobalChatScreenMaterial3};\n",
        encoding="utf-8",
    )
    polie = tmp_path / "lib" / "features" / "polie_workspace"
    polie.mkdir(parents=True)
    (polie / "polie_workspace_screen.dart").write_text("// ok\n", encoding="utf-8")
    ai = tmp_path / "lib" / "screens" / "ai_chat"
    ai.mkdir(parents=True)
    for name in (
        "ai_chat_screen.dart",
        "ai_chat_screen_new.dart",
        "ai_chat_screen_with_tracking.dart",
        "conversation_enhanced_screen.dart",
    ):
        (ai / name).write_text("// removed in prod\n", encoding="utf-8")

    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(tmp_path), "verify"],
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 1
    assert "BLOCKED_INBOUND" in result.stderr
    assert "global_chat_screen.dart" in result.stderr
