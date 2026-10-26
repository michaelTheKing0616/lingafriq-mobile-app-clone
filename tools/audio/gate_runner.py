"""TTS gate runner: ASR round-trip + F0 tone proxy (P5-059, CP-§7-yo-05/06)."""

from __future__ import annotations

import os
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from typing import Any

from tools.audio.f0_tone_proxy import (
    CARD_ID as F0_CARD_ID,
    ToneProxyError,
    assert_tone_proxy,
    gate_result_payload,
    nfc,
    normalize_tone_pattern,
)

CARD_ID = "P5-059"

AsrTranscribe = Callable[[bytes, str], str]
F0Extractor = Callable[[bytes, int], Sequence[float]]


class GateFailure(Exception):
    """Typed TTS gate rejection (AC3)."""

    def __init__(self, code: str, message: str, *, stage: str) -> None:
        self.code = code
        self.stage = stage
        super().__init__(message)


@dataclass(frozen=True)
class GateSuccess:
    source_text: str
    transcript: str
    tone_proxy: dict[str, Any] | None


def _normalize_match_text(text: str) -> str:
    return " ".join(nfc(text).split())


def intron_asr_available(env: Mapping[str, str] | None = None) -> bool:
    """Intron stays off until server flag and key are set (never client-side keys)."""
    source = env if env is not None else os.environ
    flag = source.get("AI_INTRON_ENABLED", "").strip().lower()
    key = source.get("INTRON_API_KEY", "").strip()
    return flag in {"1", "true", "yes", "on"} and bool(key)


def assert_asr_round_trip(
    source_text: str,
    transcript: str,
) -> None:
    ref = _normalize_match_text(source_text)
    hyp = _normalize_match_text(transcript)
    if ref != hyp:
        raise GateFailure(
            "ASR_TEXT_MISMATCH",
            f"ASR transcript does not match source (ref={ref!r}, hyp={hyp!r})",
            stage="asr",
        )


def run_asr_round_trip(
    *,
    source_text: str,
    audio: bytes,
    language_id: str,
    transcribe: AsrTranscribe | None = None,
    env: Mapping[str, str] | None = None,
) -> str:
    if not source_text.strip():
        raise GateFailure("SOURCE_TEXT_EMPTY", "source_text must be non-empty", stage="asr")
    if not audio:
        raise GateFailure("AUDIO_EMPTY", "audio payload must be non-empty", stage="asr")
    if transcribe is None:
        if not intron_asr_available(env):
            raise GateFailure(
                "INTRON_DISABLED",
                "Intron ASR round-trip requires AI_INTRON_ENABLED and INTRON_API_KEY",
                stage="asr",
            )
        raise GateFailure(
            "ASR_TRANSCRIBE_REQUIRED",
            "provide transcribe callable for Intron ASR round-trip",
            stage="asr",
        )
    transcript = transcribe(audio, language_id)
    assert_asr_round_trip(source_text, transcript)
    return transcript


def run_tts_gate(
    *,
    source_text: str,
    audio: bytes,
    language_id: str,
    tone_pattern: Sequence[str] | str | None = None,
    transcribe: AsrTranscribe | None = None,
    extract_f0: F0Extractor | None = None,
    env: Mapping[str, str] | None = None,
) -> GateSuccess:
    """Run ASR round-trip then optional F0 tone proxy for tonal languages."""
    transcript = run_asr_round_trip(
        source_text=source_text,
        audio=audio,
        language_id=language_id,
        transcribe=transcribe,
        env=env,
    )
    tone_payload: dict[str, Any] | None = None
    lang = language_id.strip().lower()
    if tone_pattern is not None and lang in {"yo", "ig", "ha"}:
        if extract_f0 is None:
            raise GateFailure(
                "F0_EXTRACTOR_REQUIRED",
                "tonal gate requires extract_f0(audio, syllable_count)",
                stage="f0",
            )
        expected_len = len(normalize_tone_pattern(tone_pattern))
        try:
            f0 = extract_f0(audio, expected_len)
            result = assert_tone_proxy(tone_pattern, f0, language_id=lang)
            tone_payload = gate_result_payload(result)
        except ToneProxyError as exc:
            raise GateFailure(exc.code, str(exc), stage="f0") from exc
    return GateSuccess(source_text=nfc(source_text), transcript=nfc(transcript), tone_proxy=tone_payload)


def evaluate_tts_gate(
    *,
    source_text: str,
    audio: bytes,
    language_id: str,
    tone_pattern: Sequence[str] | str | None = None,
    transcribe: AsrTranscribe | None = None,
    extract_f0: F0Extractor | None = None,
    env: Mapping[str, str] | None = None,
) -> dict[str, Any]:
    success = run_tts_gate(
        source_text=source_text,
        audio=audio,
        language_id=language_id,
        tone_pattern=tone_pattern,
        transcribe=transcribe,
        extract_f0=extract_f0,
        env=env,
    )
    body: dict[str, Any] = {
        "card_id": CARD_ID,
        "f0_card_id": F0_CARD_ID,
        "passed": True,
        "language_id": language_id,
        "source_text": success.source_text,
        "transcript": success.transcript,
    }
    if success.tone_proxy is not None:
        body["tone_proxy"] = success.tone_proxy
    return body
