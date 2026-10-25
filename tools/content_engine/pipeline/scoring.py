"""Weighted confidence score for curriculum items (CURRICULUM §3.4).

Weights are config defaults calibrated on the linguist-reviewed pilot set.
No language data.
"""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

FEATURE_KEYS = (
    "lexicon_coverage",
    "tone_agreement",
    "cross_model_naturalness",
    "backtranslation_similarity",
    "linter_results",
    "citation_entailment",
)

SOURCE_TIER_SCORES: dict[str, float] = {
    "licensed_dictionary_or_pd": 1.0,
    "cc_by_corpus": 0.66,
    "wiktionary_only": 0.33,
}

DEFAULT_WEIGHTS: dict[str, float] = {
    "lexicon_coverage": 0.18,
    "tone_agreement": 0.16,
    "cross_model_naturalness": 0.16,
    "backtranslation_similarity": 0.14,
    "linter_results": 0.14,
    "citation_entailment": 0.12,
    "source_tier": 0.10,
}

_ROUTE_AUTO_BETA = 0.90
_ROUTE_REVIEW = 0.70


class ScoringError(Exception):
    """Scoring validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def source_tier_score(tier: str) -> float:
    """Rank source tiers: licensed/PD > CC-BY corpus > Wiktionary-only."""
    if tier not in SOURCE_TIER_SCORES:
        raise ScoringError("SOURCE_TIER_UNKNOWN", f"unknown source tier: {tier}")
    return SOURCE_TIER_SCORES[tier]


def _finite_unit(value: Any) -> float | None:
    if not isinstance(value, (int, float)):
        return None
    if isinstance(value, bool):
        return None
    number = float(value)
    if number != number or number in (float("inf"), float("-inf")):
        return None
    if number < 0.0 or number > 1.0:
        return None
    return number


def score_item_features(
    item: Mapping[str, Any],
    weights: Mapping[str, float] | None = None,
) -> dict[str, Any]:
    """Blend feature scores; missing features are unsure and excluded from the blend."""
    if not isinstance(item, Mapping):
        raise ScoringError("ITEM_INVALID", "item must be a mapping")

    weight_map = dict(DEFAULT_WEIGHTS)
    if weights is not None:
        if not isinstance(weights, Mapping):
            raise ScoringError("WEIGHTS_INVALID", "weights must be a mapping")
        for key, value in weights.items():
            if not isinstance(key, str) or not isinstance(value, (int, float)):
                raise ScoringError("WEIGHTS_INVALID", "weights must be numeric")
            weight_map[key] = float(value)

    features = item.get("features")
    if features is not None and not isinstance(features, Mapping):
        raise ScoringError("FEATURES_INVALID", "features must be a mapping when present")
    feature_map: Mapping[str, Any] = features if isinstance(features, Mapping) else {}

    tier_raw = item.get("source_tier")
    tier_score: float | None = None
    tier_status = "unsure"
    if isinstance(tier_raw, str) and tier_raw.strip():
        tier_score = source_tier_score(tier_raw.strip())
        tier_status = "pass"

    breakdown: dict[str, Any] = {}
    weighted_sum = 0.0
    weight_total = 0.0
    any_unsure = tier_status == "unsure"

    for key in FEATURE_KEYS:
        weight = weight_map.get(key, 0.0)
        raw = feature_map.get(key) if isinstance(feature_map, Mapping) else None
        value = _finite_unit(raw)
        if value is None:
            any_unsure = True
            breakdown[key] = {"status": "unsure", "weight": weight, "value": None, "contribution": None}
            continue
        contribution = value * weight
        breakdown[key] = {
            "status": "pass",
            "weight": weight,
            "value": value,
            "contribution": contribution,
        }
        weighted_sum += contribution
        weight_total += weight

    st_weight = weight_map.get("source_tier", 0.0)
    if tier_score is None:
        breakdown["source_tier"] = {
            "status": "unsure",
            "weight": st_weight,
            "value": None,
            "contribution": None,
        }
    else:
        contribution = tier_score * st_weight
        breakdown["source_tier"] = {
            "status": "pass",
            "weight": st_weight,
            "value": tier_score,
            "contribution": contribution,
        }
        weighted_sum += contribution
        weight_total += st_weight

    score: float | None = None
    route: str | None = None
    if not any_unsure and weight_total > 0.0:
        score = weighted_sum / weight_total
        if score >= _ROUTE_AUTO_BETA:
            route = "auto_beta"
        elif score >= _ROUTE_REVIEW:
            route = "review"
        else:
            route = "reject"

    return {
        "weights": {key: weight_map[key] for key in DEFAULT_WEIGHTS},
        "breakdown": breakdown,
        "score": score,
        "route": route,
        "complete": not any_unsure,
    }
