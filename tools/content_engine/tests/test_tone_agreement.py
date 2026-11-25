"""Spec tests for tone and diacritic three-way agreement (P4-061). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.tone_agreement import (  # noqa: E402
    CARD_ID,
    ToneAgreementError,
    evaluate_tone_agreement,
    has_tone_or_teaching_mark,
    resolve_restorer,
    tone_agreement_feature,
)

_FIXTURE_LEX = "\u1eb9\u1e63in"
_FIXTURE_GEN_OK = _FIXTURE_LEX
_FIXTURE_GEN_BAD = "esin"


def _token(
    generator: str,
    lexicon: str,
    *,
    matched: bool = True,
    restorer: str | None = None,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "generator": generator,
        "lexicon": lexicon,
        "matched": matched,
    }
    if restorer is not None:
        row["restorer"] = restorer
    return row


def _item(tokens: list[dict[str, Any]]) -> dict[str, Any]:
    return {"id": "fixture-item", "tokens": tokens}


def test_P4_061_AC1_three_way_agreement_passes() -> None:
    kit = {"tone_restorer": "naijaml"}
    result = evaluate_tone_agreement(
        _item([_token(_FIXTURE_GEN_OK, _FIXTURE_LEX, restorer=_FIXTURE_LEX)]),
        kit,
    )
    assert result["card_id"] == CARD_ID
    assert result["can_publish"] is True
    assert result["restorer"] == "naijaml"
    assert result["features"]["tone_agreement"] == 1.0


def test_P4_061_AC1_lexicon_generator_mismatch_routes_linguist() -> None:
    kit = {"tone_restorer": "none"}
    result = evaluate_tone_agreement(
        _item([_token(_FIXTURE_GEN_BAD, _FIXTURE_LEX)]),
        kit,
    )
    assert result["can_publish"] is False
    assert result["route"] == "linguist"
    assert result["token_results"][0]["reason"] == "LEXICON_GENERATOR_MISMATCH"


def test_P4_061_AC2_unmatched_tone_marked_token_routes_linguist() -> None:
    kit: dict[str, str] = {}
    result = evaluate_tone_agreement(
        _item([_token(_FIXTURE_GEN_OK, _FIXTURE_LEX, matched=False)]),
        kit,
    )
    assert result["can_publish"] is False
    assert result["token_results"][0]["status"] == "unmatched"
    assert result["token_results"][0]["reason"] == "UNMATCHED_TONE_MARKED"


def test_P4_061_AC3_no_restorer_uses_two_way_and_reports_none() -> None:
    kit: dict[str, str] = {}
    result = evaluate_tone_agreement(
        _item([_token(_FIXTURE_GEN_OK, _FIXTURE_LEX)]),
        kit,
    )
    assert result["restorer"] == "none"
    assert result["can_publish"] is True
    assert result["features"]["tone_agreement"] == 1.0


def test_restorer_mismatch_routes_linguist() -> None:
    kit = {"tone_restorer": "naijaml"}
    result = evaluate_tone_agreement(
        _item([_token(_FIXTURE_GEN_OK, _FIXTURE_LEX, restorer=_FIXTURE_GEN_BAD)]),
        kit,
    )
    assert result["can_publish"] is False
    assert result["token_results"][0]["reason"] == "RESTORER_MISMATCH"


def test_resolve_restorer_none_string() -> None:
    assert resolve_restorer({"tone_restorer": "none"}) is None
    assert resolve_restorer({}) is None


def test_has_tone_or_teaching_mark_detects_underdot() -> None:
    assert has_tone_or_teaching_mark(_FIXTURE_LEX) is True
    assert has_tone_or_teaching_mark("plain") is False


def test_tone_agreement_feature_reader() -> None:
    assert tone_agreement_feature({"features": {"tone_agreement": 0.5}}) == 0.5
    assert tone_agreement_feature({}) is None


def test_empty_tokens_raises() -> None:
    with pytest.raises(ToneAgreementError) as exc_info:
        evaluate_tone_agreement(_item([]), {})
    assert exc_info.value.code == "ITEM_INVALID"
