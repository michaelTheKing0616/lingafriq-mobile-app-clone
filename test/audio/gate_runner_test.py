"""P5-059 TTS gate runner: ASR round-trip + F0 tone proxy."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.f0_tone_proxy import (  # noqa: E402
    ToneProxyError,
    compare_f0_to_tone_pattern,
    f0_to_relative_levels,
    normalize_tone_pattern,
)
from tools.audio.gate_runner import (  # noqa: E402
    CARD_ID,
    GateFailure,
    assert_asr_round_trip,
    evaluate_tts_gate,
    intron_asr_available,
    run_tts_gate,
)

_SOURCE = "\u00e0\u00e1r\u1ecd\u0300"
_AUDIO = b"\x00\x01fake-tts-bytes"


def test_normalize_tone_pattern_string_and_sequence() -> None:
    assert normalize_tone_pattern("H-M-L") == ("H", "M", "L")
    assert normalize_tone_pattern(["h", "m", "l"]) == ("H", "M", "L")


def test_f0_relative_levels_three_syllables() -> None:
    observed = f0_to_relative_levels([100.0, 220.0, 150.0])
    assert observed == ("L", "H", "M")


def test_f0_matcher_pass_and_fail() -> None:
    ok = compare_f0_to_tone_pattern(["L", "H", "M"], [100.0, 220.0, 150.0])
    assert ok.matched
    bad = compare_f0_to_tone_pattern(["H", "H", "H"], [100.0, 220.0, 150.0])
    assert not bad.matched
    with pytest.raises(ToneProxyError) as exc:
        compare_f0_to_tone_pattern(["H", "L"], [100.0, 200.0, 120.0])
    assert exc.value.code == "F0_SYLLABLE_COUNT"


def test_asr_round_trip_matcher() -> None:
    assert_asr_round_trip(_SOURCE, _SOURCE)
    with pytest.raises(GateFailure) as exc:
        assert_asr_round_trip(_SOURCE, "other")
    assert exc.value.code == "ASR_TEXT_MISMATCH"
    assert exc.value.stage == "asr"


def test_intron_disabled_without_env() -> None:
    assert not intron_asr_available({})
    with pytest.raises(GateFailure) as exc:
        run_tts_gate(
            source_text=_SOURCE,
            audio=_AUDIO,
            language_id="yo",
            env={},
        )
    assert exc.value.code == "INTRON_DISABLED"


def test_gate_pass_with_asr_stub() -> None:
    def transcribe(_audio: bytes, _lang: str) -> str:
        return _SOURCE

    result = run_tts_gate(
        source_text=_SOURCE,
        audio=_AUDIO,
        language_id="sw",
        transcribe=transcribe,
    )
    assert result.transcript == _SOURCE
    assert result.tone_proxy is None


def test_gate_pass_with_asr_and_f0_stubs() -> None:
    pattern = ("L", "H", "M")

    def transcribe(_audio: bytes, _lang: str) -> str:
        return _SOURCE

    def extract_f0(_audio: bytes, syllables: int) -> list[float]:
        assert syllables == 3
        return [100.0, 220.0, 150.0]

    payload = evaluate_tts_gate(
        source_text=_SOURCE,
        audio=_AUDIO,
        language_id="yo",
        tone_pattern=pattern,
        transcribe=transcribe,
        extract_f0=extract_f0,
    )
    assert payload["card_id"] == CARD_ID
    assert payload["passed"] is True
    assert payload["tone_proxy"]["matched"] is True


def test_gate_failure_f0_mismatch_typed() -> None:
    def transcribe(_audio: bytes, _lang: str) -> str:
        return _SOURCE

    def extract_f0(_audio: bytes, _syllables: int) -> list[float]:
        return [100.0, 220.0, 150.0]

    with pytest.raises(GateFailure) as exc:
        run_tts_gate(
            source_text=_SOURCE,
            audio=_AUDIO,
            language_id="yo",
            tone_pattern=("H", "H", "H"),
            transcribe=transcribe,
            extract_f0=extract_f0,
        )
    assert exc.value.code == "F0_TONE_MISMATCH"
    assert exc.value.stage == "f0"
