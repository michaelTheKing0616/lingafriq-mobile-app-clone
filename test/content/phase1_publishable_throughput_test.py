"""P5-087 Phase 1 publishable throughput and timelines (CURRICULUM §9.3)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.lexicon_select import STAGE1_LANGS  # noqa: E402
from tools.content.phase1_publishable_throughput import (  # noqa: E402
    A1_ITEMS_MAX,
    A1_WEEKS_MAX,
    CARD_ID,
    PUBLISHABLE_ITEMS_PER_WEEK_MAX,
    PUBLISHABLE_ITEMS_PER_WEEK_MIN,
    PublishableThroughputError,
    append_milestone_ledger_row,
    append_weekly_ledger_row,
    evaluate_milestone_timeline,
    evaluate_weekly_publishable,
    load_ledger,
    validate_ledger,
)


def test_ledger_validates_parallel_seven() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    assert data["planning_band"]["publishable_items_per_week_min"] == PUBLISHABLE_ITEMS_PER_WEEK_MIN
    parallel = data["stage1_parallel_schedule"]
    assert parallel["runs_in_parallel"] is True
    assert list(parallel["language_ids"]) == list(STAGE1_LANGS)
    assert len(parallel["language_ids"]) == 7


def test_weekly_within_band() -> None:
    result = evaluate_weekly_publishable(
        1100,
        language_id="yo",
        week_start=date(2026, 10, 20),
    )
    assert result["within_planning_band"] is True
    assert result["plan_update_required"] is False


def test_weekly_outside_band_requires_plan_update() -> None:
    result = evaluate_weekly_publishable(
        600,
        language_id="sw",
        week_start=date(2026, 10, 20),
    )
    assert result["within_planning_band"] is False
    assert result["plan_update_required"] is True
    bad = dict(result)
    bad["planning_band_adjusted"] = True
    store: dict = {"weekly_measurements": [], "phase1_publishable_verifications": []}
    with pytest.raises(PublishableThroughputError) as exc:
        append_weekly_ledger_row(store, bad)
    assert exc.value.code == "PLANNING_FROZEN"


def test_a1_milestone_within_bands() -> None:
    result = evaluate_milestone_timeline(
        scope="a1",
        language_id="ig",
        total_items=3500,
        elapsed_weeks=3.5,
    )
    assert result["items_within_planning_band"] is True
    assert result["weeks_within_planning_band"] is True
    assert result["plan_update_required"] is False


def test_a1_b1_milestone_outside_weeks() -> None:
    result = evaluate_milestone_timeline(
        scope="a1_b1",
        language_id="ha",
        total_items=11000,
        elapsed_weeks=20,
    )
    assert result["items_within_planning_band"] is True
    assert result["weeks_within_planning_band"] is False
    assert result["plan_update_required"] is True


def test_append_milestone_persists_summary() -> None:
    result = evaluate_milestone_timeline(
        scope="a1",
        language_id="pcm",
        total_items=A1_ITEMS_MAX,
        elapsed_weeks=A1_WEEKS_MAX,
    )
    store = load_ledger()
    before = len(store.get("phase1_publishable_verifications", []))
    append_milestone_ledger_row(store, result)
    assert len(store["milestone_measurements"]) >= 3
    assert len(store["phase1_publishable_verifications"]) == before + 1
