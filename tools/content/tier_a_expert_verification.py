"""Tier A Swahili Expert-reviewed blind-sample error gate (P5-052, CURRICULUM §6)."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.blind_sampler import aggregate_blind_error_rate

CARD_ID = "P5-052"
TIER_A_LANGUAGE_ID = "sw"
EXPERT_STRATUM = "expert_reviewed"
TIER_A_EXPERT_ERROR_CEILING = 0.01
GATE_ID = "G6"


class TierAExpertVerificationError(Exception):
    """Tier A Expert verification cannot run. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def verify_tier_a_swahili_expert_gate(
    blind_reviews: Sequence[Mapping[str, Any]],
    *,
    as_of: date | None = None,
) -> dict[str, Any]:
    """
    Given Swahili Expert-reviewed blind judgments, return a measured pilot error rate
    and whether it meets the Tier A Expert ceiling (≤1%).
    """
    aggregated = aggregate_blind_error_rate(blind_reviews)
    group: Mapping[str, Any] | None = None
    for row in aggregated.get("groups", []):
        if not isinstance(row, Mapping):
            continue
        if row.get("language_id") == TIER_A_LANGUAGE_ID and row.get("stratum") == EXPERT_STRATUM:
            group = row
            break

    if group is None:
        raise TierAExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {TIER_A_LANGUAGE_ID}",
        )

    sample_size = int(group.get("sample_size") or 0)
    if sample_size <= 0:
        raise TierAExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {TIER_A_LANGUAGE_ID}",
        )

    error_count = int(group.get("error_count") or 0)
    error_rate = group.get("error_rate")
    if not isinstance(error_rate, (int, float)) or isinstance(error_rate, bool):
        raise TierAExpertVerificationError("RATE_INVALID", "error_rate must be a number")

    rate = float(error_rate)
    passed = rate <= TIER_A_EXPERT_ERROR_CEILING
    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "language_id": TIER_A_LANGUAGE_ID,
        "stratum": EXPERT_STRATUM,
        "tier": "A",
        "measurement_status": "measured_pilot",
        "measured_on": measured_on.isoformat(),
        "sample_size": sample_size,
        "error_count": error_count,
        "error_rate": rate,
        "expert_error_ceiling": TIER_A_EXPERT_ERROR_CEILING,
        "gate_passed": passed,
        "failure_code": None if passed else "TIER_A_EXPERT_ERROR_EXCEEDED",
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    """Persist one measured gate row under store['tier_a_expert_verifications']."""
    if result.get("card_id") != CARD_ID:
        raise TierAExpertVerificationError("RESULT_INVALID", "result.card_id must be P5-052")
    rows = store.setdefault("tier_a_expert_verifications", [])
    if not isinstance(rows, list):
        raise TierAExpertVerificationError("STORE_INVALID", "tier_a_expert_verifications must be a list")
    row = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "language_id": result.get("language_id"),
        "stratum": result.get("stratum"),
        "measured_on": result.get("measured_on"),
        "sample_size": result.get("sample_size"),
        "error_rate": result.get("error_rate"),
        "gate_passed": result.get("gate_passed"),
        "measurement_status": result.get("measurement_status"),
    }
    rows.append(row)
    return row
