"""IRT item statistics and abnormal-item flags (P5-048, CURRICULUM §5)."""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.psychometrics.calibrate_irt import calibrate  # noqa: E402

CARD_ID = "P5-048"
DEFAULT_MIN_RESPONSES = 30
DISCRIMINATION_FLOOR = 0.35
DIFFICULTY_ABS_MAX = 3.5
FIT_RMS_MAX = 0.45


class IrtStatsError(Exception):
    """IRT stats failure. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class IrtFlagThresholds:
    discrimination_floor: float = DISCRIMINATION_FLOOR
    difficulty_abs_max: float = DIFFICULTY_ABS_MAX
    fit_rms_max: float = FIT_RMS_MAX


DEFAULT_THRESHOLDS = IrtFlagThresholds()


def _normalize_response(row: Mapping[str, Any], index: int) -> dict[str, Any]:
    item_id = row.get("item_id")
    person_id = row.get("person_id")
    correct = row.get("correct")
    if not isinstance(item_id, str) or not item_id.strip():
        raise IrtStatsError("RESPONSE_INVALID", f"responses[{index}].item_id must be a non-empty string")
    if not isinstance(person_id, str) or not person_id.strip():
        raise IrtStatsError("RESPONSE_INVALID", f"responses[{index}].person_id must be a non-empty string")
    if not isinstance(correct, bool):
        raise IrtStatsError("RESPONSE_INVALID", f"responses[{index}].correct must be a boolean")
    return {
        "item_id": item_id.strip(),
        "person_id": person_id.strip(),
        "correct": correct,
    }


def _expert_failure_set(expert_failures: Sequence[Mapping[str, Any]] | None) -> frozenset[str]:
    if not expert_failures:
        return frozenset()
    failed: set[str] = set()
    for index, row in enumerate(expert_failures):
        if not isinstance(row, Mapping):
            raise IrtStatsError("EXPERT_REVIEW_INVALID", f"expert_failures[{index}] must be a mapping")
        item_id = row.get("item_id")
        passed = row.get("passed")
        if not isinstance(item_id, str) or not item_id.strip():
            raise IrtStatsError("EXPERT_REVIEW_INVALID", f"expert_failures[{index}].item_id is required")
        if not isinstance(passed, bool):
            raise IrtStatsError("EXPERT_REVIEW_INVALID", f"expert_failures[{index}].passed must be boolean")
        if not passed:
            failed.add(item_id.strip())
    return frozenset(failed)


def _flag_reasons(
    *,
    calibrated: bool,
    discrimination: float | None,
    difficulty: float | None,
    fit: float | None,
    sample_size: int,
    min_responses: int,
    expert_failed: bool,
    thresholds: IrtFlagThresholds,
) -> list[str]:
    if expert_failed:
        return ["expert_failed"]
    if sample_size < min_responses:
        return []
    if not calibrated:
        return ["no_variance"]
    reasons: list[str] = []
    if discrimination is not None and discrimination < thresholds.discrimination_floor:
        reasons.append("low_discrimination")
    if difficulty is not None and abs(difficulty) > thresholds.difficulty_abs_max:
        reasons.append("extreme_difficulty")
    if fit is not None and fit > thresholds.fit_rms_max:
        reasons.append("poor_model_fit")
    return reasons


def compute_item_irt_row(
    calibrated_row: Mapping[str, Any],
    *,
    min_responses: int,
    expert_failed: bool,
    thresholds: IrtFlagThresholds = DEFAULT_THRESHOLDS,
) -> dict[str, Any]:
    item_id = str(calibrated_row["item_id"])
    sample_size = int(calibrated_row["sample_size"])
    calibrated = calibrated_row.get("calibrated") is True
    discrimination = calibrated_row.get("a")
    difficulty = calibrated_row.get("b")
    fit = calibrated_row.get("fit")
    if discrimination is not None and isinstance(discrimination, (int, float)):
        discrimination = float(discrimination)
    else:
        discrimination = None
    if difficulty is not None and isinstance(difficulty, (int, float)):
        difficulty = float(difficulty)
    else:
        difficulty = None
    if fit is not None and isinstance(fit, (int, float)):
        fit = float(fit)
    else:
        fit = None

    if sample_size < min_responses:
        return {
            "item_id": item_id,
            "response_count": sample_size,
            "status": "InsufficientData",
            "difficulty": None,
            "discrimination": None,
            "fit_rms": None,
            "flagged_for_review": False,
            "flag_reasons": [],
        }

    reasons = _flag_reasons(
        calibrated=calibrated,
        discrimination=discrimination,
        difficulty=difficulty,
        fit=fit,
        sample_size=sample_size,
        min_responses=min_responses,
        expert_failed=expert_failed,
        thresholds=thresholds,
    )
    return {
        "item_id": item_id,
        "response_count": sample_size,
        "status": "ok" if calibrated else "degenerate_responses",
        "difficulty": difficulty,
        "discrimination": discrimination,
        "fit_rms": fit,
        "flagged_for_review": bool(reasons),
        "flag_reasons": reasons,
    }


def compute_irt_item_statistics(
    responses: Sequence[Mapping[str, Any]],
    *,
    min_responses: int = DEFAULT_MIN_RESPONSES,
    expert_failures: Sequence[Mapping[str, Any]] | None = None,
    thresholds: IrtFlagThresholds = DEFAULT_THRESHOLDS,
) -> dict[str, Any]:
    """Estimate 2PL difficulty and discrimination; flag abnormal or expert-failed items."""
    if min_responses < 1:
        raise IrtStatsError("CONFIG_INVALID", "min_responses must be at least 1")
    normalized = [_normalize_response(row, index) for index, row in enumerate(responses)]
    expert_failed_items = _expert_failure_set(expert_failures)

    calibration = calibrate(normalized, min_responses=min_responses)
    items_out: dict[str, Any] = {}
    for row in calibration["items"]:
        item_id = str(row["item_id"])
        items_out[item_id] = compute_item_irt_row(
            row,
            min_responses=min_responses,
            expert_failed=item_id in expert_failed_items,
            thresholds=thresholds,
        )

    if not items_out:
        raise IrtStatsError("InsufficientData", "no item responses supplied")

    return {
        "card_id": CARD_ID,
        "min_responses": min_responses,
        "item_statistics": items_out,
        "item_statistics_count": len(items_out),
        "flagged_count": sum(1 for row in items_out.values() if row["flagged_for_review"]),
    }


def run_irt_stats_job(payload: Mapping[str, Any]) -> dict[str, Any]:
    responses = payload.get("responses")
    if not isinstance(responses, list):
        raise IrtStatsError("PAYLOAD_INVALID", "responses must be a list")
    min_responses = int(payload.get("min_responses", DEFAULT_MIN_RESPONSES))
    expert_failures = payload.get("expert_failures")
    if expert_failures is not None and not isinstance(expert_failures, list):
        raise IrtStatsError("PAYLOAD_INVALID", "expert_failures must be a list when provided")
    return compute_irt_item_statistics(
        responses,
        min_responses=min_responses,
        expert_failures=expert_failures,
    )


def _cli() -> int:
    raw = sys.stdin.read()
    if not raw.strip():
        print("request body is required", file=sys.stderr)
        return 2
    try:
        payload = json.loads(raw)
        data = run_irt_stats_job(payload)
    except IrtStatsError as error:
        print(error.code, file=sys.stderr)
        print(str(error), file=sys.stderr)
        return 2
    except (TypeError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2
    json.dump({"ok": True, "data": data}, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(_cli())
