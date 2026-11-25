"""Spec tests for placeholder, empty-field, and broken-JSON lint (P4-050)."""

from __future__ import annotations

import copy
import json
import re
import sys
from pathlib import Path
from typing import Any

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

# D28: sibling curriculum item schema. Do not import packs.
_SCHEMA_PATH = _REPO_ROOT.parent / "curriculum" / "schema" / "item.schema.json"
_VALIDATOR = Draft202012Validator(json.loads(_SCHEMA_PATH.read_text(encoding="utf-8")))
_PLACEHOLDER_RE = re.compile(r"word\d|example meaning|sample|lorem|TODO", re.I)
_KIT: dict[str, Any] = {}

_VALID_ITEM: dict[str, Any] = {
    "id": "yo.lex.0123456789ab",
    "lang": "yo",
    "type": "lexeme",
    "cefr": "A1",
    "can_do": ["greet someone"],
    "text": "Hello.",
    "provenance": {"sources": [{"source_id": "src-1", "licence": "CC BY 4.0"}]},
    "claims": [],
    "confidence": 0.5,
    "risk_tags": [],
    "status": "needs-review",
    "label": "beta",
    "audio": [],
    "feature_hooks": {},
}

_SCHEMA_ERRORS = list(_VALIDATOR.iter_errors(_VALID_ITEM))
if _SCHEMA_ERRORS:
    raise AssertionError(f"schema fixture invalid: {_SCHEMA_ERRORS[0].message}")

from tools.content_engine.linters.placeholders import lint_placeholders  # noqa: E402


def _copy_item(**overrides: Any) -> dict[str, Any]:
    item = copy.deepcopy(_VALID_ITEM)
    item.update(overrides)
    return item


def _placeholder_span(text: str) -> Span:
    match = _PLACEHOLDER_RE.search(text)
    assert match is not None
    return Span(match.start(), match.end())


@pytest.mark.parametrize(
    "text",
    ["word1", "example meaning", "sample", "lorem", "TODO"],
)
def test_P4_050_AC1_placeholder_text_fails(text: str) -> None:
    item = _copy_item(text=text)
    result = lint_placeholders(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == item["id"]
    assert result.rule_id == "PLACEHOLDER_TEXT"
    assert result.span == _placeholder_span(text)
    assert item["text"][result.span.start : result.span.end] == text[
        result.span.start : result.span.end
    ]


def test_P4_050_AC1_placeholder_in_other_field_fails() -> None:
    item = _copy_item(can_do=["lorem"])
    result = lint_placeholders(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "PLACEHOLDER_TEXT"
    assert result.item_id == _VALID_ITEM["id"]
    assert result.span == Span(0, 0)


def test_P4_050_AC2_missing_required_field_fails() -> None:
    item = _copy_item()
    del item["text"]
    result = lint_placeholders(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "SCHEMA_INVALID"
    assert result.item_id == item["id"]


def test_P4_050_AC2_empty_required_string_fails() -> None:
    result = lint_placeholders(_copy_item(text=""), _KIT)
    assert result.status == "fail"
    assert result.rule_id == "SCHEMA_INVALID"
    assert result.item_id == _VALID_ITEM["id"]


def test_P4_050_AC2_blank_nested_source_id_fails() -> None:
    item = _copy_item()
    item["provenance"]["sources"][0]["source_id"] = "   "
    result = lint_placeholders(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "SCHEMA_INVALID"
    assert result.item_id == item["id"]


def test_P4_050_AC2_broken_json_fails() -> None:
    result = lint_placeholders("{", _KIT)
    assert result.status == "fail"
    assert result.rule_id == "SCHEMA_INVALID"
    assert result.item_id == ""


def test_P4_050_valid_item_passes() -> None:
    errors = list(_VALIDATOR.iter_errors(_VALID_ITEM))
    assert errors == []
    result = lint_placeholders(_VALID_ITEM, _KIT)
    assert result == LintResult(
        item_id=_VALID_ITEM["id"],
        rule_id="PLACEHOLDERS",
        span=Span(0, 0),
        status="pass",
    )


def test_P4_050_AC3_ci_blocks_placeholder() -> None:
    lorem = _copy_item(text="lorem")
    lorem_results = run_linters(lorem, _KIT, [lint_placeholders])
    assert lorem_results[0].status == "fail"
    assert lorem_results[0].rule_id == "PLACEHOLDER_TEXT"
    assert exit_code(lorem_results) == 1

    valid_results = run_linters(_VALID_ITEM, _KIT, [lint_placeholders])
    assert valid_results[0].status == "pass"
    assert valid_results[0].rule_id == "PLACEHOLDERS"
    assert exit_code(valid_results) == 0


def test_P4_050_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_placeholders(_VALID_ITEM, ["not-a-mapping"])  # type: ignore[arg-type]
