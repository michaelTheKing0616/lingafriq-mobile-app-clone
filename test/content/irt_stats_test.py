"""P5-048 IRT item statistics and abnormal flags."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.irt_stats import (  # noqa: E402
    CARD_ID,
    DEFAULT_MIN_RESPONSES,
    IrtFlagThresholds,
    IrtStatsError,
    compute_irt_item_statistics,
    compute_item_irt_row,
)


def _responses(
    n: int,
    *,
    item: str = "yo.item.1",
    p_correct: float = 0.65,
) -> list[dict]:
    rows: list[dict] = []
    for i in range(n):
        rows.append(
            {
                "item_id": item,
                "person_id": f"p{i}",
                "correct": i < int(n * p_correct),
            }
        )
    return rows


def test_estimator_returns_difficulty_and_discrimination_with_enough_data() -> None:
    rows = _responses(40, p_correct=0.7)
    for i in range(40):
        rows.append(
            {
                "item_id": "yo.item.2",
                "person_id": f"p{i}",
                "correct": i >= 12,
            }
        )
    out = compute_irt_item_statistics(rows, min_responses=30)
    assert out["card_id"] == CARD_ID
    stat = out["item_statistics"]["yo.item.1"]
    assert stat["status"] == "ok"
    assert stat["difficulty"] is not None
    assert stat["discrimination"] is not None
    assert stat["discrimination"] > 0


def test_insufficient_data_below_minimum() -> None:
    out = compute_irt_item_statistics(_responses(10), min_responses=30)
    stat = out["item_statistics"]["yo.item.1"]
    assert stat["status"] == "InsufficientData"
    assert stat["difficulty"] is None
    assert stat["discrimination"] is None
    assert stat["flagged_for_review"] is False


def test_flags_expert_failure_and_low_discrimination() -> None:
    expert = [{"item_id": "yo.item.1", "passed": False}]
    out = compute_irt_item_statistics(_responses(35), expert_failures=expert, min_responses=30)
    assert out["item_statistics"]["yo.item.1"]["flagged_for_review"] is True
    assert out["item_statistics"]["yo.item.1"]["flag_reasons"] == ["expert_failed"]

    flat = compute_item_irt_row(
        {
            "item_id": "flat",
            "sample_size": 40,
            "calibrated": True,
            "a": 0.2,
            "b": 0.0,
            "fit": 0.1,
        },
        min_responses=30,
        expert_failed=False,
        thresholds=IrtFlagThresholds(discrimination_floor=0.35),
    )
    assert flat["flagged_for_review"] is True
    assert "low_discrimination" in flat["flag_reasons"]


def test_degenerate_all_correct_flags_no_variance() -> None:
    rows = [
        {"item_id": "easy", "person_id": f"p{i}", "correct": True}
        for i in range(35)
    ]
    out = compute_irt_item_statistics(rows, min_responses=30)
    stat = out["item_statistics"]["easy"]
    assert stat["status"] == "degenerate_responses"
    assert stat["flagged_for_review"] is True
    assert stat["flag_reasons"] == ["no_variance"]


def test_cli_round_trip() -> None:
    script = _REPO_ROOT / "tools/content/irt_stats.py"
    payload = {"responses": _responses(32), "min_responses": 30}
    proc = subprocess.run(
        [sys.executable, str(script)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=False,
        cwd=_REPO_ROOT,
    )
    assert proc.returncode == 0
    body = json.loads(proc.stdout)
    assert body["ok"] is True
    assert body["data"]["item_statistics_count"] == 1


def test_rejects_invalid_response() -> None:
    with pytest.raises(IrtStatsError) as exc:
        compute_irt_item_statistics([{"item_id": "", "person_id": "p1", "correct": True}])
    assert exc.value.code == "RESPONSE_INVALID"
