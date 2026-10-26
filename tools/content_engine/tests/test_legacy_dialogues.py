"""Spec tests for legacy dialogue regeneration (P4-085)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Mapping

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.dialogues import (  # noqa: E402
    MAX_GENERATION_ATTEMPTS,
    build_can_do_target,
    build_unit_lint_bundle,
    generation_enabled,
    run_dialogue_regeneration,
    unit_lint_status,
    vocab_turn_script,
)
from tools.content_engine.linters.duplicates import lint_duplicates as lint_dup  # noqa: E402

_LINT_KIT: dict[str, Any] = {
    "duplicate_config": {"dialogue_similarity": 0.85, "repeat_cap": 1},
}


def _lesson(
    lesson_id: str,
    objective: str,
    script: list[dict[str, str]],
    vocab: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    return {
        "id": lesson_id,
        "objective": objective,
        "vocab": vocab
        or [
            {"word": "Mo ń kọ́ èdè Yorùbá", "meaning": "I am learning Yoruba"},
            {"word": "Orúkọ mi ni", "meaning": "My name is…"},
            {"word": "Ó dára", "meaning": "It is good"},
        ],
        "dialogue": {"script": script},
    }


def _curriculum(lessons: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "languages": {
            "yoruba": {
                "A1": [
                    {
                        "unit": 1,
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


def test_P4_085_build_can_do_target() -> None:
    assert build_can_do_target("A1", "Introduce yourself simply.") == (
        "A1.SPEAK: Introduce yourself simply."
    )


def test_P4_085_AC1_regenerated_dialogue_passes_duplicate_lint(tmp_path: Path) -> None:
    repeated = [
        {"speaker": "A", "text": "same line"},
        {"speaker": "B", "text": "same line"},
        {"speaker": "A", "text": "same line"},
    ]
    path = _write_curriculum(
        tmp_path,
        _curriculum([_lesson("Yoruba-A1-u1-l1", "Introduce yourself simply.", repeated)]),
    )
    def generator(
        _can_do: str,
        lesson: Mapping[str, Any],
        _kit: Mapping[str, Any],
    ) -> list[dict[str, Any]]:
        return vocab_turn_script(lesson)

    result = run_dialogue_regeneration(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        generator=generator,
        lint_kit_by_lang={"yo": _LINT_KIT},
    )
    assert result.stats.regenerated == 1
    data = json.loads(path.read_text(encoding="utf-8"))
    lesson = data["languages"]["yoruba"]["A1"][0]["lessons"][0]
    bundle = build_unit_lint_bundle(
        "yoruba-A1-u1",
        [("Yoruba-A1-u1-l1", lesson)],
    )
    assert unit_lint_status(bundle, _LINT_KIT) == "pass"
    assert lint_dup(bundle, _LINT_KIT).rule_id == "DUPLICATES"


def test_P4_085_AC2_parks_after_two_failed_attempts(tmp_path: Path) -> None:
    bad = [{"speaker": "A", "text": "dup"}, {"speaker": "B", "text": "dup"}]
    path = _write_curriculum(
        tmp_path,
        _curriculum([_lesson("Yoruba-A1-u1-l1", "Greet by time of day.", bad)]),
    )

    def always_bad(
        _can_do: str,
        _lesson: Mapping[str, Any],
        _kit: Mapping[str, Any],
    ) -> list[dict[str, Any]]:
        return [{"speaker": "A", "text": "dup"}, {"speaker": "B", "text": "dup"}]

    result = run_dialogue_regeneration(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        generator=always_bad,
        lint_kit_by_lang={"yo": _LINT_KIT},
    )
    assert result.stats.parked == 1
    assert len(result.park_records) == 1
    assert result.park_records[0]["attempts"] == MAX_GENERATION_ATTEMPTS
    assert result.park_records[0]["publish"] is False
    assert result.park_path.is_file()
    parked_line = result.park_path.read_text(encoding="utf-8").strip().splitlines()[0]
    persisted = json.loads(parked_line)
    assert persisted["lesson_id"] == "Yoruba-A1-u1-l1"


def test_P4_085_dry_run_lists_changes_without_writing(tmp_path: Path) -> None:
    bad = [{"speaker": "A", "text": "x"}, {"speaker": "B", "text": "x"}]
    path = _write_curriculum(
        tmp_path,
        _curriculum([_lesson("Yoruba-A1-u1-l1", "Courtesy phrases.", bad)]),
    )
    before = path.read_text(encoding="utf-8")
    result = run_dialogue_regeneration(
        tmp_path,
        dry_run=True,
        curriculum_path=path,
        lint_kit_by_lang={"yo": _LINT_KIT},
    )
    assert result.changes[0].action == "would_regenerate"
    assert path.read_text(encoding="utf-8") == before


def test_P4_085_idempotent_second_run_is_clean(tmp_path: Path) -> None:
    bad = [{"speaker": "A", "text": "line"}, {"speaker": "B", "text": "line"}]
    path = _write_curriculum(
        tmp_path,
        _curriculum([_lesson("Yoruba-A1-u1-l1", "Name close family.", bad)]),
    )

    def generator(
        _can_do: str,
        lesson: Mapping[str, Any],
        _kit: Mapping[str, Any],
    ) -> list[dict[str, Any]]:
        return vocab_turn_script(lesson)

    first = run_dialogue_regeneration(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        generator=generator,
        lint_kit_by_lang={"yo": _LINT_KIT},
    )
    assert first.stats.regenerated == 1
    second = run_dialogue_regeneration(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        generator=generator,
        lint_kit_by_lang={"yo": _LINT_KIT},
    )
    assert second.stats.regenerated == 0
    assert second.changed is False


def test_P4_085_write_without_generator_requires_gemini_flag(tmp_path: Path) -> None:
    path = _write_curriculum(
        tmp_path,
        _curriculum(
            [
                _lesson(
                    "Yoruba-A1-u1-l1",
                    "Slow, respectful speech.",
                    [{"speaker": "A", "text": "a"}, {"speaker": "B", "text": "a"}],
                )
            ]
        ),
    )
    monkeypatch = pytest.MonkeyPatch()
    monkeypatch.delenv("AI_GEMINI_ENABLED", raising=False)
    assert not generation_enabled()
    with pytest.raises(RuntimeError, match="P4-055"):
        run_dialogue_regeneration(tmp_path, dry_run=False, curriculum_path=path)
    monkeypatch.undo()
