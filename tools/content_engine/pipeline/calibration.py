"""Calibrate §3.4 routing thresholds on the linguist-reviewed pilot set (P4-066)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any

CARD_ID = "P4-066"

# Planning targets from CURRICULUM §6 (verified in pilot, not asserted).
DEFAULT_MAX_BETA_ERROR_RATE = 0.03


@dataclass(frozen=True)
class RoutingThresholds:
    auto_beta: float
    review: float


DEFAULT_THRESHOLDS = RoutingThresholds(auto_beta=0.90, review=0.70)


class CalibrationError(Exception):
    """Calibration validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _finite_score(value: Any) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise CalibrationError("PILOT_SCORE_INVALID", "pilot item score must be a number")
    number = float(value)
    if number != number or number in (float("inf"), float("-inf")):
        raise CalibrationError("PILOT_SCORE_INVALID", "pilot item score must be finite")
    return number


def _normalize_tags(tags: Sequence[str] | None) -> tuple[str, ...]:
    if tags is None:
        return ()
    if not isinstance(tags, Sequence) or isinstance(tags, (str, bytes)):
        raise CalibrationError("PILOT_TAGS_INVALID", "high_risk_tags must be a sequence of strings")
    out: list[str] = []
    for tag in tags:
        if not isinstance(tag, str) or not tag.strip():
            raise CalibrationError("PILOT_TAGS_INVALID", "high_risk_tags must be non-empty strings")
        out.append(tag.strip())
    return tuple(out)


def would_auto_publish_beta(
    *,
    score: float,
    linters_pass: bool,
    high_risk_tags: Sequence[str] | None = None,
    thresholds: RoutingThresholds | None = None,
) -> bool:
    """True when an item would receive the Beta auto-publish route at given thresholds."""
    limits = thresholds or DEFAULT_THRESHOLDS
    if limits.review > limits.auto_beta:
        raise CalibrationError("THRESHOLDS_INVALID", "review threshold cannot exceed auto_beta")
    tags = _normalize_tags(high_risk_tags)
    if tags:
        return False
    if not linters_pass:
        return False
    return score >= limits.auto_beta


def _pilot_row(item: Mapping[str, Any]) -> tuple[str, float, bool, tuple[str, ...], bool]:
    if not isinstance(item, Mapping):
        raise CalibrationError("PILOT_ITEM_INVALID", "pilot item must be a mapping")
    language = item.get("language")
    if not isinstance(language, str) or not language.strip():
        raise CalibrationError("PILOT_LANGUAGE_INVALID", "pilot item language must be a non-empty string")
    score = _finite_score(item.get("score"))
    linters_pass = item.get("linters_pass")
    if not isinstance(linters_pass, bool):
        raise CalibrationError("PILOT_LINTERS_INVALID", "pilot item linters_pass must be a boolean")
    tags = _normalize_tags(item.get("high_risk_tags"))
    accepted = item.get("linguist_accepted")
    if not isinstance(accepted, bool):
        raise CalibrationError("PILOT_LABEL_INVALID", "pilot item linguist_accepted must be a boolean")
    return language.strip(), score, linters_pass, tags, accepted


def report_auto_publish_errors(
    pilot: Sequence[Mapping[str, Any]],
    *,
    thresholds: RoutingThresholds | None = None,
) -> dict[str, Any]:
    """Measured Beta auto-publish error rate per language with sample sizes."""
    limits = thresholds or DEFAULT_THRESHOLDS
    by_lang: dict[str, dict[str, int]] = {}

    for raw in pilot:
        language, score, linters_pass, tags, accepted = _pilot_row(raw)
        bucket = by_lang.setdefault(
            language,
            {"pilot_sample_size": 0, "auto_publish_count": 0, "error_count": 0},
        )
        bucket["pilot_sample_size"] += 1
        if would_auto_publish_beta(
            score=score,
            linters_pass=linters_pass,
            high_risk_tags=tags,
            thresholds=limits,
        ):
            bucket["auto_publish_count"] += 1
            if not accepted:
                bucket["error_count"] += 1

    per_language: dict[str, Any] = {}
    for language, counts in sorted(by_lang.items()):
        auto_n = counts["auto_publish_count"]
        errors = counts["error_count"]
        rate: float | None = None
        if auto_n > 0:
            rate = errors / auto_n
        per_language[language] = {
            "pilot_sample_size": counts["pilot_sample_size"],
            "auto_publish_count": auto_n,
            "error_count": errors,
            "error_rate": rate,
        }

    return {
        "card_id": CARD_ID,
        "thresholds": {"auto_beta": limits.auto_beta, "review": limits.review},
        "per_language": per_language,
    }


def tune_thresholds(
    pilot: Sequence[Mapping[str, Any]],
    *,
    max_beta_error_rate: float = DEFAULT_MAX_BETA_ERROR_RATE,
    review: float | None = None,
) -> dict[str, Any]:
    """Pick the highest auto_beta that keeps measured auto-publish errors at or below the target."""
    if not isinstance(max_beta_error_rate, (int, float)) or isinstance(max_beta_error_rate, bool):
        raise CalibrationError("TARGET_INVALID", "max_beta_error_rate must be a number")
    target = float(max_beta_error_rate)
    if target < 0.0 or target > 1.0:
        raise CalibrationError("TARGET_INVALID", "max_beta_error_rate must be between 0 and 1")

    review_floor = review if review is not None else DEFAULT_THRESHOLDS.review
    if not isinstance(review_floor, (int, float)) or isinstance(review_floor, bool):
        raise CalibrationError("THRESHOLDS_INVALID", "review must be a number")
    review_val = float(review_floor)

    chosen = RoutingThresholds(auto_beta=DEFAULT_THRESHOLDS.auto_beta, review=review_val)
    chosen_report = report_auto_publish_errors(pilot, thresholds=chosen)

    for step in range(1, 31):
        candidate_beta = round(DEFAULT_THRESHOLDS.auto_beta + step * 0.01, 2)
        if candidate_beta > 0.99:
            break
        if candidate_beta <= review_val:
            continue
        candidate = RoutingThresholds(auto_beta=candidate_beta, review=review_val)
        report = report_auto_publish_errors(pilot, thresholds=candidate)
        if _report_within_target(report, target):
            chosen = candidate
            chosen_report = report

    return {
        "card_id": CARD_ID,
        "recommended_thresholds": {
            "auto_beta": chosen.auto_beta,
            "review": chosen.review,
        },
        "max_beta_error_rate": target,
        "pilot_report": chosen_report,
    }


def _report_within_target(report: Mapping[str, Any], target: float) -> bool:
    per_lang = report.get("per_language")
    if not isinstance(per_lang, Mapping):
        return False
    for entry in per_lang.values():
        if not isinstance(entry, Mapping):
            return False
        auto_n = entry.get("auto_publish_count", 0)
        if not isinstance(auto_n, int) or auto_n <= 0:
            continue
        rate = entry.get("error_rate")
        if rate is None:
            continue
        if float(rate) > target:
            return False
    return True


class CalibrationVersionStore:
    """In-memory version history for threshold changes and pilot reports."""

    def __init__(self) -> None:
        self._versions: list[dict[str, Any]] = []

    @property
    def versions(self) -> tuple[dict[str, Any], ...]:
        return tuple(self._versions)

    def save_threshold_change(
        self,
        *,
        old_thresholds: RoutingThresholds,
        new_thresholds: RoutingThresholds,
        pilot_report: Mapping[str, Any],
    ) -> dict[str, Any]:
        if not isinstance(pilot_report, Mapping):
            raise CalibrationError("REPORT_INVALID", "pilot_report must be a mapping")
        version = len(self._versions) + 1
        record: dict[str, Any] = {
            "card_id": CARD_ID,
            "version": version,
            "old_thresholds": {
                "auto_beta": old_thresholds.auto_beta,
                "review": old_thresholds.review,
            },
            "new_thresholds": {
                "auto_beta": new_thresholds.auto_beta,
                "review": new_thresholds.review,
            },
            "pilot_report": dict(pilot_report),
        }
        self._versions.append(record)
        return record
