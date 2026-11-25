"""Tier C Beta blind-sample error gate for Yoruba and Igbo (P5-051, CURRICULUM §6)."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.blind_sampler import aggregate_blind_error_rate

CARD_ID = "P5-051"
TIER_C_LANGUAGE_IDS = ("yo", "ig")
BETA_STRATUM = "beta"
TIER_C_BETA_ERROR_CEILING = 0.05
GATE_ID = "G5"
# Curriculum §6: standalone restorer accuracy (informational; Beta counts anchored tokens only).
RESTORER_STANDALONE_ACCURACY: dict[str, float] = {"yo": 0.80, "ig": 0.62}


class TierCBetaVerificationError(Exception):
    """Tier C Beta verification cannot run. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def tier_c_counts_as_beta_review(row: Mapping[str, Any]) -> bool:
    """
    Tier C Beta error rates include only lexicon-anchored Beta items (P5-017 / §6).
    Non-anchored Beta judgments are excluded from measurement.
    """
    if not isinstance(row, Mapping):
        return False
    lang = row.get("language_id")
    stratum = row.get("stratum")
    if not isinstance(lang, str) or not isinstance(stratum, str):
        return False
    if lang.strip().lower() not in TIER_C_LANGUAGE_IDS or stratum != BETA_STRATUM:
        return True
    return row.get("lexicon_anchored") is True


def filter_tier_c_beta_reviews(
    reviews: Sequence[Mapping[str, Any]],
) -> tuple[list[Mapping[str, Any]], int]:
    """Return reviews eligible for Tier C Beta measurement and excluded non-anchored count."""
    eligible: list[Mapping[str, Any]] = []
    excluded_non_anchored = 0
    for row in reviews:
        if not isinstance(row, Mapping):
            raise TierCBetaVerificationError("REVIEW_INVALID", "review row must be a mapping")
        lang = row.get("language_id")
        stratum = row.get("stratum")
        if (
            isinstance(lang, str)
            and lang.strip().lower() in TIER_C_LANGUAGE_IDS
            and stratum == BETA_STRATUM
            and row.get("lexicon_anchored") is not True
        ):
            excluded_non_anchored += 1
            continue
        eligible.append(row)
    return eligible, excluded_non_anchored


def _group_for_language(
    aggregated: Mapping[str, Any], language_id: str
) -> Mapping[str, Any] | None:
    for row in aggregated.get("groups", []):
        if not isinstance(row, Mapping):
            continue
        if row.get("language_id") == language_id and row.get("stratum") == BETA_STRATUM:
            return row
    return None


def _measure_language_beta(
    blind_reviews: Sequence[Mapping[str, Any]],
    language_id: str,
    *,
    as_of: date,
    excluded_non_anchored: int,
) -> dict[str, Any]:
    aggregated = aggregate_blind_error_rate(blind_reviews)
    group = _group_for_language(aggregated, language_id)

    if group is None:
        raise TierCBetaVerificationError(
            "NO_BETA_SAMPLE",
            f"no anchored blind Beta reviews for language {language_id}",
        )

    sample_size = int(group.get("sample_size") or 0)
    if sample_size <= 0:
        raise TierCBetaVerificationError(
            "NO_BETA_SAMPLE",
            f"no anchored blind Beta reviews for language {language_id}",
        )

    error_count = int(group.get("error_count") or 0)
    error_rate = group.get("error_rate")
    if not isinstance(error_rate, (int, float)) or isinstance(error_rate, bool):
        raise TierCBetaVerificationError("RATE_INVALID", "error_rate must be a number")

    rate = float(error_rate)
    passed = rate <= TIER_C_BETA_ERROR_CEILING

    return {
        "language_id": language_id,
        "stratum": BETA_STRATUM,
        "tier": "C",
        "measurement_status": "measured_pilot",
        "measured_on": as_of.isoformat(),
        "sample_size": sample_size,
        "error_count": error_count,
        "error_rate": rate,
        "beta_error_ceiling": TIER_C_BETA_ERROR_CEILING,
        "gate_passed": passed,
        "failure_code": None if passed else "TIER_C_BETA_ERROR_EXCEEDED",
        "excluded_non_anchored_beta_reviews": excluded_non_anchored,
        "restorer_standalone_accuracy_reference": RESTORER_STANDALONE_ACCURACY.get(
            language_id
        ),
    }


def verify_tier_c_beta_gate(
    blind_reviews: Sequence[Mapping[str, Any]],
    *,
    as_of: date | None = None,
) -> dict[str, Any]:
    """
    Given Yoruba and Igbo Beta blind judgments on lexicon-anchored tokens only,
    return measured pilot error rates and whether each meets the Tier C Beta ceiling (≤5%).
    """
    measured_on = as_of or datetime.now(UTC).date()
    filtered, excluded_total = filter_tier_c_beta_reviews(blind_reviews)

    languages: list[dict[str, Any]] = []
    for language_id in TIER_C_LANGUAGE_IDS:
        languages.append(
            _measure_language_beta(
                filtered,
                language_id,
                as_of=measured_on,
                excluded_non_anchored=excluded_total,
            )
        )

    gate_passed = all(row["gate_passed"] for row in languages)
    failed = [row["language_id"] for row in languages if not row["gate_passed"]]

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "stratum": BETA_STRATUM,
        "tier": "C",
        "measurement_status": "measured_pilot",
        "measured_on": measured_on.isoformat(),
        "excluded_non_anchored_beta_reviews": excluded_total,
        "languages": languages,
        "gate_passed": gate_passed,
        "failure_code": None if gate_passed else "TIER_C_BETA_ERROR_EXCEEDED",
        "failed_language_ids": failed,
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> list[dict[str, Any]]:
    """Persist one measured gate row per language under store['tier_c_beta_verifications']."""
    if result.get("card_id") != CARD_ID:
        raise TierCBetaVerificationError("RESULT_INVALID", "result.card_id must be P5-051")
    rows = store.setdefault("tier_c_beta_verifications", [])
    if not isinstance(rows, list):
        raise TierCBetaVerificationError("STORE_INVALID", "tier_c_beta_verifications must be a list")

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
            "excluded_non_anchored_beta_reviews": lang.get(
                "excluded_non_anchored_beta_reviews"
            ),
        }
        rows.append(row)
        appended.append(row)
    return appended
