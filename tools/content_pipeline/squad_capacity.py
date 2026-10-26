"""Squad capacity planner for Stage-1 throughput targets (P4-126, ELEVATION §6.4.1)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from math import ceil
from typing import Any

CARD_ID = "P4-126"

PARALLEL_LANG_MIN = 4
PARALLEL_LANG_MAX = 6
DEFAULT_WAVE_SIZE = 14
TARGET_QUARTERS = 2
WEEKS_PER_QUARTER = 13
PLANNING_ASSUMPTION_LABEL = "planning assumption"

SHARED_TOOLING = ("content_studio", "validators", "eval_harness")


class SquadCapacityError(Exception):
    """Planner validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise SquadCapacityError(code, f"{label} must be a mapping")
    return value


def _language_ids(value: object, code: str, label: str) -> list[str]:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)):
        raise SquadCapacityError(code, f"{label} must be a sequence of language ids")
    out: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise SquadCapacityError(code, f"{label} entries must be non-empty strings")
        out.append(item.strip())
    return out


def assess_parallel_languages(language_ids: Sequence[str]) -> dict[str, Any]:
    """Return capacity flags for a squad's parallel language load (AC1)."""
    count = len(list(language_ids))
    overcommitted = count > PARALLEL_LANG_MAX
    if overcommitted:
        raise SquadCapacityError(
            "OVERCOMMITTED",
            f"squad assigns {count} parallel languages; maximum is {PARALLEL_LANG_MAX}",
        )
    return {
        "card_id": CARD_ID,
        "parallel_count": count,
        "within_band": PARALLEL_LANG_MIN <= count <= PARALLEL_LANG_MAX,
        "min_parallel": PARALLEL_LANG_MIN,
        "max_parallel": PARALLEL_LANG_MAX,
    }


def validate_squad_spec(squad: Mapping[str, Any]) -> dict[str, Any]:
    """Validate roster shape (lead, two writers, linguist time, reviewer panels) and parallel cap."""
    row = _require_mapping(squad, "SQUAD_INVALID", "squad")
    squad_id = row.get("squad_id")
    if not isinstance(squad_id, str) or not squad_id.strip():
        raise SquadCapacityError("SQUAD_INVALID", "squad_id must be a non-empty string")
    lead = row.get("lead_count", 1)
    writers = row.get("writer_count", 2)
    if lead != 1:
        raise SquadCapacityError("SQUAD_INVALID", "lead_count must be 1")
    if writers != 2:
        raise SquadCapacityError("SQUAD_INVALID", "writer_count must be 2")
    linguist_hours = row.get("linguist_hours_per_week")
    if not isinstance(linguist_hours, (int, float)) or isinstance(linguist_hours, bool) or linguist_hours < 0:
        raise SquadCapacityError("SQUAD_INVALID", "linguist_hours_per_week must be a non-negative number")
    panels = row.get("reviewer_panels")
    if not isinstance(panels, int) or isinstance(panels, bool) or panels < 1:
        raise SquadCapacityError("SQUAD_INVALID", "reviewer_panels must be a positive integer")
    langs = _language_ids(row.get("parallel_languages", []), "SQUAD_INVALID", "parallel_languages")
    capacity = assess_parallel_languages(langs)
    return {
        "squad_id": squad_id.strip(),
        "lead_count": lead,
        "writer_count": writers,
        "linguist_hours_per_week": float(linguist_hours),
        "reviewer_panels": panels,
        "parallel_languages": langs,
        **capacity,
    }


def marginal_language_effort(
    *,
    reviewer_hours: float,
    voice_hours: float,
) -> dict[str, Any]:
    """Per-language incremental cost counts reviewer and voice time only (AC3)."""
    if reviewer_hours < 0 or voice_hours < 0:
        raise SquadCapacityError("EFFORT_INVALID", "reviewer and voice hours must be non-negative")
    return {
        "card_id": CARD_ID,
        "tooling_hours": 0.0,
        "reviewer_hours": float(reviewer_hours),
        "voice_hours": float(voice_hours),
        "shared_tooling": list(SHARED_TOOLING),
    }


def project_wave_throughput(
    squads: Sequence[Mapping[str, Any]],
    *,
    wave_size: int = DEFAULT_WAVE_SIZE,
    target_quarters: int = TARGET_QUARTERS,
) -> dict[str, Any]:
    """Project wave ETA vs the two-quarter throughput target (AC2)."""
    if not isinstance(wave_size, int) or isinstance(wave_size, bool) or wave_size < 1:
        raise SquadCapacityError("WAVE_INVALID", "wave_size must be a positive integer")
    if not isinstance(target_quarters, int) or isinstance(target_quarters, bool) or target_quarters < 1:
        raise SquadCapacityError("WAVE_INVALID", "target_quarters must be a positive integer")
    if not squads:
        raise SquadCapacityError("SQUAD_LIST_EMPTY", "at least one squad is required")
    validated = [validate_squad_spec(s) for s in squads]
    parallel_slots = sum(row["parallel_count"] for row in validated)
    if parallel_slots < 1:
        raise SquadCapacityError("NO_PARALLEL_CAPACITY", "squads must assign at least one parallel language")
    quarters_needed = ceil(wave_size / parallel_slots)
    weeks_eta = quarters_needed * WEEKS_PER_QUARTER
    target_weeks = target_quarters * WEEKS_PER_QUARTER
    return {
        "card_id": CARD_ID,
        "wave_size": wave_size,
        "squad_count": len(validated),
        "parallel_slots": parallel_slots,
        "quarters_needed": quarters_needed,
        "weeks_eta": weeks_eta,
        "target_quarters": target_quarters,
        "target_weeks": target_weeks,
        "meets_two_quarter_target": weeks_eta <= target_weeks,
        "eta_basis": PLANNING_ASSUMPTION_LABEL,
        "squads": validated,
    }


def build_capacity_report(
    squads: Sequence[Mapping[str, Any]],
    *,
    wave_size: int = DEFAULT_WAVE_SIZE,
) -> dict[str, Any]:
    """Full planner report: per-squad validation plus wave projection."""
    projection = project_wave_throughput(squads, wave_size=wave_size)
    return {
        "card_id": CARD_ID,
        "shared_tooling": list(SHARED_TOOLING),
        "projection": projection,
    }
