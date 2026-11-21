#!/usr/bin/env python3
"""Each token rule, the colour ratchet, and the 15-line CI summary."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "lint" / "token_compliance.py"


def run(root: Path, baseline: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root), "--baseline", str(baseline)],
        check=False,
        capture_output=True,
        text=True,
    )


def write_tree(root: Path, files: dict[str, str], baseline: dict[str, int]) -> Path:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    baseline_path = root / "baseline.json"
    baseline_path.write_text(
        json.dumps({"colorLiteral": baseline}, indent=2) + "\n",
        encoding="utf-8",
    )
    return baseline_path


class TokenComplianceTest(unittest.TestCase):
    def test_each_rule_names_itself_and_the_line(self):
        samples = {
            "color-literal": "lib/design/new.dart Widget(Color(0xFF112233));\n",
            "font-family": "lib/design/new.dart fontFamily: 'ComicSans',\n",
            "font-size": "lib/design/new.dart fontSize: 12,\n",
            "spacing-literal": "lib/design/new.dart EdgeInsets.all(13)\n",
            "user-string": "lib/design/new.dart Text('Save')\n",
        }
        for rule, body in samples.items():
            with self.subTest(rule=rule):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    rel, text = body.split(" ", 1)
                    baseline = write_tree(root, {rel: text}, {})
                    result = run(root, baseline)
                    self.assertEqual(result.returncode, 1)
                    self.assertIn(f"{rule} {rel}:1", result.stdout)

    def test_ratchet_blocks_an_increase_and_prints_the_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            baseline = write_tree(
                root,
                {"lib/legacy.dart": "Color(0xFF000000)\nColor(0xFFFFFFFF)\n"},
                {"lib/legacy.dart": 1},
            )
            result = run(root, baseline)
            self.assertEqual(result.returncode, 1)
            self.assertIn("color-literal lib/legacy.dart:1", result.stdout)
            self.assertLessEqual(len(result.stdout.splitlines()), 15)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            baseline = write_tree(
                root,
                {"lib/legacy.dart": "Color(0xFF000000)\n"},
                {"lib/legacy.dart": 1},
            )
            result = run(root, baseline)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("color-literal 1 (baseline 1)", result.stdout)

    def test_design_path_outside_the_baseline_allows_zero(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            baseline = write_tree(
                root,
                {"lib/design/extra.dart": "const x = Color(0xFF010101);\n"},
                {},
            )
            result = run(root, baseline)
            self.assertEqual(result.returncode, 1)
            self.assertIn("color-literal lib/design/extra.dart:1", result.stdout)

    def test_many_findings_stay_within_fifteen_lines(self):
        lines = "\n".join(f"Color(0xFF{i:06X})" for i in range(40)) + "\n"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            baseline = write_tree(root, {"lib/design/many.dart": lines}, {})
            result = run(root, baseline)
            printed = result.stdout.splitlines()
            self.assertEqual(result.returncode, 1)
            self.assertLessEqual(len(printed), 15)
            self.assertTrue(printed[-1].startswith("+"))

    def test_repository_matches_the_recorded_baseline(self):
        result = run(ROOT, ROOT / "scripts" / "lint" / "token_baseline.json")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("color-literal", result.stdout)
        self.assertLessEqual(len(result.stdout.splitlines()), 15)


if __name__ == "__main__":
    unittest.main()
