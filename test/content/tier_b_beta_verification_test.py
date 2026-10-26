"""P5-050 Tier B Beta error gate for zu, xh, ha, pcm (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tier_b_beta_verification import (  # noqa: E402
    CARD_ID,
    TIER_B_BETA_ERROR_CEILING,
    TIER_B_LANGUAGE_IDS,
    TierBBetaVerificationError,
    append_verification_ledger_row,
    verify_tier_b_beta_gate,
)


def _beta_review(language_id: str, has_error: bool) -> dict:
    return {
        "language_id": language_id,
        "stratum": "beta",
        "has_error": has_error,
    }


def _all_tier_b_passing_reviews(errors_per_lang: int = 0) -> list[dict]:
    reviews: list[dict] = []
    for lang in TIER_B_LANGUAGE_IDS:
        reviews.extend([_beta_review(lang, False)] * (100 - errors_per_lang))
        reviews.extend([_beta_review(lang, True)] * errors_per_lang)
    return reviews


def test_each_language_measured_pilot_passes_at_ceiling() -> None:
    reviews = _all_tier_b_passing_reviews(errors_per_lang=5)
    out = verify_tier_b_beta_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_pilot"
    assert out["gate_passed"] is True
    assert out["failure_code"] is None
    assert len(out["languages"]) == 4
    for row in out["languages"]:
        assert row["error_rate"] == 0.05
        assert row["beta_error_ceiling"] == TIER_B_BETA_ERROR_CEILING
        assert row["gate_passed"] is True


def test_gate_fails_when_one_language_exceeds_ceiling() -> None:
    reviews = _all_tier_b_passing_reviews(errors_per_lang=5)
    reviews.append(_beta_review("zu", True))
    out = verify_tier_b_beta_gate(reviews, as_of=date(2026, 10, 26))
    zu = next(r for r in out["languages"] if r["language_id"] == "zu")
    assert zu["gate_passed"] is False
    assert out["gate_passed"] is False
    assert out["failure_code"] == "TIER_B_BETA_ERROR_EXCEEDED"
    assert out["failed_language_ids"] == ["zu"]


def test_missing_language_sample_raises() -> None:
    reviews = [_beta_review("zu", False)] * 10
    with pytest.raises(TierBBetaVerificationError) as exc:
        verify_tier_b_beta_gate(reviews)
    assert exc.value.code == "NO_BETA_SAMPLE"


def test_ledger_rows_record_measurement_per_language() -> None:
    reviews = _all_tier_b_passing_reviews(errors_per_lang=0)
    result = verify_tier_b_beta_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    rows = append_verification_ledger_row(store, result)
    assert len(rows) == 4
    assert len(store["tier_b_beta_verifications"]) == 4
    assert all(r["measurement_status"] == "measured_pilot" for r in rows)
