"""P5-052 Tier A Swahili Expert-reviewed error gate (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.tier_a_expert_verification import (  # noqa: E402
    CARD_ID,
    TIER_A_EXPERT_ERROR_CEILING,
    TierAExpertVerificationError,
    append_verification_ledger_row,
    verify_tier_a_swahili_expert_gate,
)


def _sw_expert_review(has_error: bool) -> dict:
    return {
        "language_id": "sw",
        "stratum": "expert_reviewed",
        "has_error": has_error,
    }


def test_measured_pilot_passes_at_or_below_ceiling() -> None:
    reviews = [_sw_expert_review(False)] * 99 + [_sw_expert_review(True)] * 1
    out = verify_tier_a_swahili_expert_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_pilot"
    assert out["error_rate"] == 0.01
    assert out["expert_error_ceiling"] == TIER_A_EXPERT_ERROR_CEILING
    assert out["gate_passed"] is True
    assert out["failure_code"] is None


def test_measured_pilot_fails_above_ceiling() -> None:
    reviews = [_sw_expert_review(False)] * 98 + [_sw_expert_review(True)] * 2
    out = verify_tier_a_swahili_expert_gate(reviews, as_of=date(2026, 10, 26))
    assert out["error_rate"] == 0.02
    assert out["gate_passed"] is False
    assert out["failure_code"] == "TIER_A_EXPERT_ERROR_EXCEEDED"


def test_no_sw_expert_sample_raises() -> None:
    reviews = [{"language_id": "yo", "stratum": "expert_reviewed", "has_error": False}]
    with pytest.raises(TierAExpertVerificationError) as exc:
        verify_tier_a_swahili_expert_gate(reviews)
    assert exc.value.code == "NO_EXPERT_SAMPLE"


def test_ledger_row_records_measurement_not_assertion() -> None:
    reviews = [_sw_expert_review(False)] * 50
    result = verify_tier_a_swahili_expert_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    row = append_verification_ledger_row(store, result)
    assert row["measurement_status"] == "measured_pilot"
    assert row["error_rate"] == 0.0
    assert len(store["tier_a_expert_verifications"]) == 1
