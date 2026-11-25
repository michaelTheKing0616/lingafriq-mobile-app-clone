"""Spec tests for independent cross-check (P4-057). Mode A."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.crosscheck import (  # noqa: E402
    EXT01_CITATION,
    CrosscheckError,
    build_crosscheck_payload,
    make_fixture_client,
    model_family,
    parse_opinion_response,
    read_crosscheck_routing,
    run_independent_crosscheck,
)

_FIXTURE_GENERATOR = "fixture-gemini-3.1-pro"
_FIXTURE_CROSS = "fixture-gpt-5-mini"
_FIXTURE_TIE = "fixture-claude-sonnet"


def _generated_bundle() -> dict[str, Any]:
    return {
        "can_do": "fixture can-do",
        "models": {"generator": _FIXTURE_GENERATOR},
        "item": {
            "claims": [
                {
                    "section": "explanation",
                    "text": "fixture claim",
                    "citation": {"source_id": "fixture-src", "locator": "p.1"},
                },
            ],
        },
    }


def _opinion(approves: bool, naturalness: int = 4) -> dict[str, Any]:
    return {
        "approves": approves,
        "naturalness": naturalness,
        "english_translation": "fixture translation",
        "errors": [],
    }


@pytest.fixture
def crosscheck_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_CROSSCHECK_MODEL", _FIXTURE_CROSS)
    monkeypatch.setenv("CONTENT_ENGINE_TIEBREAK_MODEL", _FIXTURE_TIE)


def test_model_family_separates_google_and_openai() -> None:
    assert model_family(_FIXTURE_GENERATOR) == "google"
    assert model_family(_FIXTURE_CROSS) == "openai"


def test_read_crosscheck_routing_cites_ext01(
    crosscheck_env: None,
) -> None:
    routing = read_crosscheck_routing()
    assert routing["crosscheck_model"] == _FIXTURE_CROSS
    assert routing["ext01_citation"] == EXT01_CITATION


def test_P4_057_AC1_payload_omits_generator_reasoning(
    crosscheck_env: None,
) -> None:
    payload = build_crosscheck_payload(_generated_bundle())
    assert payload["crosscheck_model"] == _FIXTURE_CROSS
    assert "models" not in payload
    assert "generation_trace" not in payload
    assert "allowed_lexicon" not in payload
    assert payload["claims"][0]["text"] == "fixture claim"


class _RecordingClient:
    def __init__(self, responses: dict[str, str]) -> None:
        self.calls: list[tuple[str, dict[str, Any]]] = []
        self._responses = responses

    def complete(self, model: str, payload: dict[str, Any]) -> str:
        self.calls.append((model, dict(payload)))
        return self._responses[model]


def test_P4_057_AC1_client_receives_item_without_generator_bundle(
    crosscheck_env: None,
) -> None:
    client = _RecordingClient({_FIXTURE_CROSS: json.dumps(_opinion(True))})
    run_independent_crosscheck(_generated_bundle(), client)
    _, sent = client.calls[0]
    assert "generation_trace" not in sent
    assert "reasoning" not in sent
    assert sent["card_id"] == "P4-057"


def test_P4_057_AC2_agreement_stores_two_opinions(
    crosscheck_env: None,
) -> None:
    client = make_fixture_client({_FIXTURE_CROSS: _opinion(True, 5)})
    result = run_independent_crosscheck(_generated_bundle(), client)
    assert result["status"] == "ok"
    assert result["can_publish"] is True
    assert len(result["model_opinions"]) == 2
    assert result["model_opinions"][0]["role"] == "generator"
    assert result["model_opinions"][1]["role"] == "crosscheck"


def test_P4_057_AC2_disagreement_invokes_tiebreak_and_stores_three(
    crosscheck_env: None,
) -> None:
    client = make_fixture_client(
        {
            _FIXTURE_CROSS: _opinion(False, 2),
            _FIXTURE_TIE: _opinion(True, 4),
        },
    )
    result = run_independent_crosscheck(_generated_bundle(), client)
    assert result["status"] == "ok"
    assert len(result["model_opinions"]) == 3
    roles = [o["role"] for o in result["model_opinions"]]
    assert roles == ["generator", "crosscheck", "tiebreak"]
    assert result["can_publish"] is True
    assert result["crosscheck_ok"] is True


def test_P4_057_AC3_crosscheck_failure_marks_xcheck_error(
    crosscheck_env: None,
) -> None:
    class _Fail:
        def complete(self, _model: str, _payload: dict[str, Any]) -> str:
            raise ConnectionError("fixture outage")

    result = run_independent_crosscheck(_generated_bundle(), _Fail())
    assert result["code"] == "XCHECK_ERROR"
    assert result["status"] == "XCHECK_ERROR"
    assert result["can_publish"] is False


def test_P4_057_AC3_tiebreak_failure_marks_xcheck_error(
    crosscheck_env: None,
) -> None:
    class _FailOnTie:
        def __init__(self) -> None:
            self._n = 0

        def complete(self, model: str, _payload: dict[str, Any]) -> str:
            if model == _FIXTURE_CROSS:
                return json.dumps(_opinion(False, 2))
            raise TimeoutError("tiebreak down")

    result = run_independent_crosscheck(_generated_bundle(), _FailOnTie())
    assert result["code"] == "XCHECK_ERROR"
    assert result["can_publish"] is False
    assert len(result["model_opinions"]) == 2


def test_parse_opinion_response_rejects_missing_approves() -> None:
    with pytest.raises(CrosscheckError, match="approves"):
        parse_opinion_response({"naturalness": 3}, "crosscheck")


def test_model_not_configured(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("CONTENT_ENGINE_CROSSCHECK_MODEL", raising=False)
    monkeypatch.delenv("CONTENT_ENGINE_TIEBREAK_MODEL", raising=False)
    with pytest.raises(CrosscheckError, match="CONTENT_ENGINE_CROSSCHECK_MODEL"):
        read_crosscheck_routing()


def test_same_model_family_rejected(crosscheck_env: None) -> None:
    bundle = _generated_bundle()
    bundle["models"] = {"generator": _FIXTURE_CROSS}
    with pytest.raises(CrosscheckError, match="different family"):
        build_crosscheck_payload(bundle)


def test_tiebreak_env_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_CROSSCHECK_MODEL", _FIXTURE_CROSS)
    monkeypatch.delenv("CONTENT_ENGINE_TIEBREAK_MODEL", raising=False)
    with pytest.raises(CrosscheckError, match="CONTENT_ENGINE_TIEBREAK_MODEL"):
        read_crosscheck_routing()
