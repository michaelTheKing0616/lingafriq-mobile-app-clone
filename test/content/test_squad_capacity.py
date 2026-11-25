"""P4-126 squad capacity planner."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.squad_capacity import (  # noqa: E402
    CARD_ID,
    DEFAULT_WAVE_SIZE,
    PLANNING_ASSUMPTION_LABEL,
    SquadCapacityError,
    assess_parallel_languages,
    build_capacity_report,
    marginal_language_effort,
    project_wave_throughput,
    validate_squad_spec,
)


def _langs(n: int) -> list[str]:
    return [f"lang_{i}" for i in range(n)]


def _squad(parallel: int, squad_id: str = "alpha") -> dict:
    return {
        "squad_id": squad_id,
        "lead_count": 1,
        "writer_count": 2,
        "linguist_hours_per_week": 8,
        "reviewer_panels": 3,
        "parallel_languages": _langs(parallel),
    }


def test_parallel_band_and_overcommitted() -> None:
    status = assess_parallel_languages(_langs(5))
    assert status["within_band"] is True
    assert status["parallel_count"] == 5
    with pytest.raises(SquadCapacityError) as exc:
        assess_parallel_languages(_langs(7))
    assert exc.value.code == "OVERCOMMITTED"


def test_squad_roster_shape() -> None:
    row = validate_squad_spec(_squad(4))
    assert row["squad_id"] == "alpha"
    assert row["writer_count"] == 2
    bad = dict(_squad(4), writer_count=1)
    with pytest.raises(SquadCapacityError) as exc:
        validate_squad_spec(bad)
    assert exc.value.code == "SQUAD_INVALID"


def test_wave_eta_two_squads_planning_assumption() -> None:
    squads = [_squad(5, "a"), _squad(5, "b")]
    report = project_wave_throughput(squads, wave_size=DEFAULT_WAVE_SIZE)
    assert report["card_id"] == CARD_ID
    assert report["squad_count"] == 2
    assert report["parallel_slots"] == 10
    assert report["quarters_needed"] == 2
    assert report["meets_two_quarter_target"] is True
    assert report["eta_basis"] == PLANNING_ASSUMPTION_LABEL


def test_wave_eta_three_squads_clears_fourteen() -> None:
    squads = [_squad(5, "a"), _squad(5, "b"), _squad(4, "c")]
    report = project_wave_throughput(squads, wave_size=14)
    assert report["parallel_slots"] == 14
    assert report["quarters_needed"] == 1
    assert report["meets_two_quarter_target"] is True


def test_marginal_cost_excludes_tooling() -> None:
    effort = marginal_language_effort(reviewer_hours=12, voice_hours=40)
    assert effort["tooling_hours"] == 0.0
    assert effort["reviewer_hours"] == 12.0
    assert effort["voice_hours"] == 40.0
    assert "validators" in effort["shared_tooling"][1]


def test_build_capacity_report_wraps_projection() -> None:
    out = build_capacity_report([_squad(6)])
    assert out["card_id"] == CARD_ID
    assert out["projection"]["wave_size"] == DEFAULT_WAVE_SIZE
