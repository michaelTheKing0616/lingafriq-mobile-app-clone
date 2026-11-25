"""Tests for Mozilla Common Voice CC0 rows in the licence register (P4-005)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    common_voice_hours,
    load_register_csv,
    validate_row,
    validate_rows,
)

_REGISTER_CSV = (
    Path(__file__).resolve().parents[1] / "licences" / "register.csv"
)

_CV_SOURCE_IDS = frozenset(
    {
        "common-voice-yo",
        "common-voice-ha",
        "common-voice-ig",
        "common-voice-sw",
        "common-voice-zu",
        "common-voice-xh",
    }
)


def _row_by_id(source_id: str) -> dict[str, str]:
    rows = load_register_csv(_REGISTER_CSV)
    return next(r for r in rows if r["source_id"] == source_id)


def test_seeded_register_rows_validate() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    validate_rows(rows)


def test_common_voice_rows_cc0_and_use_flags() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    cv_rows = [r for r in rows if r["source_id"] in _CV_SOURCE_IDS]
    assert len(cv_rows) == 6
    for row in cv_rows:
        assert row["licence"] == "CC0"
        assert row["attribution_text"] == ""
        assert row["display"] == "false"
        assert row["training"] == "false"
        assert row["evidence"] == "true"
        assert row["permitted_uses"] == "display,evidence,training"
        assert row["owner_signoff"] == ""


def test_non_cc0_empty_attribution_raises() -> None:
    row = {
        "source_id": "test-src",
        "url": "https://example.com",
        "licence": "CC BY 4.0",
        "version_or_date": "2026",
        "display": "false",
        "evidence": "true",
        "training": "false",
        "attribution_text": "",
        "owner_signoff": "",
    }
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_FIELD_MISSING"
    assert "attribution_text" in str(exc_info.value)


def test_cc0_display_true_empty_signoff_raises() -> None:
    row = {
        "source_id": "common-voice-test",
        "url": "CURRICULUM.md#§2.2:L170-L177",
        "licence": "CC0",
        "version_or_date": "26.0",
        "display": "true",
        "evidence": "true",
        "training": "false",
        "attribution_text": "",
        "owner_signoff": "",
    }
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "LICENCE_UNSIGNED"


@pytest.mark.parametrize(
    ("language", "hours", "status", "version"),
    [
        ("yo", 8.3, "recorded", 26.0),
        ("ha", 12.6, "recorded", None),
        ("ig", 18.9, "recorded", None),
        ("sw", 1065.0, "recorded", 27.0),
        ("zu", None, "verify", None),
        ("xh", None, "verify", None),
    ],
)
def test_common_voice_hours(
    language: str,
    hours: float | None,
    status: str,
    version: float | None,
) -> None:
    rows = load_register_csv(_REGISTER_CSV)
    result = common_voice_hours(language, rows)
    assert result["hours"] == hours
    assert result["status"] == status
    assert result["version"] == version


def test_swahili_hours_not_decimal() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    sw = common_voice_hours("sw", rows)
    assert sw["hours"] == 1065.0
    assert sw["hours"] != 1.065
