"""ADR-003 conformance: L1 audio readiness, tonal TTS gate, Xhosa path (P0 ADR-003)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-003.md"


def test_adr_003_exists_and_records_l1_audio_policy() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-21" in text
    for phrase in (
        "CONFLICTS C3",
        "L1 readiness",
        "tts_synthetic",
        "Synthetic voice",
        "native_verified",
        "G6",
        "G7",
        "yo",
        "ig",
        "ha",
        "tone-accuracy",
        "speech_eval.py",
        "TTS_GATE_FAIL",
        "isiXhosa",
        "EXT-12",
        "custom_voice_required",
        "readiness.py",
        "coverage_check.py",
    ):
        assert phrase in text


def test_adr_003_names_pipeline_conformance_checks() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "READINESS_L1_FAIL" in text
    assert "native_validation.py" in text
