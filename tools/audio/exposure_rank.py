"""Rank content items by learner exposure for native re-recording order (P5-072)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping, Sequence

CARD_ID = "P5-072"


class ExposureRankError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class RankedExposure:
    item_id: str
    exposure_count: int
    exposure_rank: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "item_id": self.item_id,
            "exposure_count": self.exposure_count,
            "exposure_rank": self.exposure_rank,
        }


def _parse_log_row(row: Mapping[str, Any], index: int) -> tuple[str, int]:
    item_id = row.get("item_id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise ExposureRankError(
            "USAGE_LOG_INVALID",
            f"usage_logs[{index}].item_id must be a non-empty string",
        )
    raw = row.get("exposure_count")
    if not isinstance(raw, int) or raw < 0:
        raise ExposureRankError(
            "USAGE_LOG_INVALID",
            f"usage_logs[{index}].exposure_count must be a non-negative int",
        )
    return item_id.strip(), raw


def rank_items_by_exposure(usage_logs: Sequence[Mapping[str, Any]] | None) -> list[RankedExposure]:
    """Order items by descending exposure_count; stable tie-break on item_id."""
    if usage_logs is None:
        raise ExposureRankError("ExposureDataMissing", "usage logs are required")
    if len(usage_logs) == 0:
        raise ExposureRankError("ExposureDataMissing", "usage logs must not be empty")

    parsed: list[tuple[str, int]] = []
    for index, row in enumerate(usage_logs):
        if not isinstance(row, Mapping):
            raise ExposureRankError(
                "USAGE_LOG_INVALID",
                f"usage_logs[{index}] must be an object",
            )
        parsed.append(_parse_log_row(row, index))

    parsed.sort(key=lambda pair: (-pair[1], pair[0]))
    return [
        RankedExposure(item_id=item_id, exposure_count=count, exposure_rank=rank)
        for rank, (item_id, count) in enumerate(parsed, start=1)
    ]


def recording_queue_after_top_set(
    ranked: Sequence[RankedExposure],
    top_set_item_ids: frozenset[str] | set[str],
) -> list[RankedExposure]:
    """Continue native re-recording in exposure order after the initial top set is done."""
    top = frozenset(top_set_item_ids)
    return [row for row in ranked if row.item_id not in top]


def top_n_by_exposure(
    ranked: Sequence[RankedExposure],
    n: int,
) -> list[RankedExposure]:
    if n < 0:
        raise ExposureRankError("TOP_N_INVALID", "n must be non-negative")
    return list(ranked[:n])
