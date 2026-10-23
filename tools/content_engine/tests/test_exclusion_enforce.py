"""Tests for non-commercial exclusion enforcement (P4-010)."""

from __future__ import annotations

import copy
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.exclusion_enforce import (  # noqa: E402
    ExclusionEnforceError,
    enforce_row,
    lift_exclusion,
    load_exclusions,
    scan_manifest,
)

_EXCLUDED_IDS = (
    "jw300",
    "mafand-mt",
    "masakhaner-2",
    "afrisenti",
    "panlex",
    "naijavoices",
    "igboapi",
    "kamusi",
    "helsinki-swahili-2",
)
_NEEDS_LICENCE_IDS = (
    "oxford-languages",
    "abraham-yoruba-1958",
    "bargery-hausa-1934",
)
_LICENCE = {
    "jw300": "not a CC licence",
    "mafand-mt": "CC BY-NC 4.0",
    "masakhaner-2": "CC BY-NC 4.0",
    "afrisenti": "non-commercial",
    "panlex": "CC BY-NC-SA 4.0",
    "naijavoices": "CC BY-NC-SA 4.0",
    "igboapi": "CC BY-NC-SA 4.0",
    "kamusi": "CC BY-NC-SA",
    "helsinki-swahili-2": "academic-only CLARIN ACA",
    "oxford-languages": "Commercial licence not held",
    "abraham-yoruba-1958": "Copyright unconfirmed",
    "bargery-hausa-1934": "Copyright unconfirmed",
}


def test_shipped_jw300_and_mafand_mt_are_excluded_with_uses_false() -> None:
    table = load_exclusions()
    assert table["charter"] == "v2"
    sources = table["sources"]
    assert set(sources) == set(_EXCLUDED_IDS) | set(_NEEDS_LICENCE_IDS)
    for source_id, row in sources.items():
        assert row["commercial_licence_document"] == ""
        assert row["counsel_status"] == ""
        assert row["uses"]["display"] is False
        assert row["uses"]["evidence"] is False
        assert row["uses"]["training"] is False
        assert row["licence"] == _LICENCE[source_id]
        enforce_row({**row, "source_id": source_id})
    for source_id in ("jw300", "mafand-mt"):
        assert sources[source_id]["status"] == "excluded"
    for source_id in _EXCLUDED_IDS:
        assert sources[source_id]["status"] == "excluded"
    for source_id in _NEEDS_LICENCE_IDS:
        assert sources[source_id]["status"] == "needs-licence"
    assert "BY-NC" not in sources["jw300"]["licence"]
    assert "no JW300-derived data" in sources["jw300"]["reason"]
    assert "Apache-2.0" in sources["igboapi"]["reason"]
    assert "not recorded as purchased" in sources["naijavoices"]["reason"]
    assert "not recorded" in sources["helsinki-swahili-2"]["reason"]


@pytest.mark.parametrize(
    "patch",
    [
        {"uses": {"display": True, "evidence": False, "training": False}},
        {
            "status": "needs-licence",
            "uses": {"display": False, "evidence": False, "training": False},
        },
        {"commercial_licence_document": "   "},
    ],
)
def test_nc_row_with_display_true_and_empty_document_fails_nc_excluded(
    patch: dict[str, Any],
) -> None:
    row: dict[str, Any] = {
        "source_id": "synthetic-nc",
        "status": "excluded",
        "licence": "CC BY-NC 4.0",
        "commercial_licence_document": "",
        "counsel_status": "",
        "uses": {"display": True, "evidence": False, "training": False},
    }
    row.update(patch)
    with pytest.raises(ExclusionEnforceError) as exc_info:
        enforce_row(row)
    assert exc_info.value.code == "NC_EXCLUDED"


@pytest.mark.parametrize("layer", ["lexicon", "corpus", "training", "evidence"])
def test_manifest_jw300_in_evidence_fails_excluded_source_used(layer: str) -> None:
    table = load_exclusions()
    with pytest.raises(ExclusionEnforceError) as exc_info:
        scan_manifest([{"source_id": "jw300", "layer": layer}], table)
    message = str(exc_info.value)
    assert exc_info.value.code == "EXCLUDED_SOURCE_USED"
    assert "jw300" in message


def test_manifest_needs_licence_source_fails_excluded_source_used() -> None:
    table = load_exclusions()
    with pytest.raises(ExclusionEnforceError) as exc_info:
        scan_manifest(
            [{"source_id": "oxford-languages", "layer": "lexicon"}],
            table,
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "EXCLUDED_SOURCE_USED"
    assert "oxford-languages" in message


def test_manifest_claim_does_not_lift_naijavoices() -> None:
    table = load_exclusions()
    claim = {"licensed": True}
    assert lift_exclusion(table, "naijavoices", claim) == "excluded"
    with pytest.raises(ExclusionEnforceError) as exc_info:
        scan_manifest(
            [
                {
                    "source_id": "naijavoices",
                    "layer": "training",
                    "licensed": True,
                }
            ],
            table,
        )
    assert exc_info.value.code == "EXCLUDED_SOURCE_USED"
    assert "naijavoices" in str(exc_info.value)
    shipped = load_exclusions()
    assert shipped["sources"]["naijavoices"]["counsel_status"] == ""
    assert shipped["sources"]["naijavoices"]["commercial_licence_document"] == ""


def test_copied_table_with_document_and_counsel_confirmed_is_not_excluded() -> None:
    shipped_path = (
        Path(__file__).resolve().parents[1] / "licences" / "exclusions.yaml"
    )
    before = shipped_path.read_bytes()
    table = copy.deepcopy(load_exclusions())
    row = table["sources"]["naijavoices"]
    row["commercial_licence_document"] = "waiver-ref"
    row["counsel_status"] = ""
    assert lift_exclusion(table, "naijavoices", {"licensed": True}) == "excluded"
    row["commercial_licence_document"] = ""
    row["counsel_status"] = "confirmed"
    assert lift_exclusion(table, "naijavoices", {"licensed": True}) == "excluded"
    row["commercial_licence_document"] = "waiver-ref"
    row["counsel_status"] = "confirmed"
    assert lift_exclusion(table, "naijavoices", {"licensed": True}) != "excluded"
    scan_manifest(
        [{"source_id": "naijavoices", "layer": "evidence"}],
        table,
    )
    assert shipped_path.read_bytes() == before
    shipped = load_exclusions()
    assert shipped["sources"]["naijavoices"]["counsel_status"] == ""
    assert shipped["sources"]["naijavoices"]["commercial_licence_document"] == ""
    assert shipped["sources"]["naijavoices"]["status"] == "excluded"
