"""Spec tests for NaijaML restorer stage (P4-062). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.restorer import (  # noqa: E402
    EXT01_CITATION,
    RestorerError,
    apply_naijaml_restorer,
    build_restorer_payload,
    read_restorer_routing,
    run_restorer_stage,
    yoruba_restorer_enabled,
)

_FIXTURE_MODEL = "fixture-naijaml-diacritizer"
_FIXTURE_LEX = "\u1eb9\u1e63in"
_FIXTURE_GEN = "esin"
_YO_KIT = {"tone_restorer": "naijaml"}


@pytest.fixture
def restorer_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_NAIJAML_MODEL", _FIXTURE_MODEL)


def _item(
    tokens: list[dict[str, Any]],
    language: str = "yo",
) -> dict[str, Any]:
    return {"language": language, "tokens": tokens}


def _token(generator: str, lexicon: str, *, matched: bool = True) -> dict[str, Any]:
    return {
        "generator": generator,
        "lexicon": lexicon,
        "matched": matched,
    }


class _RecordingRestorer:
    def __init__(self, restored: str | None = None, *, fail: bool = False) -> None:
        self.calls: list[dict[str, Any]] = []
        self._restored = restored if restored is not None else _FIXTURE_LEX
        self._fail = fail

    def restore(
        self,
        provider: str,
        model: str,
        payload: dict[str, Any],
    ) -> str:
        self.calls.append(
            {"provider": provider, "model": model, "payload": dict(payload)},
        )
        if self._fail:
            raise RuntimeError("fixture NaijaML down")
        return self._restored


def test_read_routing_cites_ext01(restorer_env: None) -> None:
    routing = read_restorer_routing()
    assert routing["naijaml_model"] == _FIXTURE_MODEL
    assert routing["ext01_citation"] == EXT01_CITATION


def test_yoruba_restorer_enabled(restorer_env: None) -> None:
    assert yoruba_restorer_enabled(_YO_KIT, "yo") is True
    assert yoruba_restorer_enabled(_YO_KIT, "ig") is False
    assert yoruba_restorer_enabled({"tone_restorer": "none"}, "yo") is False


def test_P4_062_AC1_restorer_feeds_three_way_agreement(restorer_env: None) -> None:
    client = _RecordingRestorer()
    item = _item([_token(_FIXTURE_LEX, _FIXTURE_LEX)])
    stage = apply_naijaml_restorer(item, _YO_KIT, client)
    assert stage["status"] == "ok"
    assert stage["can_publish"] is True
    assert stage["tone_agreement"]["restorer"] == "naijaml"
    assert stage["restored_item"]["tokens"][0]["restorer"] == _FIXTURE_LEX
    assert client.calls[0]["payload"]["text"] == _FIXTURE_LEX


def test_P4_062_AC2_unavailable_routes_linguist(restorer_env: None) -> None:
    client = _RecordingRestorer(fail=True)
    stage = run_restorer_stage(
        _item([_token(_FIXTURE_GEN, _FIXTURE_LEX)]),
        _YO_KIT,
        client,
    )
    assert stage["status"] == "RESTORER_UNAVAILABLE"
    assert stage["code"] == "RESTORER_UNAVAILABLE"
    assert stage["route"] == "linguist"
    assert stage["can_publish"] is False


def test_build_payload_rejects_non_yoruba(restorer_env: None) -> None:
    with pytest.raises(RestorerError, match="Yoruba only"):
        build_restorer_payload("ha", "test", model=_FIXTURE_MODEL)


def test_read_routing_requires_model(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("CONTENT_ENGINE_NAIJAML_MODEL", raising=False)
    with pytest.raises(RestorerError, match="CONTENT_ENGINE_NAIJAML_MODEL"):
        read_restorer_routing()
