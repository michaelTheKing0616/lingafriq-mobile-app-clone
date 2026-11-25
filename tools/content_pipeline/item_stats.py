"""Pilot item statistics aggregation (P4-134, ELEVATION §6.6)."""

from __future__ import annotations

import json
import math
import os
import statistics
import sys
from dataclasses import dataclass
from typing import Any, Mapping, MutableMapping, Sequence

CARD_ID = "P4-134"

DEFAULT_MIN_RESPONSES = 30


class ItemStatsError(Exception):
    """Item stats validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ItemStatsBounds:
    p_value_min: float = 0.25
    p_value_max: float = 0.90
    discrimination_min: float = 0.15


DEFAULT_BOUNDS = ItemStatsBounds()


def resolve_min_responses(env: Mapping[str, str] | None = None) -> int:
    source = env if env is not None else os.environ
    raw = source.get("STUDIO_QUALITY_MIN_SAMPLES", "").strip()
    if not raw:
        raw = source.get("PILOT_ITEM_STATS_MIN_RESPONSES", "").strip()
    if not raw:
        return DEFAULT_MIN_RESPONSES
    try:
        parsed = int(raw, 10)
    except ValueError:
        return DEFAULT_MIN_RESPONSES
    if parsed < 1:
        return DEFAULT_MIN_RESPONSES
    return parsed


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise ItemStatsError(code, f"{label} must be a mapping")
    return value


def _normalize_response(row: Mapping[str, Any], index: int) -> dict[str, Any]:
    item_id = row.get("item_id")
    person_id = row.get("person_id")
    correct = row.get("correct")
    if not isinstance(item_id, str) or not item_id.strip():
        raise ItemStatsError("RESPONSE_INVALID", f"responses[{index}].item_id must be a non-empty string")
    if not isinstance(person_id, str) or not person_id.strip():
        raise ItemStatsError("RESPONSE_INVALID", f"responses[{index}].person_id must be a non-empty string")
    if not isinstance(correct, bool):
        raise ItemStatsError("RESPONSE_INVALID", f"responses[{index}].correct must be a boolean")
    time_ms = row.get("time_ms")
    if time_ms is not None:
        if not isinstance(time_ms, (int, float)) or isinstance(time_ms, bool) or time_ms < 0:
            raise ItemStatsError("RESPONSE_INVALID", f"responses[{index}].time_ms must be a non-negative number")
        time_ms = float(time_ms)
    hint_used = row.get("hint_used")
    if hint_used is not None and not isinstance(hint_used, bool):
        raise ItemStatsError("RESPONSE_INVALID", f"responses[{index}].hint_used must be a boolean")
    return {
        "item_id": item_id.strip(),
        "person_id": person_id.strip(),
        "correct": correct,
        "time_ms": time_ms,
        "hint_used": bool(hint_used) if hint_used is not None else False,
    }


def _person_totals(responses: Sequence[Mapping[str, Any]]) -> dict[str, float]:
    totals: dict[str, float] = {}
    for row in responses:
        pid = str(row["person_id"])
        totals[pid] = totals.get(pid, 0.0) + (1.0 if row["correct"] else 0.0)
    return totals


def _point_biserial(item_scores: Sequence[int], person_totals: Sequence[float]) -> float | None:
    n = len(item_scores)
    if n < 2:
        return None
    ones = [person_totals[i] for i, score in enumerate(item_scores) if score == 1]
    zeros = [person_totals[i] for i, score in enumerate(item_scores) if score == 0]
    if not ones or not zeros:
        return None
    if len(person_totals) < 2:
        return None
    sd = statistics.pstdev(person_totals)
    if sd == 0:
        return None
    m1 = sum(ones) / len(ones)
    m0 = sum(zeros) / len(zeros)
    p = len(ones) / n
    q = 1.0 - p
    return (m1 - m0) / sd * math.sqrt(p * q)


def _median(values: Sequence[float]) -> float | None:
    if not values:
        return None
    return float(statistics.median(values))


def _flag_for_revision(
    p_value: float | None,
    discrimination: float | None,
    bounds: ItemStatsBounds,
) -> bool:
    if p_value is not None:
        if p_value < bounds.p_value_min or p_value > bounds.p_value_max:
            return True
    if discrimination is not None and discrimination < bounds.discrimination_min:
        return True
    return False


def compute_item_stat_row(
    item_id: str,
    rows: Sequence[Mapping[str, Any]],
    person_totals: Mapping[str, float],
    *,
    min_responses: int,
    bounds: ItemStatsBounds = DEFAULT_BOUNDS,
) -> dict[str, Any]:
    count = len(rows)
    if count < min_responses:
        return {
            "item_id": item_id,
            "response_count": count,
            "insufficient_data": True,
            "p_value": None,
            "discrimination": None,
            "median_time_ms": None,
            "hint_use_rate": None,
            "flagged_for_revision": False,
        }

    correct_count = sum(1 for r in rows if r["correct"])
    p_value = correct_count / count

    scores = [1 if r["correct"] else 0 for r in rows]
    totals = [float(person_totals[str(r["person_id"])]) for r in rows]
    discrimination = _point_biserial(scores, totals)

    times = [float(r["time_ms"]) for r in rows if r.get("time_ms") is not None]
    median_time = _median(times)

    hint_rate = sum(1 for r in rows if r.get("hint_used")) / count

    return {
        "item_id": item_id,
        "response_count": count,
        "insufficient_data": False,
        "p_value": round(p_value, 4),
        "discrimination": round(discrimination, 4) if discrimination is not None else None,
        "median_time_ms": round(median_time, 2) if median_time is not None else None,
        "hint_use_rate": round(hint_rate, 4),
        "flagged_for_revision": _flag_for_revision(p_value, discrimination, bounds),
    }


def aggregate_item_statistics(
    responses: Sequence[Mapping[str, Any]],
    *,
    min_responses: int | None = None,
    bounds: ItemStatsBounds = DEFAULT_BOUNDS,
) -> dict[str, Any]:
    """Aggregate pilot responses into per-item statistics for studio and promotion gates."""
    if min_responses is None:
        min_responses = resolve_min_responses()
    if min_responses < 1:
        raise ItemStatsError("CONFIG_INVALID", "min_responses must be at least 1")

    normalized: list[dict[str, Any]] = []
    for index, raw in enumerate(responses):
        row = _require_mapping(raw, "RESPONSE_INVALID", f"responses[{index}]")
        normalized.append(_normalize_response(row, index))

    totals = _person_totals(normalized)
    by_item: dict[str, list[dict[str, Any]]] = {}
    for row in normalized:
        by_item.setdefault(row["item_id"], []).append(row)

    items: dict[str, dict[str, Any]] = {}
    for item_id, rows in sorted(by_item.items()):
        items[item_id] = compute_item_stat_row(
            item_id,
            rows,
            totals,
            min_responses=min_responses,
            bounds=bounds,
        )

    return {
        "card_id": CARD_ID,
        "min_responses": min_responses,
        "bounds": {
            "p_value_min": bounds.p_value_min,
            "p_value_max": bounds.p_value_max,
            "discrimination_min": bounds.discrimination_min,
        },
        "item_statistics": items,
        "item_statistics_count": len(items),
    }


def studio_feed_from_aggregate(
    aggregate: Mapping[str, Any],
    *,
    language: str,
    learner_flag_counts: Mapping[str, int] | None = None,
) -> list[dict[str, Any]]:
    """Shape rows for `upsertItemStatistic` on the quality dashboard."""
    stats = _require_mapping(aggregate.get("item_statistics"), "AGGREGATE_INVALID", "item_statistics")
    flags = learner_flag_counts or {}
    out: list[dict[str, Any]] = []
    for item_id, row in stats.items():
        stat = _require_mapping(row, "AGGREGATE_INVALID", f"item_statistics[{item_id}]")
        insufficient = bool(stat.get("insufficient_data"))
        out.append(
            {
                "item_id": item_id,
                "language": language,
                "learner_flag_count": int(flags.get(item_id, 0)),
                "flagged_for_revision": bool(stat.get("flagged_for_revision")) and not insufficient,
                "p_value": None if insufficient else stat.get("p_value"),
                "discrimination": None if insufficient else stat.get("discrimination"),
                "response_count": int(stat.get("response_count", 0)),
                "median_time_ms": None if insufficient else stat.get("median_time_ms"),
                "hint_use_rate": None if insufficient else stat.get("hint_use_rate"),
            }
        )
    return out


def _bounds_from_payload(payload: Mapping[str, Any]) -> ItemStatsBounds:
    raw = payload.get("bounds")
    if raw is None:
        return DEFAULT_BOUNDS
    b = _require_mapping(raw, "CONFIG_INVALID", "bounds")
    return ItemStatsBounds(
        p_value_min=float(b.get("p_value_min", DEFAULT_BOUNDS.p_value_min)),
        p_value_max=float(b.get("p_value_max", DEFAULT_BOUNDS.p_value_max)),
        discrimination_min=float(b.get("discrimination_min", DEFAULT_BOUNDS.discrimination_min)),
    )


def run_cli() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"ok": False, "code": "INPUT_INVALID", "message": "stdin must be JSON"}))
        return 1
    if not isinstance(payload, Mapping):
        print(json.dumps({"ok": False, "code": "INPUT_INVALID", "message": "payload must be an object"}))
        return 1
    responses = payload.get("responses")
    if not isinstance(responses, list):
        print(json.dumps({"ok": False, "code": "INPUT_INVALID", "message": "responses must be a list"}))
        return 1
    min_raw = payload.get("min_responses")
    min_responses = resolve_min_responses() if min_raw is None else int(min_raw)
    try:
        result = aggregate_item_statistics(
            responses,
            min_responses=min_responses,
            bounds=_bounds_from_payload(payload),
        )
    except ItemStatsError as exc:
        print(json.dumps({"ok": False, "code": exc.code, "message": str(exc)}))
        return 1
    print(json.dumps({"ok": True, "data": result}))
    return 0


if __name__ == "__main__":
    raise SystemExit(run_cli())
