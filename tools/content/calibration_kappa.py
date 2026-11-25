"""Two-reviewer calibration sets and Cohen κ for confidence adjustment (P5-045, CURRICULUM §5)."""

from __future__ import annotations

import random
from datetime import UTC, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_pipeline.review_agreement import cohens_kappa_binary

CARD_ID = "P5-045"
CALIBRATION_TARGET_ITEMS = 300
CALIBRATION_MIN_ITEMS = 270
CALIBRATION_MAX_ITEMS = 330
CALIBRATION_METHOD = "cohen_kappa_midpoint_shrink_v1"


class CalibrationKappaError(Exception):
    """Calibration failure. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _approved_flag(review: Mapping[str, Any], label: str) -> bool:
    if not isinstance(review, Mapping):
        raise CalibrationKappaError("REVIEW_INVALID", f"{label} must be a mapping")
    approved = review.get("approved")
    if not isinstance(approved, bool):
        raise CalibrationKappaError("REVIEW_INVALID", f"{label}.approved must be boolean")
    return approved


def select_calibration_item_ids(
    item_ids: Sequence[str],
    *,
    rng: random.Random | None = None,
) -> list[str]:
    """Choose about 300 items for independent double linguist review (AC1)."""
    unique = sorted({i.strip() for i in item_ids if isinstance(i, str) and i.strip()})
    if len(unique) < CALIBRATION_MIN_ITEMS:
        raise CalibrationKappaError(
            "CalibrationIncomplete",
            f"need at least {CALIBRATION_MIN_ITEMS} items; got {len(unique)}",
        )
    target = min(CALIBRATION_TARGET_ITEMS, len(unique))
    if len(unique) <= CALIBRATION_MAX_ITEMS:
        return unique
    picker = rng or random.Random()
    return picker.sample(unique, target)


def compute_language_kappa(
    language_id: str,
    paired_reviews: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    """Cohen κ on paired linguist approve/disagree judgments (AC2)."""
    if not isinstance(language_id, str) or not language_id.strip():
        raise CalibrationKappaError("LANGUAGE_INVALID", "language_id is required")
    lang = language_id.strip().lower()
    if len(paired_reviews) < CALIBRATION_MIN_ITEMS:
        raise CalibrationKappaError(
            "CalibrationIncomplete",
            f"need at least {CALIBRATION_MIN_ITEMS} double-reviewed items; got {len(paired_reviews)}",
        )
    if len(paired_reviews) > CALIBRATION_MAX_ITEMS:
        raise CalibrationKappaError(
            "CalibrationIncomplete",
            f"at most {CALIBRATION_MAX_ITEMS} calibration items; got {len(paired_reviews)}",
        )

    ratings_a: list[bool] = []
    ratings_b: list[bool] = []
    for index, row in enumerate(paired_reviews):
        if not isinstance(row, Mapping):
            raise CalibrationKappaError("PAIR_INVALID", f"pair {index} must be a mapping")
        ratings_a.append(_approved_flag(row.get("reviewer_a", {}), "reviewer_a"))
        ratings_b.append(_approved_flag(row.get("reviewer_b", {}), "reviewer_b"))

    kappa = cohens_kappa_binary(ratings_a, ratings_b)
    return {
        "card_id": CARD_ID,
        "language_id": lang,
        "sample_size": len(paired_reviews),
        "target_items": CALIBRATION_TARGET_ITEMS,
        "kappa_overall": kappa,
        "recorded_at": datetime.now(UTC).isoformat(),
    }


def calibrate_confidence_score(
    raw_confidence: float,
    kappa: float | None,
) -> dict[str, Any]:
    """Shrink raw machine confidence toward 0.5 when reviewer agreement is weak (AC3)."""
    if not isinstance(raw_confidence, (int, float)) or isinstance(raw_confidence, bool):
        raise CalibrationKappaError("CONFIDENCE_INVALID", "raw_confidence must be a number")
    raw = float(raw_confidence)
    if raw < 0.0 or raw > 1.0 or raw != raw:
        raise CalibrationKappaError("CONFIDENCE_INVALID", "raw_confidence must be finite in [0, 1]")
    if kappa is None:
        raise CalibrationKappaError("KAPPA_MISSING", "kappa is required to calibrate confidence")
    reliability = max(0.0, min(1.0, float(kappa)))
    calibrated = raw * reliability + 0.5 * (1.0 - reliability)
    return {
        "card_id": CARD_ID,
        "method": CALIBRATION_METHOD,
        "raw_confidence": raw,
        "kappa": float(kappa),
        "calibrated_confidence": calibrated,
    }


def store_language_kappa(
    store: MutableMapping[str, Any],
    stats: Mapping[str, Any],
) -> None:
    """Persist latest κ snapshot under store['by_language'][language_id]."""
    lang = stats.get("language_id")
    if not isinstance(lang, str) or not lang.strip():
        raise CalibrationKappaError("LANGUAGE_INVALID", "language_id required in stats")
    by_lang = store.get("by_language")
    if by_lang is None:
        store["by_language"] = {}
        by_lang = store["by_language"]
    if not isinstance(by_lang, MutableMapping):
        raise CalibrationKappaError("STORE_INVALID", "store.by_language must be a mapping")
    by_lang[lang.strip().lower()] = dict(stats)


def run_language_calibration(
    language_id: str,
    paired_reviews: Sequence[Mapping[str, Any]],
    store: MutableMapping[str, Any],
) -> dict[str, Any]:
    """Compute κ, store per language, return stats (AC1–AC3)."""
    stats = compute_language_kappa(language_id, paired_reviews)
    store_language_kappa(store, stats)
    return stats
