"""P4-134 pilot item statistics."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.item_stats import (  # noqa: E402
    CARD_ID,
    DEFAULT_BOUNDS,
    ItemStatsBounds,
    ItemStatsError,
    aggregate_item_statistics,
    compute_item_stat_row,
    studio_feed_from_aggregate,
)
from tools.content_pipeline.pilot_gate import build_promotion_request  # noqa: E402


def _responses(n: int, *, item: str = "yo.item.1", p_correct: float = 0.7) -> list[dict]:
    rows: list[dict] = []
    for i in range(n):
        rows.append(
            {
                "item_id": item,
                "person_id": f"p{i}",
                "correct": i < int(n * p_correct),
                "time_ms": 1000 + i * 10,
                "hint_used": i % 5 == 0,
            }
        )
    return rows


def test_aggregate_includes_p_discrimination_median_time_and_hint_rate() -> None:
    rows = _responses(40, p_correct=0.75)
    # second item with varied ability for discrimination
    for i in range(40):
        rows.append(
            {
                "item_id": "yo.item.2",
                "person_id": f"p{i}",
                "correct": i >= 20,
                "time_ms": 2000.0,
                "hint_used": False,
            }
        )
    out = aggregate_item_statistics(rows, min_responses=30)
    assert out["card_id"] == CARD_ID
    stat = out["item_statistics"]["yo.item.1"]
    assert stat["insufficient_data"] is False
    assert stat["p_value"] == pytest.approx(0.75, abs=0.05)
    assert stat["discrimination"] is not None
    assert stat["median_time_ms"] is not None
    assert stat["hint_use_rate"] == pytest.approx(0.2, abs=0.05)


def test_insufficient_data_below_minimum() -> None:
    out = aggregate_item_statistics(_responses(10), min_responses=30)
    stat = out["item_statistics"]["yo.item.1"]
    assert stat["insufficient_data"] is True
    assert stat["p_value"] is None
    assert stat["discrimination"] is None
    assert stat["median_time_ms"] is None
    assert stat["hint_use_rate"] is None
    assert stat["flagged_for_revision"] is False


def test_flags_revision_when_p_value_or_discrimination_out_of_bounds() -> None:
    easy = compute_item_stat_row(
        "easy",
        [{"item_id": "easy", "person_id": f"p{i}", "correct": True, "time_ms": 1, "hint_used": False} for i in range(30)],
        {f"p{i}": 1.0 for i in range(30)},
        min_responses=30,
        bounds=DEFAULT_BOUNDS,
    )
    assert easy["p_value"] == 1.0
    assert easy["flagged_for_revision"] is True

    flat = compute_item_stat_row(
        "flat",
        [
            {
                "item_id": "flat",
                "person_id": f"p{i}",
                "correct": i % 2 == 0,
                "time_ms": 1,
                "hint_used": False,
            }
            for i in range(30)
        ],
        {f"p{i}": float(i % 2) for i in range(30)},
        min_responses=30,
        bounds=ItemStatsBounds(discrimination_min=0.5),
    )
    assert flat["discrimination"] is not None
    assert flat["flagged_for_revision"] is True


def test_studio_feed_and_promotion_request_shape() -> None:
    rows = _responses(35)
    aggregate = aggregate_item_statistics(rows, min_responses=30)
    feed = studio_feed_from_aggregate(aggregate, language="yo", learner_flag_counts={"yo.item.1": 2})
    assert len(feed) == 1
    row = feed[0]
    assert row["language"] == "yo"
    assert row["learner_flag_count"] == 2
    assert row["p_value"] is not None

    manifest = {
        "language": "yo",
        "readiness_level": "L1",
        "audio": {"kind": "human", "uri": "a.ogg"},
    }
    cohort = {"declared_size": 50, "enrolled_count": 50, "weeks_elapsed": 7}
    promo_stats = {
        k: {
            "p_value": v["p_value"],
            "discrimination": v["discrimination"],
            "response_count": v["response_count"],
        }
        for k, v in aggregate["item_statistics"].items()
        if not v["insufficient_data"]
    }
    req = build_promotion_request(manifest, cohort=cohort, item_statistics=promo_stats)
    assert req["item_statistics_count"] == 1


def test_cli_round_trip() -> None:
    script = _REPO_ROOT / "tools/content_pipeline/item_stats.py"
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
    with pytest.raises(ItemStatsError) as exc:
        aggregate_item_statistics([{"item_id": "", "person_id": "p1", "correct": True}])
    assert exc.value.code == "RESPONSE_INVALID"
