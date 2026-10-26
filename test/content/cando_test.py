"""P5-014 CEFR / ACTFL can-do map and linter."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.cando_linter import (  # noqa: E402
    RULE_CD001,
    RULE_CD002,
    build_map_from_curriculum,
    build_unit_entry,
    is_legacy_template_objective,
    lint_map_document,
    lint_objective,
    load_map,
    objective_to_statement_en,
)


def _lesson(objective: str) -> dict:
    return {"id": "fixture-lesson", "objective": objective}


def _curriculum_one_unit(objectives: list[str]) -> dict:
    lessons = [
        {"id": f"Yoruba-A1-u1-l{i}", "objective": obj}
        for i, obj in enumerate(objectives, start=1)
    ]
    return {
        "languages": {
            "yoruba": {
                "A1": [{"unit": 1, "lessons": lessons}],
            }
        }
    }


def test_P5_014_CD001_legacy_template_objective() -> None:
    legacy = "Understand basic phrases in Zulu unit 1"
    assert is_legacy_template_objective(legacy)
    finding = lint_objective(legacy, unit_key="zulu-A1-u1")
    assert finding is not None
    assert finding.rule_id == RULE_CD001


def test_P5_014_AC1_unit_has_two_to_four_candos() -> None:
    entry = build_unit_entry(
        "yo",
        "A1",
        "yoruba-A1-u1",
        [
            ("l1", _lesson("Introduce yourself simply.")),
            ("l2", _lesson("Greet by time of day.")),
            ("l3", _lesson("Courtesy phrases.")),
        ],
        {"A1": {"cefr": "A1", "actfl": "Novice Low", "actfl_descriptor": "x"}},
    )
    assert 2 <= len(entry["can_dos"]) <= 4
    for row in entry["can_dos"]:
        assert row["cefr"] == "A1"
        assert row["actfl"] == "Novice Low"
        assert row["statement_en"].startswith("I can ")


def test_P5_014_AC2_lint_map_rejects_template_in_unit() -> None:
    doc = {
        "cefr_actfl": {
            "A1": {"cefr": "A1", "actfl": "Novice Low", "actfl_descriptor": "x"},
            "A2": {"cefr": "A2", "actfl": "Novice High", "actfl_descriptor": "x"},
            "B1": {"cefr": "B1", "actfl": "Intermediate Low", "actfl_descriptor": "x"},
        },
        "units": {
            "zulu-A1-u1": {
                "unit_key": "zulu-A1-u1",
                "kit_lang": "zu",
                "cefr_band": "A1",
                "can_dos": [
                    {
                        "can_do_id": "zu.cando.zulu_a1_u1.l1",
                        "cefr": "A1",
                        "actfl": "Novice Low",
                        "statement_en": objective_to_statement_en(
                            "Understand basic phrases in Zulu unit 1"
                        ),
                        "skill": "LISTEN",
                        "source_objective": "Understand basic phrases in Zulu unit 1",
                    },
                    {
                        "can_do_id": "zu.cando.zulu_a1_u1.l2",
                        "cefr": "A1",
                        "actfl": "Novice Low",
                        "statement_en": "I can greet someone.",
                        "skill": "SPEAK",
                        "source_objective": "Greet someone.",
                    },
                ],
            }
        },
    }
    findings = lint_map_document(doc)
    assert any(f.rule_id == RULE_CD001 for f in findings)


def test_P5_014_AC3_cefr_actfl_rows_present() -> None:
    doc = load_map()
    for level in ("A1", "A2", "B1"):
        row = doc["cefr_actfl"][level]
        assert "gap" in row or ("cefr" in row and "actfl" in row)


def test_P5_014_committed_map_lints_clean() -> None:
    findings = lint_map_document(load_map())
    assert not findings


def test_P5_014_schema_validates_committed_map() -> None:
    schema = json.loads(
        (_REPO_ROOT / "schemas/v2/cando.schema.json").read_text(encoding="utf-8")
    )
    doc = load_map()
    Draft202012Validator(schema).validate(doc)


def test_P5_014_build_map_from_fixture_curriculum() -> None:
    doc = build_map_from_curriculum(
        _curriculum_one_unit(
            [
                "Introduce yourself simply.",
                "Greet by time of day.",
            ]
        )
    )
    entry = doc["units"]["yoruba-A1-u1"]
    assert len(entry["can_dos"]) == 2
    bad = lint_map_document(
        {
            "cefr_actfl": doc["cefr_actfl"],
            "units": {
                "yoruba-A1-u1": {
                    **entry,
                    "can_dos": entry["can_dos"][:1],
                }
            },
        }
    )
    assert any(f.rule_id == RULE_CD002 for f in bad)
