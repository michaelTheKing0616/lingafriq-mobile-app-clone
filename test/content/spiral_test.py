"""P5-018 spiral exposure planner."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.spiral_planner import (  # noqa: E402
    EXPOSURE_PHASES,
    MIN_EXPOSURES,
    SpiralShortfall,
    build_spiral_plan,
    build_spiral_plan_for_language,
    lint_spiral_plan,
    list_a1_units,
    load_map,
    plan_lexeme_exposures,
)


def _units(n: int, prefix: str = "yoruba-A1") -> list[str]:
    return [f"{prefix}-u{i}" for i in range(1, n + 1)]


def test_P5_018_AC1_six_exposures_across_units() -> None:
    unit_keys = _units(8)
    exposures = plan_lexeme_exposures("yo.lex.fixture", 3, unit_keys)
    assert len(exposures) == MIN_EXPOSURES
    units = {row.unit_key for row in exposures}
    assert len(units) == MIN_EXPOSURES


def test_P5_018_AC2_phase_progression() -> None:
    unit_keys = _units(6)
    exposures = plan_lexeme_exposures("yo.lex.fixture", 0, unit_keys)
    assert [row.phase for row in exposures] == list(EXPOSURE_PHASES)


def test_P5_018_AC3_spiral_shortfall_lists_lexemes() -> None:
    plan = {
        "min_exposures": 6,
        "lexeme_count": 2,
        "lexeme_ids": ["a", "b"],
        "exposures": [
            {"lexeme_id": "a", "unit_key": "u1", "phase": "input", "sequence": 1},
            {"lexeme_id": "b", "unit_key": "u1", "phase": "input", "sequence": 1},
        ],
    }
    with pytest.raises(SpiralShortfall) as exc:
        lint_spiral_plan(plan)
    assert "a" in exc.value.lexeme_ids
    assert "b" in exc.value.lexeme_ids


def test_P5_018_build_plan_lints_clean_for_fixture() -> None:
    lexemes = [{"id": f"lex.{i}"} for i in range(4)]
    plan = build_spiral_plan("yo", lexemes=lexemes, unit_keys=_units(7))
    assert plan["lexeme_count"] == 4
    assert len(plan["exposures"]) == 4 * MIN_EXPOSURES


def test_P5_018_repo_yoruba_a1_plan() -> None:
    plan = build_spiral_plan_for_language("yo")
    assert plan["lexeme_count"] >= 600
    lint_spiral_plan(plan)


def test_P5_018_list_a1_units_from_cando_map() -> None:
    doc = load_map()
    units = list_a1_units(doc, "yo")
    assert len(units) >= MIN_EXPOSURES
    assert units[0].startswith("yoruba-A1-u")
