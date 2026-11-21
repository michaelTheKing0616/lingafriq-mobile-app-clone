#!/usr/bin/env python3
"""Banned words, em dashes, and unmeasured confidence chips fail the lint."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "honest_copy.py"


def run(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root), "--baseline", str(root / "baseline.json")],
        check=False,
        capture_output=True,
        text=True,
    )


def tree(files: dict[str, str], allowed: list[str] | None = None) -> tuple[Path, tempfile.TemporaryDirectory[str]]:
    tmp = tempfile.TemporaryDirectory()
    root = Path(tmp.name)
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    (root / "baseline.json").write_text(
        json.dumps({"allowed": allowed or []}) + "\n",
        encoding="utf-8",
    )
    return root, tmp


class HonestCopyTest(unittest.TestCase):
    def test_banned_word_names_the_file(self):
        root, tmp = tree({"lib/ui.dart": "const label = 'World-class lesson';\n"})
        try:
            result = run(root)
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("banned-word lib/ui.dart:1 World-class", result.stdout)

    def test_elite_and_seamless_fail(self):
        root, tmp = tree({"lib/ui.dart": "title: 'Elite path';\nsubtitle: 'Seamless flow';\n"})
        try:
            result = run(root)
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1)
        self.assertIn("banned-word lib/ui.dart:1 Elite", result.stdout)
        self.assertIn("banned-word lib/ui.dart:2 Seamless", result.stdout)

    def test_em_dash_fails(self):
        root, tmp = tree({"lib/ui.dart": "const note = 'Hold — then speak';\n"})
        try:
            result = run(root)
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1)
        self.assertIn("em-dash lib/ui.dart:1", result.stdout)

    def test_unmeasured_confidence_fails_and_a_field_does_not(self):
        root, tmp = tree({
            "lib/widgets/chip.dart": "confidence: 0.9,\nconfidence: result.score,\n",
        })
        try:
            result = run(root)
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1)
        self.assertIn("fake-confidence lib/widgets/chip.dart:1", result.stdout)
        self.assertNotIn("lib/widgets/chip.dart:2", result.stdout)

    def test_comments_are_not_ui_copy(self):
        root, tmp = tree({"lib/note.dart": "// World-class comment\n/// Elite doc\n"})
        try:
            result = run(root)
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_repository_has_no_new_hits(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(ROOT)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
