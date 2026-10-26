"""P5-088 LLM generation cost vs EXT-01 pricing (CURRICULUM §9.4)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.llm_generation_cost_verify import (  # noqa: E402
    CARD_ID,
    ITEMS_PER_LANGUAGE_MAX,
    ITEMS_PER_LANGUAGE_MIN,
    LlmGenerationCostError,
    USD_PER_LANGUAGE_MAX,
    USD_PER_LANGUAGE_MIN,
    USD_STAGE1_MAX,
    USD_STAGE1_MIN,
    append_verification_ledger_row,
    evaluate_stage1_llm_cost,
    load_ledger,
    pass_profiles_from_ledger,
    validate_ledger,
)


def test_ledger_validates() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    band = data["planning_band"]
    assert band["usd_per_language_min"] == USD_PER_LANGUAGE_MIN
    assert band["usd_stage1_max"] == USD_STAGE1_MAX


def test_cost_at_curriculum_item_bands_records_verdict() -> None:
    profiles = pass_profiles_from_ledger(load_ledger())
    low = evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MIN)
    high = evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MAX)

    for result in (low, high):
        pl = result["per_language"]
        st = result["stage1"]
        assert pl["usd_total"] > 0
        assert st["usd_total"] == round(pl["usd_total"] * 7, 2)
        assert pl["verification"] in ("confirmed_within_band", "delta_recorded")
        assert st["verification"] in ("confirmed_within_band", "delta_recorded")
        if pl["within_planning_band"]:
            assert USD_PER_LANGUAGE_MIN <= pl["usd_total"] <= USD_PER_LANGUAGE_MAX
        if st["within_planning_band"]:
            assert USD_STAGE1_MIN <= st["usd_total"] <= USD_STAGE1_MAX


def test_append_row_updates_store() -> None:
    profiles = pass_profiles_from_ledger(load_ledger())
    result = evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MAX)
    store = load_ledger()
    before = len(store.get("llm_generation_cost_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["llm_generation_cost_verifications"]) == before + 1
    assert store["latest_evaluation"]["card_id"] == CARD_ID


def test_rejects_items_outside_curriculum_band() -> None:
    profiles = pass_profiles_from_ledger(load_ledger())
    with pytest.raises(LlmGenerationCostError) as exc:
        evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MIN - 1)
    assert exc.value.code == "ITEMS"
