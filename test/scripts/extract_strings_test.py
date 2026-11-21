#!/usr/bin/env python3
"""The string extractor names keys, rejects bad ICU, and ratchets new copy."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "i18n" / "extract_strings.py"


def run(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--root", str(root), *args],
        check=False,
        capture_output=True,
        text=True,
    )


class ExtractStringsTest(unittest.TestCase):
    def test_extract_writes_a_prefixed_key(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        try:
            lib = root / "lib" / "screens" / "onboarding"
            lib.mkdir(parents=True)
            (lib / "hello.dart").write_text("class Hi { Widget build(BuildContext context) { return Text('Welcome aboard'); } }\n", encoding="utf-8")
            arb = root / "lib" / "l10n" / "app_en.arb"
            arb.parent.mkdir(parents=True)
            arb.write_text('{ "@@locale": "en" }\n', encoding="utf-8")
            result = run(root, "--extract", "lib/screens/onboarding", "--baseline", "scripts/i18n/string_baseline.json")
            data = json.loads(arb.read_text(encoding="utf-8"))
            keys = [key for key in data if not str(key).startswith("@")]
            self.assertTrue(any(key.startswith("onboarding") for key in keys), keys)
            self.assertIn("Welcome aboard", data.values())
            self.assertNotIn("Welcome aboard", (lib / "hello.dart").read_text(encoding="utf-8"))
            self.assertIn("l10nOf(context).onboarding", (lib / "hello.dart").read_text(encoding="utf-8"))
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_new_string_above_the_baseline_fails(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        try:
            screen = root / "lib" / "screens" / "games"
            screen.mkdir(parents=True)
            (screen / "play.dart").write_text("Text('New game');\n", encoding="utf-8")
            arb = root / "lib" / "l10n"
            arb.mkdir(parents=True)
            (arb / "app_en.arb").write_text('{ "@@locale": "en" }\n', encoding="utf-8")
            base = root / "baseline.json"
            base.write_text(json.dumps({"count": 0, "files": {}}) + "\n", encoding="utf-8")
            result = run(root, "--baseline", str(base))
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("New game", result.stdout)
        self.assertIn("remaining", result.stdout)

    def test_malformed_plural_fails(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        try:
            (root / "lib").mkdir()
            arb = root / "lib" / "l10n"
            arb.mkdir(parents=True)
            (arb / "app_en.arb").write_text(
                json.dumps(
                    {
                        "@@locale": "en",
                        "broken": "{count, plural, =1{one}",
                        "@broken": {"placeholders": {"count": {"type": "int"}}},
                    }
                ),
                encoding="utf-8",
            )
            base = root / "baseline.json"
            base.write_text(json.dumps({"count": 0, "files": {}}) + "\n", encoding="utf-8")
            result = run(root, "--baseline", str(base))
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("malformed", result.stdout)
        self.assertIn("broken", result.stdout)

    def test_valid_plural_passes(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        try:
            (root / "lib").mkdir()
            arb = root / "lib" / "l10n"
            arb.mkdir(parents=True)
            (arb / "app_en.arb").write_text(
                json.dumps(
                    {
                        "@@locale": "en",
                        "days": "{count, plural, =1{1 day} other{{count} days}}",
                        "@days": {"placeholders": {"count": {"type": "int"}}},
                    }
                ),
                encoding="utf-8",
            )
            base = root / "baseline.json"
            base.write_text(json.dumps({"count": 0, "files": {}}) + "\n", encoding="utf-8")
            result = run(root, "--baseline", str(base))
        finally:
            tmp.cleanup()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("remaining", result.stdout)

    def test_repository_matches_the_baseline(self):
        result = run(ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("inventory 9293", result.stdout)


if __name__ == "__main__":
    unittest.main()
