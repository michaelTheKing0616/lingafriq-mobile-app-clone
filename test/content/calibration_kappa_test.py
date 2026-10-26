"""P5-045 calibration sets and Cohen κ (CURRICULUM §5)."""

from __future__ import annotations

import random
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.calibration_kappa import (  # noqa: E402
    CALIBRATION_METHOD,
    CALIBRATION_MIN_ITEMS,
    CALIBRATION_TARGET_ITEMS,
    CARD_ID,
    CalibrationKappaError,
    calibrate_confidence_score,
    compute_language_kappa,
    run_language_calibration,
    select_calibration_item_ids,
)
from tools.content_pipeline.review_agreement import cohens_kappa_binary  # noqa: E402


def _pair(approved_a: bool, approved_b: bool) -> dict:
    return {
        "item_id": "fixture",
        "reviewer_a": {"approved": approved_a},
        "reviewer_b": {"approved": approved_b},
    }


def _pairs(n: int, agree: bool = True) -> list[dict]:
    rows: list[dict] = []
    for i in range(n):
        a = i % 2 == 0
        b = a if agree else not a
        rows.append({**_pair(a, b), "item_id": f"yo.item.{i}"})
    return rows


def test_cohens_kappa_formula_perfect_agreement() -> None:
    assert cohens_kappa_binary([True, False, True], [True, False, True]) == 1.0


def test_select_calibration_about_three_hundred() -> None:
    ids = [f"yo.{i}" for i in range(400)]
    picked = select_calibration_item_ids(ids, rng=random.Random(0))
    assert len(picked) == CALIBRATION_TARGET_ITEMS


def test_incomplete_set_raises_calibration_incomplete() -> None:
    with pytest.raises(CalibrationKappaError) as exc:
        compute_language_kappa("yo", _pairs(CALIBRATION_MIN_ITEMS - 1))
    assert exc.value.code == "CalibrationIncomplete"


def test_complete_set_stores_kappa() -> None:
    store: dict = {}
    stats = run_language_calibration("yo", _pairs(CALIBRATION_MIN_ITEMS), store)
    assert stats["card_id"] == CARD_ID
    assert stats["sample_size"] == CALIBRATION_MIN_ITEMS
    assert stats["kappa_overall"] is not None
    assert store["by_language"]["yo"]["kappa_overall"] == stats["kappa_overall"]


def test_calibrate_confidence_records_method() -> None:
    out = calibrate_confidence_score(0.9, 1.0)
    assert out["method"] == CALIBRATION_METHOD
    assert out["calibrated_confidence"] == 0.9
    mid = calibrate_confidence_score(0.9, 0.0)
    assert mid["calibrated_confidence"] == 0.5
