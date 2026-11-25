"""P4-125 pilot cohort and promotion gate runner."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.pilot_gate import (  # noqa: E402
    CARD_ID,
    PILOT_WINDOW_WEEKS_MAX,
    PILOT_WINDOW_WEEKS_MIN,
    build_promotion_request,
    cohort_ready_for_promotion,
    pilot_timing_flags,
    run_pilot_promotion,
)
from tools.content_pipeline.schema_loader import SYNTHETIC_VOICE_TAG  # noqa: E402


def _cohort(**overrides: object) -> dict:
    body = {"declared_size": 50, "enrolled_count": 50, "weeks_elapsed": 7}
    body.update(overrides)
    return body


def _stats() -> dict:
    return {
        "yo.item.1": {"p_value": 0.72, "discrimination": 0.35, "response_count": 120},
    }


def _human_audio() -> dict:
    return {"kind": "human", "uri": "audio/yo/sample.ogg"}


def _synth_audio() -> dict:
    return {
        "kind": "tts_synthetic",
        "uri": "audio/yo/synth.ogg",
        "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
    }


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
        "items": [
            {
                "id": "yo.item.1",
                "label": "beta",
                "audio": [_synth_audio()],
            }
        ],
    }


def test_pilot_window_and_overdue() -> None:
    assert pilot_timing_flags(5)["window_open"] is False
    assert pilot_timing_flags(PILOT_WINDOW_WEEKS_MIN)["window_open"] is True
    assert pilot_timing_flags(PILOT_WINDOW_WEEKS_MAX)["overdue"] is False
    assert pilot_timing_flags(PILOT_WINDOW_WEEKS_MAX + 1)["overdue"] is True


def test_cohort_size_and_window() -> None:
    status = cohort_ready_for_promotion(_cohort(enrolled_count=40))
    assert status["size_met"] is False
    assert status["ready"] is False
    status = cohort_ready_for_promotion(_cohort(weeks_elapsed=3))
    assert status["ready"] is False
    assert cohort_ready_for_promotion(_cohort())["ready"] is True


def test_promotion_request_attaches_stats() -> None:
    req = build_promotion_request(_l1_manifest(), cohort=_cohort(), item_statistics=_stats())
    assert req["card_id"] == CARD_ID
    assert req["item_statistics_count"] == 1
    assert req["item_statistics"]["yo.item.1"]["p_value"] == 0.72
    assert req["cohort"]["ready"] is True


def test_promotion_lists_gate_failures_and_blocks() -> None:
    manifest = _l1_manifest()
    manifest["coverage"]["A1"] = "in_progress"
    out = run_pilot_promotion(manifest, cohort=_cohort(), item_statistics=_stats())
    assert out["promoted"] is False
    assert out["code"] == "PROMOTION_BLOCKED"
    assert manifest["readiness_level"] == "L0"
    assert any(not row["passed"] for row in out["gate_results"])


def test_promotion_succeeds_when_gates_pass() -> None:
    manifest = _l1_manifest()
    out = run_pilot_promotion(manifest, cohort=_cohort(), item_statistics=_stats())
    assert out["promoted"] is True
    assert manifest["readiness_level"] == "L1"
    assert all(row["passed"] for row in out["gate_results"] if row["gate"] == "L1")


def test_incomplete_cohort_refuses_promotion() -> None:
    manifest = _l1_manifest()
    out = run_pilot_promotion(
        manifest,
        cohort=_cohort(weeks_elapsed=9, enrolled_count=10),
        item_statistics=_stats(),
    )
    assert out["promoted"] is False
    assert out["code"] == "PILOT_OVERDUE_INCOMPLETE"
    assert manifest["readiness_level"] == "L0"
    assert out["cohort"]["overdue"] is True
