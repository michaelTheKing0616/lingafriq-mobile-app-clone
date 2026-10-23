"""Tests for share-alike evidence sources in the licence register (P4-003)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    assert_no_biblica_mark,
    check_items,
    load_register_csv,
    validate_rows,
)

_REGISTER_CSV = (
    Path(__file__).resolve().parents[1] / "licences" / "register.csv"
)

_SHAREALIKE_SOURCE_IDS = frozenset(
    {
        "wiktionary-kaikki",
        "ud-yoruba-ytb",
        "ud-naija-nsc",
        "biblica-yoruba",
        "biblica-hausa",
    }
)


def _row_by_id(source_id: str) -> dict[str, str]:
    rows = load_register_csv(_REGISTER_CSV)
    return next(r for r in rows if r["source_id"] == source_id)


def test_seeded_sharealike_rows_validate() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    seeded = [r for r in rows if r["source_id"] in _SHAREALIKE_SOURCE_IDS]
    assert len(seeded) == 5
    validate_rows(seeded)


def test_wiktionary_kaikki_licence_and_display() -> None:
    row = _row_by_id("wiktionary-kaikki")
    licence = row["licence"]
    assert "CC BY-SA 4.0" in licence
    assert "GFDL" in licence
    assert "MIT" in licence
    assert row["display"] == "false"
    assert row["training"] == "false"
    assert row["evidence"] == "true"
    assert "proprietary lexicon" in row["attribution_text"].lower()


@pytest.mark.parametrize(
    "source_id",
    ["ud-yoruba-ytb", "ud-naija-nsc", "biblica-yoruba", "biblica-hausa"],
)
def test_share_alike_rows_flags(source_id: str) -> None:
    row = _row_by_id(source_id)
    assert row["share_alike"] == "true"
    assert row["display"] == "false"
    assert row["training"] == "false"
    assert row["evidence"] == "true"
    assert row["licence"] == "CC BY-SA 4.0"


@pytest.mark.parametrize(
    "source_id",
    ["biblica-yoruba", "biblica-hausa"],
)
def test_biblica_religious_register(source_id: str) -> None:
    row = _row_by_id(source_id)
    assert row["religious_register"] == "true"


def test_assert_no_biblica_mark_fails_on_trademark() -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        assert_no_biblica_mark("Open Biblica Yoruba text")
    assert exc_info.value.code == "BIBLICA_MARK_PRESENT"


def test_assert_no_biblica_mark_passes_without_trademark() -> None:
    assert_no_biblica_mark("Open Yoruba Bible corpus excerpt")


def test_biblica_lexicon_item_forbidden() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [{"source_id": "biblica-yoruba", "kind": "lexicon"}]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(rows, items)
    assert exc_info.value.code == "BIBLE_USE_FORBIDDEN"


def test_biblica_corpus_item_passes() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [{"source_id": "biblica-yoruba", "kind": "corpus"}]
    check_items(rows, items)


def test_biblica_corpus_grammar_evidence_forbidden() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [
        {"source_id": "biblica-yoruba", "kind": "corpus", "evidence_use": "grammar"},
    ]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(rows, items)
    assert exc_info.value.code == "BIBLE_USE_FORBIDDEN"


def test_biblica_corpus_frequency_evidence_passes() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [
        {"source_id": "biblica-yoruba", "kind": "corpus", "evidence_use": "frequency"},
    ]
    check_items(rows, items)


def test_wiktionary_proprietary_lexicon_copy_forbidden() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    items = [
        {
            "source_id": "wiktionary-kaikki",
            "kind": "lexicon",
            "copy_into": "proprietary_lexicon",
        },
    ]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_items(rows, items)
    assert exc_info.value.code == "WIKTIONARY_LEXICON_COPY"
