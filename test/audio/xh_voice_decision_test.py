"""P5-068 isiXhosa voice-path decision artefact."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.xh_voice_decision import (  # noqa: E402
    CARD_ID,
    LANGUAGE_ID,
    XhVoiceDecisionError,
    load_xh_voice_decision,
    validate_xh_voice_decision,
    xh_dynamic_tts_enabled,
    xh_interim_audio_sources,
)


def test_decision_file_validates() -> None:
    data = load_xh_voice_decision()
    validate_xh_voice_decision(data)
    assert data["card_id"] == CARD_ID
    assert data["language_id"] == LANGUAGE_ID


def test_option_b_custom_voice_option_a_interim() -> None:
    voice = load_xh_voice_decision()["voice_path"]
    assert voice["option_b_primary"]["id"] == "custom_voice_commission"
    assert voice["option_a_interim"]["id"] == "corpus_matched_audio"
    assert voice["option_b_primary"]["procurement_blocker"] == "EXT-12"


def test_dynamic_tts_stays_off() -> None:
    assert xh_dynamic_tts_enabled() is False


def test_interim_sources_for_p5_069() -> None:
    assert xh_interim_audio_sources() == ["fleurs", "waxal"]


def test_wrong_option_b_fails() -> None:
    data = load_xh_voice_decision()
    bad = dict(data)
    voice = dict(data["voice_path"])
    opt_b = dict(voice["option_b_primary"])
    opt_b["id"] = "azure_neural"
    voice["option_b_primary"] = opt_b
    bad["voice_path"] = voice
    with pytest.raises(XhVoiceDecisionError) as exc:
        validate_xh_voice_decision(bad)
    assert exc.value.code == "OPTION_B"
