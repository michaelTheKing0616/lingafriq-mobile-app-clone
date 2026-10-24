"""Tests for Unicode NFC, code-point, and look-alike lint (P4-040)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402
from tools.content_engine.linters.unicode import lint_unicode  # noqa: E402

_LATIN = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
_KIT = {"character_set": [_LATIN, "\u00e9", "\u025b"]}


def test_nfd_fails_unicode_not_nfc() -> None:
    item = {"id": "item-nfd-1", "text": "e\u0301"}
    result = lint_unicode(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-nfd-1"
    assert result.rule_id == "UNICODE_NOT_NFC"
    assert item["text"][result.span.start : result.span.end]


def test_nfc_e_acute_passes_when_allowed() -> None:
    item = {"id": "item-nfc-1", "text": "\u00e9"}
    result = lint_unicode(item, _KIT)
    assert result == LintResult(
        item_id="item-nfc-1",
        rule_id="UNICODE",
        span=Span(0, 1),
        status="pass",
    )


def test_codepoint_outside_kit_fails_and_span_names_it() -> None:
    item = {"id": "item-cp-1", "text": "abç"}
    result = lint_unicode(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-cp-1"
    assert result.rule_id == "CODEPOINT_NOT_ALLOWED"
    char = item["text"][result.span.start : result.span.end]
    assert char == "ç"
    assert hex(ord(char)) == hex(ord("ç"))
    assert char == item["text"][2]


def test_whitespace_and_digits_fail_unless_listed() -> None:
    space = lint_unicode({"id": "item-ws-1", "text": "a b"}, _KIT)
    assert space.rule_id == "CODEPOINT_NOT_ALLOWED"
    assert space.status == "fail"
    assert {"id": "item-ws-1", "text": "a b"}["text"][
        space.span.start : space.span.end
    ] == " "
    digit = lint_unicode({"id": "item-d-1", "text": "a1"}, _KIT)
    assert digit.rule_id == "CODEPOINT_NOT_ALLOWED"
    assert {"id": "item-d-1", "text": "a1"}["text"][
        digit.span.start : digit.span.end
    ] == "1"
    listed = lint_unicode(
        {"id": "item-ws-2", "text": "a 1"},
        {"character_set": [_LATIN, " ", "1"]},
    )
    assert listed.status == "pass"
    assert listed.rule_id == "UNICODE"


def test_greek_epsilon_fails_lookalike_before_allowed_set() -> None:
    item = {"id": "item-el-1", "text": "bɛ"}
    kit = {"character_set": ["b", "\u025b"]}
    # Greek ε is not in the kit; look-alike must win over CODEPOINT_NOT_ALLOWED.
    item_greek = {"id": "item-el-1", "text": "b\u03b5"}
    result = lint_unicode(item_greek, kit)
    assert result.status == "fail"
    assert result.rule_id == "LOOKALIKE_CHAR"
    assert result.rule_id != "CODEPOINT_NOT_ALLOWED"
    char = item_greek["text"][result.span.start : result.span.end]
    assert char == "\u03b5"
    assert hex(ord(char)) == "0x3b5"
    assert lint_unicode(item, kit).status == "pass"


def test_cyrillic_a_fails_lookalike() -> None:
    item = {"id": "item-cy-1", "text": "c\u0430t"}
    result = lint_unicode(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-cy-1"
    assert result.rule_id == "LOOKALIKE_CHAR"
    char = item["text"][result.span.start : result.span.end]
    assert char == "\u0430"
    assert hex(ord(char)) == "0x430"


def test_clean_nfc_allowed_string_passes() -> None:
    item = {"id": "item-ok-1", "text": "b\u025b"}
    result = lint_unicode(item, _KIT)
    assert result == LintResult(
        item_id="item-ok-1",
        rule_id="UNICODE",
        span=Span(0, 2),
        status="pass",
    )


def test_run_linters_failing_item_exit_code_1() -> None:
    item = {"id": "item-ci-1", "text": "e\u0301"}
    results = run_linters(item, _KIT, [lint_unicode])
    assert len(results) == 1
    assert results[0].status == "fail"
    assert results[0].rule_id == "UNICODE_NOT_NFC"
    assert results[0].item_id == "item-ci-1"
    assert exit_code(results) == 1


def test_nfd_span_is_first_differing_code_point() -> None:
    item = {"id": "item-nfd-2", "text": "ae\u0301"}
    result = lint_unicode(item, _KIT)
    assert result.rule_id == "UNICODE_NOT_NFC"
    assert result.span == Span(1, 2)
    assert item["text"][result.span.start : result.span.end] == "e"


def test_missing_required_keys_raise() -> None:
    with pytest.raises(KeyError):
        lint_unicode({"text": "a"}, _KIT)
    with pytest.raises(KeyError):
        lint_unicode({"id": "item-x"}, _KIT)
    with pytest.raises(KeyError):
        lint_unicode({"id": "item-x", "text": "a"}, {})
