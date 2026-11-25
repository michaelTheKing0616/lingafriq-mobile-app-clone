"""Spec tests for claims and banned generic-template lint (P4-049)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.claims import lint_claims  # noqa: E402
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

_FACT = "Market day is on Tuesday."
_AFFIX = "affixes carry tense and person"
_KIT: dict[str, object] = {}
_AFFIX_RE = re.compile(r"affixes carry tense and person", re.IGNORECASE)
_SVO_RE = re.compile(
    r"pattern:\s*subject\s*(?:→|->)\s*verb\s*(?:→|->)",
    re.IGNORECASE,
)


def _item(item_id: str, section: str, text: str, **extra: object) -> dict[str, object]:
    item: dict[str, object] = {"id": item_id, "section": section, "text": text}
    item.update(extra)
    return item


def _pass(item_id: str) -> LintResult:
    return LintResult(item_id=item_id, rule_id="CLAIMS", span=Span(0, 0), status="pass")


def _match_span(pattern: re.Pattern[str], text: str) -> Span:
    match = pattern.search(text)
    assert match is not None
    return Span(match.start(), match.end())


def test_P4_049_AC1_explanation_without_citation_fails() -> None:
    item = _item("item-expl", "explanation", _FACT)
    result = lint_claims(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-expl"
    assert result.rule_id == "CLAIM_NO_CITATION"
    assert result.span == Span(0, len(_FACT))


def test_P4_049_AC1_culture_note_without_citation_fails() -> None:
    item = _item("item-culture", "culture_note", _FACT)
    result = lint_claims(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-culture"
    assert result.rule_id == "CLAIM_NO_CITATION"
    assert result.span == Span(0, len(_FACT))


def test_P4_049_AC1_citation_id_passes() -> None:
    item = _item("item-cited", "explanation", _FACT, citation_id="cite-1")
    assert lint_claims(item, _KIT) == _pass("item-cited")


def test_P4_049_AC1_other_section_without_citation_passes() -> None:
    item = _item("item-lesson", "lesson", _FACT)
    assert lint_claims(item, _KIT) == _pass("item-lesson")


def test_P4_049_AC1_blank_citation_fails() -> None:
    empty = lint_claims(
        _item("item-blank", "explanation", _FACT, citation_id=""),
        _KIT,
    )
    assert empty.status == "fail"
    assert empty.rule_id == "CLAIM_NO_CITATION"
    assert empty.span == Span(0, len(_FACT))

    whitespace = lint_claims(
        _item("item-ws", "explanation", _FACT, citation_id="   "),
        _KIT,
    )
    assert whitespace.status == "fail"
    assert whitespace.rule_id == "CLAIM_NO_CITATION"
    assert whitespace.span == Span(0, len(_FACT))


def test_P4_049_AC2_affix_template_fails() -> None:
    item = _item("item-affix", "lesson", _AFFIX, citation_id="cite-1")
    result = lint_claims(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-affix"
    assert result.rule_id == "GENERIC_TEMPLATE"
    assert result.span == _match_span(_AFFIX_RE, _AFFIX)
    assert item["text"][result.span.start : result.span.end]


@pytest.mark.parametrize(
    "text",
    [
        "Pattern: subject → verb → object",
        "Pattern: subject -> verb -> object",
    ],
)
def test_P4_049_AC2_svo_arrow_template_fails(text: str) -> None:
    item = _item("item-svo", "lesson", text, citation_id="cite-1")
    result = lint_claims(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-svo"
    assert result.rule_id == "GENERIC_TEMPLATE"
    assert result.span == _match_span(_SVO_RE, text)
    assert text[result.span.start : result.span.end]


def test_P4_049_AC2_template_wins_over_missing_citation() -> None:
    item = _item("item-priority", "explanation", _AFFIX)
    result = lint_claims(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "GENERIC_TEMPLATE"
    assert result.rule_id != "CLAIM_NO_CITATION"
    assert result.span == _match_span(_AFFIX_RE, _AFFIX)


def test_P4_049_AC1_ci_exit_code_blocks_failure() -> None:
    uncited = _item("item-ci-uncited", "explanation", _FACT)
    uncited_results = run_linters(uncited, _KIT, [lint_claims])
    assert uncited_results[0].rule_id == "CLAIM_NO_CITATION"
    assert exit_code(uncited_results) == 1

    affix = _item("item-ci-affix", "lesson", _AFFIX, citation_id="cite-1")
    affix_results = run_linters(affix, _KIT, [lint_claims])
    assert affix_results[0].rule_id == "GENERIC_TEMPLATE"
    assert exit_code(affix_results) == 1

    cited = _item("item-ci-cited", "explanation", _FACT, citation_id="cite-1")
    assert exit_code(run_linters(cited, _KIT, [lint_claims])) == 0


def test_P4_049_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_claims(_item("item-kit", "explanation", _FACT), ["not-a-mapping"])  # type: ignore[arg-type]
