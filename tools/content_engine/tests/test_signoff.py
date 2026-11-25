"""Tests for counsel sign-off gates and verbatim copy rules (P4-008)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.check_register import (  # noqa: E402
    check_verbatim,
    g4_counsel_gate,
    main as register_main,
)
from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    load_register_csv,
    validate_row,
    validate_rows,
)

_REGISTER_CSV = (
    Path(__file__).resolve().parents[1] / "licences" / "register.csv"
)
def _verbatim_item(source_id: str, attribution_text: str = "Item attribution") -> dict[str, str]:
    return {
        "verbatim": "true",
        "source_id": source_id,
        "attribution_text": attribution_text,
    }


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
        "counsel_status": "",
    }
    base.update(overrides)
    return base


def test_shipped_register_validates_and_exits_zero() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    validate_rows(rows)
    assert register_main(["--register", str(_REGISTER_CSV)]) == 0


def test_g4_counsel_gate_blocks_shipped_register() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    assert g4_counsel_gate(rows) == {
        "status": "Blocked-External",
        "blocker": "EXT-03",
    }


def test_display_true_without_counsel_raises_counsel_pending() -> None:
    row = _valid_row(display="true", owner_signoff="owner@example.com")
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "COUNSEL_PENDING"


def test_training_true_without_counsel_raises_counsel_pending() -> None:
    row = _valid_row(training="true", owner_signoff="owner@example.com")
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "COUNSEL_PENDING"


def test_evidence_only_empty_counsel_allowed() -> None:
    row = _valid_row(
        display="false",
        evidence="true",
        training="false",
        owner_signoff="",
        counsel_status="",
    )
    validate_row(row)


def test_counsel_status_invalid_raises() -> None:
    row = _valid_row(counsel_status="pending")
    with pytest.raises(LicenceRegisterError) as exc_info:
        validate_row(row)
    assert exc_info.value.code == "COUNSEL_STATUS_INVALID"


def test_register_cli_counsel_pending(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    csv_path = tmp_path / "register.csv"
    csv_path.write_text(
        "source_id,url,licence,version_or_date,display,evidence,training,"
        "attribution_text,owner_signoff,counsel_status\n"
        "x,https://example.com,CC BY 4.0,2026,true,false,false,"
        "Attributed,owner@example.com,\n",
        encoding="utf-8",
    )
    exit_code = register_main(["--register", str(csv_path)])
    captured = capsys.readouterr()
    assert exit_code != 0
    assert "COUNSEL_PENDING" in captured.err


def test_check_verbatim_fsi_yoruba_passes() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    check_verbatim(
        _verbatim_item(
            "fsi-yoruba",
            "US government work (Foreign Service Institute Basic Course). Public domain.",
        ),
        rows,
    )


def test_check_verbatim_peace_corps_hausa_incompatible() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_verbatim(_verbatim_item("peace-corps-hausa", "Peace Corps attribution"), rows)
    assert exc_info.value.code == "VERBATIM_INCOMPATIBLE"


def test_check_verbatim_leipzig_corpora_incompatible() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_verbatim(
            _verbatim_item("leipzig-corpora", "Leipzig Corpora attribution"),
            rows,
        )
    assert exc_info.value.code == "VERBATIM_INCOMPATIBLE"


def test_check_verbatim_by_sa_incompatible() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_verbatim(
            _verbatim_item("wiktionary-kaikki", "Wiktionary attribution"),
            rows,
        )
    assert exc_info.value.code == "VERBATIM_INCOMPATIBLE"


@pytest.mark.parametrize("missing_field", ["source_id", "attribution_text"])
def test_check_verbatim_missing_fields_raises(missing_field: str) -> None:
    rows = load_register_csv(_REGISTER_CSV)
    item = _verbatim_item("fsi-yoruba")
    item[missing_field] = ""
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_verbatim(item, rows)
    assert exc_info.value.code == "ATTRIBUTION_MISSING"


def test_check_verbatim_skipped_when_not_verbatim() -> None:
    register = [_valid_row(source_id="src-pd", licence="CC BY-SA 4.0")]
    check_verbatim(
        {"verbatim": "false", "source_id": "", "attribution_text": ""},
        register,
    )
