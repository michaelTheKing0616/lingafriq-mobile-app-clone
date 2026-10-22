#!/usr/bin/env python3
"""Block a prompt or model-identifier change that has no passing eval.

No relevant path prints "skipped: no prompt or model identifier change".
A relevant change is scored from eval outputs for those exact bytes.
Missing outputs, a hash mismatch, or a git failure is an infrastructure
failure and does not print "skipped". A score under the threshold prints
"blocked:". This script does not call a model.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
THRESHOLDS = ROOT / "evals" / "thresholds.yaml"
DEFAULT_OUTPUTS = ROOT / "evals" / "outputs.json"
SKIP = "skipped: no prompt or model identifier change"
TONE_MARKS = frozenset("\u0300\u0301\u0304\u0302\u030c\u030b\u030f")
METRICS = ("diacritic_completeness", "refusal_correctness", "persona_fidelity")


class InfraError(Exception):
    pass


def load_config(path: Path) -> tuple[list[str], list[str], dict[str, float]]:
    prompts: list[str] = []
    models: list[str] = []
    metrics: dict[str, float] = {}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.startswith("  - "):
            item = line.strip()[2:].strip()
            if section == "prompt_paths":
                prompts.append(item)
            elif section == "model_paths":
                models.append(item)
            continue
        if ":" not in line:
            raise InfraError(f"eval infrastructure failure: bad thresholds line {line}")
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            section = key
            continue
        if section == "metrics":
            metrics[key] = float(value)
    missing = [name for name in METRICS if name not in metrics]
    if missing or not prompts or not models:
        raise InfraError("eval infrastructure failure: thresholds are incomplete")
    return prompts, models, metrics


def relevant(path: str, prompts: list[str], models: list[str]) -> bool:
    for root in prompts + models:
        if path == root or path.startswith(root.rstrip("/") + "/"):
            return True
    return False


def git_changed() -> list[str]:
    base = os.environ.get("EVAL_BASE", "").strip()
    if not base:
        base_ref = os.environ.get("GITHUB_BASE_REF", "").strip()
        if base_ref:
            base = f"origin/{base_ref}"
        else:
            before = os.environ.get("GITHUB_EVENT_BEFORE", "").strip()
            if before and set(before) != {"0"}:
                base = before
            else:
                base = "HEAD~1"
    result = subprocess.run(
        ["git", "diff", "--name-only", f"{base}...HEAD"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise InfraError(f"eval infrastructure failure: git diff failed {detail}")
    return [line for line in result.stdout.splitlines() if line.strip()]


def sources_hash(paths: list[str]) -> str:
    digest = hashlib.sha256()
    for rel in sorted(paths):
        file = ROOT / rel
        if not file.is_file():
            raise InfraError(f"eval infrastructure failure: missing source {rel}")
        digest.update(rel.encode())
        digest.update(b"\0")
        digest.update(file.read_bytes())
    return digest.hexdigest()


def has_tone(text: str) -> bool:
    return any(ch in TONE_MARKS for ch in unicodedata.normalize("NFD", text))


def score_item(item: object) -> str:
    if not isinstance(item, dict):
        raise InfraError("eval infrastructure failure: an eval item is not an object")
    metric = item.get("metric")
    if metric not in METRICS:
        raise InfraError("eval infrastructure failure: item missing metric")
    if metric == "diacritic_completeness":
        output = item.get("output")
        reference = item.get("reference")
        if not isinstance(output, str) or not isinstance(reference, str):
            raise InfraError("eval infrastructure failure: diacritic item is incomplete")
        passed = has_tone(reference) and has_tone(output) and (
            unicodedata.normalize("NFC", output) == unicodedata.normalize("NFC", reference)
        )
    elif metric == "refusal_correctness":
        if not isinstance(item.get("refused"), bool) or not isinstance(item.get("expected_refused"), bool):
            raise InfraError("eval infrastructure failure: refusal item is incomplete")
        passed = item["refused"] is item["expected_refused"]
    else:
        output = item.get("output")
        citation = item.get("citation")
        if not isinstance(output, str) or not isinstance(citation, str) or not citation:
            raise InfraError("eval infrastructure failure: persona item is incomplete")
        passed = citation in output
    return metric if passed else ""


def evaluate(outputs: Path, expected_hash: str, metrics: dict[str, float]) -> int:
    if not outputs.is_file():
        raise InfraError(f"eval infrastructure failure: no eval outputs at {outputs}")
    try:
        document = json.loads(outputs.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise InfraError(f"eval infrastructure failure: {exc}") from exc
    if not isinstance(document, dict):
        raise InfraError("eval infrastructure failure: eval outputs are not an object")
    if document.get("sources_sha256") != expected_hash:
        raise InfraError("eval infrastructure failure: eval outputs do not match the changed files")
    items = document.get("items")
    if not isinstance(items, list) or not items:
        raise InfraError("eval infrastructure failure: eval outputs have no items")
    passed: dict[str, int] = {name: 0 for name in METRICS}
    seen: dict[str, int] = {name: 0 for name in METRICS}
    for item in items:
        metric = item.get("metric") if isinstance(item, dict) else None
        if metric not in METRICS:
            raise InfraError("eval infrastructure failure: item missing metric")
        seen[metric] += 1
        if score_item(item):
            passed[metric] += 1
    empty = [name for name in METRICS if seen[name] == 0]
    if empty:
        raise InfraError("eval infrastructure failure: " + ", ".join(empty) + " has no items")
    blocked: list[str] = []
    for name in METRICS:
        rate = passed[name] / seen[name]
        if rate < metrics[name]:
            blocked.append(f"blocked: {name} {rate:.3f} below {metrics[name]}")
    if blocked:
        print("\n".join(blocked))
        return 1
    print("eval passed")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changed", action="append", default=[])
    parser.add_argument("--outputs", type=Path, default=DEFAULT_OUTPUTS)
    parser.add_argument("--print-sources-hash", action="store_true")
    args = parser.parse_args(argv)
    try:
        prompts, models, metrics = load_config(THRESHOLDS)
        changed = args.changed if args.changed else git_changed()
        watched = [path for path in changed if relevant(path, prompts, models)]
        if args.print_sources_hash:
            if not watched:
                raise InfraError("eval infrastructure failure: no prompt or model file to hash")
            print(sources_hash(watched))
            return 0
        if not watched:
            print(SKIP)
            return 0
        return evaluate(args.outputs, sources_hash(watched), metrics)
    except InfraError as exc:
        print(str(exc))
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
