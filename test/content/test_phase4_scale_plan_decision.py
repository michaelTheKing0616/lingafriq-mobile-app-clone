"""P5-080 Phase 4 scale plan ADR artefact."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.phase4_scale_plan_decision import (  # noqa: E402
    CARD_ID,
    Phase4ScalePlanError,
    load_phase4_scale_plan_decision,
    milestone_by_id,
    validate_phase4_scale_plan_decision,
    wave2_a1_beta_language_count,
    wave3_l0_language_count,
)


def test_decision_file_validates() -> None:
    data = load_phase4_scale_plan_decision()
    validate_phase4_scale_plan_decision(data)
    assert data["card_id"] == CARD_ID
    assert data["window"]["start_month"] == 9
    assert data["window"]["end_month"] == 24


def test_milestones_align_with_wave_roster_sizes() -> None:
    wave2 = milestone_by_id(load_phase4_scale_plan_decision(), "wave2_a1_beta")
    assert "fourteen" in wave2["summary"].lower() or "14" in wave2["summary"]
    assert wave2_a1_beta_language_count() == 14
    wave3 = milestone_by_id(load_phase4_scale_plan_decision(), "wave3_l0_taste")
    assert wave3_l0_language_count() == 25


def test_native_audio_top_set_2000() -> None:
    native = milestone_by_id(load_phase4_scale_plan_decision(), "native_audio_by_exposure")
    assert "2000" in native["summary"]
    assert "exposure_rank" in native["summary"] or "P5-072" in native["summary"]


def test_missing_milestone_fails() -> None:
    data = load_phase4_scale_plan_decision()
    bad = dict(data)
    bad["milestones"] = [m for m in data["milestones"] if m["id"] != "wave3_l0_taste"]
    with pytest.raises(Phase4ScalePlanError) as exc:
        validate_phase4_scale_plan_decision(bad)
    assert exc.value.code == "MILESTONES_INCOMPLETE"
