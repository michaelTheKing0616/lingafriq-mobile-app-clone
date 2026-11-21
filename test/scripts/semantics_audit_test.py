#!/usr/bin/env python3
"""A new interactive design widget without a label fails. A labelled one passes."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "semantics_audit.py"

UNLABELLED = """// Semantics
class SaveButton extends StatelessWidget {
  const SaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
"""

LABELLED = """class QuietButton extends StatelessWidget {
  const QuietButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quiet',
      button: true,
      child: const SizedBox.shrink(),
    );
  }
}
"""

NOTE = """class LessonNote extends StatelessWidget {
  const LessonNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
"""

SCREEN = """class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
"""


def git(root: Path, *args: str) -> None:
    subprocess.run(
        ["git", *args],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )


def write(root: Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def commit(root: Path, message: str) -> None:
    git(root, "add", "-A")
    git(
        root,
        "-c",
        "user.email=lint@example.com",
        "-c",
        "user.name=Lint",
        "-c",
        "commit.gpgsign=false",
        "commit",
        "-q",
        "-m",
        message,
    )


def init_repo(root: Path) -> None:
    git(root, "init", "-q")
    git(root, "config", "user.email", "lint@example.com")
    git(root, "config", "user.name", "Lint")
    git(root, "config", "commit.gpgsign", "false")
    write(root, "README", "base\n")
    commit(root, "base")
    git(root, "update-ref", "refs/remotes/origin/cloud-handoff", "HEAD")


def run(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root)],
        check=False,
        capture_output=True,
        text=True,
    )


def count_semantics(lib: Path) -> int:
    if not lib.is_dir():
        return 0
    total = 0
    for path in lib.rglob("*.dart"):
        total += path.read_text(encoding="utf-8", errors="replace").count("Semantics(")
    return total


class SemanticsAuditTest(unittest.TestCase):
    def test_missing_label_fails_and_labelled_widget_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            init_repo(root)
            write(root, "lib/design/save_button.dart", UNLABELLED)
            write(root, "lib/design/quiet_button.dart", LABELLED)
            write(root, "lib/design/note.dart", NOTE)
            write(root, "lib/screens/home_button.dart", SCREEN)
            commit(root, "add widgets")
            result = run(root)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("missing-label lib/design/save_button.dart:2 SaveButton", result.stdout)
        self.assertNotIn("quiet_button.dart", result.stdout)
        self.assertNotIn("note.dart", result.stdout)
        self.assertNotIn("home_button.dart", result.stdout)
        self.assertIn("not scanned: existing app screens", result.stdout)

    def test_switch_field_and_text_button_need_a_label(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            init_repo(root)
            write(
                root,
                "lib/design/controls.dart",
                "class VolumeSwitch extends StatelessWidget {}\n"
                "class NameField extends StatelessWidget {}\n"
                "class ContinueAction extends StatelessWidget {\n"
                "  Widget build() => TextButton(onPressed: () {}, child: const Text('Go'));\n"
                "}\n",
            )
            commit(root, "add controls")
            result = run(root)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("VolumeSwitch", result.stdout)
        self.assertIn("NameField", result.stdout)
        self.assertIn("ContinueAction", result.stdout)

    def test_existing_design_file_is_not_scanned(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            init_repo(root)
            write(root, "lib/design/old_button.dart", UNLABELLED)
            commit(root, "old")
            git(root, "update-ref", "refs/remotes/origin/cloud-handoff", "HEAD")
            write(root, "lib/design/quiet_button.dart", LABELLED)
            commit(root, "new")
            result = run(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("old_button.dart", result.stdout)
        self.assertNotIn("SaveButton", result.stdout)

    def test_repository_diff_passes_and_count_matches_lib(self) -> None:
        result = run(ROOT)
        count = count_semantics(ROOT / "lib")
        comment = SCRIPT.read_text(encoding="utf-8").splitlines()[1]
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"Semantics( under lib/: {count}", result.stdout)
        self.assertIn(str(count), comment)
        self.assertIn("not scanned: existing app screens", result.stdout)


if __name__ == "__main__":
    unittest.main()
