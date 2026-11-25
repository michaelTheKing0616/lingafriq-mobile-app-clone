"""P5-051 Tier C Beta error gate for yo and ig (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tier_c_beta_verification import (  # noqa: E402
    CARD_ID,
    TIER_C_BETA_ERROR_CEILING,
    TIER_C_LANGUAGE_IDS,
    TierCBetaVerificationError,
    append_verification_ledger_row,
    filter_tier_c_beta_reviews,
    tier_c_counts_as_beta_review,
    verify_tier_c_beta_gate,
)


def _beta_review(
    language_id: str,
    has_error: bool,
    *,
    lexicon_anchored: bool = True,
) -> dict:
    return {
        "language_id": language_id,
        "stratum": "beta",
        "has_error": has_error,
        "lexicon_anchored": lexicon_anchored,
    }


def _all_tier_c_passing_reviews(errors_per_lang: int = 0) -> list[dict]:
    reviews: list[dict] = []
    for lang in TIER_C_LANGUAGE_IDS:
        reviews.extend([_beta_review(lang, False)] * (100 - errors_per_lang))
        reviews.extend([_beta_review(lang, True)] * errors_per_lang)
    return reviews


def test_non_anchored_beta_excluded_from_measurement() -> None:
    anchored_yo = _beta_review("yo", False, lexicon_anchored=True)
    unanchored_err = _beta_review("yo", True, lexicon_anchored=False)
    anchored_ig = _beta_review("ig", False, lexicon_anchored=True)
    filtered, excluded = filter_tier_c_beta_reviews(
        [anchored_yo, unanchored_err, anchored_ig]
    )
    assert excluded == 1
    assert len(filtered) == 2
    assert tier_c_counts_as_beta_review(unanchored_err) is False
    out = verify_tier_c_beta_gate(
        [anchored_yo, unanchored_err, anchored_ig], as_of=date(2026, 10, 26)
    )
    yo = next(r for r in out["languages"] if r["language_id"] == "yo")
    assert yo["error_rate"] == 0.0
    assert yo["gate_passed"] is True
    assert out["excluded_non_anchored_beta_reviews"] == 1


def test_each_language_measured_pilot_passes_at_ceiling() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=5)
    out = verify_tier_c_beta_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_pilot"
    assert out["gate_passed"] is True
    assert out["failure_code"] is None
    assert len(out["languages"]) == 2
    for row in out["languages"]:
        assert row["error_rate"] == 0.05
        assert row["beta_error_ceiling"] == TIER_C_BETA_ERROR_CEILING
        assert row["gate_passed"] is True
        assert row["restorer_standalone_accuracy_reference"] in (0.80, 0.62)


def test_gate_fails_when_one_language_exceeds_ceiling() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=5)
    reviews.append(_beta_review("ig", True))
    out = verify_tier_c_beta_gate(reviews, as_of=date(2026, 10, 26))
    ig = next(r for r in out["languages"] if r["language_id"] == "ig")
    assert ig["gate_passed"] is False
    assert out["gate_passed"] is False
    assert out["failure_code"] == "TIER_C_BETA_ERROR_EXCEEDED"
    assert out["failed_language_ids"] == ["ig"]


def test_missing_language_sample_raises() -> None:
    reviews = [_beta_review("yo", False)] * 10
    with pytest.raises(TierCBetaVerificationError) as exc:
        verify_tier_c_beta_gate(reviews)
    assert exc.value.code == "NO_BETA_SAMPLE"


def test_ledger_rows_record_measurement_per_language() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=0)
    result = verify_tier_c_beta_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    rows = append_verification_ledger_row(store, result)
    assert len(rows) == 2
    assert len(store["tier_c_beta_verifications"]) == 2
    assert all(r["measurement_status"] == "measured_pilot" for r in rows)
