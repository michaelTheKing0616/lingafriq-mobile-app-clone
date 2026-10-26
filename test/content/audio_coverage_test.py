"""P5-058 audio coverage publish gate."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.audio_coverage_gate import (  # noqa: E402
    CARD_ID,
    AudioCoverageError,
    assert_batch_published_audio,
    assert_published_item_audio,
    evaluate_audio_coverage_gate,
    item_spoken_text,
)
from tools.content_engine.legacy.structure import audio_content_hash  # noqa: E402
from tools.content_pipeline.schema_loader import SYNTHETIC_VOICE_TAG  # noqa: E402

_SPOKEN = "\u00e0\u00e1r\u1ecd\u0300"


def _base_item(**overrides: object) -> dict[str, Any]:
    digest = audio_content_hash(_SPOKEN)
    body: dict[str, Any] = {
        "id": "yo.item.audio.fixture",
        "stimulus": {"text": _SPOKEN},
        "audio": [
            {
                "kind": "human",
                "uri": f"audio/yo/{digest}.ogg",
                "transcript": _SPOKEN,
            }
        ],
    }
    body.update(overrides)
    return body


def test_P5_058_AC1_missing_audio_blocks_publish() -> None:
    with pytest.raises(AudioCoverageError) as exc:
        assert_published_item_audio(_base_item(audio=[]))
    assert exc.value.code == "AUDIO_MISSING"


def test_P5_058_AC2_tts_requires_synthetic_voice_tag() -> None:
    item = _base_item(
        audio=[{"kind": "tts", "uri": "audio/yo/synth.ogg"}],
    )
    with pytest.raises(AudioCoverageError) as exc:
        assert_published_item_audio(item)
    assert exc.value.code == "SYNTHETIC_TAG_MISSING"

    ok = _base_item(
        audio=[
            {
                "kind": "tts",
                "uri": "audio/yo/synth.ogg",
                "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
            }
        ],
    )
    assert_published_item_audio(ok)


def test_P5_058_AC3_human_text_mismatch() -> None:
    digest = audio_content_hash(_SPOKEN)
    item = _base_item(
        audio=[
            {
                "kind": "human",
                "uri": f"audio/yo/{digest}.ogg",
                "transcript": "\u1ecd\u0300k\u1ecd\u0300",
            }
        ],
    )
    with pytest.raises(AudioCoverageError) as exc:
        assert_published_item_audio(item)
    assert exc.value.code == "AudioTextMismatch"


def test_item_spoken_text_prefers_stimulus() -> None:
    item = {
        "stimulus": {"text": _SPOKEN},
        "answer_spec": {"correct": "other"},
    }
    assert item_spoken_text(item) == _SPOKEN


def test_evaluate_audio_coverage_gate_report() -> None:
    report = evaluate_audio_coverage_gate(_base_item())
    assert report["card_id"] == CARD_ID
    assert report["passed"] is True
    assert report["clip_count"] == 1


def test_human_audio_matches_via_text_hash() -> None:
    digest = audio_content_hash(_SPOKEN)
    item = _base_item(
        audio=[{"kind": "human", "uri": f"audio/yo/{digest}.ogg", "text_hash": digest}],
    )
    assert_published_item_audio(item)


def test_tts_synthetic_kind_and_batch() -> None:
    synth = _base_item(
        audio=[
            {
                "kind": "tts_synthetic",
                "uri": "audio/yo/x.ogg",
                "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
            }
        ],
    )
    assert_published_item_audio(synth)
    assert_batch_published_audio([_base_item(), synth])


def test_evaluate_reports_failure() -> None:
    report = evaluate_audio_coverage_gate(_base_item(audio=[]))
    assert report["passed"] is False
    assert report["code"] == "AUDIO_MISSING"


def test_invalid_audio_kind() -> None:
    with pytest.raises(AudioCoverageError) as exc:
        assert_published_item_audio(
            _base_item(audio=[{"kind": "robot", "uri": "audio/yo/x.ogg"}]),
        )
    assert exc.value.code == "AUDIO_KIND_INVALID"


def test_item_spoken_text_answer_fallback() -> None:
    assert item_spoken_text({"answer_spec": {"correct": _SPOKEN}}) == _SPOKEN
