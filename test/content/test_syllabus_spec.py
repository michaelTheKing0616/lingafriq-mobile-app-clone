"""P4-130 per-language syllabus and corpora licence check."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.syllabus_spec import (  # noqa: E402
    CARD_ID,
    SyllabusSpecError,
    build_can_do_index,
    check_corpus_licence,
    load_syllabus_schema,
    submit_syllabus,
)

_REGISTER_FIXTURE: list[dict[str, str]] = [
    {
        "source_id": "test-corpus-yo",
        "url": "https://example.test/corpus",
        "licence": "CC0",
        "version_or_date": "2026-01-01",
        "display": "false",
        "evidence": "true",
        "training": "false",
        "attribution_text": "Test corpus",
        "owner_signoff": "counsel-ok",
        "counsel_status": "confirmed",
    },
    {
        "source_id": "masakhane-yo-ner",
        "url": "https://example.test/masakhane",
        "licence": "CC BY 4.0",
        "version_or_date": "2026-01-01",
        "display": "false",
        "evidence": "true",
        "training": "false",
        "attribution_text": "Masakhane NER",
        "owner_signoff": "counsel-ok",
        "counsel_status": "confirmed",
    },
]


def _base_syllabus(**overrides: object) -> dict:
    doc = {
        "charter": "v2",
        "card_id": CARD_ID,
        "language_id": "yo",
        "status": "draft",
        "applied_linguist": {
            "linguist_id": "ling-yo-01",
            "display_name": "Dr. Applied Linguist",
            "role": "applied_linguist",
        },
        "units": [
            {
                "unit_id": "yo-a1-u01",
                "can_do_ids": ["yo.A1.SOC.greet_market"],
            }
        ],
        "corpora": [
            {
                "corpus_id": "freq-yo-01",
                "source_id": "test-corpus-yo",
                "kind": "register",
            }
        ],
    }
    doc.update(overrides)
    return doc


def test_schema_loads() -> None:
    schema = load_syllabus_schema()
    Draft202012Validator.check_schema(schema)


def test_submit_records_linguist_and_can_do_map() -> None:
    out = submit_syllabus(_base_syllabus(), register_rows=_REGISTER_FIXTURE)
    assert out["status"] == "submitted"
    assert out["applied_linguist"]["recorded_at_submit"] is True
    assert out["can_do_index"] == {"yo-a1-u01": ["yo.A1.SOC.greet_market"]}


def test_masakhane_requires_explicit_licence_field() -> None:
    syllabus = _base_syllabus(
        corpora=[
            {
                "corpus_id": "msk-yo",
                "source_id": "masakhane-yo-ner",
                "kind": "masakhane",
            }
        ]
    )
    with pytest.raises(SyllabusSpecError) as exc:
        submit_syllabus(syllabus, register_rows=_REGISTER_FIXTURE)
    assert exc.value.code == "SOURCE_UNLICENSED"
    syllabus["corpora"][0]["licence"] = "CC BY 4.0"
    out = submit_syllabus(syllabus, register_rows=_REGISTER_FIXTURE)
    assert out["corpora"][0]["licence"] == "CC BY 4.0"


def test_unlicensed_corpus_blocks() -> None:
    syllabus = _base_syllabus(
        corpora=[{"corpus_id": "bad", "source_id": "not-in-register", "kind": "news"}]
    )
    with pytest.raises(SyllabusSpecError) as exc:
        submit_syllabus(syllabus, register_rows=_REGISTER_FIXTURE)
    assert exc.value.code == "SOURCE_UNLICENSED"


def test_jw300_blocks() -> None:
    with pytest.raises(SyllabusSpecError) as exc:
        check_corpus_licence(
            {"corpus_id": "j", "source_id": "jw300", "kind": "jw300_alternative"},
            _REGISTER_FIXTURE,
        )
    assert exc.value.code == "JW300_DERIVED_DATA"


def test_build_can_do_index_rejects_empty() -> None:
    with pytest.raises(SyllabusSpecError):
        build_can_do_index([{"unit_id": "u1", "can_do_ids": []}])
