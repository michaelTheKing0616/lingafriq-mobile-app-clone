#!/usr/bin/env python3
"""A plain Text of target-language copy fails. TargetText does not."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "target_text_only.py"


def run(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root)],
        check=False,
        capture_output=True,
        text=True,
    )


def write(root: Path, files: dict[str, str]) -> None:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")


class TargetTextOnlyLintTest(unittest.TestCase):
    def test_plain_text_fails_and_target_text_does_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/bad.dart": "Widget build() {\n  return Text('Ẹ kú àárọ̀');\n}\n",
                    "lib/design/good.dart": "Widget build() {\n  return TargetText(text: 'Ẹ kú àárọ̀');\n}\n",
                    "lib/design/english.dart": "Widget build() {\n  return Text('Save');\n}\n",
                    "lib/design/comment.dart": "// Text('Ẹ kú')\nWidget build() {\n  return Text('Save');\n}\n",
                    "lib/screens/lesson.dart": "Text('Ẹ kú àárọ̀');\n",
                },
            )
            result = run(root)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("lib/design/bad.dart:2", result.stdout)
            self.assertNotIn("good.dart", result.stdout)
            self.assertNotIn("english.dart", result.stdout)
            self.assertNotIn("comment.dart", result.stdout)
            self.assertNotIn("screens/lesson.dart", result.stdout)

    def test_multiline_and_escape_and_identifier_name_the_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(
                root,
                {
                    "lib/design/wrap.dart": "Text(\n  '\\u1EB9',\n);\n",
                    "lib/design/name.dart": "final word = 'Ẹ';\nText(word);\n",
                    "lib/design/proof.dart": "Text(LingAfriqType.glyphProof);\n",
                },
            )
            result = run(root)
            self.assertEqual(result.returncode, 1, result.stdout)
            self.assertIn("lib/design/wrap.dart:2", result.stdout)
            self.assertIn("lib/design/name.dart:2", result.stdout)
            self.assertIn("lib/design/proof.dart:1", result.stdout)

    def test_repo_design_tree_passes(self):
        result = run(ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("target-text-only: ok", result.stdout)


if __name__ == "__main__":
    unittest.main()
