"""P5-072 exposure ranking for native re-recording."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.exposure_rank import (  # noqa: E402
    CARD_ID,
    ExposureRankError,
    rank_items_by_exposure,
    recording_queue_after_top_set,
    top_n_by_exposure,
)


def test_rank_orders_by_exposure_descending() -> None:
    logs = [
        {"item_id": "yo.a1.u01.i03", "exposure_count": 12},
        {"item_id": "yo.a1.u01.i01", "exposure_count": 40},
        {"item_id": "yo.a1.u02.i01", "exposure_count": 40},
    ]
    ranked = rank_items_by_exposure(logs)
    assert [r.item_id for r in ranked] == [
        "yo.a1.u01.i01",
        "yo.a1.u02.i01",
        "yo.a1.u01.i03",
    ]
    assert ranked[0].exposure_rank == 1
    assert ranked[-1].exposure_rank == 3


def test_missing_logs_raises_exposure_data_missing() -> None:
    with pytest.raises(ExposureRankError) as exc:
        rank_items_by_exposure(None)
    assert exc.value.code == "ExposureDataMissing"

    with pytest.raises(ExposureRankError) as exc2:
        rank_items_by_exposure([])
    assert exc2.value.code == "ExposureDataMissing"


def test_recording_proceeds_by_rank_after_top_set() -> None:
    logs = [
        {"item_id": "a", "exposure_count": 100},
        {"item_id": "b", "exposure_count": 80},
        {"item_id": "c", "exposure_count": 60},
        {"item_id": "d", "exposure_count": 40},
    ]
    ranked = rank_items_by_exposure(logs)
    top_set = frozenset({"a", "b"})
    queue = recording_queue_after_top_set(ranked, top_set)
    assert [r.item_id for r in queue] == ["c", "d"]
    assert [r.exposure_rank for r in queue] == [3, 4]


def test_top_n_supports_p5_073_export_cap() -> None:
    logs = [{"item_id": f"i{n}", "exposure_count": n} for n in range(5)]
    ranked = rank_items_by_exposure(logs)
    top = top_n_by_exposure(ranked, 2)
    assert len(top) == 2
    assert top[0].item_id == "i4"


def test_card_id_constant() -> None:
    assert CARD_ID == "P5-072"
