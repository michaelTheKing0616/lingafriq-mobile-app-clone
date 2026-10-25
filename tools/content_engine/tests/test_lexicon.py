"""Spec tests for lexicon frequency list and store (P4-053). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import load_register_csv  # noqa: E402
from tools.content_engine.pipeline.lexicon import (  # noqa: E402
    LexiconError,
    build_frequency_list,
    store_lexeme,
)

_REGISTER_CSV = _REPO_ROOT / "tools/content_engine/licences/register.csv"
_LEIPZIG_SOURCE_ID = "leipzig-corpora"

# Fixture tokens only — not language data and not corpus text.
_FIXTURE_FORM = "fixture-form"
_FIXTURE_FORM_A = "fixture-form-a"
_FIXTURE_FORM_B = "fixture-form-b"
_FIXTURE_FORM_M = "fixture-form-m"
_FIXTURE_FORM_Z = "fixture-form-z"
_FIXTURE_TONE = "fixture-tone"
_FIXTURE_IPA = "fixture-ipa"
_FIXTURE_IPA_OTHER = "fixture-ipa-other"
_FIXTURE_POS = "fixture-pos"
_FIXTURE_NOUN_CLASS = "fixture-noun-class"
_FIXTURE_PLURAL = "fixture-plural"
_FIXTURE_SOURCE_A = "fixture-source-a"
_FIXTURE_SOURCE_B = "fixture-source-b"
_FIXTURE_SOURCE_FORBIDDEN = "fixture-source-forbidden"
_FIXTURE_SOURCE_ABSENT = "fixture-source-absent"
_FIXTURE_COUNT = 3
_FIXTURE_COUNT_HIGH = 5
_FIXTURE_COUNT_LOW = 2

_MANDATORY_STORE_FIELDS = (
    "tone_pattern",
    "ipa",
    "pos",
    "noun_class",
    "plural",
    "sources",
)


def _register_row(
    source_id: str,
    *,
    display: str = "false",
    evidence: str = "true",
    training: str = "false",
) -> dict[str, str]:
    """Fixture register row using the real register columns."""
    return {
        "source_id": source_id,
        "url": "https://example.test/fixture-source",
        "licence": "CC BY 4.0",
        "version_or_date": "2026-10-25",
        "display": display,
        "evidence": evidence,
        "training": training,
        "attribution_text": "fixture-attribution",
        "owner_signoff": "fixture-owner",
    }


def _allowed_register() -> list[dict[str, str]]:
    return [
        _register_row(_FIXTURE_SOURCE_A),
        _register_row(_FIXTURE_SOURCE_B),
    ]


def _corpus_entry(source_id: str, form: str, count: int) -> dict[str, Any]:
    return {"source_id": source_id, "form": form, "count": count}


def _fixture_lexeme(**overrides: Any) -> dict[str, Any]:
    lexeme: dict[str, Any] = {
        "form": _FIXTURE_FORM,
        "tone_pattern": _FIXTURE_TONE,
        "ipa": _FIXTURE_IPA,
        "pos": _FIXTURE_POS,
        "noun_class": _FIXTURE_NOUN_CLASS,
        "plural": _FIXTURE_PLURAL,
        "sources": [_FIXTURE_SOURCE_A],
        "g2p": {"ipa": _FIXTURE_IPA},
    }
    lexeme.update(overrides)
    return lexeme


def test_P4_053_AC1_frequency_list_source_ids_in_register() -> None:
    register = _allowed_register()
    register_ids = {row["source_id"] for row in register}
    entries = [
        _corpus_entry(_FIXTURE_SOURCE_A, _FIXTURE_FORM_A, _FIXTURE_COUNT_HIGH),
        _corpus_entry(_FIXTURE_SOURCE_B, _FIXTURE_FORM_B, _FIXTURE_COUNT_LOW),
    ]

    rows = build_frequency_list(entries, register)

    assert len(rows) == 2
    for row in rows:
        assert set(row) >= {"form", "count", "source_id"}
        assert row["source_id"] in register_ids


def test_P4_053_AC1_unregistered_source_raises() -> None:
    entries = [
        _corpus_entry(_FIXTURE_SOURCE_ABSENT, _FIXTURE_FORM, _FIXTURE_COUNT),
    ]

    with pytest.raises(LexiconError) as exc_info:
        build_frequency_list(entries, _allowed_register())

    assert exc_info.value.code == "LICENCE_UNREGISTERED"


def test_P4_053_AC1_order_descending_count_then_form_then_source() -> None:
    entries = [
        _corpus_entry(_FIXTURE_SOURCE_B, _FIXTURE_FORM_M, _FIXTURE_COUNT_LOW),
        _corpus_entry(_FIXTURE_SOURCE_A, _FIXTURE_FORM_Z, _FIXTURE_COUNT_HIGH),
        _corpus_entry(_FIXTURE_SOURCE_B, _FIXTURE_FORM_A, _FIXTURE_COUNT_HIGH),
        _corpus_entry(_FIXTURE_SOURCE_A, _FIXTURE_FORM_A, _FIXTURE_COUNT_HIGH),
    ]

    rows = build_frequency_list(entries, _allowed_register())

    assert [(row["count"], row["form"], row["source_id"]) for row in rows] == [
        (_FIXTURE_COUNT_HIGH, _FIXTURE_FORM_A, _FIXTURE_SOURCE_A),
        (_FIXTURE_COUNT_HIGH, _FIXTURE_FORM_A, _FIXTURE_SOURCE_B),
        (_FIXTURE_COUNT_HIGH, _FIXTURE_FORM_Z, _FIXTURE_SOURCE_A),
        (_FIXTURE_COUNT_LOW, _FIXTURE_FORM_M, _FIXTURE_SOURCE_B),
    ]


def test_P4_053_AC1_does_not_merge_rows() -> None:
    entries = [
        _corpus_entry(_FIXTURE_SOURCE_A, _FIXTURE_FORM, _FIXTURE_COUNT),
        _corpus_entry(_FIXTURE_SOURCE_B, _FIXTURE_FORM, _FIXTURE_COUNT),
    ]

    rows = build_frequency_list(entries, _allowed_register())

    assert len(rows) == 2
    assert {row["source_id"] for row in rows} == {_FIXTURE_SOURCE_A, _FIXTURE_SOURCE_B}
    assert all(row["form"] == _FIXTURE_FORM for row in rows)
    assert all(row["count"] == _FIXTURE_COUNT for row in rows)


def test_P4_053_AC1_integration_leipzig_register_contract() -> None:
    register_rows = load_register_csv(_REGISTER_CSV)
    register_ids = {row["source_id"] for row in register_rows}
    assert _LEIPZIG_SOURCE_ID in register_ids
    entries = [
        _corpus_entry(_LEIPZIG_SOURCE_ID, _FIXTURE_FORM, _FIXTURE_COUNT),
    ]

    rows = build_frequency_list(entries, register_rows)

    assert rows == [
        {
            "form": _FIXTURE_FORM,
            "count": _FIXTURE_COUNT,
            "source_id": _LEIPZIG_SOURCE_ID,
        }
    ]
    assert rows[0]["source_id"] in register_ids


def test_P4_053_AC2_store_holds_tone_ipa_pos_class_plural() -> None:
    stored = store_lexeme(_fixture_lexeme(), _allowed_register())

    assert stored["form"] == _FIXTURE_FORM
    assert stored["tone_pattern"] == _FIXTURE_TONE
    assert stored["ipa"] == _FIXTURE_IPA
    assert stored["pos"] == _FIXTURE_POS
    assert stored["noun_class"] == _FIXTURE_NOUN_CLASS
    assert stored["plural"] == _FIXTURE_PLURAL
    assert stored["sources"] == [_FIXTURE_SOURCE_A]


@pytest.mark.parametrize("field", _MANDATORY_STORE_FIELDS)
def test_P4_053_AC2_missing_mandatory_field_raises(field: str) -> None:
    lexeme = _fixture_lexeme()
    del lexeme[field]

    with pytest.raises(LexiconError) as exc_info:
        store_lexeme(lexeme, _allowed_register())

    assert exc_info.value.code == "LEXEME_FIELD_MISSING"
    assert field in str(exc_info.value)


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("tone_pattern", ""),
        ("tone_pattern", "   "),
        ("ipa", ""),
        ("pos", ""),
        ("noun_class", ""),
        ("plural", ""),
        ("sources", []),
    ],
)
def test_P4_053_AC2_blank_mandatory_field_raises(field: str, value: Any) -> None:
    lexeme = _fixture_lexeme(**{field: value})

    with pytest.raises(LexiconError) as exc_info:
        store_lexeme(lexeme, _allowed_register())

    assert exc_info.value.code == "LEXEME_FIELD_MISSING"
    assert field in str(exc_info.value)


def test_P4_053_AC2_missing_g2p_raises_for_ipa() -> None:
    lexeme = _fixture_lexeme()
    del lexeme["g2p"]

    with pytest.raises(LexiconError) as exc_info:
        store_lexeme(lexeme, _allowed_register())

    assert exc_info.value.code == "LEXEME_FIELD_MISSING"
    assert "ipa" in str(exc_info.value)


def test_P4_053_AC2_g2p_ipa_mismatch_raises() -> None:
    lexeme = _fixture_lexeme(g2p={"ipa": _FIXTURE_IPA_OTHER})

    with pytest.raises(LexiconError) as exc_info:
        store_lexeme(lexeme, _allowed_register())

    assert exc_info.value.code == "LEXEME_FIELD_MISSING"
    assert "ipa" in str(exc_info.value)


def test_P4_053_AC2_integration_store_registered_source() -> None:
    register_rows = load_register_csv(_REGISTER_CSV)
    lexeme = _fixture_lexeme(sources=[_LEIPZIG_SOURCE_ID])

    stored = store_lexeme(lexeme, register_rows)

    assert stored["tone_pattern"] == _FIXTURE_TONE
    assert stored["ipa"] == _FIXTURE_IPA
    assert stored["pos"] == _FIXTURE_POS
    assert stored["noun_class"] == _FIXTURE_NOUN_CLASS
    assert stored["plural"] == _FIXTURE_PLURAL
    assert stored["sources"] == [_LEIPZIG_SOURCE_ID]


def test_P4_053_AC3_build_frequency_list_forbidden_uses() -> None:
    register = [
        _register_row(
            _FIXTURE_SOURCE_FORBIDDEN,
            display="false",
            evidence="false",
            training="false",
        )
    ]
    entries = [
        _corpus_entry(_FIXTURE_SOURCE_FORBIDDEN, _FIXTURE_FORM, _FIXTURE_COUNT),
    ]

    with pytest.raises(LexiconError) as exc_info:
        build_frequency_list(entries, register)

    assert exc_info.value.code == "LICENCE_USE_FORBIDDEN"


def test_P4_053_AC3_store_lexeme_forbidden_uses() -> None:
    register = [
        _register_row(
            _FIXTURE_SOURCE_FORBIDDEN,
            display="false",
            evidence="false",
            training="false",
        )
    ]
    lexeme = _fixture_lexeme(sources=[_FIXTURE_SOURCE_FORBIDDEN])

    with pytest.raises(LexiconError) as exc_info:
        store_lexeme(lexeme, register)

    assert exc_info.value.code == "LICENCE_USE_FORBIDDEN"
