"""P5-092 data licence cost vs CURRICULUM §9.4 band (EXT-04/05/06/08/09 quotes)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.data_licence_cost_verify import (  # noqa: E402
    CARD_ID,
    USD_STAGE1_MAX,
    USD_STAGE1_MIN,
    DataLicenceCostError,
    append_verification_ledger_row,
    evaluate_data_licence_cost,
    load_ledger,
    load_quotes,
    validate_ledger,
    validate_quotes,
)


def test_ledger_and_quotes_validate() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    band = data["planning_band"]
    assert band["usd_stage1_min"] == USD_STAGE1_MIN
    assert band["usd_stage1_max"] == USD_STAGE1_MAX
    quotes = load_quotes()
    assert quotes["card_id"] == CARD_ID
    assert len(validate_quotes(quotes)) >= 3


def test_pending_required_quotes_do_not_assert_band() -> None:
    items = validate_quotes(load_quotes())
    result = evaluate_data_licence_cost(items)
    assert result["verification"] == "quotes_pending_required"
    assert "EXT-04" in result["pending_required_blockers"]
    assert result["known_total_usd"] is None


def test_received_required_quotes_sum_within_band() -> None:
    items = [
        {
            "blocker": "EXT-04",
            "vendor": "Oxford Languages",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 12000,
        },
        {
            "blocker": "EXT-05",
            "vendor": "IgboAPI",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 8000,
        },
        {
            "blocker": "EXT-06",
            "vendor": "isiZulu dictionary",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 5000,
        },
    ]
    result = evaluate_data_licence_cost(items)
    assert result["known_total_usd"] == 25000.0
    assert result["within_planning_band"] is True
    assert result["verification"] == "confirmed_within_band"


def test_optional_hcs_eur_converts_and_records_delta() -> None:
    items = [
        {
            "blocker": "EXT-04",
            "vendor": "Oxford",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 40000,
        },
        {
            "blocker": "EXT-05",
            "vendor": "IgboAPI",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 15000,
        },
        {
            "blocker": "EXT-06",
            "vendor": "Zulu dict",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 10000,
        },
        {
            "blocker": "EXT-09",
            "vendor": "HCS",
            "required": False,
            "optional": True,
            "status": "received",
            "eur_amount": 15000,
        },
    ]
    result = evaluate_data_licence_cost(items, eur_usd_rate=1.0)
    assert result["known_total_usd"] == 80000.0
    assert result["within_planning_band"] is False
    assert result["verification"] == "delta_recorded"
    assert result["delta_usd_vs_band"] == 20000.0


def test_append_row_updates_store() -> None:
    items = validate_quotes(load_quotes())
    result = evaluate_data_licence_cost(items)
    store = load_ledger()
    before = len(store.get("data_licence_cost_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["data_licence_cost_verifications"]) == before + 1
    assert store["latest_evaluation"]["card_id"] == CARD_ID


def test_rejects_received_without_amount() -> None:
    items = [
        {
            "blocker": "EXT-04",
            "vendor": "Oxford",
            "required": True,
            "optional": False,
            "status": "received",
        },
        {
            "blocker": "EXT-05",
            "vendor": "IgboAPI",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 1,
        },
        {
            "blocker": "EXT-06",
            "vendor": "Zulu",
            "required": True,
            "optional": False,
            "status": "received",
            "usd_amount": 1,
        },
    ]
    with pytest.raises(DataLicenceCostError) as exc:
        evaluate_data_licence_cost(items)
    assert exc.value.code == "QUOTE_AMOUNT"
