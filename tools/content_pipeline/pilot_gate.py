"""Pilot cohort timing and readiness promotion runner (P4-125, ELEVATION §6.4)."""

from __future__ import annotations

from collections.abc import Mapping, MutableMapping, Sequence
from copy import deepcopy
from typing import Any

from tools.content_pipeline.readiness import (
    READINESS_LEVELS,
    ReadinessError,
    _NEXT_LEVEL,
    gate_readiness,
    request_promotion,
)

CARD_ID = "P4-125"

PILOT_WINDOW_WEEKS_MIN = 6
PILOT_WINDOW_WEEKS_MAX = 8


class PilotGateError(Exception):
    """Pilot cohort or promotion failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise PilotGateError(code, f"{label} must be a mapping")
    return value


def _positive_int(value: object, code: str, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value < 1:
        raise PilotGateError(code, f"{label} must be a positive integer")
    return value


def pilot_timing_flags(weeks_elapsed: int) -> dict[str, bool]:
    """Report whether the pilot is inside the 6–8 week window or overdue."""
    if not isinstance(weeks_elapsed, int) or isinstance(weeks_elapsed, bool) or weeks_elapsed < 0:
        raise PilotGateError("PILOT_WEEKS_INVALID", "weeks_elapsed must be a non-negative integer")
    return {
        "window_open": weeks_elapsed >= PILOT_WINDOW_WEEKS_MIN,
        "overdue": weeks_elapsed > PILOT_WINDOW_WEEKS_MAX,
        "weeks_elapsed": weeks_elapsed,
        "window_min_weeks": PILOT_WINDOW_WEEKS_MIN,
        "window_max_weeks": PILOT_WINDOW_WEEKS_MAX,
    }


def cohort_ready_for_promotion(cohort: Mapping[str, Any]) -> dict[str, Any]:
    """True when enrolled learners meet declared cohort size and the pilot window has opened."""
    row = _require_mapping(cohort, "COHORT_INVALID", "cohort")
    declared = _positive_int(row.get("declared_size"), "COHORT_INVALID", "declared_size")
    enrolled = row.get("enrolled_count")
    if not isinstance(enrolled, int) or isinstance(enrolled, bool) or enrolled < 0:
        raise PilotGateError("COHORT_INVALID", "enrolled_count must be a non-negative integer")
    weeks = row.get("weeks_elapsed")
    if not isinstance(weeks, int) or isinstance(weeks, bool) or weeks < 0:
        raise PilotGateError("COHORT_INVALID", "weeks_elapsed must be a non-negative integer")
    timing = pilot_timing_flags(weeks)
    size_met = enrolled >= declared
    return {
        "card_id": CARD_ID,
        "declared_size": declared,
        "enrolled_count": enrolled,
        "size_met": size_met,
        **timing,
        "ready": size_met and timing["window_open"],
    }


def _gate_checks_for_level(manifest: Mapping[str, Any], target_level: str) -> list[dict[str, Any]]:
    result = gate_readiness(manifest, target_level)
    if result.passed:
        return [{"gate": target_level, "check": target_level, "passed": True}]
    checks: list[dict[str, Any]] = []
    for missing in result.missing:
        checks.append({"gate": target_level, "check": missing, "passed": False})
    if not checks:
        checks.append({"gate": target_level, "check": result.code or "fail", "passed": False})
    return checks


def gates_through_target(manifest: Mapping[str, Any], target_level: str) -> list[dict[str, Any]]:
    """Evaluate every readiness gate up to and including the promotion target."""
    if target_level not in READINESS_LEVELS:
        raise PilotGateError("LEVEL_INVALID", f"unknown target level {target_level}")
    idx = READINESS_LEVELS.index(target_level)
    out: list[dict[str, Any]] = []
    for level in READINESS_LEVELS[: idx + 1]:
        out.extend(_gate_checks_for_level(manifest, level))
    return out


def _normalize_item_statistics(raw: object) -> Mapping[str, Mapping[str, Any]]:
    stats = _require_mapping(raw, "ITEM_STATS_INVALID", "item_statistics")
    out: dict[str, Mapping[str, Any]] = {}
    for item_id, row in stats.items():
        if not isinstance(item_id, str) or not item_id.strip():
            raise PilotGateError("ITEM_STATS_INVALID", "item_statistics keys must be non-empty strings")
        out[item_id.strip()] = _require_mapping(row, "ITEM_STATS_INVALID", f"item_statistics[{item_id}]")
    return out


def build_promotion_request(
    manifest: Mapping[str, Any],
    *,
    cohort: Mapping[str, Any],
    item_statistics: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    """Attach pilot cohort facts and item statistics to a promotion request payload."""
    m = _require_mapping(manifest, "MANIFEST_INVALID", "manifest")
    current = m.get("readiness_level")
    if current not in _NEXT_LEVEL and current != "L3":
        raise PilotGateError("LEVEL_INVALID", "readiness_level must be L0, L1, L2, or L3")
    cohort_status = cohort_ready_for_promotion(cohort)
    stats = _normalize_item_statistics(item_statistics)
    target = _NEXT_LEVEL.get(str(current))
    return {
        "card_id": CARD_ID,
        "language": m.get("language"),
        "readiness_level": current,
        "target_level": target,
        "cohort": cohort_status,
        "item_statistics": {k: dict(v) for k, v in stats.items()},
        "item_statistics_count": len(stats),
    }


def run_pilot_promotion(
    manifest: MutableMapping[str, Any],
    *,
    cohort: Mapping[str, Any],
    item_statistics: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    """
    Run promotion after pilot cohort gates: attach stats, list gate results, refuse on any failure.
    """
    request = build_promotion_request(manifest, cohort=cohort, item_statistics=item_statistics)
    cohort_status = request["cohort"]
    target = request["target_level"]
    if target is None:
        return {
            **request,
            "promoted": False,
            "code": "ALREADY_AT_MAX",
            "gate_results": [],
        }
    if not cohort_status["ready"]:
        code = "PILOT_COHORT_INCOMPLETE"
        if cohort_status.get("overdue"):
            code = "PILOT_OVERDUE_INCOMPLETE"
        gate_results = gates_through_target(manifest, target)
        return {
            **request,
            "promoted": False,
            "code": code,
            "gate_results": gate_results,
            "readiness_level": manifest.get("readiness_level"),
        }

    gate_results = gates_through_target(manifest, target)
    any_fail = any(not row["passed"] for row in gate_results)
    if any_fail:
        return {
            **request,
            "promoted": False,
            "code": "PROMOTION_BLOCKED",
            "gate_results": gate_results,
            "readiness_level": manifest.get("readiness_level"),
        }

    snapshot = deepcopy(dict(manifest))
    try:
        outcome = request_promotion(manifest)
    except ReadinessError as exc:
        raise PilotGateError(exc.code, str(exc)) from exc

    if not outcome.get("promoted"):
        return {
            **request,
            **outcome,
            "gate_results": gate_results,
        }

    if manifest.get("readiness_level") == snapshot.get("readiness_level"):
        return {
            **request,
            "promoted": False,
            "code": "PROMOTION_BLOCKED",
            "gate_results": gate_results,
            "readiness_level": snapshot.get("readiness_level"),
        }

    return {
        **request,
        **outcome,
        "gate_results": gate_results,
        "pilot_overdue": cohort_status.get("overdue", False),
    }
