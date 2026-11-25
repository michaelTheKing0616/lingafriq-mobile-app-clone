"""P5 curriculum item schema (schemas/v2/item.schema.json)."""

from __future__ import annotations

import copy
import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.item_validator import (  # noqa: E402
    SchemaError,
    apply_version_bump,
    assert_publishable,
    bump_item_version,
    load_item_schema,
    validate_item_schema,
)


def _sample_item(**overrides: object) -> dict:
    body: dict = {
        "id": "yo.item.tone.aar",
        "version": 1,
        "type": "multiple_choice",
        "stimulus": {
            "refs": ["yo.lex.ọkọ.vehicle", "audio/yo/9f2c1a4b5e6d7c8a.ogg"],
            "text": "àárọ̀",
        },
        "answer_spec": {
            "correct": "àárọ̀",
            "accepted_variants": ["aaro"],
            "diacritic_matching": "tone_lenient",
        },
        "distractors": [
            {
                "text": "ọkọ̀",
                "rationale": "Vehicle or husband, not morning.",
            }
        ],
        "skill_tags": ["yo.lex.aaro.morning"],
        "irt": {"irt_status": "calibrated", "a": 1.2, "b": -0.4},
        "label": "expert",
        "provenance": {
            "author": "content-studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "Yoruba item bank draft",
                    "licence": "CC BY 4.0",
                    "uri_or_citation": "curriculum/items/yo/tone-aar",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        "claims": [
            {
                "text": "àárọ̀ means morning",
                "source_id": "lexicon:yo:aaro",
                "locator": "sense:1",
            }
        ],
        "confidence": 0.9,
        "risk_tags": ["tone"],
        "audio": [{"kind": "human", "uri": "audio/yo/9f2c1a4b5e6d7c8a.ogg"}],
    }
    body.update(overrides)
    return body


def test_p5_item_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(load_item_schema())


def test_complete_item_passes_publish_gate() -> None:
    assert_publishable(_sample_item())


def test_invalid_label_raises_schema_error() -> None:
    broken = _sample_item(label="expert_reviewed")
    with pytest.raises(SchemaError) as exc:
        validate_item_schema(broken)
    assert exc.value.code == "LABEL_INVALID"


def test_invalid_audio_kind_raises_schema_error() -> None:
    broken = _sample_item(audio=[{"kind": "tts_synthetic", "uri": "audio/x.ogg"}])
    with pytest.raises(SchemaError) as exc:
        validate_item_schema(broken)
    assert exc.value.code in {"AUDIO_KIND_INVALID", "ITEM_INVALID"}


def test_missing_claim_locator_blocks_publish() -> None:
    broken = _sample_item()
    broken["claims"] = [{"text": "x", "source_id": "src:1"}]
    with pytest.raises(SchemaError) as exc:
        assert_publishable(broken)
    assert exc.value.code == "CLAIM_INVALID"


def test_missing_provenance_sources_blocks_publish() -> None:
    broken = _sample_item()
    broken["provenance"] = {
        "author": "a",
        "created_at": "2026-10-21T12:00:00Z",
        "ai_assisted": False,
        "sources": [],
    }
    with pytest.raises(SchemaError) as exc:
        assert_publishable(broken)
    assert exc.value.code == "PROVENANCE_MISSING"


def test_version_bumps_on_content_change() -> None:
    prev = _sample_item(version=3)
    nxt = copy.deepcopy(prev)
    nxt["answer_spec"]["correct"] = "ọkọ̀"
    assert bump_item_version(prev, nxt) == 4


def test_version_bumps_on_audio_change_only() -> None:
    prev = _sample_item(version=2)
    nxt = copy.deepcopy(prev)
    nxt["audio"] = [{"kind": "tts", "uri": "audio/yo/synth.ogg"}]
    assert bump_item_version(prev, nxt) == 3


def test_version_unchanged_when_no_content_or_audio_delta() -> None:
    prev = _sample_item(version=5)
    nxt = copy.deepcopy(prev)
    nxt["version"] = 99
    assert bump_item_version(prev, nxt) == 5


def test_apply_version_bump_writes_version_field() -> None:
    prev = _sample_item(version=1)
    nxt = copy.deepcopy(prev)
    nxt["stimulus"]["text"] = "ọkọ̀"
    out = apply_version_bump(prev, nxt)
    assert out["version"] == 2
