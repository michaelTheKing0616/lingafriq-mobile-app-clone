"""ADR-008 conformance: Stage-1 TTS vendors and licence exclusions (P6-045 AC)."""

from __future__ import annotations

import csv
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-008-tts-vendors.md"
_REGISTER = _REPO_ROOT / "docs/build/licence_register.csv"


def test_adr_008_exists_and_records_stage1_vendors() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    for phrase in (
        "Intron TTS",
        "Spitch",
        "Chirp 3 HD",
        "Azure",
        "zu-ZA",
        "Commissioned custom voice",
        "voice_coming",
        "LINGAFRIQ_AI_MODEL_STACK",
        "sw_tts_decision.json",
    ):
        assert phrase in text
    for lang in ("Yoruba", "Igbo", "Hausa", "Nigerian Pidgin", "Swahili", "isiZulu", "isiXhosa"):
        assert lang in text


def test_adr_008_excluded_models_in_licence_register() -> None:
    text = _ADR.read_text(encoding="utf-8")
    for name in ("YarnGPT", "MMS-TTS", "XTTS-v2"):
        assert name in text
    rows = {r["model_id"]: r for r in csv.DictReader(_REGISTER.read_text(encoding="utf-8").splitlines())}
    for model_id in ("yarn-gpt", "mms-tts", "coqui-xtts-v2"):
        assert model_id in rows
        assert rows[model_id]["commercial_use"].lower() == "no"
