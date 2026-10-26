"""P5-093 reference book costs and engineering weeks vs CURRICULUM §9.4 (EXT-22 purchases)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.reference_books_cost_verify import (  # noqa: E402
    CARD_ID,
    ENG_WEEKS_STAGE1_MAX,
    ENG_WEEKS_STAGE1_MIN,
    STUDIO_PLANNED_ENGINEER_WEEKS,
    USD_STAGE1_MAX,
    USD_STAGE1_MIN,
    ReferenceBooksCostError,
    append_verification_ledger_row,
    evaluate_engineering_weeks,
    evaluate_p5_093,
    evaluate_reference_purchases,
    load_engineering,
    load_ledger,
    load_purchases,
    validate_ledger,
    validate_purchases,
)


def test_ledger_purchases_and_engineering_validate() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    band = data["planning_band_usd"]
    assert band["usd_stage1_min"] == USD_STAGE1_MIN
    assert band["usd_stage1_max"] == USD_STAGE1_MAX
    eng_band = data["planning_band_engineer_weeks"]
    assert eng_band["min"] == ENG_WEEKS_STAGE1_MIN
    assert eng_band["max"] == ENG_WEEKS_STAGE1_MAX
    assert len(validate_purchases(load_purchases())) >= 6


def test_pending_ext22_purchases_do_not_assert_usd_band() -> None:
    items = validate_purchases(load_purchases())
    result = evaluate_reference_purchases(items)
    assert result["verification"] == "purchases_pending_required"
    assert "EXT-22" in result["pending_required_blockers"]
    assert result["known_total_usd"] is None


def test_received_purchases_within_per_lang_and_stage_bands() -> None:
    items = [
        {
            "language_code": "yo",
            "title": "Bámgbóṣé",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 400,
        },
        {
            "language_code": "ig",
            "title": "Emenanjo",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 350,
        },
        {
            "language_code": "ha",
            "title": "Newman",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 300,
        },
        {
            "language_code": "pcm",
            "title": "Faraclas",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 250,
        },
        {
            "language_code": "sw",
            "title": "Ashton",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 200,
        },
        {
            "language_code": "zu",
            "title": "Poulos & Msimang",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 500,
        },
    ]
    result = evaluate_reference_purchases(items)
    assert result["known_total_usd"] == 2000.0
    assert result["within_planning_band"] is True
    assert result["verification"] == "confirmed_within_band"


def test_engineering_planned_weeks_within_curriculum_band() -> None:
    result = evaluate_engineering_weeks(load_engineering())
    assert result["studio_planned_engineer_weeks"] == STUDIO_PLANNED_ENGINEER_WEEKS
    assert result["range_within_planning_band"] is True
    assert result["verification"] == "confirmed_within_band"


def test_combined_eval_pending_purchases_engineering_ok() -> None:
    result = evaluate_p5_093(validate_purchases(load_purchases()), load_engineering())
    assert result["verification"] == "purchases_pending_required"
    assert result["engineering"]["verification"] == "confirmed_within_band"


def test_append_row_updates_store() -> None:
    result = evaluate_p5_093(validate_purchases(load_purchases()), load_engineering())
    store = load_ledger()
    before = len(store.get("reference_books_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["reference_books_verifications"]) == before + 1
    assert store["latest_evaluation"]["card_id"] == CARD_ID


def test_rejects_received_without_amount() -> None:
    items = [
        {
            "language_code": "yo",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
        },
        {
            "language_code": "ig",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 1,
        },
        {
            "language_code": "ha",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 1,
        },
        {
            "language_code": "pcm",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 1,
        },
        {
            "language_code": "sw",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 1,
        },
        {
            "language_code": "zu",
            "blocker": "EXT-22",
            "required": True,
            "status": "received",
            "usd_amount": 1,
        },
    ]
    with pytest.raises(ReferenceBooksCostError) as exc:
        evaluate_reference_purchases(items)
    assert exc.value.code == "PURCHASE_AMOUNT"
