#!/usr/bin/env python3
"""Aggregate P7-944 ML Kit Latin OCR diacritic verification ledger."""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
FIXTURES = REPO_ROOT / "assets/data/lens/ocr_diacritic_fixtures.json"
LEDGER = REPO_ROOT / "assets/data/lens/ml_kit_latin_ocr_ledger.json"

_COMBINING = re.compile(r"[\u0300-\u036f\u0323-\u0331]")


def _nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def _grapheme_clusters(text: str) -> list[str]:
    normalized = unicodedata.normalize("NFD", _nfc(text))
    clusters: list[str] = []
    index = 0
    while index < len(normalized):
        cluster = normalized[index]
        index += 1
        while index < len(normalized) and _COMBINING.match(normalized[index]):
            cluster += normalized[index]
            index += 1
        clusters.append(cluster)
    return clusters


def _strip_marks(cluster: str) -> str:
    return _COMBINING.sub("", cluster)


def _mark_count(cluster: str) -> int:
    return len(_COMBINING.findall(cluster))


def per_mark_error_rate(reference: str, hypothesis: str) -> dict[str, object]:
    ref_clusters = _grapheme_clusters(reference)
    hyp_clusters = _grapheme_clusters(hypothesis)
    hyp_bases = [_strip_marks(c) for c in hyp_clusters]

    reference_marks = 0
    matched_marks = 0
    mismatched: list[str] = []
    hyp_index = 0

    for ref_cluster in ref_clusters:
        marks = _mark_count(ref_cluster)
        reference_marks += marks
        if marks == 0:
            continue
        base = _strip_marks(ref_cluster)
        while hyp_index < len(hyp_bases) and hyp_bases[hyp_index] != base:
            hyp_index += 1
        if hyp_index >= len(hyp_bases):
            mismatched.append(ref_cluster)
            continue
        hyp_cluster = hyp_clusters[hyp_index]
        hyp_index += 1
        hyp_marks = _mark_count(hyp_cluster)
        matched_marks += min(hyp_marks, marks)
        if hyp_cluster != ref_cluster:
            mismatched.append(f"{ref_cluster}→{hyp_cluster}")

    rate = 0.0 if reference_marks == 0 else 1.0 - (matched_marks / reference_marks)
    return {
        "reference_marks": reference_marks,
        "matched_marks": matched_marks,
        "per_mark_error_rate": round(rate, 4),
        "mismatched_clusters": mismatched,
    }


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def aggregate(ledger: dict, fixtures: dict) -> dict:
    gold_by_id = {f["id"]: f["gold_text"] for f in fixtures["fixtures"]}
    summary: dict[str, object] = {"by_language": {}, "by_platform": {}}
    for platform, pdata in ledger["platforms"].items():
        runs = pdata.get("runs") or []
        platform_rates: list[float] = []
        by_lang: dict[str, list[float]] = {}
        for run in runs:
            fid = run["fixture_id"]
            gold = gold_by_id[fid]
            stats = per_mark_error_rate(gold, run["ml_kit_text"])
            run["per_mark_error_rate"] = stats["per_mark_error_rate"]
            platform_rates.append(stats["per_mark_error_rate"])
            lang = next(
                f["language"] for f in fixtures["fixtures"] if f["id"] == fid
            )
            by_lang.setdefault(lang, []).append(stats["per_mark_error_rate"])
        avg = sum(platform_rates) / len(platform_rates) if platform_rates else 0.0
        summary["by_platform"][platform] = {
            "mean_per_mark_error_rate": round(avg, 4),
            "fixture_count": len(runs),
        }
        for lang, rates in by_lang.items():
            bucket = summary["by_language"].setdefault(lang, {"rates": []})
            bucket["rates"].extend(rates)
    for lang, bucket in summary["by_language"].items():
        rates = bucket["rates"]
        bucket["mean_per_mark_error_rate"] = round(sum(rates) / len(rates), 4)
        del bucket["rates"]
    overall = [
        p["mean_per_mark_error_rate"] for p in summary["by_platform"].values()
    ]
    summary["overall_mean_per_mark_error_rate"] = round(
        sum(overall) / len(overall), 4
    ) if overall else 0.0
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--require-device-capture",
        action="store_true",
        help="Fail if ledger still uses fixture_placeholder devices",
    )
    args = parser.parse_args()

    fixtures = load_json(FIXTURES)
    ledger = load_json(LEDGER)
    if args.require_device_capture:
        for platform, pdata in ledger["platforms"].items():
            if pdata.get("device_model") == "fixture_placeholder":
                print(f"device capture pending for {platform}", file=sys.stderr)
                return 2
    summary = aggregate(ledger, fixtures)
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
