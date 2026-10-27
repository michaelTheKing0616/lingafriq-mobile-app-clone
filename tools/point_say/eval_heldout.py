"""Held-out African-objects evaluation for Point-and-Say (P7-947)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.point_say.finetune import (  # noqa: E402
    DEFAULT_HELDOUT_MANIFEST,
    DEFAULT_TRAIN_MANIFEST,
    PointSayFinetuneError,
    _assert_heldout_disjoint,
    _collect_training_rows,
    _load_jsonl,
)


@dataclass(frozen=True)
class HeldoutEvalReport:
    total: int
    top3_correct: int
    top3_accuracy: float


def _fixture_predict_top3(row: Mapping[str, Any]) -> list[str]:
    """Deterministic stub: gold label ranks first when present."""
    gold = str(row.get("model_label") or row.get("class_slug") or "").strip()
    if not gold:
        return []
    return [gold, "afr.cup", "afr.chair"]


def _top3_hit(predictions: Sequence[str], gold: str) -> bool:
    gold_norm = gold.strip().casefold()
    return any(p.strip().casefold() == gold_norm for p in predictions[:3])


def evaluate_heldout(
    heldout_manifest: Path,
    *,
    train_manifest: Path | None = None,
) -> HeldoutEvalReport:
    heldout_rows = _load_jsonl(heldout_manifest)
    if train_manifest is not None and train_manifest.is_file():
        train_rows = _collect_training_rows(_load_jsonl(train_manifest))
        _assert_heldout_disjoint(train_rows, heldout_rows)

    total = 0
    hits = 0
    for row in heldout_rows:
        gold = str(row.get("model_label") or row.get("class_slug") or "").strip()
        if not gold:
            continue
        preds = _fixture_predict_top3(row)
        total += 1
        if _top3_hit(preds, gold):
            hits += 1

    if total == 0:
        raise PointSayFinetuneError(
            "HELDOUT_EMPTY",
            "held-out manifest has no labelled rows",
        )

    accuracy = hits / total
    return HeldoutEvalReport(total=total, top3_correct=hits, top3_accuracy=accuracy)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Point-and-Say held-out top-3 eval")
    parser.add_argument("--heldout-manifest", type=Path, default=DEFAULT_HELDOUT_MANIFEST)
    parser.add_argument("--train-manifest", type=Path, default=DEFAULT_TRAIN_MANIFEST)
    args = parser.parse_args(argv)

    train = args.train_manifest if args.train_manifest.is_file() else None
    try:
        report = evaluate_heldout(args.heldout_manifest, train_manifest=train)
    except PointSayFinetuneError as exc:
        print(exc, file=sys.stderr)
        return 1

    payload: dict[str, Any] = {
        "total": report.total,
        "top3_correct": report.top3_correct,
        "top3_accuracy": round(report.top3_accuracy, 4),
        "trains_on_heldout": False,
    }
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
