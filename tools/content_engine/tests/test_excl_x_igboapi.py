"""IgboAPI data exclusion pending EXT-05 from Nkọwa okwu (P4-015)."""

from __future__ import annotations

import copy
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.exclusion_enforce import (  # noqa: E402
    enforce_row,
    lift_exclusion,
    load_exclusions,
)

_IGBOAPI_LICENCE = "CC BY-NC-SA 4.0"
_CODE_LICENCE = "Apache-2.0"
_LICENSOR = "Nkọwa okwu"


def test_igboapi_shipped_row_excluded_data_uses_false() -> None:
    table = load_exclusions()
    row = table["sources"]["igboapi"]
    assert row["status"] == "excluded"
    assert row["licence"] == _IGBOAPI_LICENCE
    assert row["code_licence"] == _CODE_LICENCE
    assert row["code_status"] == "allowed"
    assert row["ext05_status"] == "Open"
    assert row["licensor"] == _LICENSOR
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "igboapi"})


def test_igboapi_code_status_allowed_does_not_enable_data_uses() -> None:
    table = load_exclusions()
    row = table["sources"]["igboapi"]
    assert row["code_status"] == "allowed"
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False


def test_igboapi_ext05_open_keeps_exclusion_despite_licence_on_copy() -> None:
    table = copy.deepcopy(load_exclusions())
    row = table["sources"]["igboapi"]
    row["commercial_licence_document"] = "nkowa-okwu-ref"
    row["counsel_status"] = "confirmed"
    row["ext05_status"] = "Open"
    assert lift_exclusion(table, "igboapi", {"licensed": True}) == "excluded"


def test_igboapi_ext05_received_lifts_when_licence_on_copy() -> None:
    table = copy.deepcopy(load_exclusions())
    row = table["sources"]["igboapi"]
    row["commercial_licence_document"] = "nkowa-okwu-ref"
    row["counsel_status"] = "confirmed"
    row["ext05_status"] = "Received"
    assert lift_exclusion(table, "igboapi", {"licensed": True}) == "licensed"
