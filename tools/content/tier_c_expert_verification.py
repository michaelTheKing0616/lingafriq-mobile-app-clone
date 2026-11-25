"""Tier C Expert-reviewed blind-sample error gate for yo and ig (P5-054, CURRICULUM §6)."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.blind_sampler import aggregate_blind_error_rate

CARD_ID = "P5-054"
TIER_C_LANGUAGE_IDS = ("yo", "ig")
EXPERT_STRATUM = "expert_reviewed"
TIER_C_EXPERT_ERROR_CEILING = 0.015
GATE_ID = "G6"


class TierCExpertVerificationError(Exception):
    """Tier C Expert verification cannot run. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _group_for_language(
    aggregated: Mapping[str, Any], language_id: str
) -> Mapping[str, Any] | None:
    for row in aggregated.get("groups", []):
        if not isinstance(row, Mapping):
            continue
        if row.get("language_id") == language_id and row.get("stratum") == EXPERT_STRATUM:
            return row
    return None


def _measure_language_expert(
    blind_reviews: Sequence[Mapping[str, Any]],
    language_id: str,
    *,
    as_of: date,
) -> dict[str, Any]:
    aggregated = aggregate_blind_error_rate(blind_reviews)
    group = _group_for_language(aggregated, language_id)

    if group is None:
        raise TierCExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {language_id}",
        )

    sample_size = int(group.get("sample_size") or 0)
    if sample_size <= 0:
        raise TierCExpertVerificationError(
            "NO_EXPERT_SAMPLE",
            f"no blind Expert-reviewed reviews for language {language_id}",
        )

    error_count = int(group.get("error_count") or 0)
    error_rate = group.get("error_rate")
    if not isinstance(error_rate, (int, float)) or isinstance(error_rate, bool):
        raise TierCExpertVerificationError("RATE_INVALID", "error_rate must be a number")

    rate = float(error_rate)
    passed = rate <= TIER_C_EXPERT_ERROR_CEILING

    return {
        "language_id": language_id,
        "stratum": EXPERT_STRATUM,
        "tier": "C",
        "measurement_status": "measured_pilot",
        "measured_on": as_of.isoformat(),
        "sample_size": sample_size,
        "error_count": error_count,
        "error_rate": rate,
        "expert_error_ceiling": TIER_C_EXPERT_ERROR_CEILING,
        "gate_passed": passed,
        "failure_code": None if passed else "TIER_C_EXPERT_ERROR_EXCEEDED",
    }


def verify_tier_c_expert_gate(
    blind_reviews: Sequence[Mapping[str, Any]],
    *,
    as_of: date | None = None,
) -> dict[str, Any]:
    """
    Given Tier C language Expert-reviewed blind judgments, return measured pilot error rates
    per language and whether each meets the Tier C Expert ceiling (≤1.5%).
    """
    measured_on = as_of or datetime.now(UTC).date()
    languages: list[dict[str, Any]] = []
    for language_id in TIER_C_LANGUAGE_IDS:
        languages.append(
            _measure_language_expert(blind_reviews, language_id, as_of=measured_on)
        )

    gate_passed = all(row["gate_passed"] for row in languages)
    failed = [row["language_id"] for row in languages if not row["gate_passed"]]

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "stratum": EXPERT_STRATUM,
        "tier": "C",
        "measurement_status": "measured_pilot",
        "measured_on": measured_on.isoformat(),
        "languages": languages,
        "gate_passed": gate_passed,
        "failure_code": None if gate_passed else "TIER_C_EXPERT_ERROR_EXCEEDED",
        "failed_language_ids": failed,
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> list[dict[str, Any]]:
    """Persist one measured gate row per language under store['tier_c_expert_verifications']."""
    if result.get("card_id") != CARD_ID:
        raise TierCExpertVerificationError("RESULT_INVALID", "result.card_id must be P5-054")
    rows = store.setdefault("tier_c_expert_verifications", [])
    if not isinstance(rows, list):
        raise TierCExpertVerificationError("STORE_INVALID", "tier_c_expert_verifications must be a list")

    appended: list[dict[str, Any]] = []
    for lang in result.get("languages", []):
        if not isinstance(lang, Mapping):
            continue
        row = {
            "card_id": CARD_ID,
            "gate": GATE_ID,
            "language_id": lang.get("language_id"),
            "stratum": lang.get("stratum"),
            "measured_on": lang.get("measured_on"),
            "sample_size": lang.get("sample_size"),
            "error_rate": lang.get("error_rate"),
            "gate_passed": lang.get("gate_passed"),
            "measurement_status": lang.get("measurement_status"),
        }
        rows.append(row)
        appended.append(row)
    return appended
