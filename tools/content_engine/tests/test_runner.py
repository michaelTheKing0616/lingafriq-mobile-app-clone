"""Tests for the deterministic linter runner (P4-039)."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from collections.abc import Mapping
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import (  # noqa: E402
    cli_with_linters,
    exit_code,
    main,
    run_linters,
)
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

_ITEM = {"id": "item-yo-001", "text": "ẹ káàbọ̀"}
_KIT = {"lang": "yo", "script": "Latn"}


def _pass_linter(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
    del kit
    return LintResult(
        item_id=item["id"],
        rule_id="pass_rule",
        span=Span(0, 2),
        status="pass",
    )


def _fail_linter(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
    del kit
    return LintResult(
        item_id=item["id"],
        rule_id="fail_rule",
        span=Span(1, 4),
        status="fail",
    )


def _boom_linter(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
    del item, kit
    raise ZeroDivisionError


def test_pass_and_fail_linters_return_typed_results() -> None:
    results = run_linters(_ITEM, _KIT, [_pass_linter, _fail_linter])
    assert len(results) == 2
    passed, failed = results
    assert passed == LintResult(
        item_id="item-yo-001",
        rule_id="pass_rule",
        span=Span(0, 2),
        status="pass",
    )
    assert failed == LintResult(
        item_id="item-yo-001",
        rule_id="fail_rule",
        span=Span(1, 4),
        status="fail",
    )
    assert failed.status == "fail"
    assert exit_code(results) == 1
    assert exit_code([passed]) == 0


def test_raised_linter_is_lint_error_and_does_not_stop_next() -> None:
    results = run_linters(_ITEM, _KIT, [_boom_linter, _pass_linter])
    crashed, passed = results
    assert crashed.status == "LINT_ERROR"
    assert crashed.status != "pass"
    assert crashed.item_id == "item-yo-001"
    assert crashed.rule_id == "_boom_linter"
    assert crashed.span == Span(0, 0)
    assert passed.status == "pass"
    assert passed.item_id == "item-yo-001"
    assert passed.rule_id == "pass_rule"
    assert exit_code(results) == 1


def test_cli_and_run_linters_return_equal_results(capsys: pytest.CaptureFixture[str]) -> None:
    linters = [_pass_linter, _fail_linter]
    direct = run_linters(_ITEM, _KIT, linters)
    code = cli_with_linters(_ITEM, _KIT, linters)
    printed = json.loads(capsys.readouterr().out)
    cli_results = [
        LintResult(
            item_id=row["item_id"],
            rule_id=row["rule_id"],
            span=Span(row["span"]["start"], row["span"]["end"]),
            status=row["status"],
        )
        for row in printed
    ]
    assert cli_results == direct
    assert [row.status for row in cli_results] == [row.status for row in direct]
    assert code == exit_code(direct) == 1


def test_subprocess_failing_linter_exits_1() -> None:
    env = {**os.environ, "PYTHONPATH": str(_REPO_ROOT)}
    script = (
        "from tools.content_engine.linters.runner import cli_with_linters\n"
        "from tools.content_engine.linters.types import LintResult, Span\n"
        "def fail_linter(item, kit):\n"
        "    return LintResult(item_id=item['id'], rule_id='fail_rule', "
        "span=Span(0, 1), status='fail')\n"
        "raise SystemExit(cli_with_linters({'id': 'item-cli-1'}, {'lang': 'yo'}, "
        "[fail_linter]))\n"
    )
    completed = subprocess.run(
        ["python3", "-c", script],
        cwd=_REPO_ROOT,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert completed.returncode == 1


def test_empty_linter_list_raises_value_error() -> None:
    with pytest.raises(ValueError):
        run_linters(_ITEM, _KIT, [])


def test_item_not_mapping_raises_type_error() -> None:
    with pytest.raises(TypeError):
        run_linters("not-a-mapping", _KIT, [_pass_linter])  # type: ignore[arg-type]


def test_kit_not_mapping_raises_type_error() -> None:
    with pytest.raises(TypeError):
        run_linters(_ITEM, ["not-a-mapping"], [_pass_linter])  # type: ignore[arg-type]


def test_linter_non_lint_result_raises_type_error() -> None:
    def _not_lint_result(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
        del item, kit
        return {"status": "pass"}  # type: ignore[return-value]

    with pytest.raises(TypeError):
        run_linters(_ITEM, _KIT, [_not_lint_result])


def test_mismatched_item_id_raises_value_error_and_does_not_record_pass() -> None:
    def _mismatch_pass(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
        del item, kit
        return LintResult(
            item_id="other-id",
            rule_id="mismatch_rule",
            span=Span(0, 1),
            status="pass",
        )

    with pytest.raises(ValueError):
        results = run_linters(_ITEM, _KIT, [_mismatch_pass])
        assert all(result.status != "pass" for result in results)


def test_exit_code_empty_results_is_one() -> None:
    assert exit_code([]) == 1


def test_main_demo_raises_value_error() -> None:
    with pytest.raises(ValueError):
        main(["--demo"])


def test_main_item_kit_files_empty_linters_raises_and_does_not_return_zero(
    tmp_path: Path,
) -> None:
    item_file = tmp_path / "item.json"
    kit_file = tmp_path / "kit.json"
    item_file.write_text(json.dumps(_ITEM), encoding="utf-8")
    kit_file.write_text(json.dumps(_KIT), encoding="utf-8")
    with pytest.raises(ValueError):
        code = main(["--item", str(item_file), "--kit", str(kit_file)])
        assert code != 0
