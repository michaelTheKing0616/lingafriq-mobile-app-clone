"""Spec tests for back-translation stage (P4-059). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.backtranslate import (  # noqa: E402
    EXT01_CITATION,
    BacktranslateError,
    build_mt_payload,
    mt_provider_for_language,
    read_backtranslate_routing,
    run_backtranslate,
    semantic_similarity,
)

_FIXTURE_GOOGLE = "google-cloud-translate-v3"
_FIXTURE_MADLAD = "madlad-400-3b"


@pytest.fixture
def bt_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CONTENT_ENGINE_GOOGLE_MT_MODEL", _FIXTURE_GOOGLE)
    monkeypatch.setenv("CONTENT_ENGINE_MADLAD_MT_MODEL", _FIXTURE_MADLAD)


def _item(
    language: str = "yo",
    target_text: str = "fixture target",
    intended_meaning: str = "fixture intended meaning",
) -> dict[str, Any]:
    return {
        "language": language,
        "target_text": target_text,
        "intended_meaning": intended_meaning,
    }


class _RecordingMt:
    def __init__(self, english: str | None = None, *, fail: bool = False) -> None:
        self.calls: list[dict[str, Any]] = []
        self._english = english if english is not None else "fixture intended meaning"
        self._fail = fail

    def translate(
        self,
        provider: str,
        model: str,
        payload: dict[str, Any],
    ) -> str:
        self.calls.append(
            {"provider": provider, "model": model, "payload": dict(payload)},
        )
        if self._fail:
            raise RuntimeError("fixture MT down")
        return self._english


def test_read_routing_cites_ext01(bt_env: None) -> None:
    routing = read_backtranslate_routing()
    assert routing["google_mt_model"] == _FIXTURE_GOOGLE
    assert routing["madlad_mt_model"] == _FIXTURE_MADLAD
    assert routing["ext01_citation"] == EXT01_CITATION


def test_P4_059_AC1_google_for_yoruba(bt_env: None) -> None:
    assert mt_provider_for_language("yo") == "google_cloud"
    client = _RecordingMt()
    stage = run_backtranslate(_item(language="yo"), client)
    assert stage["provider"] == "google_cloud"
    assert stage["model"] == _FIXTURE_GOOGLE
    assert client.calls[0]["payload"]["source_language"] == "yo"


def test_P4_059_AC1_madlad_for_pidgin(bt_env: None) -> None:
    client = _RecordingMt()
    stage = run_backtranslate(_item(language="pcm"), client)
    assert stage["provider"] == "madlad"
    assert stage["model"] == _FIXTURE_MADLAD


def test_P4_059_AC2_low_similarity_flags_without_blocking_publish(
    bt_env: None,
) -> None:
    client = _RecordingMt(english="completely different gloss")
    stage = run_backtranslate(
        _item(intended_meaning="hello and goodbye"),
        client,
    )
    assert stage["status"] == "ok"
    assert stage["can_publish"] is True
    assert stage["flagged"] is True
    assert stage["back_translation"]["status"] == "flagged"


def test_P4_059_AC3_mt_unavailable_blocks_publish(bt_env: None) -> None:
    client = _RecordingMt(fail=True)
    stage = run_backtranslate(_item(), client)
    assert stage["status"] == "BT_UNAVAILABLE"
    assert stage["code"] == "BT_UNAVAILABLE"
    assert stage["can_publish"] is False


def test_stage_contract_happy_path(bt_env: None) -> None:
    intended = "fixture intended meaning"
    client = _RecordingMt(intended)
    stage = run_backtranslate(_item(intended_meaning=intended), client)
    assert stage["can_publish"] is True
    assert stage["flagged"] is False
    assert stage["back_translation"]["status"] == "pass"
    assert stage["features"]["backtranslation_similarity"] == pytest.approx(1.0)


def test_semantic_similarity_is_case_insensitive() -> None:
    assert semantic_similarity("Hello", "hello") == 1.0


def test_build_mt_payload_includes_provider(bt_env: None) -> None:
    payload = build_mt_payload(
        "ha",
        "text",
        provider="google_cloud",
        model=_FIXTURE_GOOGLE,
    )
    assert payload["provider"] == "google_cloud"
    assert payload["target_language"] == "en"


def test_read_routing_requires_google_model(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("CONTENT_ENGINE_GOOGLE_MT_MODEL", raising=False)
    monkeypatch.setenv("CONTENT_ENGINE_MADLAD_MT_MODEL", _FIXTURE_MADLAD)
    with pytest.raises(BacktranslateError, match="CONTENT_ENGINE_GOOGLE_MT_MODEL"):
        read_backtranslate_routing()
