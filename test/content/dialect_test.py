"""P5-039 dialect standards and per-item dialect tags."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.dialect_check import (  # noqa: E402
    CODE_DIALECT_TAG_MISSING,
    CODE_DIALECT_UNSOURCED,
    DialectCheckError,
    assert_language_kit_declares_standard,
    assert_yo_ig_kit_standards,
    validate_item_dialect,
)


def _sample_item(**overrides: object) -> dict:
    body: dict = {
        "id": "yo.item.tone.aar",
        "version": 1,
        "type": "multiple_choice",
        "stimulus": {"refs": ["yo.lex.ọkọ.vehicle"], "text": "àárọ̀"},
        "answer_spec": {
            "correct": "àárọ̀",
            "accepted_variants": ["aaro"],
            "diacritic_matching": "tone_lenient",
        },
        "distractors": [{"text": "ọkọ̀", "rationale": "Not morning."}],
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


def test_yo_ig_kits_declare_standard() -> None:
    standards = assert_yo_ig_kit_standards()
    assert "Yoruba" in standards["yo"] or "yoruba" in standards["yo"].lower()
    assert "Igbo" in standards["ig"] or "igbo" in standards["ig"].lower()
    assert assert_language_kit_declares_standard("yo")
    assert assert_language_kit_declares_standard("ig")


def test_yo_item_requires_dialect_tag() -> None:
    item = _sample_item()
    with pytest.raises(DialectCheckError) as exc:
        validate_item_dialect(item)
    assert exc.value.code == CODE_DIALECT_TAG_MISSING

    item["dialect_tag"] = "standard"
    validate_item_dialect(item)


def test_sw_item_skips_dialect_tag() -> None:
    item = _sample_item(id="sw.item.greet.hello")
    validate_item_dialect(item)


def test_unsourced_regional_variant_blocks_publish() -> None:
    item = _sample_item(
        dialect_tag="yo-lagos",
        dialect_variants=[
            {
                "text": "Ẹ káàárọ̀",
                "dialect_tag": "yo-lagos",
                "source_id": "missing-source",
            }
        ],
    )
    validate_item_dialect(item, publish=False)
    with pytest.raises(DialectCheckError) as exc:
        validate_item_dialect(item, publish=True)
    assert exc.value.code == CODE_DIALECT_UNSOURCED


def test_sourced_regional_variant_passes_publish() -> None:
    item = _sample_item(
        dialect_tag="standard",
        dialect_variants=[
            {
                "text": "Ẹ káàárọ̀",
                "dialect_tag": "yo-lagos",
                "source_id": "lexicon:yo:aaro",
            }
        ],
    )
    validate_item_dialect(item, publish=True)


def test_policy_regional_tag_without_variant_row_ok_at_store() -> None:
    item = _sample_item(dialect_tag="yo-lagos")
    validate_item_dialect(item, publish=False)
