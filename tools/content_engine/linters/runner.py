"""Deterministic linter runner for CI and the studio (CURRICULUM §3.3).

Studio and CI call the same function: run_linters. This module does not
register share-alike or exclusion linters; callers supply linters.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Callable, Mapping, Sequence
from typing import Any

from tools.content_engine.linters.types import LintResult, Span

Linter = Callable[[Mapping[str, Any], Mapping[str, Any]], LintResult]


def run_linters(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
    linters: Sequence[Linter],
) -> list[LintResult]:
    """Run each linter on item and kit. Catch only to record LINT_ERROR."""
    if not isinstance(item, Mapping):
        raise TypeError("item must be a mapping")
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")
    if not linters:
        raise ValueError("linters must be a non-empty sequence")

    item_id = item["id"]
    results: list[LintResult] = []
    for linter in linters:
        try:
            result = linter(item, kit)
        except Exception:
            results.append(
                LintResult(
                    item_id=item_id,
                    rule_id=getattr(linter, "__name__", "linter"),
                    span=Span(0, 0),
                    status="LINT_ERROR",
                )
            )
            continue
        if not isinstance(result, LintResult):
            raise TypeError("linter must return LintResult")
        if result.item_id != item_id:
            raise ValueError(
                f"linter item_id {result.item_id!r} does not match item id {item_id!r}"
            )
        results.append(result)
    return results


def exit_code(results: Sequence[LintResult]) -> int:
    """0 only when every result is pass and the list is non-empty."""
    if not results:
        return 1
    return 0 if all(result.status == "pass" for result in results) else 1


def _result_to_dict(result: LintResult) -> dict[str, Any]:
    return {
        "item_id": result.item_id,
        "rule_id": result.rule_id,
        "span": {"start": result.span.start, "end": result.span.end},
        "status": result.status,
    }


def cli_with_linters(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
    linters: Sequence[Linter],
) -> int:
    """Print JSON results from run_linters and return the exit code."""
    results = run_linters(item, kit, linters)
    print(json.dumps([_result_to_dict(result) for result in results], sort_keys=True))
    return exit_code(results)


def main(argv: Sequence[str] | None = None) -> int:
    """Read --item and --kit JSON files. --demo is not allowed."""
    args_list = list(sys.argv[1:] if argv is None else argv)
    if "--demo" in args_list:
        raise ValueError("--demo is not allowed")
    parser = argparse.ArgumentParser(prog="linter-runner")
    parser.add_argument("--item", required=True)
    parser.add_argument("--kit", required=True)
    args = parser.parse_args(args_list)
    with open(args.item, encoding="utf-8") as handle:
        item = json.load(handle)
    with open(args.kit, encoding="utf-8") as handle:
        kit = json.load(handle)
    if not isinstance(item, Mapping) or not isinstance(kit, Mapping):
        raise TypeError("--item and --kit must be JSON objects")
    return cli_with_linters(item, kit, ())


if __name__ == "__main__":
    sys.exit(main())
