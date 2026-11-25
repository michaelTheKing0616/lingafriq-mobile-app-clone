"""Register and honorific unit publish gate (P5-036)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.register_gate import (  # noqa: E402
    CODE_REGISTER_FORMAL_REQUIRED,
    CODE_REGISTER_NOTES_ONLY,
    CODE_REGISTER_UNREVIEWED,
    RegisterGateError,
    RULE_RG002,
    RULE_RG003,
    RULE_RG004,
    lint_all_register_files,
    lint_register_library,
    lint_register_unit,
    main,
    rg_findings,
)


def _valid_unit() -> dict:
    return {
        "id": "yo.register.greetings_elder",
        "title": "Morning greeting to an elder",
        "cefr": "A1",
        "respect_sensitive": True,
        "addressee_context": "elder",
        "required_register": "formal",
        "themes": ["greetings"],
        "register_markers": {
            "formal_contains_any": ["Ẹ kú"],
            "informal_forbidden_in_responses": ["Báwo ni"],
        },
        "label": "expert_reviewed",
        "provenance": {
            "author": "content-studio",
            "created_at": "2026-10-26T22:30:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "FSI Yoruba Basic Course",
                    "licence": "public-domain",
                    "uri_or_citation": "register:fsi-yoruba; CURRICULUM.md#§4",
                    "retrieved_at": "2026-10-26T22:30:00Z",
                }
            ],
        },
        "claims": [
            {
                "kind": "cultural",
                "source_ref": "register:fsi-yoruba",
                "text": "Ẹ kú àárọ̀ greets elders in the morning.",
                "confidence": 0.9,
                "confidence_floor": 0.85,
            }
        ],
        "confidence": 0.9,
        "risk_tags": ["honorific_register"],
        "review": {
            "reviewers": [
                {"role": "linguist", "reviewer_id": "yo-linguist-1", "approved": True}
            ]
        },
        "practice_items": [
            {
                "id": "g1",
                "kind": "choose_register",
                "prompt_en": "Greet an elder in the morning.",
                "options": [
                    {"text": "Ẹ kú àárọ̀", "register": "formal"},
                    {"text": "Báwo ni", "register": "informal"},
                ],
                "correct_index": 0,
            }
        ],
    }


def test_P5_036_shipped_register_libraries_pass_gate() -> None:
    assert lint_all_register_files(root=_REPO_ROOT) == []


def test_valid_unit_passes() -> None:
    assert lint_register_unit(_valid_unit()) == []


def test_notes_only_fails_rg003() -> None:
    broken = dict(_valid_unit())
    broken["practice_items"] = []
    findings = rg_findings(broken)
    assert any(f.code == CODE_REGISTER_NOTES_ONLY and f.rule_id == RULE_RG003 for f in findings)


def test_beta_label_fails_rg002() -> None:
    broken = dict(_valid_unit())
    broken["label"] = "beta"
    findings = rg_findings(broken)
    assert any(f.code == CODE_REGISTER_UNREVIEWED and f.rule_id == RULE_RG002 for f in findings)


def test_informal_correct_choice_fails_rg004() -> None:
    broken = dict(_valid_unit())
    broken["practice_items"] = [
        {
            "id": "g1",
            "kind": "choose_register",
            "prompt_en": "Greet an elder.",
            "options": [
                {"text": "Ẹ kú àárọ̀", "register": "formal"},
                {"text": "Báwo ni", "register": "informal"},
            ],
            "correct_index": 1,
        }
    ]
    findings = rg_findings(broken)
    assert any(f.code == CODE_REGISTER_FORMAL_REQUIRED and f.rule_id == RULE_RG004 for f in findings)


def test_missing_linguist_fails() -> None:
    broken = dict(_valid_unit())
    broken["review"] = {}
    findings = rg_findings(broken)
    assert any(f.code == CODE_REGISTER_UNREVIEWED for f in findings)


def test_lint_library_and_cli(tmp_path: Path) -> None:
    doc = {
        "language": "yo",
        "units": [
            _valid_unit(),
            dict(_valid_unit(), id="yo.register.honorific_address"),
            dict(_valid_unit(), id="yo.register.kinship_respect"),
        ],
    }
    doc["units"][1]["id"] = "yo.register.honorific_address"
    doc["units"][2]["id"] = "yo.register.kinship_respect"
    assert lint_register_library(doc) == []
    lib_path = tmp_path / "yo.json"
    lib_path.write_text(json.dumps(doc), encoding="utf-8")
    assert main([str(lib_path)]) == 0
    bad = dict(doc)
    bad["units"] = [dict(_valid_unit(), label="beta")]
    bad_path = tmp_path / "bad.json"
    bad_path.write_text(json.dumps(bad), encoding="utf-8")
    assert main([str(bad_path)]) == 1


def test_lint_register_unit_invalid() -> None:
    with pytest.raises(RegisterGateError):
        lint_register_unit("not-a-map")  # type: ignore[arg-type]


def test_main_all_clean() -> None:
    assert main([]) == 0
