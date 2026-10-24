"""Tests for Yoruba dot-below, tone, and lexicon-diacritic lint (P4-041)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402
from tools.content_engine.linters.yoruba import lint_yoruba  # noqa: E402

_KIT: dict[str, str] = {"lang": "yo"}


def _token(surface: str, lexicon: str, syllabic: bool = False) -> dict[str, object]:
    return {"surface": surface, "lexicon": lexicon, "syllabic": syllabic}


def _item(
    item_id: str,
    tokens: list[dict[str, object]],
    learner_facing: bool = True,
) -> dict[str, object]:
    return {
        "id": item_id,
        "learner_facing": learner_facing,
        "tokens": tokens,
    }


def test_plain_esin_for_lexicon_ẹṣin_fails_dotbelow() -> None:
    item = _item("item-dot-1", [_token("esin", "ẹṣin")])
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-dot-1"
    assert result.rule_id == "YO_DOTBELOW"
    char = "esin"[result.span.start : result.span.end]
    assert char in {"e", "s"}


def test_correct_ẹṣin_passes_dot_check() -> None:
    item = _item("item-dot-ok", [_token("ẹṣin", "ẹṣin")])
    result = lint_yoruba(item, _KIT)
    assert result == LintResult(
        item_id="item-dot-ok",
        rule_id="YO",
        span=Span(0, 0),
        status="pass",
    )
    assert result.rule_id != "YO_DOTBELOW"


def test_nfd_underdot_ẹṣin_matches_nfc_lexicon() -> None:
    surface = "e\u0323s\u0323in"
    item = _item("item-nfd-dot", [_token(surface, "ẹṣin")])
    result = lint_yoruba(item, _KIT)
    assert result.status == "pass"
    assert result.rule_id == "YO"


def test_ọ_and_ṣ_plain_replacements_fail_dotbelow() -> None:
    o_result = lint_yoruba(_item("item-o", [_token("o", "ọ")]), _KIT)
    assert o_result.rule_id == "YO_DOTBELOW"
    assert o_result.status == "fail"
    assert "o"[o_result.span.start : o_result.span.end] == "o"

    s_result = lint_yoruba(_item("item-s", [_token("S", "Ṣ")]), _KIT)
    assert s_result.rule_id == "YO_DOTBELOW"
    assert "S"[s_result.span.start : s_result.span.end] == "S"


def test_dropped_underdot_on_toned_vowel_fails_dotbelow() -> None:
    item = _item("item-drop", [_token("é", "ẹ\u0301")])
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DOTBELOW"
    assert result.status == "fail"
    assert "é"[result.span.start : result.span.end] == "é"


def test_surface_drops_underdot_letter_fails_dotbelow() -> None:
    item = _item("item-short", [_token("ẹ", "ẹṣin")])
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DOTBELOW"
    assert result.status == "fail"


def test_correct_ẹ_is_not_dotbelow_when_later_token_fails() -> None:
    item = _item(
        "item-later",
        [_token("ẹ", "ẹ"), _token("esin", "ẹṣin")],
    )
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DOTBELOW"
    assert result.item_id == "item-later"
    char = "esin"[result.span.start : result.span.end]
    assert char in {"e", "s"}


def test_syllabic_n_without_tone_fails_nasal_tone() -> None:
    item = _item("item-nasal-1", [_token("n", "n", syllabic=True)])
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-nasal-1"
    assert result.rule_id == "YO_NASAL_TONE"


def test_syllabic_n_with_acute_passes_nasal_rule() -> None:
    item = _item("item-nasal-ok", [_token("ń", "ń", syllabic=True)])
    result = lint_yoruba(item, _KIT)
    assert result.status == "pass"
    assert result.rule_id == "YO"
    assert result.rule_id != "YO_NASAL_TONE"


def test_syllabic_n_with_combining_grave_passes_nasal_rule() -> None:
    marked = "n\u0300"
    item = _item("item-nasal-grave", [_token(marked, marked, syllabic=True)])
    result = lint_yoruba(item, _KIT)
    assert result.status == "pass"
    assert result.rule_id != "YO_NASAL_TONE"


def test_non_syllabic_n_without_tone_does_not_fail_nasal() -> None:
    item = _item("item-nonsyl", [_token("n", "n", syllabic=False)])
    result = lint_yoruba(item, _KIT)
    assert result.status == "pass"
    assert result.rule_id == "YO"
    assert result.rule_id != "YO_NASAL_TONE"


def test_high_surface_vs_low_lexicon_fails_mismatch() -> None:
    item = _item("item-tone-1", [_token("bá", "bà")])
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-tone-1"
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"


def test_missing_underdot_on_other_letter_is_mismatch() -> None:
    item = _item("item-x", [_token("xin", "ṣin")])
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"
    assert result.status == "fail"


def test_extra_tone_on_mid_lexicon_is_mismatch() -> None:
    item = _item("item-extra", [_token("bá", "ba")])
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"
    assert result.status == "fail"


def test_learner_facing_missing_low_tone_is_unmarked_token() -> None:
    item = _item("item-unmarked-1", [_token("ba", "bà")], learner_facing=True)
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.status != "pass"
    assert result.item_id == "item-unmarked-1"
    assert result.rule_id == "YO_UNMARKED_TOKEN"


def test_learner_facing_mid_lexicon_unmarked_surface_passes() -> None:
    item = _item("item-mid", [_token("ba", "ba")], learner_facing=True)
    result = lint_yoruba(item, _KIT)
    assert result == LintResult(
        item_id="item-mid",
        rule_id="YO",
        span=Span(0, 0),
        status="pass",
    )


def test_non_learner_missing_tone_is_mismatch_not_unmarked() -> None:
    item = _item("item-nl", [_token("ba", "bà")], learner_facing=False)
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.item_id == "item-nl"
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"
    assert result.rule_id != "YO_UNMARKED_TOKEN"


def test_run_linters_failing_item_exit_code_1() -> None:
    item = _item("item-ci-1", [_token("esin", "ẹṣin")])
    results = run_linters(item, _KIT, [lint_yoruba])
    assert len(results) == 1
    assert results[0].status == "fail"
    assert results[0].rule_id == "YO_DOTBELOW"
    assert results[0].item_id == "item-ci-1"
    assert exit_code(results) == 1


def test_missing_lexicon_raises_keyerror() -> None:
    item = {
        "id": "item-missing",
        "learner_facing": True,
        "tokens": [{"surface": "ba", "syllabic": False}],
    }
    with pytest.raises(KeyError):
        lint_yoruba(item, _KIT)


def test_kit_must_be_mapping() -> None:
    item = _item("item-kit", [_token("ba", "ba")])
    with pytest.raises(TypeError):
        lint_yoruba(item, ["not-a-mapping"])  # type: ignore[arg-type]


def test_empty_surface_shorter_mismatch_span() -> None:
    item = _item("item-empty", [_token("", "ba")], learner_facing=False)
    result = lint_yoruba(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"


def test_longer_surface_mismatch() -> None:
    item = _item("item-long", [_token("bat", "ba")], learner_facing=False)
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_DIACRITIC_MISMATCH"
    assert result.status == "fail"


def test_syllabic_wins_over_unmarked() -> None:
    item = _item(
        "item-order",
        [_token("n", "ń", syllabic=True)],
        learner_facing=True,
    )
    result = lint_yoruba(item, _KIT)
    assert result.rule_id == "YO_NASAL_TONE"
    assert result.rule_id != "YO_UNMARKED_TOKEN"
    assert result.status == "fail"
