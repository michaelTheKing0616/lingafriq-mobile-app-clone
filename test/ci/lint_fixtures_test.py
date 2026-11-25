#!/usr/bin/env python3
"""Fixture checks for the placeholder and claim linters."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLACEHOLDER = ROOT / "scripts" / "ci" / "placeholder_lint.py"
CLAIM = ROOT / "scripts" / "ci" / "claim_lint.py"
PATTERNS = ROOT / "scripts" / "ci" / "lint_patterns.yaml"


def run(script: Path, *args: str, patterns: Path | None = None) -> subprocess.CompletedProcess[str]:
    cmd = [sys.executable, str(script), "--patterns", str(patterns or PATTERNS), *args]
    return subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)


class PlaceholderLintTest(unittest.TestCase):
    def test_example_fails_with_file_line_and_rule(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lib" / "new.dart"
            path.parent.mkdir()
            path.write_text("void main() {\n  var name = 'example';\n}\n", encoding="utf-8")
            result = run(PLACEHOLDER, str(path))
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("new.dart:2 placeholder.example example", result.stdout)

    def test_clean_text_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "clean.dart"
            path.write_text("void main() {\n  var name = 'hello';\n}\n", encoding="utf-8")
            result = run(PLACEHOLDER, str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_word_slot_and_lorem_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "slot.json"
            path.write_text('{"word": "word12", "note": "lorem"}\n', encoding="utf-8")
            result = run(PLACEHOLDER, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("placeholder.word word12", result.stdout)
        self.assertIn("placeholder.lorem lorem", result.stdout)

    def test_word_without_a_digit_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "plain.json"
            path.write_text('{"word": "hello"}\n', encoding="utf-8")
            result = run(PLACEHOLDER, str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_empty_field_fails_and_filled_field_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            empty = Path(tmp) / "empty.json"
            filled = Path(tmp) / "filled.json"
            empty.write_text('{"question": ""}\n', encoding="utf-8")
            filled.write_text('{"question": "What is this?"}\n', encoding="utf-8")
            bad = run(PLACEHOLDER, str(empty))
            good = run(PLACEHOLDER, str(filled))
        self.assertEqual(bad.returncode, 1, bad.stdout)
        self.assertIn("empty.json:1 empty_field", bad.stdout)
        self.assertEqual(good.returncode, 0, good.stdout + good.stderr)

    def test_sample_mcq_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "quiz.json"
            path.write_text('{"question": "Sample MCQ", "answer": "a"}\n', encoding="utf-8")
            result = run(PLACEHOLDER, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("placeholder.sample Sample", result.stdout)

    def test_allowlist_requires_reason_and_owner(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "ok.dart"
            path.write_text("const label = 'example';\n", encoding="utf-8")
            shown = path.resolve().as_posix()
            complete = Path(tmp) / "complete.yaml"
            missing = Path(tmp) / "missing.yaml"
            header = (PATTERNS.read_text(encoding="utf-8").split("allowlist:", 1)[0] + "allowlist:\n")
            complete.write_text(
                header
                + f"  - path: {shown}\n    rule: placeholder.example\n    span: example\n"
                + '    reason: "Names the demo label"\n    owner: content\n',
                encoding="utf-8",
            )
            missing.write_text(
                header
                + f"  - path: {shown}\n    rule: placeholder.example\n    span: example\n"
                + '    reason: "Names the demo label"\n',
                encoding="utf-8",
            )
            ok = run(PLACEHOLDER, str(path), patterns=complete)
            bad = run(PLACEHOLDER, str(path), patterns=missing)
        self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
        self.assertEqual(bad.returncode, 1, bad.stdout + bad.stderr)
        self.assertIn("placeholder.example", bad.stdout)

    def test_baseline_count_blocks_only_an_increase(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "legacy.dart"
            path.write_text("const a = 'example';\n", encoding="utf-8")
            baseline = Path(tmp) / "base.tsv"
            written = run(PLACEHOLDER, "--write-baseline", str(baseline), str(path))
            self.assertEqual(written.returncode, 0, written.stderr)
            same = run(PLACEHOLDER, "--baseline", str(baseline), str(path))
            path.write_text("const a = 'example';\nconst b = 'example';\n", encoding="utf-8")
            more = run(PLACEHOLDER, "--baseline", str(baseline), str(path))
        self.assertEqual(same.returncode, 0, same.stdout + same.stderr)
        self.assertEqual(more.returncode, 1, more.stdout)
        self.assertIn("baseline 1 now 2", more.stdout)


class ClaimLintTest(unittest.TestCase):
    def test_generic_affix_claim_prints_the_span(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "grammar.json"
            path.write_text(
                '{"grammar": ["Listen for the verb stem; affixes carry tense and person."]}\n',
                encoding="utf-8",
            )
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("claim.affix_tense affixes carry tense and person", result.stdout)

    def test_language_specific_grammar_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "grammar.json"
            path.write_text(
                '{"grammar": ["Yoruba marks tense with a preverbal particle."], '
                '"reviewer_id": "native_1", "review_date": "2026-01-15"}\n',
                encoding="utf-8",
            )
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_svo_claim_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "grammar.txt"
            path.write_text("Pattern: subject → verb → object\n", encoding="utf-8")
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("claim.svo_default", result.stdout)
        self.assertIn("subject → verb → object", result.stdout)

    def test_tone_without_source_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tone.json"
            path.write_text('{"tonal_note": "High tone on àárọ̀ marks respect"}\n', encoding="utf-8")
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("claim.tone_without_source", result.stdout)
        self.assertIn("High tone on àárọ̀ marks respect", result.stdout)

    def test_dictionary_corpus_native_and_media_sources_pass(self) -> None:
        notes = {
            "dictionary": '{"tonal_note": "High tone on àárọ̀ marks respect", "dictionary_entry": "yo.lex.aro"}\n',
            "corpus": '{"tonal_note": "High tone on àárọ̀ marks respect", "corpus_id": "jw-1", "licence": "cc-by"}\n',
            "native": (
                '{"tonal_note": "High tone on àárọ̀ marks respect", '
                '"reviewer_id": "native_1", "review_date": "2026-01-15"}\n'
            ),
            "media": (
                '{"tonal_note": "High tone on àárọ̀ marks respect", '
                '"media_id": "media-42", "timestamp": "00:01:02-00:01:08"}\n'
            ),
        }
        with tempfile.TemporaryDirectory() as tmp:
            for name, body in notes.items():
                path = Path(tmp) / f"{name}.json"
                path.write_text(body, encoding="utf-8")
                result = run(CLAIM, str(path))
                self.assertEqual(result.returncode, 0, f"{name}\n{result.stdout}{result.stderr}")

    def test_native_id_without_review_date_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tone.json"
            path.write_text(
                '{"tonal_note": "High tone on àárọ̀ marks respect", "author_id": "native_1"}\n',
                encoding="utf-8",
            )
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("claim.tone_without_source", result.stdout)

    def test_media_id_without_span_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tone.json"
            path.write_text(
                '{"tonal_note": "High tone on àárọ̀ marks respect", "media_id": "media-42"}\n',
                encoding="utf-8",
            )
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)

    def test_runtime_import_lesson_is_not_a_build_failure(self) -> None:
        body = (
            '{"provenance": "from your media", "media_id": "media-42", '
            '"tonal_note": "High tone on àárọ̀ marks respect"}\n'
        )
        generated = (
            '{"provenance": "AI-generated, unreviewed", '
            '"grammar": ["High tone on the question marks surprise"]}\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            media = Path(tmp) / "runtime.json"
            media.write_text(body, encoding="utf-8")
            ai = Path(tmp) / "generated.json"
            ai.write_text(generated, encoding="utf-8")
            from_media = run(CLAIM, str(media))
            from_ai = run(CLAIM, str(ai))
        self.assertEqual(from_media.returncode, 0, from_media.stdout + from_media.stderr)
        self.assertEqual(from_ai.returncode, 0, from_ai.stdout + from_ai.stderr)

    def test_lesson_without_any_source_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lesson.json"
            path.write_text('{"grammar": ["Yoruba marks tense with a preverbal particle."]}\n', encoding="utf-8")
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("claim.lesson_without_source", result.stdout)
        self.assertIn("Yoruba marks tense with a preverbal particle.", result.stdout)

    def test_claim_scan_roots_are_bundled_curriculum_only(self) -> None:
        sys.path.insert(0, str(ROOT / "scripts" / "ci"))
        import placeholder_lint as gate

        names = {path.name for path in gate.curriculum_roots()}
        self.assertIn("curriculum_bundle", names)
        self.assertIn("data", names)
        self.assertNotIn("lib", names)
        self.assertNotIn("node-backend", names)

    def test_tone_with_lexicon_source_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tone.json"
            path.write_text(
                '{"tonal_note": "High tone on àárọ̀ marks respect", "lexicon_source": "yoruba-lexicon"}\n',
                encoding="utf-8",
            )
            result = run(CLAIM, str(path))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_allowlist_without_owner_does_not_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tone.json"
            line = '{"tonal_note": "High tone marks the question"}'
            path.write_text(line + "\n", encoding="utf-8")
            shown = path.resolve().as_posix()
            header = PATTERNS.read_text(encoding="utf-8").split("allowlist:", 1)[0] + "allowlist:\n"
            no_owner = Path(tmp) / "no-owner.yaml"
            owned = Path(tmp) / "owned.yaml"
            entry = (
                f"  - path: {shown}\n    rule: claim.tone_without_source\n"
                + f'    span: "{line}"\n'
            )
            no_owner.write_text(header + entry + '    reason: "Quoted from a cited note"\n', encoding="utf-8")
            owned.write_text(
                header + entry + '    reason: "Quoted from a cited note"\n    owner: linguist\n',
                encoding="utf-8",
            )
            bad = run(CLAIM, str(path), patterns=no_owner)
            ok = run(CLAIM, str(path), patterns=owned)
        self.assertEqual(bad.returncode, 1, bad.stdout + bad.stderr)
        self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)


if __name__ == "__main__":
    unittest.main()
