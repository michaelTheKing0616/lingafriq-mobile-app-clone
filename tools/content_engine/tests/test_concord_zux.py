"""Fixture markers are decimal class numbers; this fixture is not a concord paradigm."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.concord_zux import (  # noqa: E402
    concord_report,
    lint_concord_zux,
)
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

_KIT: dict[str, object] = {
    "concord_table": {
        n: {
            "subject": [str(n)],
            "object": [str(n)],
            "adjective": [str(n)],
        }
        for n in range(1, 16)
    }
}

_PASS = ("ZX", Span(0, 0), "pass")
_FORBIDDEN_SOURCE = ("zulmorph", "ZulMorph", "requests", "urllib")


def _item(
    item_id: str,
    *,
    language: str = "zu",
    noun_class: int = 1,
    subject: str | None = None,
    object: str | None = None,
    adjective: str | None = None,
    has_prefixes: bool = False,
    surface: str = "ab",
) -> dict[str, object]:
    return {
        "id": item_id,
        "language": language,
        "noun_class": noun_class,
        "subject": subject,
        "object": object,
        "adjective": adjective,
        "has_prefixes": has_prefixes,
        "surface": surface,
    }


def _assert_concord_fail(result: LintResult, item_id: str, marker: str) -> None:
    assert result.status == "fail"
    assert result.rule_id == "ZX_CONCORD"
    assert result.item_id == item_id
    assert marker[result.span.start : result.span.end] == marker
    assert result.span == Span(0, len(marker))


def test_P4_045_AC1_slot_disagrees() -> None:
    subject_item = _item("zx-ac1-subject", subject="2")
    _assert_concord_fail(lint_concord_zux(subject_item, _KIT), "zx-ac1-subject", "2")

    object_item = _item("zx-ac1-object", subject="1", object="2")
    _assert_concord_fail(lint_concord_zux(object_item, _KIT), "zx-ac1-object", "2")

    adjective_item = _item(
        "zx-ac1-adjective",
        subject="1",
        object="1",
        adjective="2",
    )
    _assert_concord_fail(lint_concord_zux(adjective_item, _KIT), "zx-ac1-adjective", "2")

    xh_item = _item("zx-ac1-xh-subject", language="xh", subject="2")
    _assert_concord_fail(lint_concord_zux(xh_item, _KIT), "zx-ac1-xh-subject", "2")


@pytest.mark.parametrize("noun_class", [1, 15])
def test_P4_045_AC1_classes_agree_pass(noun_class: int) -> None:
    marker = str(noun_class)
    item = _item(
        f"zx-ac1-zu-{noun_class}",
        noun_class=noun_class,
        subject=marker,
        object=marker,
        adjective=marker,
        has_prefixes=False,
        surface="ab",
    )
    assert lint_concord_zux(item, _KIT) == LintResult(f"zx-ac1-zu-{noun_class}", *_PASS)

    if noun_class == 1:
        xh = _item(
            "zx-ac1-xh-7",
            language="xh",
            noun_class=7,
            subject="7",
            object="7",
            adjective="7",
            has_prefixes=False,
            surface="ab",
        )
        assert lint_concord_zux(xh, _KIT) == LintResult("zx-ac1-xh-7", *_PASS)


def test_P4_045_AC1_ci_exit_code() -> None:
    failing = _item("zx-ac1-ci-fail", subject="2")
    assert exit_code(run_linters(failing, _KIT, [lint_concord_zux])) == 1

    passing = _item(
        "zx-ac1-ci-pass",
        subject="1",
        object="1",
        adjective="1",
    )
    assert exit_code(run_linters(passing, _KIT, [lint_concord_zux])) == 0


def test_P4_045_AC2_disjunctive_verb_fails() -> None:
    disjunctive = _item(
        "zx-ac2-ws",
        subject="1",
        object="1",
        adjective="1",
        has_prefixes=True,
        surface="a b",
    )
    result = lint_concord_zux(disjunctive, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "ZX_CONJUNCTIVE"
    assert result.item_id == "zx-ac2-ws"
    assert " " in disjunctive["surface"][result.span.start : result.span.end]

    conjunctive = _item(
        "zx-ac2-one-word",
        subject="1",
        object="1",
        adjective="1",
        has_prefixes=True,
        surface="ab",
    )
    assert lint_concord_zux(conjunctive, _KIT) == LintResult("zx-ac2-one-word", *_PASS)

    no_prefixes = _item(
        "zx-ac2-no-prefix",
        subject="1",
        object="1",
        adjective="1",
        has_prefixes=False,
        surface="a b",
    )
    assert lint_concord_zux(no_prefixes, _KIT) == LintResult("zx-ac2-no-prefix", *_PASS)


def test_P4_045_AC2_concord_before_conjunctive() -> None:
    item = _item(
        "zx-ac2-order",
        subject="2",
        object="1",
        adjective="1",
        has_prefixes=True,
        surface="a b",
    )
    result = lint_concord_zux(item, _KIT)
    assert result.rule_id == "ZX_CONCORD"
    assert result.rule_id != "ZX_CONJUNCTIVE"
    _assert_concord_fail(result, "zx-ac2-order", "2")


def test_P4_045_AC3_xhosa_analyser_none() -> None:
    xh = _item(
        "zx-ac3-xh",
        language="xh",
        noun_class=7,
        subject="7",
        object="7",
        adjective="7",
    )
    assert concord_report(xh, _KIT) == {"analyser": "none"}

    xh_fail = dict(xh)
    xh_fail["id"] = "zx-ac3-xh-fail"
    xh_fail["subject"] = "2"
    _assert_concord_fail(lint_concord_zux(xh_fail, _KIT), "zx-ac3-xh-fail", "2")

    zu = _item("zx-ac3-zu", subject="1", object="1", adjective="1")
    report = concord_report(zu, _KIT)
    assert report == {"analyser": "rule"}
    assert "zulmorph" not in str(report).lower()


def test_P4_045_no_external_analyser_import() -> None:
    source = (_REPO_ROOT / "tools/content_engine/linters/concord_zux.py").read_text(
        encoding="utf-8"
    )
    for forbidden in _FORBIDDEN_SOURCE:
        assert forbidden not in source


def test_P4_045_class_out_of_range_raises() -> None:
    with pytest.raises(ValueError):
        lint_concord_zux(_item("zx-range", noun_class=0, subject="1"), _KIT)
    with pytest.raises(ValueError):
        lint_concord_zux(_item("zx-range-hi", noun_class=16, subject="1"), _KIT)


def test_P4_045_bad_language_raises() -> None:
    with pytest.raises(ValueError):
        lint_concord_zux(_item("zx-lang", language="sw", subject="1"), _KIT)


def test_P4_045_missing_table_raises() -> None:
    with pytest.raises(ValueError):
        lint_concord_zux(_item("zx-no-table", subject="1"), {"lang": "zu"})


def test_P4_045_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_concord_zux(_item("zx-kit", subject="1"), ["not-a-mapping"])  # type: ignore[arg-type]


def test_P4_045_missing_key_raises() -> None:
    item = {
        "id": "zx-missing",
        "language": "zu",
        "subject": "1",
        "object": None,
        "adjective": None,
        "has_prefixes": False,
        "surface": "ab",
    }
    with pytest.raises(KeyError):
        lint_concord_zux(item, _KIT)
