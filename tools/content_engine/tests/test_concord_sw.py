"""Fixture uses only the §3.3 pairs and is not a subject-concord paradigm."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.concord_sw import lint_concord_sw  # noqa: E402
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

_KIT: dict[str, object] = {
    "concord_table": {
        "m/wa": {
            "subject": ["m", "wa"],
            "object": ["m", "wa"],
            "adjective": ["m", "wa"],
        },
        "ki/vi": {
            "subject": ["ki", "vi"],
            "object": ["ki", "vi"],
            "adjective": ["ki", "vi"],
        },
    }
}

_PASS = ("SW", Span(0, 0), "pass")


def _item(
    item_id: str,
    *,
    in_lexicon: bool,
    class_pair: str | None,
    subject: str | None,
    object: str | None = None,
    adjective: str | None = None,
) -> dict[str, object]:
    return {
        "id": item_id,
        "noun": {"in_lexicon": in_lexicon, "class_pair": class_pair},
        "subject": subject,
        "object": object,
        "adjective": adjective,
    }


def _assert_concord_fail(result: LintResult, item_id: str, marker: str) -> None:
    assert result.status == "fail"
    assert result.rule_id == "SW_CONCORD"
    assert result.item_id == item_id
    assert marker[result.span.start : result.span.end] == marker


def test_P4_044_AC1_subject_object_adjective_disagree() -> None:
    subject_item = _item(
        "sw-ac1-subject",
        in_lexicon=True,
        class_pair="m/wa",
        subject="ki",
    )
    subject_result = lint_concord_sw(subject_item, _KIT)
    _assert_concord_fail(subject_result, "sw-ac1-subject", "ki")

    object_item = _item(
        "sw-ac1-object",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
        object="ki",
    )
    object_result = lint_concord_sw(object_item, _KIT)
    _assert_concord_fail(object_result, "sw-ac1-object", "ki")

    adjective_item = _item(
        "sw-ac1-adjective",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
        object="m",
        adjective="ki",
    )
    adjective_result = lint_concord_sw(adjective_item, _KIT)
    _assert_concord_fail(adjective_result, "sw-ac1-adjective", "ki")


def test_P4_044_AC1_listed_pairs_agree_pass() -> None:
    mwa = _item(
        "sw-ac1-mwa-pass",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
        object="m",
        adjective="m",
    )
    assert lint_concord_sw(mwa, _KIT) == LintResult("sw-ac1-mwa-pass", *_PASS)

    kivi = _item(
        "sw-ac1-kivi-pass",
        in_lexicon=True,
        class_pair="ki/vi",
        subject="ki",
        object="vi",
        adjective="ki",
    )
    assert lint_concord_sw(kivi, _KIT) == LintResult("sw-ac1-kivi-pass", *_PASS)


def test_P4_044_AC1_ci_exit_code() -> None:
    failing = _item(
        "sw-ac1-ci-fail",
        in_lexicon=True,
        class_pair="m/wa",
        subject="ki",
    )
    assert exit_code(run_linters(failing, _KIT, [lint_concord_sw])) == 1

    passing = _item(
        "sw-ac1-ci-pass",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
        object="m",
        adjective="m",
    )
    assert exit_code(run_linters(passing, _KIT, [lint_concord_sw])) == 0


def test_P4_044_AC2_noun_unknown_fails() -> None:
    item = _item(
        "sw-ac2-unknown",
        in_lexicon=False,
        class_pair=None,
        subject="wa",
    )
    result = lint_concord_sw(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "SW_NOUN_UNKNOWN"
    assert result.status != "pass"
    assert exit_code(run_linters(item, _KIT, [lint_concord_sw])) == 1


def test_P4_044_absent_marker_is_not_checked() -> None:
    item = _item(
        "sw-absent",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
        object=None,
        adjective=None,
    )
    assert lint_concord_sw(item, _KIT) == LintResult("sw-absent", *_PASS)


def test_P4_044_unlisted_class_raises() -> None:
    item = _item(
        "sw-unlisted",
        in_lexicon=True,
        class_pair="ji/ma",
        subject="wa",
    )
    with pytest.raises(ValueError):
        lint_concord_sw(item, _KIT)


def test_P4_044_missing_table_raises() -> None:
    item = _item(
        "sw-no-table",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
    )
    with pytest.raises(ValueError):
        lint_concord_sw(item, {"lang": "sw"})


def test_P4_044_kit_must_be_mapping() -> None:
    item = _item(
        "sw-kit",
        in_lexicon=True,
        class_pair="m/wa",
        subject="wa",
    )
    with pytest.raises(TypeError):
        lint_concord_sw(item, ["not-a-mapping"])  # type: ignore[arg-type]


def test_P4_044_missing_key_raises() -> None:
    item = {
        "id": "sw-missing",
        "subject": "wa",
        "object": None,
        "adjective": None,
    }
    with pytest.raises(KeyError):
        lint_concord_sw(item, _KIT)
