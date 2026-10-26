"""Spec tests for legacy unit structure rebuild and signed packs (P4-086)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.structure import (  # noqa: E402
    StructureError,
    audio_content_hash,
    build_unit_pack,
    collect_lesson_targets,
    derive_cefr_map,
    run_structure_rebuild,
    sign_content_pack,
    validate_cefr_coverage,
)

_FIXTURE_KEY = "fixture-pack-signing-key"
_BUILT_AT = "2026-10-26T00:00:00.000Z"


def _lesson(lesson_id: str, objective: str, word: str = "Ẹ káàbọ̀") -> dict:
    return {
        "id": lesson_id,
        "objective": objective,
        "vocab": [{"word": word, "meaning": "Welcome"}],
    }


def _curriculum(lessons: list[dict], unit_num: int = 1) -> dict:
    return {
        "languages": {
            "yoruba": {
                "A1": [
                    {
                        "unit": unit_num,
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


def test_P4_086_AC1_unit_lists_can_do_targets(tmp_path: Path) -> None:
    payload = _curriculum([_lesson("Yoruba-A1-u1-l1", "Introduce yourself simply.")])
    path = _write_curriculum(tmp_path, payload)
    run_structure_rebuild(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    unit = json.loads(path.read_text(encoding="utf-8"))["languages"]["yoruba"]["A1"][0]
    assert unit["can_do_targets"] == ["A1.SPEAK: Introduce yourself simply."]


def test_P4_086_AC1_cefr_target_missing_raises() -> None:
    lessons = [("Yoruba-A1-u1-l1", _lesson("Yoruba-A1-u1-l1", "Greet someone."))]
    with pytest.raises(StructureError) as exc:
        validate_cefr_coverage(
            "yoruba-A1-u1",
            collect_lesson_targets("A1", lessons),
            ["A1.SPEAK: Missing objective."],
        )
    assert exc.value.code == "CEFR_TARGET_MISSING"


def test_P4_086_AC2_one_signed_pack_per_unit(tmp_path: Path) -> None:
    payload = _curriculum(
        [
            _lesson("Yoruba-A1-u1-l1", "Introduce yourself simply."),
            _lesson("Yoruba-A1-u1-l2", "Ask someone's name."),
        ]
    )
    path = _write_curriculum(tmp_path, payload)
    result = run_structure_rebuild(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    pack_path = result.packs_dir / "yoruba-A1-u1.json"
    assert pack_path.is_file()
    pack = json.loads(pack_path.read_text(encoding="utf-8"))
    assert pack["unit_key"] == "yoruba-A1-u1"
    assert len(pack["manifest"]["items"]) == 2
    assert pack["signature"]
    assert all(item["payload"]["text"] for item in pack["items"])


def test_P4_086_dry_run_lists_changes_without_writing(tmp_path: Path) -> None:
    payload = _curriculum([_lesson("Yoruba-A1-u1-l1", "Introduce yourself simply.")])
    path = _write_curriculum(tmp_path, payload)
    before = path.read_text(encoding="utf-8")
    result = run_structure_rebuild(tmp_path, dry_run=True, curriculum_path=path)
    assert result.changes[0].action == "would_rebuild"
    assert path.read_text(encoding="utf-8") == before


def test_P4_086_idempotent_rerun(tmp_path: Path) -> None:
    payload = _curriculum([_lesson("Yoruba-A1-u1-l1", "Introduce yourself simply.")])
    path = _write_curriculum(tmp_path, payload)
    first = run_structure_rebuild(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    after_first = path.read_text(encoding="utf-8")
    pack_path = first.packs_dir / "yoruba-A1-u1.json"
    first_pack = pack_path.read_text(encoding="utf-8")

    second = run_structure_rebuild(
        tmp_path,
        dry_run=False,
        curriculum_path=path,
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    assert second.stats.units_rebuilt == 0
    assert second.stats.packs_written == 0
    assert path.read_text(encoding="utf-8") == after_first
    assert pack_path.read_text(encoding="utf-8") == first_pack


def test_P4_086_derive_cefr_map_from_objectives() -> None:
    curriculum = _curriculum(
        [
            _lesson("Yoruba-A1-u1-l1", "Introduce yourself simply."),
            _lesson("Yoruba-A1-u1-l2", "Introduce yourself simply."),
        ]
    )
    mapping = derive_cefr_map(curriculum)
    assert mapping["yoruba-A1-u1"] == ("A1.SPEAK: Introduce yourself simply.",)


def test_P4_086_audio_content_hash_is_stable() -> None:
    assert audio_content_hash("Ẹ káàbọ̀") == audio_content_hash("Ẹ káàbọ̀")
    assert audio_content_hash("Ẹ káàbọ̀") != audio_content_hash("ekaabo")


def test_P4_086_sign_content_pack_matches_hmac_shape() -> None:
    items = [
        {
            "item_id": "yo.lesson.1",
            "quality_label": "Beta",
            "payload": {"id": "yo.lesson.1", "text": "Mo ń kọ́ èdè Yorùbá"},
        }
    ]
    pack = sign_content_pack(
        "1.0.0",
        items,
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    assert len(pack["signature"]) == 64

    pack2 = build_unit_pack(
        "yoruba-A1-u1",
        "yo",
        "A1",
        [("Yoruba-A1-u1-l1", _lesson("Yoruba-A1-u1-l1", "Introduce yourself simply."))],
        signing_key=_FIXTURE_KEY,
        built_at=_BUILT_AT,
    )
    assert pack2["manifest"]["version"] == "1.0.0"
