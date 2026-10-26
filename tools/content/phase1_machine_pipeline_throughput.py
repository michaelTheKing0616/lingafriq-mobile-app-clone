"""Phase 1 machine pipeline throughput verification (P5-085, CURRICULUM §9.3)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-085"
GATE_ID = "G5"
LEDGER_REL = "assets/content/phase1_machine_pipeline_throughput_ledger.json"

# CURRICULUM §9.3:L820 — planning estimate [to measure in Phase 1]; do not narrow to fit data.
PLANNING_ITEMS_PER_WEEK_MIN = 2000
PLANNING_ITEMS_PER_WEEK_MAX = 4000


class MachinePipelineThroughputError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise MachinePipelineThroughputError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise MachinePipelineThroughputError("LEDGER_INVALID", "ledger root must be an object")
    return data


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise MachinePipelineThroughputError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band")
    if not isinstance(planning, dict):
        raise MachinePipelineThroughputError("PLANNING", "planning_band object required")
    if planning.get("items_per_week_min") != PLANNING_ITEMS_PER_WEEK_MIN:
        raise MachinePipelineThroughputError(
            "PLANNING_FROZEN",
            "planning_band.items_per_week_min must match CURRICULUM §9.3",
        )
    if planning.get("items_per_week_max") != PLANNING_ITEMS_PER_WEEK_MAX:
        raise MachinePipelineThroughputError(
            "PLANNING_FROZEN",
            "planning_band.items_per_week_max must match CURRICULUM §9.3",
        )
    if planning.get("source") != "docs/source/CURRICULUM.md#§9.3:L820":
        raise MachinePipelineThroughputError("PLANNING", "planning_band.source must cite §9.3:L820")

    measurements = data.get("weekly_measurements")
    if not isinstance(measurements, list):
        raise MachinePipelineThroughputError("MEASUREMENTS", "weekly_measurements must be a list")

    for row in measurements:
        if not isinstance(row, Mapping):
            raise MachinePipelineThroughputError("MEASUREMENT_INVALID", "each measurement must be an object")
        _validate_measurement_row(row, planning_frozen=True)


def _validate_measurement_row(row: Mapping[str, Any], *, planning_frozen: bool) -> None:
    status = row.get("measurement_status")
    if status not in ("awaiting_phase1", "measured"):
        raise MachinePipelineThroughputError("STATUS", "measurement_status must be awaiting_phase1 or measured")

    if status == "awaiting_phase1":
        if row.get("items_generated_and_verified") is not None:
            raise MachinePipelineThroughputError(
                "DATA_INVENTED",
                "awaiting_phase1 rows must not record throughput counts",
            )
        return

    count = row.get("items_generated_and_verified")
    if not isinstance(count, int) or count < 0:
        raise MachinePipelineThroughputError("COUNT", "items_generated_and_verified must be a non-negative int")

    within = PLANNING_ITEMS_PER_WEEK_MIN <= count <= PLANNING_ITEMS_PER_WEEK_MAX
    if row.get("within_planning_band") is not within:
        raise MachinePipelineThroughputError("BAND_FLAG", "within_planning_band must match measured count")

    plan_update = row.get("plan_update_required")
    if plan_update is not (not within):
        raise MachinePipelineThroughputError(
            "PLAN_UPDATE",
            "plan_update_required must be true when outside the planning band (AC2)",
        )

    if not within and row.get("planning_band_adjusted") is True:
        raise MachinePipelineThroughputError(
            "PLANNING_FROZEN",
            "do not adjust planning_band to fit measured data; update the plan instead (AC2)",
        )

    if planning_frozen and row.get("planning_band_adjusted") is True:
        raise MachinePipelineThroughputError("PLANNING_FROZEN", "planning_band_adjusted must stay false")


def evaluate_weekly_throughput(
    items_generated_and_verified: int,
    *,
    language_id: str,
    week_start: date,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Record one language-week against the §9.3 machine pipeline planning band."""
    lang = language_id.strip().lower()
    if not lang:
        raise MachinePipelineThroughputError("LANGUAGE", "language_id required")
    if items_generated_and_verified < 0:
        raise MachinePipelineThroughputError("COUNT", "items_generated_and_verified cannot be negative")

    within = PLANNING_ITEMS_PER_WEEK_MIN <= items_generated_and_verified <= PLANNING_ITEMS_PER_WEEK_MAX
    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "language_id": lang,
        "week_start": week_start.isoformat(),
        "measurement_status": "measured",
        "measured_on": measured_on.isoformat(),
        "items_generated_and_verified": items_generated_and_verified,
        "planning_band": {
            "items_per_week_min": PLANNING_ITEMS_PER_WEEK_MIN,
            "items_per_week_max": PLANNING_ITEMS_PER_WEEK_MAX,
        },
        "within_planning_band": within,
        "plan_update_required": not within,
        "planning_band_adjusted": False,
        "note": (
            "Within CURRICULUM §9.3 planning estimate."
            if within
            else "Outside planning band — revise capacity plan; do not change planning_band or counts."
        ),
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise MachinePipelineThroughputError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")
    rows = store.setdefault("weekly_measurements", [])
    if not isinstance(rows, list):
        raise MachinePipelineThroughputError("STORE_INVALID", "weekly_measurements must be a list")
    _validate_measurement_row(result, planning_frozen=True)
    row = dict(result)
    rows.append(row)
    verifications = store.setdefault("phase1_machine_pipeline_verifications", [])
    if not isinstance(verifications, list):
        raise MachinePipelineThroughputError("STORE_INVALID", "phase1_machine_pipeline_verifications must be a list")
    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measured_on": result.get("measured_on"),
        "language_id": result.get("language_id"),
        "week_start": result.get("week_start"),
        "items_generated_and_verified": result.get("items_generated_and_verified"),
        "within_planning_band": result.get("within_planning_band"),
        "plan_update_required": result.get("plan_update_required"),
    }
    verifications.append(summary)
    return row
