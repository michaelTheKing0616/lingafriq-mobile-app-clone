"""Spec tests for citation entailment (P4-058). Mode A."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.entailment import (  # noqa: E402
    EXT01_CITATION,
    EntailmentError,
    build_entailment_payload,
    check_claim_entailment,
    lookup_passage,
    make_fixture_client,
    parse_entailment_response,
    read_entailment_routing,
    run_claim_entailment,
)

_FIXTURE_MODEL = "fixture-gemini-entailment"


def _passage_fixture() -> list[dict[str, Any]]:
    return [
        {
            "source_id": "fixture-src",
            "locator": "p.1",
            "passage": "The fixture passage supports the claim.",
        },
    ]


@pytest.fixture
def entailment_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_ENTAILMENT_MODEL", _FIXTURE_MODEL)


def test_read_entailment_routing_cites_ext01(entailment_env: None) -> None:
    routing = read_entailment_routing()
    assert routing["entailment_model"] == _FIXTURE_MODEL
    assert routing["ext01_citation"] == EXT01_CITATION


def test_P4_058_AC3_missing_passage_fails_passage_not_found(
    entailment_env: None,
) -> None:
    claim = {
        "section": "explanation",
        "text": "fixture claim",
        "citation": {"source_id": "missing-src", "locator": "p.9"},
    }
    client = make_fixture_client({_FIXTURE_MODEL: json.dumps({"entailed": True})})
    result = check_claim_entailment(claim, _passage_fixture(), client)
    assert result["code"] == "PASSAGE_NOT_FOUND"
    assert result["can_publish"] is False


def test_P4_058_AC1_unsupported_claim_fails_claim_not_entailed(
    entailment_env: None,
) -> None:
    claim = {
        "section": "explanation",
        "text": "unsupported fixture claim",
        "citation": {"source_id": "fixture-src", "locator": "p.1"},
    }
    client = make_fixture_client({_FIXTURE_MODEL: json.dumps({"entailed": False})})
    result = check_claim_entailment(claim, _passage_fixture(), client)
    assert result["code"] == "CLAIM_NOT_ENTAILED"
    assert result["entailed"] is False


def test_P4_058_AC2_grammar_and_culture_always_route_to_reviewer(
    entailment_env: None,
) -> None:
    claims = [
        {
            "section": "grammar_note",
            "text": "fixture grammar",
            "citation": {"source_id": "fixture-src", "locator": "p.1"},
        },
        {
            "section": "culture_note",
            "text": "fixture culture",
            "citation": {"source_id": "fixture-src", "locator": "p.1"},
        },
    ]
    client = make_fixture_client({_FIXTURE_MODEL: json.dumps({"entailed": True})})
    stage = run_claim_entailment(claims, _passage_fixture(), client)
    assert stage["can_publish"] is True
    routes = [r["reviewer_route"] for r in stage["claim_results"]]
    assert routes == ["linguist", "cultural_reviewer"]


class _RecordingClient:
    def __init__(self, entailed: bool) -> None:
        self.calls: list[dict[str, Any]] = []
        self._body = json.dumps({"entailed": entailed})

    def complete(self, model: str, payload: dict[str, Any]) -> str:
        self.calls.append({"model": model, "payload": dict(payload)})
        return self._body


def test_stage_contract_happy_path(entailment_env: None) -> None:
    claims = [
        {
            "section": "explanation",
            "text": "supported claim",
            "citation": {"source_id": "fixture-src", "locator": "p.1"},
        },
    ]
    client = _RecordingClient(True)
    stage = run_claim_entailment(claims, _passage_fixture(), client)
    assert stage["status"] == "ok"
    assert stage["can_publish"] is True
    assert client.calls[0]["payload"]["passage"].startswith("The fixture passage")


def test_lookup_passage_matches_source_and_locator() -> None:
    citation = {"source_id": "fixture-src", "locator": "p.1"}
    text = lookup_passage(citation, _passage_fixture())
    assert text is not None and "fixture passage" in text


def test_parse_entailment_response_rejects_non_boolean() -> None:
    with pytest.raises(EntailmentError) as exc:
        parse_entailment_response({"entailed": "yes"})
    assert exc.value.code == "ENTAILMENT_RESPONSE_INVALID"


def test_build_entailment_payload_includes_claim_and_passage(
    entailment_env: None,
) -> None:
    claim = {
        "section": "explanation",
        "text": "fixture",
        "citation": {"source_id": "fixture-src", "locator": "p.1"},
    }
    payload = build_entailment_payload(claim, "passage text")
    assert payload["claim_text"] == "fixture"
    assert payload["passage"] == "passage text"
