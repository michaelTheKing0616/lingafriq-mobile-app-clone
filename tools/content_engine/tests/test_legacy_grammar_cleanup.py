"""Spec tests for legacy grammar generic-sentence cleanup (P4-083)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.grammar_cleanup import (  # noqa: E402
    EXPECTED_LESSON_COUNT,
    grammar_lint_failures,
    is_generic_grammar_sentence,
    run_grammar_cleanup,
)

_GENERIC_A = "Pattern: subject → verb → object (default sentence order)."
_GENERIC_B = "Listen for the verb stem; affixes carry tense and person."
_REAL = "Yoruba uses preverbal particles for tense and aspect."


def _lesson(lesson_id: str, grammar: list[str]) -> dict:
    return {
        "id": lesson_id,
        "vocab": [],
        "grammar": grammar,
    }


def _curriculum(lessons: list[dict]) -> dict:
    return {
        "languages": {
            "yoruba": {
                "A1": [
                    {
                        "lessons": lessons,
                    }
                ]
            }
        }
    }


def _write_curriculum(tmp_path: Path, payload: dict) -> Path:
    rel = "assets/data/lingafriq_authentic_curriculum_a1_c2.json"
    path = tmp_path / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_P4_083_is_generic_grammar_sentence() -> None:
    assert is_generic_grammar_sentence(_GENERIC_A)
    assert is_generic_grammar_sentence(_GENERIC_B)
    assert not is_generic_grammar_sentence(_REAL)


def test_P4_083_AC1_dry_run_lists_removals_without_writing(tmp_path: Path) -> None:
    payload = _curriculum(
        [
            _lesson("Yoruba-A1-u1-l1", [_GENERIC_A, _GENERIC_B]),
            _lesson("Yoruba-A1-u1-l2", [_REAL]),
        ]
    )
    path = _write_curriculum(tmp_path, payload)
    before = path.read_text(encoding="utf-8")
    result = run_grammar_cleanup(tmp_path, dry_run=True, curriculum_path=path)
    assert result.stats.lessons_total == 2
    assert result.stats.lessons_affected == 1
    assert result.stats.sentences_removed == 2
    assert path.read_text(encoding="utf-8") == before


def test_P4_083_AC1_writes_cleaned_grammar(tmp_path: Path) -> None:
    payload = _curriculum([_lesson("Yoruba-A1-u1-l1", [_GENERIC_A, _GENERIC_B, _REAL])])
    path = _write_curriculum(tmp_path, payload)
    run_grammar_cleanup(tmp_path, dry_run=False, curriculum_path=path)
    data = json.loads(path.read_text(encoding="utf-8"))
    grammar = data["languages"]["yoruba"]["A1"][0]["lessons"][0]["grammar"]
    assert grammar == [_REAL]


def test_P4_083_AC2_zero_generic_template_after_cleanup(tmp_path: Path) -> None:
    payload = _curriculum(
        [
            _lesson("Yoruba-A1-u1-l1", [_GENERIC_A, _GENERIC_B]),
            _lesson("Yoruba-A1-u1-l2", [_GENERIC_B, _REAL]),
        ]
    )
    path = _write_curriculum(tmp_path, payload)
    run_grammar_cleanup(tmp_path, dry_run=False, curriculum_path=path)
    data = json.loads(path.read_text(encoding="utf-8"))
    for _lang, lesson in [
        ("yoruba", data["languages"]["yoruba"]["A1"][0]["lessons"][0]),
        ("yoruba", data["languages"]["yoruba"]["A1"][0]["lessons"][1]),
    ]:
        assert grammar_lint_failures(lesson) == []


def test_P4_083_integration_idempotent(tmp_path: Path) -> None:
    payload = _curriculum([_lesson("Yoruba-A1-u1-l1", [_GENERIC_A, _GENERIC_B])])
    path = _write_curriculum(tmp_path, payload)
    first = run_grammar_cleanup(tmp_path, dry_run=False, curriculum_path=path)
    second = run_grammar_cleanup(tmp_path, dry_run=False, curriculum_path=path)
    assert first.stats.sentences_removed == 2
    assert second.stats.sentences_removed == 0
    assert second.stats.lessons_affected == 0


def test_P4_083_expected_lesson_count_constant_matches_spec() -> None:
    assert EXPECTED_LESSON_COUNT == 1546
