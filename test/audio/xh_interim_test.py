"""P5-069 isiXhosa FLEURS/WAXAL interim audio match and listen gate."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.xh_interim_match import (  # noqa: E402
    CARD_ID,
    LANGUAGE_ID,
    REQUIRED_LISTEN_SAMPLES,
    XhInterimError,
    assert_listen_batch_approved,
    assert_no_commercial_dynamic_tts,
    listen_batch_approved,
    lookup_interim_audio,
    parse_clip,
    parse_clips,
    parse_listen_batch,
    summary_payload,
    xh_click_inventory,
)


def _fleurs_clip(transcript: str, audio_ref: str = "fleurs/xh/1.wav") -> dict:
    return {
        "clip_id": "f1",
        "provider": "fleurs",
        "language": "xh",
        "transcript": transcript,
        "audio_ref": audio_ref,
        "licence_id": "fleurs",
        "text_scope": "own_sentences_only",
    }


def _waxal_clip(transcript: str, audio_ref: str = "waxal/xh/1.wav") -> dict:
    return {
        "clip_id": "w1",
        "provider": "waxal",
        "language": "xh",
        "transcript": transcript,
        "audio_ref": audio_ref,
        "licence_id": "waxal-other",
        "text_scope": "own_sentences_only",
        "register_id": "waxal-other",
        "subset_licence_verified": True,
    }


def test_card_constants() -> None:
    assert CARD_ID == "P5-069"
    assert LANGUAGE_ID == "xh"
    assert REQUIRED_LISTEN_SAMPLES == 100


def test_no_commercial_dynamic_tts() -> None:
    assert_no_commercial_dynamic_tts()


def test_fleurs_match_before_waxal_fallback() -> None:
    sentence = "Molo"
    clips = parse_clips(
        [
            _waxal_clip("Enkosi"),
            _fleurs_clip(sentence, "fleurs/xh/molo.wav"),
            _waxal_clip(sentence, "waxal/xh/molo.wav"),
        ]
    )
    match = lookup_interim_audio(sentence, clips)
    assert match.provider == "fleurs"
    assert match.audio_ref == "fleurs/xh/molo.wav"


def test_waxal_used_when_fleurs_missing() -> None:
    sentence = "Enkosi"
    clips = parse_clips([_waxal_clip(sentence)])
    match = lookup_interim_audio(sentence, clips)
    assert match.provider == "waxal"


def test_own_sentence_only_mismatch_raises() -> None:
    clips = parse_clips([_fleurs_clip("Molo")])
    with pytest.raises(XhInterimError) as exc:
        lookup_interim_audio("Enkosi", clips)
    assert exc.value.code == "NO_MATCH"


def test_waxal_without_subset_verification_fails() -> None:
    row = _waxal_clip("nceda")
    row["subset_licence_verified"] = False
    clip = parse_clip(row)
    with pytest.raises(XhInterimError) as exc:
        lookup_interim_audio("nceda", [clip])
    assert exc.value.code == "SUBSET_LICENCE_UNVERIFIED"


def test_click_inventory_and_listen_asr() -> None:
    assert xh_click_inventory("nceda") == ["c"]
    rows = []
    for i in range(100):
        rows.append(
            {
                "sample_id": f"s{i}",
                "source_text": "nceda",
                "audio_ref": f"xh/{i}.wav",
                "linguist_pass": True,
                "asr_transcript": "nceda",
                "asr_provider": "intron",
            }
        )
    samples = parse_listen_batch(rows)
    assert listen_batch_approved(samples)


def test_click_sentence_without_asr_fails_listen_batch() -> None:
    rows = [
        {
            "sample_id": "s0",
            "source_text": "nceda",
            "audio_ref": "xh/0.wav",
            "linguist_pass": True,
        }
    ]
    samples = parse_listen_batch(rows)
    with pytest.raises(XhInterimError) as exc:
        assert_listen_batch_approved(samples, required=1)
    assert exc.value.code == "CLICK_ASR_MISSING"


def test_listen_batch_requires_100_passes() -> None:
    rows = [
        {
            "sample_id": f"s{i}",
            "source_text": "Molo",
            "audio_ref": f"xh/{i}.wav",
            "linguist_pass": True,
        }
        for i in range(99)
    ]
    samples = parse_listen_batch(rows)
    assert not listen_batch_approved(samples)


def test_summary_payload() -> None:
    samples = parse_listen_batch(
        [{"sample_id": "a", "source_text": "Molo", "audio_ref": "a.wav", "linguist_pass": True}]
    )
    summary = summary_payload(samples)
    assert summary["card_id"] == "P5-069"
    assert summary["dynamic_tts_enabled"] is False
    assert summary["interim_sources"] == ["fleurs", "waxal"]


def test_load_clips_json_round_trip() -> None:
    from tools.audio.xh_interim_match import load_clips_json

    payload = json.dumps([_fleurs_clip("Molo")])
    clips = load_clips_json(payload)
    assert len(clips) == 1
