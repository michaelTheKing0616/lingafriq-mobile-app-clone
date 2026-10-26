"""Spec tests for confidence routing (P4-064). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.generation_guard import MAX_REGENERATION_ATTEMPTS  # noqa: E402
from tools.content_engine.pipeline.routing import (  # noqa: E402
    CARD_ID,
    RoutingError,
    route_scored_item,
    run_routing_stage,
)


def _full_features(high: float = 0.95) -> dict[str, float]:
    return {
        "lexicon_coverage": high,
        "tone_agreement": high,
        "cross_model_naturalness": high,
        "backtranslation_similarity": high,
        "linter_results": 1.0,
        "citation_entailment": high,
    }


def test_P4_064_AC1_publish_beta_when_score_linters_and_no_high_risk() -> None:
    result = route_scored_item(score=0.92, linters_pass=True, high_risk_tags=[])
    assert result["card_id"] == CARD_ID
    assert result["route"] == "publish_beta"
    assert result["publish_label"] == "Beta"
    assert result["can_publish"] is True


def test_P4_064_AC2_mid_score_routes_linguist() -> None:
    result = route_scored_item(score=0.80, linters_pass=True)
    assert result["route"] == "linguist"
    assert result["queue"] == "linguist"
    assert result["can_publish"] is False


def test_P4_064_AC2_high_risk_tag_routes_linguist_even_with_high_score() -> None:
    result = route_scored_item(
        score=0.95,
        linters_pass=True,
        high_risk_tags=["idiom"],
    )
    assert result["route"] == "linguist"
    assert result["high_risk_tags"] == ["idiom"]


def test_P4_064_AC3_low_score_regenerates_then_parks() -> None:
    first = route_scored_item(score=0.55, linters_pass=True, regeneration_count=0)
    assert first["route"] == "regenerate"
    assert first["regeneration_count"] == 1

    second = route_scored_item(score=0.55, linters_pass=True, regeneration_count=1)
    assert second["route"] == "regenerate"
    assert second["regeneration_count"] == 2

    third = route_scored_item(score=0.55, linters_pass=True, regeneration_count=2)
    assert third["route"] == "park"
    assert third["queue"] == "human_park"
    assert third["may_regenerate"] is False


def test_P4_064_AC3_hard_linter_failure_uses_regeneration_cap() -> None:
    at_cap = route_scored_item(
        score=0.99,
        linters_pass=False,
        hard_linter_failure=True,
        regeneration_count=MAX_REGENERATION_ATTEMPTS,
    )
    assert at_cap["route"] == "park"


def test_P4_064_run_routing_stage_integration() -> None:
    item: dict[str, Any] = {
        "source_tier": "licensed_dictionary_or_pd",
        "features": _full_features(),
    }
    lint_ok = {"status": "ok", "can_publish": True}
    routed = run_routing_stage(item, lint_stage=lint_ok)
    assert routed["route"] == "publish_beta"
    assert routed["score"] >= 0.9


def test_P4_064_typed_error_on_negative_regeneration() -> None:
    with pytest.raises(RoutingError) as exc:
        route_scored_item(score=0.8, linters_pass=True, regeneration_count=-1)
    assert exc.value.code == "REGENERATION_INVALID"


def test_P4_064_incomplete_score_raises() -> None:
    with pytest.raises(RoutingError) as exc:
        run_routing_stage({"features": {"lexicon_coverage": 0.9}})
    assert exc.value.code == "SCORE_INCOMPLETE"
