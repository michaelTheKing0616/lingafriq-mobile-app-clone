"""Spec tests for weighted confidence scoring (P4-063). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.scoring import (  # noqa: E402
    DEFAULT_WEIGHTS,
    ScoringError,
    score_item_features,
    source_tier_score,
)


def _full_features() -> dict[str, float]:
    return {
        "lexicon_coverage": 0.95,
        "tone_agreement": 0.92,
        "cross_model_naturalness": 0.9,
        "backtranslation_similarity": 0.88,
        "linter_results": 1.0,
        "citation_entailment": 0.91,
    }


def test_P4_063_AC2_source_tier_ranking() -> None:
    licensed = source_tier_score("licensed_dictionary_or_pd")
    cc_by = source_tier_score("cc_by_corpus")
    wiki = source_tier_score("wiktionary_only")
    assert licensed > cc_by > wiki


def test_P4_063_AC1_weighted_blend_and_breakdown() -> None:
    result = score_item_features(
        {
            "source_tier": "licensed_dictionary_or_pd",
            "features": _full_features(),
        },
    )
    assert result["complete"] is True
    assert isinstance(result["score"], float)
    assert result["score"] >= 0.9
    assert result["route"] == "auto_beta"
    breakdown = result["breakdown"]
    assert breakdown["lexicon_coverage"]["contribution"] is not None
    assert breakdown["source_tier"]["value"] == 1.0


def test_P4_063_AC3_stores_config_weights_and_breakdown() -> None:
    custom = dict(DEFAULT_WEIGHTS)
    custom["lexicon_coverage"] = 0.5
    result = score_item_features(
        {"source_tier": "cc_by_corpus", "features": _full_features()},
        weights=custom,
    )
    assert result["weights"]["lexicon_coverage"] == 0.5
    assert "tone_agreement" in result["breakdown"]


def test_P4_063_missing_feature_marks_unsure_incomplete() -> None:
    partial = _full_features()
    del partial["citation_entailment"]
    result = score_item_features(
        {"source_tier": "wiktionary_only", "features": partial},
    )
    assert result["complete"] is False
    assert result["score"] is None
    assert result["breakdown"]["citation_entailment"]["status"] == "unsure"


def test_P4_063_unknown_tier_raises() -> None:
    with pytest.raises(ScoringError) as exc_info:
        source_tier_score("fixture-unknown-tier")
    assert exc_info.value.code == "SOURCE_TIER_UNKNOWN"
