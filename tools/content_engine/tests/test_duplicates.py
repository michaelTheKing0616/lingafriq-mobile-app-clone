"""Spec tests for near-identical dialogues and repeated lines (P4-051)."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import Span  # noqa: E402
from tools.content_engine.linters.duplicates import lint_duplicates  # noqa: E402

_LINE_A = "line-a"
_LINE_B = "line-b"
_BUNDLE_ID = "bundle-1"
_LINTER_SOURCE = _REPO_ROOT / "tools/content_engine/linters/duplicates.py"

_IDENTICAL: dict[str, Any] = {
    "id": _BUNDLE_ID,
    "dialogues": [
        {"id": "d1", "lines": [_LINE_A, _LINE_B]},
        {"id": "d2", "lines": [_LINE_A, _LINE_B]},
    ],
    "units": [{"id": "u1", "lines": [_LINE_A, _LINE_A]}],
}


def _kit(dialogue_similarity: float, repeat_cap: int) -> dict[str, Any]:
    return {
        "duplicate_config": {
            "dialogue_similarity": dialogue_similarity,
            "repeat_cap": repeat_cap,
        }
    }


def _bundle(
    dialogues: list[dict[str, Any]],
    units: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    return {
        "id": _BUNDLE_ID,
        "dialogues": dialogues,
        "units": (
            [{"id": "u1", "lines": [_LINE_A, _LINE_A]}]
            if units is None
            else units
        ),
    }


def _assert_pass(result: Any) -> None:
    assert result.status == "pass"
    assert result.rule_id == "DUPLICATES"
    assert result.span == Span(0, 0)
    assert result.left_id == ""
    assert result.right_id == ""
    assert result.item_id == _BUNDLE_ID


def test_P4_051_AC1_identical_dialogues_fail() -> None:
    result = lint_duplicates(_IDENTICAL, _kit(1.0, 2))
    assert result.status == "fail"
    assert result.rule_id == "DUPLICATE_DIALOGUE"
    assert result.item_id == _BUNDLE_ID
    assert result.left_id == "d1"
    assert result.right_id == "d2"


def test_P4_051_AC1_below_threshold_passes() -> None:
    bundle = _bundle(
        [
            {"id": "d1", "lines": [_LINE_A, _LINE_B]},
            {"id": "d2", "lines": [_LINE_B]},
        ]
    )
    _assert_pass(lint_duplicates(bundle, _kit(1.0, 5)))


def test_P4_051_AC1_threshold_equal_fails() -> None:
    # Jaccard({line-a}, {line-a, line-b}) == 0.5.
    bundle = _bundle(
        [
            {"id": "d1", "lines": [_LINE_A]},
            {"id": "d2", "lines": [_LINE_A, _LINE_B]},
        ]
    )
    result = lint_duplicates(bundle, _kit(0.5, 5))
    assert result.status == "fail"
    assert result.rule_id == "DUPLICATE_DIALOGUE"
    assert result.item_id == _BUNDLE_ID
    assert result.left_id == "d1"
    assert result.right_id == "d2"


def test_P4_051_AC2_repeated_line_beyond_cap_fails() -> None:
    bundle = _bundle(
        [],
        [{"id": "u1", "lines": [_LINE_A, _LINE_A, _LINE_A]}],
    )
    result = lint_duplicates(bundle, _kit(1.0, 2))
    assert result.status == "fail"
    assert result.rule_id == "REPEATED_LINE"
    assert result.item_id == _BUNDLE_ID
    assert result.left_id == "u1"
    assert result.right_id == ""


def test_P4_051_AC2_at_cap_passes() -> None:
    bundle = _bundle([], [{"id": "u1", "lines": [_LINE_A, _LINE_A]}])
    _assert_pass(lint_duplicates(bundle, _kit(1.0, 2)))


def test_P4_051_AC3_thresholds_not_in_source() -> None:
    text = _LINTER_SOURCE.read_text(encoding="utf-8")
    assert re.search(r"dialogue_similarity\s*=\s*[0-9]", text) is None
    assert re.search(r"repeat_cap\s*=\s*[0-9]", text) is None


def test_P4_051_missing_config_raises() -> None:
    with pytest.raises(KeyError):
        lint_duplicates(_IDENTICAL, {})


def test_P4_051_AC1_ci_exit_code() -> None:
    fail_results = run_linters(_IDENTICAL, _kit(1.0, 2), [lint_duplicates])
    assert fail_results[0].rule_id == "DUPLICATE_DIALOGUE"
    assert exit_code(fail_results) == 1

    below = _bundle(
        [
            {"id": "d1", "lines": [_LINE_A, _LINE_B]},
            {"id": "d2", "lines": [_LINE_B]},
        ]
    )
    pass_results = run_linters(below, _kit(1.0, 5), [lint_duplicates])
    assert pass_results[0].status == "pass"
    assert exit_code(pass_results) == 0


def test_P4_051_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_duplicates(_IDENTICAL, ["not-a-mapping"])  # type: ignore[arg-type]
