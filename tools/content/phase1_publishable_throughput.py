"""Phase 1 publishable throughput and timeline verification (P5-087, CURRICULUM §9.3)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Literal, Mapping, MutableMapping

from tools.content.lexicon_select import STAGE1_LANGS
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-087"
GATE_ID = "G5"
LEDGER_REL = "assets/content/phase1_publishable_throughput_ledger.json"

# CURRICULUM §9.3:L823-L826 — planning estimates [to measure in Phase 1].
PUBLISHABLE_ITEMS_PER_WEEK_MIN = 800
PUBLISHABLE_ITEMS_PER_WEEK_MAX = 1500

A1_ITEMS_MIN = 3000
A1_ITEMS_MAX = 4000
A1_WEEKS_MIN = 3
A1_WEEKS_MAX = 4

A1_B1_ITEMS_MIN = 10000
A1_B1_ITEMS_MAX = 12000
A1_B1_WEEKS_MIN = 10
A1_B1_WEEKS_MAX = 14

MilestoneScope = Literal["a1", "a1_b1"]


class PublishableThroughputError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise PublishableThroughputError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise PublishableThroughputError("LEDGER_INVALID", "ledger root must be an object")
    return data


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise PublishableThroughputError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band")
    if not isinstance(planning, dict):
        raise PublishableThroughputError("PLANNING", "planning_band object required")
    if planning.get("publishable_items_per_week_min") != PUBLISHABLE_ITEMS_PER_WEEK_MIN:
        raise PublishableThroughputError(
            "PLANNING_FROZEN",
            "planning_band.publishable_items_per_week_min must match CURRICULUM §9.3:L823",
        )
    if planning.get("publishable_items_per_week_max") != PUBLISHABLE_ITEMS_PER_WEEK_MAX:
        raise PublishableThroughputError(
            "PLANNING_FROZEN",
            "planning_band.publishable_items_per_week_max must match CURRICULUM §9.3:L823",
        )
    if planning.get("source") != "docs/source/CURRICULUM.md#§9.3:L823-L826":
        raise PublishableThroughputError("PLANNING", "planning_band.source must cite §9.3:L823-L826")

    parallel = data.get("stage1_parallel_schedule")
    if not isinstance(parallel, dict):
        raise PublishableThroughputError("PARALLEL", "stage1_parallel_schedule object required")
    langs = parallel.get("language_ids")
    if list(langs) != list(STAGE1_LANGS):
        raise PublishableThroughputError(
            "PARALLEL",
            "stage1_parallel_schedule.language_ids must be the seven Stage-1 languages",
        )
    if parallel.get("runs_in_parallel") is not True:
        raise PublishableThroughputError("PARALLEL", "runs_in_parallel must be true per §9.3:L826")

    measurements = data.get("weekly_measurements")
    if not isinstance(measurements, list):
        raise PublishableThroughputError("MEASUREMENTS", "weekly_measurements must be a list")
    for row in measurements:
        if not isinstance(row, Mapping):
            raise PublishableThroughputError("MEASUREMENT_INVALID", "each measurement must be an object")
        _validate_weekly_row(row)

    milestones = data.get("milestone_measurements")
    if not isinstance(milestones, list):
        raise PublishableThroughputError("MILESTONES", "milestone_measurements must be a list")
    for row in milestones:
        if not isinstance(row, Mapping):
            raise PublishableThroughputError("MILESTONE_INVALID", "each milestone must be an object")
        _validate_milestone_row(row)


def _validate_weekly_row(row: Mapping[str, Any]) -> None:
    status = row.get("measurement_status")
    if status not in ("awaiting_phase1", "measured"):
        raise PublishableThroughputError("STATUS", "measurement_status must be awaiting_phase1 or measured")

    if status == "awaiting_phase1":
        if row.get("publishable_items") is not None:
            raise PublishableThroughputError(
                "DATA_INVENTED",
                "awaiting_phase1 rows must not record publishable counts",
            )
        return

    count = row.get("publishable_items")
    if not isinstance(count, int) or count < 0:
        raise PublishableThroughputError("COUNT", "publishable_items must be a non-negative int")

    within = PUBLISHABLE_ITEMS_PER_WEEK_MIN <= count <= PUBLISHABLE_ITEMS_PER_WEEK_MAX
    if row.get("within_planning_band") is not within:
        raise PublishableThroughputError("BAND_FLAG", "within_planning_band must match measured count")

    plan_update = row.get("plan_update_required")
    if plan_update is not (not within):
        raise PublishableThroughputError(
            "PLAN_UPDATE",
            "plan_update_required must be true when outside the planning band",
        )

    if row.get("planning_band_adjusted") is True:
        raise PublishableThroughputError(
            "PLANNING_FROZEN",
            "do not adjust planning_band to fit measured data",
        )


def _validate_milestone_row(row: Mapping[str, Any]) -> None:
    status = row.get("measurement_status")
    if status not in ("awaiting_phase1", "measured"):
        raise PublishableThroughputError("STATUS", "measurement_status must be awaiting_phase1 or measured")

    scope = row.get("scope")
    if scope not in ("a1", "a1_b1"):
        raise PublishableThroughputError("SCOPE", "scope must be a1 or a1_b1")

    if status == "awaiting_phase1":
        if row.get("total_items") is not None or row.get("elapsed_weeks") is not None:
            raise PublishableThroughputError(
                "DATA_INVENTED",
                "awaiting_phase1 milestone rows must not record counts or elapsed time",
            )
        return

    total = row.get("total_items")
    weeks = row.get("elapsed_weeks")
    if not isinstance(total, int) or total < 0:
        raise PublishableThroughputError("COUNT", "total_items must be a non-negative int")
    if not isinstance(weeks, (int, float)) or weeks < 0:
        raise PublishableThroughputError("ELAPSED", "elapsed_weeks must be a non-negative number")

    within_items, within_weeks = _milestone_within_band(scope, total, float(weeks))
    if row.get("items_within_planning_band") is not within_items:
        raise PublishableThroughputError("BAND_FLAG", "items_within_planning_band must match totals")
    if row.get("weeks_within_planning_band") is not within_weeks:
        raise PublishableThroughputError("BAND_FLAG", "weeks_within_planning_band must match elapsed time")

    plan_update = row.get("plan_update_required")
    if plan_update is not (not (within_items and within_weeks)):
        raise PublishableThroughputError(
            "PLAN_UPDATE",
            "plan_update_required must be true when outside item or week planning bands",
        )


def _milestone_within_band(scope: MilestoneScope, total_items: int, elapsed_weeks: float) -> tuple[bool, bool]:
    if scope == "a1":
        items_ok = A1_ITEMS_MIN <= total_items <= A1_ITEMS_MAX
        weeks_ok = A1_WEEKS_MIN <= elapsed_weeks <= A1_WEEKS_MAX
    else:
        items_ok = A1_B1_ITEMS_MIN <= total_items <= A1_B1_ITEMS_MAX
        weeks_ok = A1_B1_WEEKS_MIN <= elapsed_weeks <= A1_B1_WEEKS_MAX
    return items_ok, weeks_ok


def evaluate_weekly_publishable(
    publishable_items: int,
    *,
    language_id: str,
    week_start: date,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Record one language-week against the §9.3 publishable planning band."""
    lang = language_id.strip().lower()
    if not lang:
        raise PublishableThroughputError("LANGUAGE", "language_id required")
    if publishable_items < 0:
        raise PublishableThroughputError("COUNT", "publishable_items cannot be negative")

    within = PUBLISHABLE_ITEMS_PER_WEEK_MIN <= publishable_items <= PUBLISHABLE_ITEMS_PER_WEEK_MAX
    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "language_id": lang,
        "week_start": week_start.isoformat(),
        "measurement_status": "measured",
        "measured_on": measured_on.isoformat(),
        "publishable_items": publishable_items,
        "planning_band": {
            "publishable_items_per_week_min": PUBLISHABLE_ITEMS_PER_WEEK_MIN,
            "publishable_items_per_week_max": PUBLISHABLE_ITEMS_PER_WEEK_MAX,
        },
        "within_planning_band": within,
        "plan_update_required": not within,
        "planning_band_adjusted": False,
        "note": (
            "Within CURRICULUM §9.3 publishable estimate."
            if within
            else "Outside planning band — revise capacity plan; do not change planning_band."
        ),
    }


def evaluate_milestone_timeline(
    *,
    scope: MilestoneScope,
    language_id: str,
    total_items: int,
    elapsed_weeks: float,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Record A1 or A1–B1 closure against §9.3 item and week planning bands."""
    lang = language_id.strip().lower()
    if not lang:
        raise PublishableThroughputError("LANGUAGE", "language_id required")
    if total_items < 0:
        raise PublishableThroughputError("COUNT", "total_items cannot be negative")
    if elapsed_weeks < 0:
        raise PublishableThroughputError("ELAPSED", "elapsed_weeks cannot be negative")

    items_ok, weeks_ok = _milestone_within_band(scope, total_items, elapsed_weeks)
    measured_on = as_of or datetime.now(UTC).date()

    if scope == "a1":
        item_band = {"min": A1_ITEMS_MIN, "max": A1_ITEMS_MAX}
        week_band = {"min": A1_WEEKS_MIN, "max": A1_WEEKS_MAX}
    else:
        item_band = {"min": A1_B1_ITEMS_MIN, "max": A1_B1_ITEMS_MAX}
        week_band = {"min": A1_B1_WEEKS_MIN, "max": A1_B1_WEEKS_MAX}

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "scope": scope,
        "language_id": lang,
        "measurement_status": "measured",
        "measured_on": measured_on.isoformat(),
        "total_items": total_items,
        "elapsed_weeks": elapsed_weeks,
        "planning_item_band": item_band,
        "planning_week_band": week_band,
        "items_within_planning_band": items_ok,
        "weeks_within_planning_band": weeks_ok,
        "plan_update_required": not (items_ok and weeks_ok),
        "planning_band_adjusted": False,
        "note": (
            "Within CURRICULUM §9.3 milestone estimate."
            if items_ok and weeks_ok
            else "Outside item or week band — revise schedule plan; do not change planning bands."
        ),
    }


def append_weekly_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise PublishableThroughputError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")
    rows = store.setdefault("weekly_measurements", [])
    if not isinstance(rows, list):
        raise PublishableThroughputError("STORE_INVALID", "weekly_measurements must be a list")
    _validate_weekly_row(result)
    row = dict(result)
    rows.append(row)
    verifications = store.setdefault("phase1_publishable_verifications", [])
    if not isinstance(verifications, list):
        raise PublishableThroughputError("STORE_INVALID", "phase1_publishable_verifications must be a list")
    verifications.append(
        {
            "card_id": CARD_ID,
            "gate": GATE_ID,
            "kind": "weekly",
            "measured_on": result.get("measured_on"),
            "language_id": result.get("language_id"),
            "week_start": result.get("week_start"),
            "publishable_items": result.get("publishable_items"),
            "within_planning_band": result.get("within_planning_band"),
            "plan_update_required": result.get("plan_update_required"),
        }
    )
    return row


def append_milestone_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise PublishableThroughputError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")
    rows = store.setdefault("milestone_measurements", [])
    if not isinstance(rows, list):
        raise PublishableThroughputError("STORE_INVALID", "milestone_measurements must be a list")
    _validate_milestone_row(result)
    row = dict(result)
    rows.append(row)
    verifications = store.setdefault("phase1_publishable_verifications", [])
    if not isinstance(verifications, list):
        raise PublishableThroughputError("STORE_INVALID", "phase1_publishable_verifications must be a list")
    verifications.append(
        {
            "card_id": CARD_ID,
            "gate": GATE_ID,
            "kind": "milestone",
            "measured_on": result.get("measured_on"),
            "scope": result.get("scope"),
            "language_id": result.get("language_id"),
            "total_items": result.get("total_items"),
            "elapsed_weeks": result.get("elapsed_weeks"),
            "plan_update_required": result.get("plan_update_required"),
        }
    )
    return row
