"""Tests for US-government public-domain course rows in the licence register."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    FSI_NO_COURSE_NOTE,
    LicenceRegisterError,
    apply_pd_status_constraints,
    check_items,
    fsi_course,
    load_register_csv,
    non_fsi_grammar,
    require_modernised,
    validate_rows,
)

_REGISTER_CSV = (
    Path(__file__).resolve().parents[1] / "licences" / "register.csv"
)


def test_seeded_register_rows_validate() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    validate_rows(rows)


@pytest.mark.parametrize("language", ["yo", "ig", "ha", "sw"])
def test_fsi_course_present_for_seeded_languages(language: str) -> None:
    rows = load_register_csv(_REGISTER_CSV)
    row = fsi_course(language, rows)
    assert row is not None
    assert row["licence"] == "public-domain"
    assert row["pd_status"] == "confirmed"
    assert row["modernise_vocabulary"] == "true"


@pytest.mark.parametrize("language", ["zu", "xh"])
def test_fsi_course_absent_for_zulu_and_xhosa(language: str) -> None:
    rows = load_register_csv(_REGISTER_CSV)
    assert fsi_course(language, rows) is None


def test_fsi_kit_note_matches_curriculum() -> None:
    assert FSI_NO_COURSE_NOTE == "No FSI Zulu or Xhosa course found"


def test_peace_corps_rows_public_domain_unconfirmed_pd_status() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    peace_corps = [r for r in rows if r["source_id"].startswith("peace-corps-")]
    assert len(peace_corps) == 4
    for row in peace_corps:
        assert row["licence"] == "public-domain"
        assert row["pd_status"] == "unconfirmed"


@pytest.mark.parametrize(
    ("language", "expected"),
    [
        ("zu", "Poulos & Msimang [purchase]"),
        ("zulu", "Poulos & Msimang [purchase]"),
        ("xh", "a standard Xhosa reference grammar [linguist to choose]"),
        ("xhosa", "a standard Xhosa reference grammar [linguist to choose]"),
    ],
)
def test_non_fsi_grammar_for_zulu_and_xhosa(language: str, expected: str) -> None:
    grammar = non_fsi_grammar(language)
    assert grammar == expected
    assert "FSI" not in grammar


def test_load_register_csv_applies_pd_status_constraints(tmp_path: Path) -> None:
    csv_path = tmp_path / "register.csv"
    csv_path.write_text(
        "source_id,url,licence,version_or_date,display,evidence,training,"
        "attribution_text,owner_signoff,pd_status,modernise_vocabulary\n"
        "pc-test,CURRICULUM.md#§2.2:L136-L146,public-domain,"
        "1965,true,true,true,Peace Corps test,,unconfirmed,false\n",
        encoding="utf-8",
    )
    rows = load_register_csv(csv_path)
    assert len(rows) == 1
    assert rows[0]["display"] == "false"
    assert rows[0]["training"] == "false"


def test_pd_status_unconfirmed_forces_display_and_training_false() -> None:
    row: dict[str, str] = {
        "source_id": "peace-corps-test",
        "url": "CURRICULUM.md#§2.2:L136-L146",
        "licence": "public-domain",
        "version_or_date": "test",
        "display": "true",
        "evidence": "true",
        "training": "true",
        "attribution_text": "test attribution",
        "owner_signoff": "",
        "pd_status": "unconfirmed",
        "modernise_vocabulary": "false",
    }
    apply_pd_status_constraints(row)
    assert row["display"] == "false"
    assert row["training"] == "false"
    validate_rows([row])


def test_require_modernised_raises_for_unmodernised_lexicon() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    fsi = fsi_course("yo", rows)
    assert fsi is not None
    item = {"source_id": fsi["source_id"], "kind": "lexicon", "modernised": "false"}
    with pytest.raises(LicenceRegisterError) as exc_info:
        require_modernised(fsi, item)
    assert exc_info.value.code == "MODERNISE_REQUIRED"


def test_require_modernised_passes_when_modernised() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    fsi = fsi_course("yo", rows)
    assert fsi is not None
    item = {"source_id": fsi["source_id"], "kind": "lexicon", "modernised": "true"}
    require_modernised(fsi, item)


def test_check_items_raises_modernise_required_for_unmodernised_lexicon() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    fsi = fsi_course("yo", rows)
    assert fsi is not None
    items = [
        {"source_id": fsi["source_id"], "kind": "lexicon", "modernised": "false"},
    ]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(rows, items)
    assert exc_info.value.code == "MODERNISE_REQUIRED"


def test_check_items_passes_lexicon_without_modernised_flag() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    fsi = fsi_course("yo", rows)
    assert fsi is not None
    items = [{"source_id": fsi["source_id"], "kind": "lexicon"}]
    check_items(rows, items)


def test_check_items_passes_when_modernise_vocabulary_not_true() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    pc = next(r for r in rows if r["source_id"] == "peace-corps-hausa")
    items = [
        {"source_id": pc["source_id"], "kind": "lexicon", "modernised": "false"},
    ]
    check_items(rows, items)
