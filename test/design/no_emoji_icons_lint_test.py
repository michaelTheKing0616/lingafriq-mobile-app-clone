#!/usr/bin/env python3
"""Emoji in a new Icon or as a button's only child fails. Existing files do not."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "no_emoji_icons.py"


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


def git(root: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True, text=True)


def commit_tree(root: Path) -> None:
    git(root, "init")
    git(root, "config", "user.email", "lint@example.com")
    git(root, "config", "user.name", "Lint")
    git(root, "add", ".")
    git(root, "-c", "commit.gpgsign=false", "commit", "-m", "base")


class NoEmojiIconsLintTest(unittest.TestCase):
    def test_icon_and_button_child_fail_with_file_and_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/bad_icon.dart": "Widget build() {\n  return Icon(semanticLabel: '🔥');\n}\n",
                    "lib/design/bad_button.dart": "ElevatedButton(\n  onPressed: () {},\n  child: Text('🔥'),\n)\n",
                    "lib/design/bad_tonal.dart": "FilledButton.tonal(\n  child: const Text(\n    '🔥',\n  ),\n)\n",
                    "lib/design/bad_icon_button.dart": "IconButton(\n  icon: Text('📚'),\n)\n",
                    "lib/design/escape.dart": "Icon('\\u{1F525}');\n",
                    "lib/design/ok_copy.dart": "Text('🔥');\n",
                    "lib/design/ok_button.dart": "ElevatedButton(\n  child: Text('Save'),\n)\n",
                    "lib/design/ok_comment.dart": "// Icon('🔥')\nWidget build() {\n  return const SizedBox();\n}\n",
                    "lib/design/ok_ling.dart": "LingIcon(\n  name: LingIconName.today,\n)\n",
                    "lib/design/ok_letters.dart": "TextButton(\n  child: Text('Ẹ kú'),\n)\n",
                    "lib/screens/old.dart": "Icon(semanticLabel: '🔥');\n",
                },
            )
            result = run(root)
            output = result.stdout
            self.assertEqual(result.returncode, 1, output + result.stderr)
            self.assertIn("lib/design/bad_icon.dart:2: emoji used as an icon", output)
            self.assertIn("lib/design/bad_button.dart:3: emoji used as an icon", output)
            self.assertIn("lib/design/bad_tonal.dart:3: emoji used as an icon", output)
            self.assertIn("lib/design/bad_icon_button.dart:2: emoji used as an icon", output)
            self.assertIn("lib/design/escape.dart:1: emoji used as an icon", output)
            self.assertNotIn("ok_copy.dart", output)
            self.assertNotIn("ok_button.dart", output)
            self.assertNotIn("ok_comment.dart", output)
            self.assertNotIn("ok_ling.dart", output)
            self.assertNotIn("ok_letters.dart", output)
            self.assertNotIn("screens/old.dart", output)

    def test_diff_ignores_emoji_already_on_the_base(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root, {"lib/design/old.dart": "Icon(semanticLabel: '🔥');\n"})
            commit_tree(root)
            write(root, {"lib/design/new_ok.dart": "LingIcon(name: LingIconName.today);\n"})
            result = run(root, base="HEAD")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("no-emoji-icons: ok", result.stdout)
            self.assertNotIn("old.dart", result.stdout)

    def test_diff_flags_a_new_file_and_an_added_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/old.dart": "Icon(semanticLabel: '🔥');\n",
                    "lib/design/mark.dart": "Widget build() {\n  return Icon(Icons.home);\n}\n",
                },
            )
            commit_tree(root)
            write(
                root,
                {
                    "lib/design/new_bad.dart": "ElevatedButton(\n  child: Text('🔥'),\n)\n",
                    "lib/design/mark.dart": "Widget build() {\n  return Icon(semanticLabel: '🔥');\n}\n",
                },
            )
            result = run(root, base="HEAD")
            output = result.stdout
            self.assertEqual(result.returncode, 1, output + result.stderr)
            self.assertIn("lib/design/new_bad.dart:2: emoji used as an icon", output)
            self.assertIn("lib/design/mark.dart:2: emoji used as an icon", output)
            self.assertNotIn("old.dart", output)

    def test_repo_diff_against_cloud_handoff_passes(self):
        result = run(ROOT, base="origin/cloud-handoff")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("no-emoji-icons: ok", result.stdout)


if __name__ == "__main__":
    unittest.main()
