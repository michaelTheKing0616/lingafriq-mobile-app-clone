#!/usr/bin/env python3
"""Fixtures for the v1 content validator."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "content" / "validate_content.py"
BUNDLES = (
    "curriculum_bundle",
    "curriculum_expanded_bundle",
    "lingafriq_FINAL_curriculum",
    "lingafriq_full_curriculum_bundle",
)


def lexeme(**overrides: object) -> dict:
    item = {
        "kind": "lexeme",
        "id": "yo.lex.oko.vehicle",
        "language": "yo",
        "lemma": "ọkọ̀",
        "orthography": {"standard": "ọkọ̀", "script": "Latn"},
        "senses": [{"gloss_en": "vehicle"}],
        "cefr": "A1",
        "provenance": {
            "author": "linguist",
            "source": "lexicon",
            "licence": "cc-by",
            "created_at": "2026-01-01",
        },
        "review": {
            "status": "approved",
            "reviewers": ["native_1"],
            "tone_checked": True,
            "audio_checked": True,
            "version": 1,
        },
    }
    item.update(overrides)
    return {"schema_version": "lingafriq.content.v1", "items": [item]}


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class ValidatorTest(unittest.TestCase):
    def test_valid_pack_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pack.json"
            path.write_text(json.dumps(lexeme()), encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_schema_failure_names_id_and_pointer(self) -> None:
        pack = lexeme()
        del pack["items"][0]["lemma"]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pack.json"
            path.write_text(json.dumps(pack), encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("yo.lex.oko.vehicle /items/0/lemma", result.stdout)

    def test_non_nfc_names_the_field(self) -> None:
        pack = lexeme(lemma="o\u0300")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pack.json"
            path.write_text(json.dumps(pack, ensure_ascii=False), encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("field lemma", result.stdout)
        self.assertIn("is not NFC", result.stdout)

    def test_tonal_lemma_without_tone_mark_fails(self) -> None:
        pack = lexeme(lemma="oko")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pack.json"
            path.write_text(json.dumps(pack), encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("yo.lex.oko.vehicle /items/0/lemma", result.stdout)
        self.assertIn("missing tone mark", result.stdout)

    def test_non_tonal_lemma_without_tone_mark_passes(self) -> None:
        pack = lexeme(id="sw.lex.habari", language="sw", lemma="habari")
        pack["items"][0]["orthography"]["standard"] = "habari"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pack.json"
            path.write_text(json.dumps(pack), encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_four_legacy_bundles_are_rejected_with_a_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            report = Path(tmp) / "migration.txt"
            result = run("--legacy-report", str(report), *BUNDLES)
            text = report.read_text(encoding="utf-8")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr + text[:500])
        self.assertIn("accepted 0", text)
        self.assertIn("rejected ", text)
        for name in BUNDLES:
            self.assertIn(name, text)
        self.assertNotIn("\taccepted", text)


if __name__ == "__main__":
    unittest.main()
