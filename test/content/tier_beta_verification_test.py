"""P5-049 Tier A Swahili Beta error gate (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tier_beta_verification import (  # noqa: E402
    CARD_ID,
    TIER_A_BETA_ERROR_CEILING,
    TierBetaVerificationError,
    append_verification_ledger_row,
    verify_tier_a_swahili_beta_gate,
)


def _sw_beta_review(has_error: bool) -> dict:
    return {
        "language_id": "sw",
        "stratum": "beta",
        "has_error": has_error,
    }


def test_measured_pilot_passes_at_or_below_ceiling() -> None:
    reviews = [_sw_beta_review(False)] * 97 + [_sw_beta_review(True)] * 3
    out = verify_tier_a_swahili_beta_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_pilot"
    assert out["error_rate"] == 0.03
    assert out["beta_error_ceiling"] == TIER_A_BETA_ERROR_CEILING
    assert out["gate_passed"] is True
    assert out["failure_code"] is None


def test_measured_pilot_fails_above_ceiling() -> None:
    reviews = [_sw_beta_review(False)] * 96 + [_sw_beta_review(True)] * 4
    out = verify_tier_a_swahili_beta_gate(reviews, as_of=date(2026, 10, 26))
    assert out["error_rate"] == 0.04
    assert out["gate_passed"] is False
    assert out["failure_code"] == "TIER_A_BETA_ERROR_EXCEEDED"


def test_no_sw_beta_sample_raises() -> None:
    reviews = [{"language_id": "yo", "stratum": "beta", "has_error": False}]
    with pytest.raises(TierBetaVerificationError) as exc:
        verify_tier_a_swahili_beta_gate(reviews)
    assert exc.value.code == "NO_BETA_SAMPLE"


def test_ledger_row_records_measurement_not_assertion() -> None:
    reviews = [_sw_beta_review(False)] * 50
    result = verify_tier_a_swahili_beta_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    row = append_verification_ledger_row(store, result)
    assert row["measurement_status"] == "measured_pilot"
    assert row["error_rate"] == 0.0
    assert len(store["tier_beta_verifications"]) == 1
