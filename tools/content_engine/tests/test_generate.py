"""Spec tests for grounded generation (P4-055). Mode A."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.generate import (  # noqa: E402
    EXT01_CITATION,
    GenerateError,
    allowed_lexemes_for_generation,
    build_generation_request,
    generate_grounded_item,
    make_fixture_client,
    parse_generation_response,
    read_model_routing,
)

_FIXTURE_TONE = "fixture-tone"
_FIXTURE_IPA = "fixture-ipa"
_FIXTURE_POS = "fixture-pos"
_FIXTURE_NOUN_CLASS = "fixture-noun-class"
_FIXTURE_PLURAL = "fixture-plural"
_FIXTURE_SOURCE_A = "fixture-source-a"
_FIXTURE_SOURCE_B = "fixture-source-b"


def _source(source_id: str, **overrides: Any) -> dict[str, Any]:
    row: dict[str, Any] = {
        "source_id": source_id,
        "tone_pattern": _FIXTURE_TONE,
        "ipa": _FIXTURE_IPA,
        "pos": _FIXTURE_POS,
        "noun_class": _FIXTURE_NOUN_CLASS,
        "plural": _FIXTURE_PLURAL,
    }
    row.update(overrides)
    return row


def _lexeme(*sources: dict[str, Any], form: str = "fixture-form") -> dict[str, Any]:
    return {
        "form": form,
        "tone_pattern": _FIXTURE_TONE,
        "ipa": _FIXTURE_IPA,
        "pos": _FIXTURE_POS,
        "noun_class": _FIXTURE_NOUN_CLASS,
        "plural": _FIXTURE_PLURAL,
        "g2p": {"ipa": _FIXTURE_IPA},
        "sources": list(sources),
    }


def _valid_response() -> dict[str, Any]:
    return {
        "claims": [
            {
                "section": "explanation",
                "text": "fixture claim text",
                "citation": {
                    "source_id": "fixture-source",
                    "locator": "p.1",
                },
            },
        ],
    }


@pytest.fixture
def generation_model(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_GENERATION_MODEL", "fixture-gemini-3.1-pro")


def test_P4_055_AC3_model_routing_cites_ext01(generation_model: None) -> None:
    routing = read_model_routing()
    assert routing["model"] == "fixture-gemini-3.1-pro"
    assert routing["ext01_citation"] == EXT01_CITATION


def test_P4_055_AC3_model_not_configured(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("CONTENT_ENGINE_GENERATION_MODEL", raising=False)
    with pytest.raises(GenerateError) as exc_info:
        read_model_routing()
    assert exc_info.value.code == "MODEL_NOT_CONFIGURED"


def test_P4_055_AC1_request_includes_only_anchored_lexicon(generation_model: None) -> None:
    anchored = _lexeme(_source(_FIXTURE_SOURCE_A), _source(_FIXTURE_SOURCE_B))
    single = _lexeme(_source(_FIXTURE_SOURCE_A), form="fixture-single")
    request = build_generation_request(
        "A1.SPEAK: fixture objective",
        [anchored, single],
    )
    assert request["can_do"] == "A1.SPEAK: fixture objective"
    assert request["allowed_lexicon"] == [anchored]
    assert request["routing"]["ext01_citation"] == EXT01_CITATION


def test_P4_055_AC1_allowed_lexeme_filter(generation_model: None) -> None:
    anchored = _lexeme(_source(_FIXTURE_SOURCE_A), _source(_FIXTURE_SOURCE_B))
    conflicted = _lexeme(
        _source(_FIXTURE_SOURCE_A),
        _source(_FIXTURE_SOURCE_B, tone_pattern=_FIXTURE_TONE + "-other"),
    )
    assert allowed_lexemes_for_generation([anchored, conflicted]) == [anchored]


def test_P4_055_AC2_parse_happy_path() -> None:
    parsed = parse_generation_response(json.dumps(_valid_response()))
    assert parsed["claims"][0]["citation"]["locator"] == "p.1"


def test_P4_055_AC2_citation_missing_locator() -> None:
    bad = _valid_response()
    bad["claims"][0]["citation"] = {"source_id": "fixture-source"}
    with pytest.raises(GenerateError) as exc_info:
        parse_generation_response(bad)
    assert exc_info.value.code == "CITATION_MISSING"


def test_P4_055_AC2_citation_missing_source_id() -> None:
    bad = _valid_response()
    bad["claims"][0]["citation"] = {"locator": "p.1"}
    with pytest.raises(GenerateError) as exc_info:
        parse_generation_response(bad)
    assert exc_info.value.code == "CITATION_MISSING"


def test_P4_055_generate_grounded_item_end_to_end(generation_model: None) -> None:
    lexeme = _lexeme(_source(_FIXTURE_SOURCE_A), _source(_FIXTURE_SOURCE_B))
    client = make_fixture_client(_valid_response())
    result = generate_grounded_item(
        "A1.SPEAK: fixture",
        [lexeme],
        client,
    )
    assert result["models"]["generator"] == "fixture-gemini-3.1-pro"
    assert result["ext01_citation"] == EXT01_CITATION
    assert result["item"]["claims"][0]["text"] == "fixture claim text"


def test_P4_055_generate_empty_lexicon_fails(generation_model: None) -> None:
    single = _lexeme(_source(_FIXTURE_SOURCE_A))
    with pytest.raises(GenerateError) as exc_info:
        build_generation_request("A1.SPEAK: fixture", [single])
    assert exc_info.value.code == "LEXICON_EMPTY"
