#!/usr/bin/env python3
"""P9-923: Multilingual moderation classifier evaluation harness (fixture + gate)."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parent
NODE_BACKEND = REPO / "node-backend"
NODE_BIN = "node"

SEVERE_RECALL_THRESHOLD = 0.8
MIN_NATIVE_LABELS = 500
SEVERE_CATEGORIES = (
    "hate_threatening",
    "harassment_threatening",
    "sexual_minors",
    "violence_graphic",
    "self_harm_intent",
)
POLICY_THRESHOLD = 0.8


def _max_severe(scores: dict[str, float]) -> float | None:
    values = [scores[k] for k in SEVERE_CATEGORIES if isinstance(scores.get(k), (int, float))]
    if not values:
        return None
    return max(float(v) for v in values)


def predict_severe(scores: dict[str, float]) -> bool:
    peak = _max_severe(scores)
    if peak is None:
        for key in ("hate", "harassment", "violence"):
            val = scores.get(key)
            if isinstance(val, (int, float)):
                return float(val) > POLICY_THRESHOLD
        return False
    return peak > POLICY_THRESHOLD


def confusion(examples: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"tp": 0, "fp": 0, "tn": 0, "fn": 0}
    for row in examples:
        gold = bool(row["goldSevere"])
        pred = predict_severe(row["scores"])
        if gold and pred:
            counts["tp"] += 1
        elif not gold and pred:
            counts["fp"] += 1
        elif not gold:
            counts["tn"] += 1
        else:
            counts["fn"] += 1
    return counts


def rate(num: int, den: int) -> float | None:
    if den <= 0:
        return None
    return num / den


def evaluate_slice(slice_id: str, language: str, examples: list[dict[str, Any]], pair: str | None) -> dict[str, Any]:
    count = len(examples)
    if count < MIN_NATIVE_LABELS:
        return {
            "sliceId": slice_id,
            "language": language,
            "codeSwitchPair": pair,
            "exampleCount": count,
            "status": "insufficient_evidence",
            "precision": None,
            "recall": None,
            "falsePositiveRate": None,
        }
    c = confusion(examples)
    return {
        "sliceId": slice_id,
        "language": language,
        "codeSwitchPair": pair,
        "exampleCount": count,
        "status": "scored",
        "precision": rate(c["tp"], c["tp"] + c["fp"]),
        "recall": rate(c["tp"], c["tp"] + c["fn"]),
        "falsePositiveRate": rate(c["fp"], c["fp"] + c["tn"]),
    }


def build_report(manifest: list[dict[str, Any]]) -> dict[str, Any]:
    by_slice: dict[str, list[dict[str, Any]]] = {}
    for row in manifest:
        pair = row.get("codeSwitchPair")
        key = f"cs:{pair}" if pair else f"lang:{row['language']}"
        by_slice.setdefault(key, []).append(row)

    slices: list[dict[str, Any]] = []
    for lang in ("yo", "ig", "ha", "sw", "zu", "xh", "pcm"):
        key = f"lang:{lang}"
        slices.append(evaluate_slice(key, lang, by_slice.get(key, []), None))

    for pair, lang in (("pcm+en", "pcm"), ("sheng", "sw"), ("sw+en", "sw")):
        key = f"cs:{pair}"
        slices.append(evaluate_slice(key, lang, by_slice.get(key, []), pair))

    gate_passed = True
    for sl in slices:
        if sl["status"] != "scored":
            continue
        recall = sl["recall"]
        if recall is None or recall < SEVERE_RECALL_THRESHOLD:
            gate_passed = False

    return {
        "thresholdRecall": SEVERE_RECALL_THRESHOLD,
        "slices": slices,
        "gatePassed": gate_passed,
    }


def load_manifest_from_node() -> list[dict[str, Any]]:
    if not NODE_BACKEND.is_dir():
        raise RuntimeError("node-backend missing")
    script = (
        "import { serializeModerationEvalManifest } from './src/services/moderation/evalSets.ts';"
        "console.log(serializeModerationEvalManifest());"
    )
    proc = subprocess.run(
        [NODE_BIN, "--loader", "ts-node/esm", "-e", script],
        cwd=NODE_BACKEND,
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr or proc.stdout or "tsx manifest export failed")
    return json.loads(proc.stdout.strip())


def run_self_test() -> list[str]:
    errors: list[str] = []
    examples = [
        {"goldSevere": True, "scores": {"hate_threatening": 0.95}},
        {"goldSevere": True, "scores": {"hate_threatening": 0.2}},
        {"goldSevere": False, "scores": {"hate_threatening": 0.1}},
        {"goldSevere": False, "scores": {"hate_threatening": 0.95}},
    ]
    c = confusion(examples)
    if c["tp"] != 1 or c["fn"] != 1 or c["tn"] != 1 or c["fp"] != 1:
        errors.append("metric math self-test failed")
    prec = rate(c["tp"], c["tp"] + c["fp"])
    rec = rate(c["tp"], c["tp"] + c["fn"])
    fpr = rate(c["fp"], c["fp"] + c["tn"])
    if prec != 0.5 or rec != 0.5 or fpr != 0.5:
        errors.append("rate helpers self-test failed")
    tiny = evaluate_slice("t", "yo", examples, None)
    if tiny["status"] != "insufficient_evidence":
        errors.append("expected insufficient_evidence for small slice")
    big = [{"goldSevere": i % 5 == 0, "scores": severe_scores(i % 5 == 0 and i % 10 != 7)} for i in range(520)]
    scored = evaluate_slice("yo", "yo", big, None)
    if scored["status"] != "scored" or scored["recall"] is None:
        errors.append("expected scored slice for 520 examples")
    return errors


def severe_scores(high: bool) -> dict[str, float]:
    if high:
        return {"hate_threatening": 0.92, "harassment": 0.1}
    return {"hate_threatening": 0.05, "harassment": 0.08}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--gate", action="store_true", help="Exit non-zero when recall gate fails")
    parser.add_argument("--json", action="store_true", help="Print report JSON")
    args = parser.parse_args()

    if args.self_test:
        errors = run_self_test()
        if errors:
            for err in errors:
                print(err, file=sys.stderr)
            return 1
        return 0

    manifest = load_manifest_from_node()
    for row in manifest:
        ann = row.get("annotator") or {}
        if not ann.get("annotatorId") or not ann.get("licenceId"):
            print("label audit: missing annotator metadata", file=sys.stderr)
            return 1

    report = build_report(manifest)
    if args.json:
        print(json.dumps(report, indent=2))

    if args.gate and not report["gatePassed"]:
        print("moderation eval gate failed: severe recall below threshold", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
