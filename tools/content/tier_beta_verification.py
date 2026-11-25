"""Tier A Swahili Beta blind-sample error gate (P5-049, CURRICULUM §6)."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.blind_sampler import aggregate_blind_error_rate

CARD_ID = "P5-049"
TIER_A_LANGUAGE_ID = "sw"
BETA_STRATUM = "beta"
TIER_A_BETA_ERROR_CEILING = 0.03
GATE_ID = "G5"


class TierBetaVerificationError(Exception):
    """Tier Beta verification cannot run. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def verify_tier_a_swahili_beta_gate(
    blind_reviews: Sequence[Mapping[str, Any]],
    *,
    as_of: date | None = None,
) -> dict[str, Any]:
    """
    Given Swahili Beta blind judgments, return a measured pilot error rate and
    whether it meets the Tier A Beta ceiling (≤3%).
    """
    aggregated = aggregate_blind_error_rate(blind_reviews)
    group: Mapping[str, Any] | None = None
    for row in aggregated.get("groups", []):
        if not isinstance(row, Mapping):
            continue
        if row.get("language_id") == TIER_A_LANGUAGE_ID and row.get("stratum") == BETA_STRATUM:
            group = row
            break

    if group is None:
        raise TierBetaVerificationError(
            "NO_BETA_SAMPLE",
            f"no blind Beta reviews for language {TIER_A_LANGUAGE_ID}",
        )

    sample_size = int(group.get("sample_size") or 0)
    if sample_size <= 0:
        raise TierBetaVerificationError(
            "NO_BETA_SAMPLE",
            f"no blind Beta reviews for language {TIER_A_LANGUAGE_ID}",
        )

    error_count = int(group.get("error_count") or 0)
    error_rate = group.get("error_rate")
    if not isinstance(error_rate, (int, float)) or isinstance(error_rate, bool):
        raise TierBetaVerificationError("RATE_INVALID", "error_rate must be a number")

    rate = float(error_rate)
    passed = rate <= TIER_A_BETA_ERROR_CEILING
    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "language_id": TIER_A_LANGUAGE_ID,
        "stratum": BETA_STRATUM,
        "tier": "A",
        "measurement_status": "measured_pilot",
        "measured_on": measured_on.isoformat(),
        "sample_size": sample_size,
        "error_count": error_count,
        "error_rate": rate,
        "beta_error_ceiling": TIER_A_BETA_ERROR_CEILING,
        "gate_passed": passed,
        "failure_code": None if passed else "TIER_A_BETA_ERROR_EXCEEDED",
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    """Persist one measured gate row under store['tier_beta_verifications']."""
    if result.get("card_id") != CARD_ID:
        raise TierBetaVerificationError("RESULT_INVALID", "result.card_id must be P5-049")
    rows = store.setdefault("tier_beta_verifications", [])
    if not isinstance(rows, list):
        raise TierBetaVerificationError("STORE_INVALID", "tier_beta_verifications must be a list")
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
