"""Spec tests for high-risk tagging and never-AI-only routing (P4-065). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.highrisk import (  # noqa: E402
    CARD_ID,
    TAG_CHILD,
    TAG_CULTURE,
    TAG_GRAMMAR,
    TAG_HONORIFIC,
    TAG_IDIOM,
    TAG_TONE,
    HighRiskError,
    detect_high_risk_tags,
    enforce_never_ai_only_route,
    run_highrisk_routing_stage,
    run_highrisk_stage,
    validate_publish_with_high_risk,
)

_TONE_SURFACE = "\u1eb9\u1e63in"


def _full_features(high: float = 0.95) -> dict[str, float]:
    return {
        "lexicon_coverage": high,
        "tone_agreement": high,
        "cross_model_naturalness": high,
        "backtranslation_similarity": high,
        "linter_results": 1.0,
        "citation_entailment": high,
    }


def test_P4_065_AC1_idiom_content_kind() -> None:
    tags = detect_high_risk_tags({"content_kind": "idiom"})
    assert TAG_IDIOM in tags


def test_P4_065_AC1_unmatched_tone_marked_token() -> None:
    item = {
        "tokens": [
            {
                "generator": _TONE_SURFACE,
                "lexicon": "",
                "matched": False,
            }
        ]
    }
    tags = detect_high_risk_tags(item)
    assert TAG_TONE in tags


def test_P4_065_AC1_grammar_culture_child_and_honorific() -> None:
    item = {
        "claims": [
            {"section": "grammar_note", "text": "fixture grammar"},
            {"section": "culture_note", "text": "fixture culture"},
            {"section": "explanation", "text": "fixture elder form", "topic": "culture"},
        ],
        "honorific_surfaces": ["elder"],
        "audience": "child",
    }
    tags = detect_high_risk_tags(item)
    assert TAG_GRAMMAR in tags
    assert TAG_CULTURE in tags
    assert TAG_HONORIFIC in tags
    assert TAG_CHILD in tags


def test_P4_065_AC2_high_risk_routes_linguist_not_beta() -> None:
    item = {
        "content_kind": "idiom",
        "source_tier": "licensed_dictionary_or_pd",
        "features": _full_features(),
    }
    result = run_highrisk_routing_stage(item, lint_stage={"status": "pass", "can_publish": True})
    assert result["card_id"] != CARD_ID or "high_risk_stage" in result
    assert result["high_risk_stage"]["card_id"] == CARD_ID
    assert TAG_IDIOM in result["high_risk_tags"]
    assert result["route"] == "linguist"
    assert result["can_publish"] is False
    assert result.get("publish_label") is None


def test_P4_065_AC2_beta_forbidden_for_high_risk() -> None:
    with pytest.raises(HighRiskError) as exc:
        validate_publish_with_high_risk(
            high_risk_tags=[TAG_IDIOM],
            publish_label="Beta",
            reviewer_id="rev-1",
        )
    assert exc.value.code == "HIGH_RISK_BETA_FORBIDDEN"


def test_P4_065_AC2_publish_requires_reviewer_id() -> None:
    with pytest.raises(HighRiskError) as exc:
        validate_publish_with_high_risk(
            high_risk_tags=[TAG_CULTURE],
            publish_label="Reviewed",
            reviewer_id=None,
        )
    assert exc.value.code == "HIGH_RISK_REVIEWER_REQUIRED"


def test_P4_065_enforce_never_ai_only_patches_beta_route() -> None:
    patched = enforce_never_ai_only_route(
        {
            "route": "publish_beta",
            "publish_label": "Beta",
            "can_publish": True,
            "high_risk_tags": ["idiom"],
        }
    )
    assert patched["route"] == "linguist"
    assert patched["can_publish"] is False


def test_P4_065_run_highrisk_stage_contract() -> None:
    stage = run_highrisk_stage({"content_kind": "proverb"})
    assert stage["requires_human"] is True
    assert stage["never_ai_only"] is True
    assert "proverb" in stage["high_risk_tags"]


def test_P4_065_typed_error_invalid_item() -> None:
    with pytest.raises(HighRiskError) as exc:
        detect_high_risk_tags({"claims": "not-a-list"})  # type: ignore[arg-type]
    assert exc.value.code == "ITEM_INVALID"
