"""P4-110 readiness levels L0–L3 and promotion gates."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.readiness import (  # noqa: E402
    ReadinessError,
    gate_readiness,
    promote_native_verified,
    request_promotion,
)
from tools.content_pipeline.schema_loader import SYNTHETIC_VOICE_TAG  # noqa: E402


def _human_audio() -> dict:
    return {"kind": "human", "uri": "audio/yo/sample.ogg"}


def _synth_audio() -> dict:
    return {
        "kind": "tts_synthetic",
        "uri": "audio/yo/synth.ogg",
        "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
    }


def _item(item_id: str, *, label: str = "beta", audio: list | None = None) -> dict:
    return {
        "id": item_id,
        "label": label,
        "audio": audio if audio is not None else [_human_audio()],
    }


def _l0_manifest(**overrides: object) -> dict:
    body = {
        "language": "yo",
        "readiness_level": "L0",
        "inventory": {
            "has_greetings": True,
            "has_numbers": True,
            "word_count": 60,
            "culture_card_count": 1,
            "recorded_voice_ids": ["voice_a", "voice_b"],
        },
        "coverage": {"A1": "in_progress", "A2": "missing", "B1": "missing"},
        "features": {},
        "items": [],
    }
    body.update(overrides)
    return body


def _l1_manifest() -> dict:
    return {
        "language": "yo",
        "readiness_level": "L0",
        "inventory": {
            "has_greetings": True,
            "has_numbers": True,
            "word_count": 80,
            "culture_card_count": 2,
            "recorded_voice_ids": ["voice_a", "voice_b"],
        },
        "coverage": {"A1": "complete", "A2": "missing", "B1": "missing"},
        "features": {"asr_understood_feedback": True},
        "items": [_item("yo.item.1"), _item("yo.item.2", audio=[_synth_audio()])],
    }


def _l2_manifest() -> dict:
    return {
        "language": "yo",
        "readiness_level": "L1",
        "inventory": {
            "has_greetings": True,
            "has_numbers": True,
            "word_count": 90,
            "culture_card_count": 2,
            "recorded_voice_ids": ["v1", "v2", "v3", "v4"],
        },
        "coverage": {"A1": "complete", "A2": "complete", "B1": "missing"},
        "features": {
            "asr_understood_feedback": True,
            "tone_scoring": True,
            "pronunciation_scoring": True,
            "dynamic_tts": True,
            "ai_tutor_modes": True,
        },
        "items": [_item("yo.item.1")],
    }


def _l3_manifest() -> dict:
    return {
        "language": "yo",
        "readiness_level": "L2",
        "inventory": {
            "has_greetings": True,
            "has_numbers": True,
            "word_count": 90,
            "culture_card_count": 2,
            "recorded_voice_ids": ["v1", "v2", "v3", "v4"],
        },
        "coverage": {"A1": "complete", "A2": "complete", "B1": "complete"},
        "features": {
            "realtime_voice": True,
            "personas": True,
            "credential_checkpoints": True,
        },
        "evals": {"realtime_voice": "pass", "persona": "pass"},
        "items": [],
    }


def test_l0_fail_lists_missing() -> None:
    manifest = _l0_manifest(
        inventory={
            "has_greetings": False,
            "has_numbers": True,
            "word_count": 10,
            "culture_card_count": 0,
            "recorded_voice_ids": ["only_one"],
        }
    )
    result = gate_readiness(manifest, "L0")
    assert not result.passed
    assert result.code == "READINESS_L0_FAIL"
    assert "greetings" in result.missing
    assert "words>=50" in result.missing


def test_l0_passes_fixture() -> None:
    assert gate_readiness(_l0_manifest(), "L0").passed


def test_l1_requires_a1_and_gated_audio() -> None:
    bad = _l1_manifest()
    bad["items"] = [_item("x", audio=[{"kind": "tts_synthetic", "uri": "a.ogg"}])]
    result = gate_readiness(bad, "L1")
    assert not result.passed
    assert any("item_audio" in m for m in result.missing)


def test_l1_passes_fixture() -> None:
    assert gate_readiness(_l1_manifest(), "L1").passed


def test_l2_and_l3_fixtures() -> None:
    assert gate_readiness(_l2_manifest(), "L2").passed
    assert gate_readiness(_l3_manifest(), "L3").passed


def test_promotion_blocked_leaves_level() -> None:
    manifest = _l0_manifest()
    out = request_promotion(manifest)
    assert out["promoted"] is False
    assert out["code"] == "PROMOTION_BLOCKED"
    assert manifest["readiness_level"] == "L0"
    assert out["target_level"] == "L1"


def test_promotion_one_step_when_gates_pass() -> None:
    manifest = _l1_manifest()
    out = request_promotion(manifest)
    assert out["promoted"] is True
    assert manifest["readiness_level"] == "L1"
    assert out["previous_level"] == "L0"


def test_native_verified_promotion() -> None:
    items = [
        {
            "id": "yo.lex.a",
            "label": "beta",
            "audio": [_human_audio()],
            "review": {
                "reviewers": [
                    {"reviewer_id": "n1", "role": "native", "approved": True},
                    {"reviewer_id": "n2", "role": "native", "approved": True},
                ]
            },
        }
    ]
    out = promote_native_verified(items)
    assert out[0]["label"] == "native_verified"


def test_native_verified_rejects_synth_only() -> None:
    items = [
        {
            "id": "yo.lex.a",
            "label": "expert_reviewed",
            "audio": [_synth_audio()],
            "review": {
                "reviewers": [
                    {"reviewer_id": "n1", "role": "native", "approved": True},
                    {"reviewer_id": "n2", "role": "native", "approved": True},
                ]
            },
        }
    ]
    with pytest.raises(ReadinessError) as exc:
        promote_native_verified(items)
    assert exc.value.code == "NATIVE_VERIFY_BLOCKED"
