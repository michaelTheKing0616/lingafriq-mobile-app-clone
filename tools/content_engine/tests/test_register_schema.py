"""Tests for licence register schema validation."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    check_items,
    validate_row,
)


def _valid_row(**overrides: str) -> dict[str, str]:
    base = {
        "source_id": "src-1",
        "url": "https://example.com/source",
        "licence": "CC BY 4.0",
        "version_or_date": "2026-10-21",
        "display": "false",
        "evidence": "true",
        "training": "false",
        "attribution_text": "Example attribution",
        "owner_signoff": "owner@example.com",
    }
    base.update(overrides)
    return base


@pytest.mark.parametrize(
    "field",
    [
        "url",
        "licence",
        "version_or_date",
        "display",
        "evidence",
        "training",
        "attribution_text",
        "owner_signoff",
    ],
)
def test_missing_required_field_raises(field: str) -> None:
    row = _valid_row()
    del row[field]
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_FIELD_MISSING"
    assert field in str(exc_info.value)


@pytest.mark.parametrize("field", ["url", "licence", "version_or_date", "attribution_text"])
def test_blank_required_field_raises(field: str) -> None:
    row = _valid_row(**{field: "   "})
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_FIELD_MISSING"
    assert field in str(exc_info.value)


@pytest.mark.parametrize("bad", ["", "yes", "1", "TRUE", "False"])
def test_non_boolean_use_flag_raises(bad: str) -> None:
    row = _valid_row(display=bad)
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_USE_INVALID"


def test_unregistered_source_id_raises() -> None:
    register = [_valid_row(source_id="known")]
    items = [{"source_id": "missing", "kind": "lexicon"}]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(register, items)
    assert exc_info.value.code == "LICENCE_UNREGISTERED"


def test_unsigned_display_true_raises() -> None:
    row = _valid_row(display="true", owner_signoff="")
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_UNSIGNED"


def test_unsigned_training_true_raises() -> None:
    row = _valid_row(training="true", owner_signoff="")
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_UNSIGNED"


def test_evidence_only_empty_signoff_allowed() -> None:
    row = _valid_row(
        display="false",
        evidence="true",
        training="false",
        owner_signoff="",
    )
    validate_row(row)


def test_by_nc_with_display_true_fails() -> None:
    row = _valid_row(
        licence="CC BY-NC 4.0",
        display="true",
        evidence="false",
        training="false",
    )
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_NONCOMMERCIAL"


def test_by_sa_evidence_only_passes() -> None:
    row = _valid_row(
        licence="CC BY-SA 4.0",
        display="false",
        evidence="true",
        training="false",
        owner_signoff="",
    )
    validate_row(row)
