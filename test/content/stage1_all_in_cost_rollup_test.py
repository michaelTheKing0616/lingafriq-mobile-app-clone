"""P5-094 Stage 1 all-in content cost rollup vs CURRICULUM §9.4."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.stage1_all_in_cost_rollup import (  # noqa: E402
    ALL_IN_STAGE1_MAX,
    ALL_IN_STAGE1_MIN,
    BLOCKED_EXTERNAL,
    CARD_ID,
    LATER_LANGUAGE_MAX,
    LATER_LANGUAGE_MIN,
    Stage1AllInCostError,
    append_verification_ledger_row,
    collect_component_spans,
    evaluate_later_language_rollup,
    evaluate_p5_094,
    evaluate_stage1_all_in_rollup,
    load_ledger,
    validate_ledger,
)


def test_ledger_frozen_bands() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    assert data["planning_band_all_in"]["usd_stage1_min"] == ALL_IN_STAGE1_MIN
    assert data["planning_band_later_language"]["usd_max"] == LATER_LANGUAGE_MAX


def test_stage1_rollup_overlaps_curriculum_all_in_band() -> None:
    components = collect_component_spans()
    assert len(components) == 7
    result = evaluate_stage1_all_in_rollup(components)
    assert result["stage1_all_in_usd_min"] < result["stage1_all_in_usd_max"]
    base_verification = result["all_in_verification"].split("_with_pending")[0]
    assert base_verification in (
        "confirmed_within_all_in_band",
        "estimate_overlaps_all_in_band",
        "delta_recorded",
    )
    assert result["stage1_all_in_usd_min"] <= ALL_IN_STAGE1_MAX
    assert result["stage1_all_in_usd_max"] >= ALL_IN_STAGE1_MIN
    assert len(result["blocked_external_logged"]) == len(BLOCKED_EXTERNAL)


def test_later_language_rollup_vs_band() -> None:
    later = evaluate_later_language_rollup()
    assert LATER_LANGUAGE_MIN <= later["later_language_usd_min"]
    assert later["later_language_usd_max"] >= LATER_LANGUAGE_MIN
    assert later["excludes_one_off_licences"] is True


def test_evaluate_p5_094_and_append_row() -> None:
    result = evaluate_p5_094()
    assert result["card_id"] == CARD_ID
    assert "stage1_all_in" in result
    assert "later_language" in result
    store = load_ledger()
    before = len(store.get("stage1_all_in_cost_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["stage1_all_in_cost_verifications"]) == before + 1
    assert store["latest_evaluation"]["verification"] == result["verification"]


def test_empty_components_raises() -> None:
    with pytest.raises(Stage1AllInCostError):
        evaluate_stage1_all_in_rollup([])
