#!/usr/bin/env python3
"""A new design animation that ignores reduced motion fails. Screens do not."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "motion_reduced.py"

BAD_CONTROLLER = """class Celebrate {
  void play() {
    final controller = AnimationController();
  }
}
"""

BAD_TWEEN = """class Celebrate {
  Widget build() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      builder: (_, value, child) => child,
    );
  }
}
"""

READS_SETTING = """class Celebrate {
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimationController(vsync: this, duration: reduced);
  }
}
"""

USES_SCOPE = """class Celebrate {
  Widget build(BuildContext context) {
    return LingMotionScope(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.25, end: 1),
        builder: (_, value, child) => child,
      ),
    );
  }
}
"""

COMMENT_ONLY = """class Celebrate {
  void play() {
    // MediaQuery.disableAnimations LingMotionScope
    final controller = AnimationController();
  }
}
"""

STRING_ONLY = """class Celebrate {
  void play() {
    const label = 'disableAnimations LingMotionScope';
    final controller = AnimationController();
  }
}
"""

SCREEN = """class Home {
  void play() {
    final controller = AnimationController();
  }
}
"""


def run(root: Path, base: str | None = None) -> subprocess.CompletedProcess[str]:
    command = [sys.executable, str(SCRIPT)]
    if base is None:
        command.extend(["--root", str(root)])
    else:
        command.extend(["--repo", str(root), "--base", base])
    return subprocess.run(command, check=False, capture_output=True, text=True)


def write(root: Path, files: dict[str, str]) -> None:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")


def git(root: Path, *args: str) -> str:
    proc = subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip()


def commit_tree(root: Path, message: str) -> str:
    git(root, "add", "-A")
    git(root, "-c", "commit.gpgsign=false", "commit", "-m", message)
    return git(root, "rev-parse", "HEAD")


class MotionReducedLintTest(unittest.TestCase):
    def test_new_animation_without_a_read_fails_with_file_and_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/bad_controller.dart": BAD_CONTROLLER,
                    "lib/design/bad_tween.dart": BAD_TWEEN,
                    "lib/design/reads.dart": READS_SETTING,
                    "lib/design/uses_scope.dart": USES_SCOPE,
                    "lib/design/comment_only.dart": COMMENT_ONLY,
                    "lib/design/string_only.dart": STRING_ONLY,
                    "lib/screens/home.dart": SCREEN,
                    "lib/widgets/old.dart": SCREEN,
                },
            )
            result = run(root)
            output = result.stdout
            self.assertEqual(result.returncode, 1, output + result.stderr)
            self.assertIn(
                "lib/design/bad_controller.dart:3: new animation does not read reduced motion",
                output,
            )
            self.assertIn(
                "lib/design/bad_tween.dart:3: new animation does not read reduced motion",
                output,
            )
            self.assertIn(
                "lib/design/comment_only.dart:4: new animation does not read reduced motion",
                output,
            )
            self.assertIn(
                "lib/design/string_only.dart:4: new animation does not read reduced motion",
                output,
            )
            self.assertNotIn("reads.dart", output)
            self.assertNotIn("uses_scope.dart", output)
            self.assertNotIn("screens/home.dart", output)
            self.assertNotIn("widgets/old.dart", output)
            self.assertIn("not scanned: existing app screens", output)

    def test_clean_design_file_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root, {"lib/design/quiet.dart": "class Quiet {\n  final int n = 1;\n}\n"})
            result = run(root)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("motion-reduced: ok", result.stdout)
            self.assertIn("not scanned: existing app screens", result.stdout)

    def test_diff_ignores_an_animation_already_on_the_base(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/old.dart": BAD_CONTROLLER,
                    "lib/screens/home.dart": SCREEN,
                },
            )
            git(root, "init")
            git(root, "config", "user.email", "lint@example.com")
            git(root, "config", "user.name", "Lint")
            base = commit_tree(root, "base")
            write(root, {"lib/design/new_ok.dart": "class Quiet {\n  final int n = 1;\n}\n"})
            commit_tree(root, "add quiet")
            result = run(root, base=base)
            output = result.stdout
            self.assertEqual(result.returncode, 0, output + result.stderr)
            self.assertIn("motion-reduced: ok", output)
            self.assertNotIn("old.dart", output)
            self.assertNotIn("screens/home.dart", output)

    def test_diff_flags_only_the_added_animation_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root, {"lib/design/old.dart": BAD_CONTROLLER})
            git(root, "init")
            git(root, "config", "user.email", "lint@example.com")
            git(root, "config", "user.name", "Lint")
            base = commit_tree(root, "base")
            write(
                root,
                {
                    "lib/design/old.dart": BAD_CONTROLLER
                    + "\nvoid extra() {\n  final next = TweenAnimationBuilder();\n}\n",
                    "lib/design/new_bad.dart": BAD_CONTROLLER,
                    "lib/screens/home.dart": SCREEN,
                    "lib/widgets/banner.dart": SCREEN,
                },
            )
            commit_tree(root, "add animations")
            result = run(root, base=base)
            output = result.stdout
            self.assertEqual(result.returncode, 1, output + result.stderr)
            self.assertIn(
                "lib/design/old.dart:8: new animation does not read reduced motion",
                output,
            )
            self.assertNotIn("lib/design/old.dart:3:", output)
            self.assertIn(
                "lib/design/new_bad.dart:3: new animation does not read reduced motion",
                output,
            )
            self.assertNotIn("screens/home.dart", output)
            self.assertNotIn("widgets/banner.dart", output)
            self.assertIn("not scanned: existing app screens", output)

    def test_diff_passes_when_the_added_lines_read_the_setting(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root, {"lib/design/old.dart": "class Old {\n  final int n = 1;\n}\n"})
            git(root, "init")
            git(root, "config", "user.email", "lint@example.com")
            git(root, "config", "user.name", "Lint")
            base = commit_tree(root, "base")
            write(root, {"lib/design/old.dart": READS_SETTING, "lib/design/scope.dart": USES_SCOPE})
            commit_tree(root, "honour reduced motion")
            result = run(root, base=base)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("motion-reduced: ok", result.stdout)

    def test_repo_diff_against_cloud_handoff_passes(self):
        result = run(ROOT, base="origin/cloud-handoff")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("motion-reduced: ok", result.stdout)
        self.assertIn("not scanned: existing app screens", result.stdout)


if __name__ == "__main__":
    unittest.main()
