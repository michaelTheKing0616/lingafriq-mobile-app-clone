"""P5-085 Phase 1 machine pipeline throughput (CURRICULUM §9.3)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.phase1_machine_pipeline_throughput import (  # noqa: E402
    CARD_ID,
    PLANNING_ITEMS_PER_WEEK_MAX,
    PLANNING_ITEMS_PER_WEEK_MIN,
    MachinePipelineThroughputError,
    append_verification_ledger_row,
    evaluate_weekly_throughput,
    load_ledger,
    validate_ledger,
)


def test_ledger_validates() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    assert data["planning_band"]["items_per_week_min"] == PLANNING_ITEMS_PER_WEEK_MIN
    assert data["planning_band"]["items_per_week_max"] == PLANNING_ITEMS_PER_WEEK_MAX


def test_within_band_no_plan_update() -> None:
    result = evaluate_weekly_throughput(
        3200,
        language_id="yo",
        week_start=date(2026, 10, 20),
    )
    assert result["within_planning_band"] is True
    assert result["plan_update_required"] is False


def test_outside_band_requires_plan_update_not_data_fudge() -> None:
    result = evaluate_weekly_throughput(
        1500,
        language_id="sw",
        week_start=date(2026, 10, 20),
    )
    assert result["within_planning_band"] is False
    assert result["plan_update_required"] is True
    assert result["planning_band_adjusted"] is False

    bad = dict(result)
    bad["planning_band_adjusted"] = True
    store: dict = {"weekly_measurements": [], "phase1_machine_pipeline_verifications": []}
    with pytest.raises(MachinePipelineThroughputError) as exc:
        append_verification_ledger_row(store, bad)
    assert exc.value.code == "PLANNING_FROZEN"


def test_append_row_persists_summary() -> None:
    result = evaluate_weekly_throughput(
        PLANNING_ITEMS_PER_WEEK_MAX,
        language_id="ig",
        week_start=date(2026, 10, 27),
    )
    store = load_ledger()
    before = len(store.get("phase1_machine_pipeline_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["weekly_measurements"]) >= 1
    assert len(store["phase1_machine_pipeline_verifications"]) == before + 1
