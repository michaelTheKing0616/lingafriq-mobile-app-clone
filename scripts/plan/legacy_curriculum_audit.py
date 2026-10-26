#!/usr/bin/env python3
"""Reproduce legacy curriculum audit counts from ELEVATION §6.1 (P5-001)."""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
import unittest
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DEFAULT_GAME_CONTENT = ROOT / "assets/data/game_content.json"

# Prior audit snapshot (ELEVATION §6.1:L1108–L1128); deltas are reported, not hidden.
EXPECTED_LESSONS_PER_LANGUAGE = 126
EXPECTED_CURRICULUM_UNIQUE_VOCAB: dict[str, int] = {
    "afrikaans": 91,
    "amharic": 87,
    "hausa": 107,
    "igbo": 102,
    "lingala": 85,
    "nigerian_pidgin": 102,
    "pidgin": 102,
    "shona": 86,
    "somali": 88,
    "swahili": 109,
    "twi": 86,
    "wolof": 101,
    "xhosa": 104,
    "yoruba": 111,
    "zulu": 104,
}
EXPECTED_GAME_WORDS_TOTAL = 1409
EXPECTED_GAME_WORDS_PER_LANGUAGE: dict[str, int] = {
    "afrikaans": 92,
    "amharic": 88,
    "hausa": 113,
    "igbo": 108,
    "lingala": 85,
    "pidgin": 105,
    "shona": 86,
    "somali": 89,
    "swahili": 114,
    "twi": 87,
    "wolof": 107,
    "xhosa": 108,
    "yoruba": 118,
    "zulu": 109,
}
QUARANTINE_RATIONALE = (
    "Legacy data is quarantined (not a build target): real A1 needs about 500–800 items; "
    "B2 about 4,000 word families; C2 beyond 10,000."
)


@dataclass(frozen=True)
class MismatchReport:
    field: str
    language: str | None
    expected: int
    actual: int

    def line(self) -> str:
        lang = self.language or "(all)"
        return f"MismatchReport\t{self.field}\t{lang}\texpected={self.expected}\tactual={self.actual}"


@dataclass(frozen=True)
class CurriculumLanguageStats:
    language: str
    lessons: int
    unique_vocab: int


@dataclass(frozen=True)
class AuditResult:
    curriculum_path: Path
    game_content_path: Path
    curriculum: tuple[CurriculumLanguageStats, ...]
    game_total: int
    game_per_language: dict[str, int]
    mismatches: tuple[MismatchReport, ...]


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def count_curriculum_languages(curriculum: Mapping[str, Any]) -> dict[str, CurriculumLanguageStats]:
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return {}

    out: dict[str, CurriculumLanguageStats] = {}
    for lang_key, levels in languages.items():
        if not isinstance(lang_key, str) or not isinstance(levels, Mapping):
            continue
        lesson_count = 0
        vocab: set[str] = set()
        for _cefr, units in levels.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                if not isinstance(unit, Mapping):
                    continue
                for lesson in unit.get("lessons", []):
                    if not isinstance(lesson, Mapping):
                        continue
                    lesson_count += 1
                    raw_vocab = lesson.get("vocab")
                    if not isinstance(raw_vocab, list):
                        continue
                    for entry in raw_vocab:
                        if not isinstance(entry, Mapping):
                            continue
                        word = entry.get("word")
                        if isinstance(word, str) and word.strip():
                            vocab.add(nfc(word).casefold())
        out[lang_key] = CurriculumLanguageStats(
            language=lang_key,
            lessons=lesson_count,
            unique_vocab=len(vocab),
        )
    return out


def count_game_words(game_content: Mapping[str, Any]) -> tuple[int, dict[str, int]]:
    words = game_content.get("words")
    if not isinstance(words, list):
        return 0, {}
    per: dict[str, int] = {}
    for row in words:
        if not isinstance(row, Mapping):
            continue
        lang = row.get("language")
        if not isinstance(lang, str) or not lang.strip():
            continue
        per[lang] = per.get(lang, 0) + 1
    return len(words), per


def compare_curriculum(stats: Mapping[str, CurriculumLanguageStats]) -> list[MismatchReport]:
    mismatches: list[MismatchReport] = []
    for lang, expected_vocab in sorted(EXPECTED_CURRICULUM_UNIQUE_VOCAB.items()):
        row = stats.get(lang)
        if row is None:
            mismatches.append(
                MismatchReport("curriculum_language_missing", lang, expected_vocab, 0)
            )
            continue
        if row.lessons != EXPECTED_LESSONS_PER_LANGUAGE:
            mismatches.append(
                MismatchReport(
                    "lessons_per_language",
                    lang,
                    EXPECTED_LESSONS_PER_LANGUAGE,
                    row.lessons,
                )
            )
        if row.unique_vocab != expected_vocab:
            mismatches.append(
                MismatchReport(
                    "unique_vocab_per_language",
                    lang,
                    expected_vocab,
                    row.unique_vocab,
                )
            )
    for lang in sorted(stats):
        if lang not in EXPECTED_CURRICULUM_UNIQUE_VOCAB:
            mismatches.append(
                MismatchReport(
                    "curriculum_language_unexpected",
                    lang,
                    0,
                    stats[lang].lessons,
                )
            )
    return mismatches


def compare_game(total: int, per_language: Mapping[str, int]) -> list[MismatchReport]:
    mismatches: list[MismatchReport] = []
    if total != EXPECTED_GAME_WORDS_TOTAL:
        mismatches.append(
            MismatchReport("game_words_total", None, EXPECTED_GAME_WORDS_TOTAL, total)
        )
    for lang, expected in sorted(EXPECTED_GAME_WORDS_PER_LANGUAGE.items()):
        actual = per_language.get(lang, 0)
        if actual != expected:
            mismatches.append(
                MismatchReport("game_words_per_language", lang, expected, actual)
            )
    for lang, actual in sorted(per_language.items()):
        if lang not in EXPECTED_GAME_WORDS_PER_LANGUAGE:
            mismatches.append(
                MismatchReport("game_language_unexpected", lang, 0, actual)
            )
    return mismatches


def run_audit(curriculum_path: Path, game_content_path: Path) -> AuditResult:
    curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
    game_content = json.loads(game_content_path.read_text(encoding="utf-8"))
    stats = count_curriculum_languages(curriculum)
    game_total, game_per = count_game_words(game_content)
    mismatches = tuple(
        compare_curriculum(stats) + compare_game(game_total, game_per)
    )
    return AuditResult(
        curriculum_path=curriculum_path,
        game_content_path=game_content_path,
        curriculum=tuple(stats[k] for k in sorted(stats)),
        game_total=game_total,
        game_per_language=dict(sorted(game_per.items())),
        mismatches=mismatches,
    )


def format_report(result: AuditResult) -> str:
    lines: list[str] = []
    lines.append(f"curriculum\t{result.curriculum_path}")
    for row in result.curriculum:
        lines.append(
            f"lessons\t{row.language}\t{row.lessons}\tunique_vocab\t{row.unique_vocab}"
        )
    lines.append(f"game_content\t{result.game_content_path}")
    lines.append(f"game_words_total\t{result.game_total}")
    for lang, count in result.game_per_language.items():
        lines.append(f"game_words\t{lang}\t{count}")
    lines.append(f"quarantine_rationale\t{QUARANTINE_RATIONALE}")
    if result.mismatches:
        lines.append("status\tMismatchReport")
        for m in result.mismatches:
            lines.append(m.line())
    else:
        lines.append("status\tok")
    return "\n".join(lines) + "\n"


def resolve_default_curriculum(root: Path) -> Path:
    from tools.content_engine.legacy.salvage import resolve_curriculum_path

    return resolve_curriculum_path(root)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Legacy curriculum sizing audit (P5-001).")
    parser.add_argument(
        "--curriculum",
        type=Path,
        help="Authentic curriculum JSON (default: quarantined canonical).",
    )
    parser.add_argument(
        "--game-content",
        type=Path,
        default=DEFAULT_GAME_CONTENT,
        help="Legacy game_content.json path.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=ROOT,
        help="Mobile repo root for default curriculum resolution.",
    )
    args = parser.parse_args(argv)

    curriculum_path = args.curriculum or resolve_default_curriculum(args.root)
    if not curriculum_path.is_file():
        print(f"curriculum not found: {curriculum_path}", file=sys.stderr)
        return 1
    if not args.game_content.is_file():
        print(f"game_content not found: {args.game_content}", file=sys.stderr)
        return 1

    result = run_audit(curriculum_path, args.game_content)
    print(format_report(result), end="")
    return 1 if result.mismatches else 0


class LegacyCurriculumAuditTests(unittest.TestCase):
    def _mini_curriculum(self) -> dict[str, Any]:
        lesson = {
            "id": "yo-a1-u1-l1",
            "vocab": [{"word": "Ó dára", "meaning": "fine"}],
            "lessons": [],
        }
        unit = {"unit": 1, "lessons": [lesson]}
        return {
            "languages": {
                "yoruba": {"A1": [unit]},
                "lingala": {"A1": [unit]},
            }
        }

    def test_count_vocab_casefold(self) -> None:
        data = {
            "languages": {
                "yoruba": {
                    "A1": [
                        {
                            "unit": 1,
                            "lessons": [
                                {
                                    "id": "l1",
                                    "vocab": [
                                        {"word": "A"},
                                        {"word": "a"},
                                    ],
                                }
                            ],
                        }
                    ]
                }
            }
        }
        stats = count_curriculum_languages(data)
        self.assertEqual(stats["yoruba"].unique_vocab, 1)

    def test_mismatch_report_emitted(self) -> None:
        td = Path(tempfile.mkdtemp())
        curriculum = td / "curriculum.json"
        curriculum.write_text(
            json.dumps(self._mini_curriculum()),
            encoding="utf-8",
        )
        game = td / "game.json"
        game.write_text(json.dumps({"words": []}), encoding="utf-8")
        result = run_audit(curriculum, game)
        self.assertTrue(result.mismatches)
        text = format_report(result)
        self.assertIn("MismatchReport", text)
        self.assertIn(QUARANTINE_RATIONALE, text)

    def test_ok_when_reference_matches_fixture(self) -> None:
        td = Path(tempfile.mkdtemp())
        # Build minimal langs that match expected lesson=1 and vocab=1 — still mismatch reference 126.
        # Instead patch compare by using only game check with exact fixture.
        game = td / "game.json"
        words = [{"language": lang} for lang, n in EXPECTED_GAME_WORDS_PER_LANGUAGE.items() for _ in range(n)]
        self.assertEqual(len(words), EXPECTED_GAME_WORDS_TOTAL)
        game.write_text(json.dumps({"words": words}), encoding="utf-8")
        curriculum = td / "curriculum.json"
        langs: dict[str, Any] = {}
        for lang, vocab_n in EXPECTED_CURRICULUM_UNIQUE_VOCAB.items():
            lessons = []
            vocab = [{"word": f"w{i}", "meaning": "m"} for i in range(vocab_n)]
            for i in range(EXPECTED_LESSONS_PER_LANGUAGE):
                lessons.append({"id": f"{lang}-l{i}", "vocab": vocab})
            unit = {"unit": 1, "lessons": lessons}
            langs[lang] = {"A1": [unit]}
        curriculum.write_text(json.dumps({"languages": langs}), encoding="utf-8")
        result = run_audit(curriculum, game)
        self.assertEqual(result.mismatches, ())
        self.assertIn("status\tok", format_report(result))


if __name__ == "__main__":
    if "--run-tests" in sys.argv:
        ok = unittest.main(module=__name__, argv=[sys.argv[0]], exit=False).result.wasSuccessful()
        raise SystemExit(0 if ok else 1)
    raise SystemExit(main())
