"""Spec tests for generation guard (P4-056). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.generation_guard import (  # noqa: E402
    CARD_ID,
    GenerationGuardError,
    MAX_REGENERATION_ATTEMPTS,
    allowed_form_set,
    first_out_of_lexicon_token,
    may_regenerate,
    next_regeneration_count,
    run_generation_guard,
)


def _lexeme(form: str) -> dict[str, Any]:
    return {"form": form}


def _citation() -> dict[str, str]:
    return {"source_id": "fixture-source", "locator": "p.1"}


def test_P4_056_AC1_out_of_lexicon_names_token() -> None:
    allowed = allowed_form_set([_lexeme("fixture-a")])
    offender = first_out_of_lexicon_token("fixture-a fixture-b", allowed)
    assert offender == "fixture-b"


def test_P4_056_AC1_rejects_item_with_out_of_lexicon() -> None:
    item = {
        "claims": [
            {
                "section": "dialogue_line",
                "text": "fixture-a fixture-unknown",
            },
        ],
    }
    result = run_generation_guard(
        item,
        [_lexeme("fixture-a")],
        regeneration_count=0,
    )
    assert result["status"] == "rejected"
    assert result["code"] == "OUT_OF_LEXICON"
    assert "fixture-unknown" in result["message"]


def test_P4_056_AC2_claim_uncited_culture() -> None:
    item = {
        "claims": [
            {
                "section": "culture_note",
                "text": "fixture culture fact",
            },
        ],
    }
    result = run_generation_guard(item, [_lexeme("fixture-a")])
    assert result["code"] == "CLAIM_UNCITED"


def test_P4_056_AC2_claim_uncited_grammar() -> None:
    item = {
        "claims": [
            {
                "section": "grammar_note",
                "text": "fixture grammar fact",
            },
        ],
    }
    result = run_generation_guard(item, [_lexeme("fixture-a")])
    assert result["code"] == "CLAIM_UNCITED"


def test_P4_056_happy_path_accepted() -> None:
    item = {
        "claims": [
            {
                "section": "dialogue_line",
                "text": "fixture-a",
            },
            {
                "section": "culture_note",
                "text": "fixture culture fact",
                "citation": _citation(),
            },
        ],
    }
    result = run_generation_guard(item, [_lexeme("fixture-a")], regeneration_count=1)
    assert result["status"] == "accepted"
    assert result["card_id"] == CARD_ID
    assert result["regeneration_count"] == 1


def test_P4_056_AC3_rejection_increments_regeneration_count() -> None:
    item = {
        "claims": [
            {"section": "grammar_note", "text": "uncited"},
        ],
    }
    first = run_generation_guard(item, [_lexeme("fixture-a")], regeneration_count=0)
    assert first["regeneration_count"] == 1
    assert first["may_regenerate"] is True
    second = run_generation_guard(item, [_lexeme("fixture-a")], regeneration_count=1)
    assert second["regeneration_count"] == 2
    assert second["may_regenerate"] is False


def test_P4_056_regeneration_cap_is_two() -> None:
    assert MAX_REGENERATION_ATTEMPTS == 2
    assert may_regenerate(0) is True
    assert may_regenerate(1) is True
    assert may_regenerate(2) is False


def test_P4_056_next_regeneration_count_rejects_negative() -> None:
    with pytest.raises(GenerationGuardError) as exc_info:
        next_regeneration_count(-1)
    assert exc_info.value.code == "REGENERATION_INVALID"


def test_P4_056_stage_contract_with_generate_shape() -> None:
    """Integration: guard accepts dialogue plus cited culture from P4-055 claim shape."""
    item = {
        "claims": [
            {
                "section": "dialogue_line",
                "text": "fixture-form",
            },
            {
                "section": "explanation",
                "text": "fixture claim text",
                "citation": _citation(),
            },
        ],
    }
    result = run_generation_guard(item, [_lexeme("fixture-form")])
    assert result["status"] == "accepted"
