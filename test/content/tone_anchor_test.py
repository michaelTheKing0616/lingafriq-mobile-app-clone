"""P5-017 tonal Beta lexicon-anchor gate."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tone_anchor_check import (  # noqa: E402
    CARD_ID,
    ToneAnchorError,
    TonePairUnsourced,
    assert_beta_label_tone_anchor,
    assert_tone_pairs_sourced,
    evaluate_tone_beta_gate,
    partition_tier_c_beta_batch,
)

_FIXTURE_LEX = "\u1eb9\u1e63in"
_FIXTURE_GEN_OK = _FIXTURE_LEX


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


def _yo_item(**overrides: object) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": "yo.tone.fixture",
        "language": "yo",
        "label": "beta",
        "tokens": [_token(_FIXTURE_GEN_OK, _FIXTURE_LEX)],
    }
    body.update(overrides)
    return body


def test_P5_017_AC1_three_way_agreement_allows_beta() -> None:
    kit = {"tone_restorer": "none"}
    gate = evaluate_tone_beta_gate(_yo_item(), kit)
    assert gate["card_id"] == CARD_ID
    assert gate["beta_allowed"] is True
    assert gate["route"] == "auto"


def test_P5_017_AC1_mismatch_blocks_beta() -> None:
    kit: dict[str, str] = {}
    item = _yo_item(tokens=[_token("esin", _FIXTURE_LEX)])
    gate = evaluate_tone_beta_gate(item, kit)
    assert gate["beta_allowed"] is False
    assert gate["route"] == "linguist"


def test_P5_017_AC2_unmatched_token_blocks_beta() -> None:
    kit: dict[str, str] = {}
    item = _yo_item(tokens=[_token(_FIXTURE_GEN_OK, _FIXTURE_LEX, matched=False)])
    gate = evaluate_tone_beta_gate(item, kit)
    assert gate["beta_allowed"] is False


def test_P5_017_AC3_unsourced_minimal_pair_raises() -> None:
    item = _yo_item(
        content_kind="tone_teaching",
        tone_teaching={
            "minimal_pairs": [
                {"a": "\u1ecd\u1e63\u1ecd\u0301", "b": "\u1ecd\u1e63\u1ecd\u0300"},
            ],
        },
    )
    with pytest.raises(TonePairUnsourced) as exc:
        assert_tone_pairs_sourced(item)
    assert exc.value.code == "TonePairUnsourced"


def test_P5_017_AC3_sourced_pair_passes() -> None:
    item = _yo_item(
        risk_tags=["tone_teaching"],
        tone_teaching={
            "minimal_pairs": [
                {
                    "a": "\u1ecd\u1e63\u1ecd\u0301",
                    "b": "\u1ecd\u1e63\u1ecd\u0300",
                    "source_id": "wiktionary:yo_oko_vehicle",
                },
            ],
        },
    )
    assert_tone_pairs_sourced(item)


def test_assert_beta_label_raises_when_not_anchored() -> None:
    kit: dict[str, str] = {}
    item = _yo_item(tokens=[_token("esin", _FIXTURE_LEX)])
    with pytest.raises(ToneAnchorError) as exc:
        assert_beta_label_tone_anchor(item, kit)
    assert exc.value.code == "BETA_TONE_NOT_ANCHORED"


def test_P5_017_AC4_partition_non_anchored_under_review() -> None:
    kit = {"tone_restorer": "none"}
    good = _yo_item(id="yo.good")
    bad = _yo_item(id="yo.bad", tokens=[_token("esin", _FIXTURE_LEX)])
    expert = _yo_item(id="yo.expert", label="expert")
    result = partition_tier_c_beta_batch([good, bad, expert], kit)
    assert len(result["live"]) == 2
    assert {row["id"] for row in result["live"]} == {"yo.good", "yo.expert"}
    assert len(result["under_review"]) == 1
    assert result["under_review"][0]["id"] == "yo.bad"
    assert result["under_review"][0]["publish_state"] == "under_review"


def test_non_tonal_language_skips_tone_gate() -> None:
    kit: dict[str, str] = {}
    item = {"id": "sw.fixture", "language": "sw", "label": "beta"}
    gate = evaluate_tone_beta_gate(item, kit)
    assert gate["beta_allowed"] is True
