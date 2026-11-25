"""P5-054 Tier C Expert-reviewed error gate for yo and ig (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tier_c_expert_verification import (  # noqa: E402
    CARD_ID,
    TIER_C_EXPERT_ERROR_CEILING,
    TIER_C_LANGUAGE_IDS,
    TierCExpertVerificationError,
    append_verification_ledger_row,
    verify_tier_c_expert_gate,
)


def _expert_review(language_id: str, has_error: bool) -> dict:
    return {
        "language_id": language_id,
        "stratum": "expert_reviewed",
        "has_error": has_error,
    }


def _all_tier_c_passing_reviews(errors_per_lang: int = 0, sample_size: int = 200) -> list[dict]:
    reviews: list[dict] = []
    for lang in TIER_C_LANGUAGE_IDS:
        good = sample_size - errors_per_lang
        reviews.extend([_expert_review(lang, False)] * good)
        reviews.extend([_expert_review(lang, True)] * errors_per_lang)
    return reviews


def test_each_language_measured_pilot_passes_at_ceiling() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=3, sample_size=200)
    out = verify_tier_c_expert_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_pilot"
    assert out["gate_passed"] is True
    assert out["failure_code"] is None
    assert len(out["languages"]) == 2
    for row in out["languages"]:
        assert row["error_rate"] == 0.015
        assert row["expert_error_ceiling"] == TIER_C_EXPERT_ERROR_CEILING
        assert row["gate_passed"] is True


def test_gate_fails_when_one_language_exceeds_ceiling() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=1, sample_size=100)
    reviews.append(_expert_review("yo", True))
    out = verify_tier_c_expert_gate(reviews, as_of=date(2026, 10, 26))
    yo = next(r for r in out["languages"] if r["language_id"] == "yo")
    assert yo["gate_passed"] is False
    assert out["gate_passed"] is False
    assert out["failure_code"] == "TIER_C_EXPERT_ERROR_EXCEEDED"
    assert out["failed_language_ids"] == ["yo"]


def test_missing_language_sample_raises() -> None:
    reviews = [_expert_review("yo", False)] * 10
    with pytest.raises(TierCExpertVerificationError) as exc:
        verify_tier_c_expert_gate(reviews)
    assert exc.value.code == "NO_EXPERT_SAMPLE"


def test_ledger_rows_record_measurement_per_language() -> None:
    reviews = _all_tier_c_passing_reviews(errors_per_lang=0, sample_size=50)
    result = verify_tier_c_expert_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    rows = append_verification_ledger_row(store, result)
    assert len(rows) == 2
    assert len(store["tier_c_expert_verifications"]) == 2
    assert all(r["measurement_status"] == "measured_pilot" for r in rows)
