"""Spec tests for lexeme anchoring status (P4-054). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.anchoring import (  # noqa: E402
    AnchoringError,
    compute_lexeme_status,
)

# Fixture tokens only — not language data.
_FIXTURE_TONE = "fixture-tone"
_FIXTURE_IPA = "fixture-ipa"
_FIXTURE_IPA_OTHER = "fixture-ipa-other"
_FIXTURE_POS = "fixture-pos"
_FIXTURE_NOUN_CLASS = "fixture-noun-class"
_FIXTURE_PLURAL = "fixture-plural"
_FIXTURE_SOURCE_A = "fixture-source-a"
_FIXTURE_SOURCE_B = "fixture-source-b"

_CONTRACT_KEYS = frozenset({"status", "held", "available_to_generation"})


def _source_record(source_id: str, **overrides: Any) -> dict[str, Any]:
    record: dict[str, Any] = {
        "source_id": source_id,
        "tone_pattern": _FIXTURE_TONE,
        "ipa": _FIXTURE_IPA,
        "pos": _FIXTURE_POS,
        "noun_class": _FIXTURE_NOUN_CLASS,
        "plural": _FIXTURE_PLURAL,
    }
    record.update(overrides)
    return record


def _lexeme(*records: dict[str, Any]) -> dict[str, Any]:
    return {"sources": list(records)}


def test_P4_054_AC1_two_agreeing_sources_anchored() -> None:
    lexeme = _lexeme(
        _source_record(_FIXTURE_SOURCE_A),
        _source_record(_FIXTURE_SOURCE_B),
    )

    result = compute_lexeme_status(lexeme)

    assert result["status"] == "anchored"
    assert result["held"] is False
    assert result["available_to_generation"] is True


def test_P4_054_AC2_one_source_is_single_source() -> None:
    lexeme = _lexeme(_source_record(_FIXTURE_SOURCE_A))

    result = compute_lexeme_status(lexeme)

    assert result["status"] == "single-source"
    assert result["held"] is False


def test_P4_054_AC2_high_frequency_held_for_linguist_review() -> None:
    lexeme = _lexeme(_source_record(_FIXTURE_SOURCE_A))

    result = compute_lexeme_status(lexeme, high_frequency=True)

    assert result["status"] == "single-source"
    assert result["held"] is True


@pytest.mark.parametrize("high_frequency", [False, None])
def test_P4_054_AC2_missing_or_false_high_frequency_not_held(
    high_frequency: bool | None,
) -> None:
    lexeme = _lexeme(_source_record(_FIXTURE_SOURCE_A))
    kwargs = {} if high_frequency is None else {"high_frequency": high_frequency}

    result = compute_lexeme_status(lexeme, **kwargs)

    assert result["status"] == "single-source"
    assert result["held"] is False


def test_P4_054_AC3_disagreement_conflicted_and_unavailable() -> None:
    lexeme = _lexeme(
        _source_record(_FIXTURE_SOURCE_A),
        _source_record(_FIXTURE_SOURCE_B, ipa=_FIXTURE_IPA_OTHER),
    )

    result = compute_lexeme_status(lexeme)

    assert result["status"] == "conflicted"
    assert result["available_to_generation"] is False
    assert result["held"] is False


def test_P4_054_AC1_missing_sources_raises() -> None:
    with pytest.raises(AnchoringError) as exc_info:
        compute_lexeme_status({})

    assert exc_info.value.code == "SOURCE_MISSING"


def test_P4_054_AC1_source_field_missing_raises() -> None:
    record = _source_record(_FIXTURE_SOURCE_A)
    del record["tone_pattern"]

    with pytest.raises(AnchoringError) as exc_info:
        compute_lexeme_status(_lexeme(record, _source_record(_FIXTURE_SOURCE_B)))

    assert exc_info.value.code == "SOURCE_FIELD_MISSING"
    assert "tone_pattern" in str(exc_info.value)


def test_P4_054_AC1_stage_contract_with_fixtures() -> None:
    agreeing = compute_lexeme_status(
        _lexeme(
            _source_record(_FIXTURE_SOURCE_A),
            _source_record(_FIXTURE_SOURCE_B),
        )
    )
    single = compute_lexeme_status(_lexeme(_source_record(_FIXTURE_SOURCE_A)))
    conflicted = compute_lexeme_status(
        _lexeme(
            _source_record(_FIXTURE_SOURCE_A),
            _source_record(_FIXTURE_SOURCE_B, ipa=_FIXTURE_IPA_OTHER),
        )
    )

    for result in (agreeing, single, conflicted):
        assert _CONTRACT_KEYS <= set(result)
    assert agreeing["status"] == "anchored"
    assert agreeing["available_to_generation"] is True
    assert single["status"] == "single-source"
    assert single["held"] is False
    assert conflicted["status"] == "conflicted"
    assert conflicted["available_to_generation"] is False
