"""Spec tests for routing threshold calibration (P4-066). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.calibration import (  # noqa: E402
    CARD_ID,
    CalibrationError,
    CalibrationVersionStore,
    DEFAULT_THRESHOLDS,
    RoutingThresholds,
    report_auto_publish_errors,
    tune_thresholds,
    would_auto_publish_beta,
)


def _pilot_item(
    language: str,
    score: float,
    *,
    linters_pass: bool = True,
    linguist_accepted: bool = True,
    high_risk_tags: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "language": language,
        "score": score,
        "linters_pass": linters_pass,
        "linguist_accepted": linguist_accepted,
        "high_risk_tags": high_risk_tags or [],
    }


def test_P4_066_AC1_report_per_language_with_sample_size() -> None:
    pilot = [
        _pilot_item("sw", 0.95, linguist_accepted=True),
        _pilot_item("sw", 0.92, linguist_accepted=False),
        _pilot_item("yo", 0.91, linguist_accepted=True),
        _pilot_item("yo", 0.50, linguist_accepted=False),
    ]
    report = report_auto_publish_errors(pilot)
    assert report["card_id"] == CARD_ID
    sw = report["per_language"]["sw"]
    assert sw["pilot_sample_size"] == 2
    assert sw["auto_publish_count"] == 2
    assert sw["error_count"] == 1
    assert sw["error_rate"] == 0.5
    yo = report["per_language"]["yo"]
    assert yo["pilot_sample_size"] == 2
    assert yo["auto_publish_count"] == 1
    assert yo["error_count"] == 0
    assert yo["error_rate"] == 0.0


def test_P4_066_auto_publish_respects_high_risk_and_linters() -> None:
    assert would_auto_publish_beta(score=0.99, linters_pass=True, high_risk_tags=["idiom"]) is False
    assert would_auto_publish_beta(score=0.99, linters_pass=False) is False
    assert would_auto_publish_beta(score=0.89, linters_pass=True) is False
    assert would_auto_publish_beta(score=0.90, linters_pass=True) is True


def test_P4_066_tune_raises_auto_beta_when_errors_exceed_target() -> None:
    pilot = [
        _pilot_item("sw", 0.91, linguist_accepted=False),
        _pilot_item("sw", 0.92, linguist_accepted=True),
        _pilot_item("sw", 0.93, linguist_accepted=True),
        _pilot_item("sw", 0.94, linguist_accepted=True),
    ]
    tuned = tune_thresholds(pilot, max_beta_error_rate=0.0)
    assert tuned["recommended_thresholds"]["auto_beta"] > DEFAULT_THRESHOLDS.auto_beta
    sw = tuned["pilot_report"]["per_language"]["sw"]
    assert sw["error_count"] == 0


def test_P4_066_AC2_version_store_keeps_old_thresholds_and_report() -> None:
    store = CalibrationVersionStore()
    old = RoutingThresholds(0.90, 0.70)
    new = RoutingThresholds(0.93, 0.70)
    report = report_auto_publish_errors([_pilot_item("ha", 0.95)])
    saved = store.save_threshold_change(
        old_thresholds=old,
        new_thresholds=new,
        pilot_report=report,
    )
    assert saved["version"] == 1
    assert saved["old_thresholds"]["auto_beta"] == 0.90
    assert saved["new_thresholds"]["auto_beta"] == 0.93
    assert saved["pilot_report"]["per_language"]["ha"]["pilot_sample_size"] == 1

    second = store.save_threshold_change(
        old_thresholds=new,
        new_thresholds=RoutingThresholds(0.94, 0.70),
        pilot_report=report,
    )
    assert second["version"] == 2
    assert len(store.versions) == 2


def test_P4_066_invalid_pilot_raises() -> None:
    with pytest.raises(CalibrationError):
        report_auto_publish_errors([{"language": "sw"}])
