"""Spec tests for Hausa hooked-letter and display/teaching lint (P4-043)."""

from __future__ import annotations

import sys
import unicodedata
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.hausa import lint_hausa  # noqa: E402
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import LintResult, Span  # noqa: E402

_KIT: dict[str, str] = {"lang": "ha"}
_CORRECT_HOOKS = "ɓɗƙƴʼ"
_MACRON = "\u0304"
_GRAVE = "\u0300"


def _token(
    surface: str,
    lexicon: str,
    dictionary_sourced: bool = False,
    **provenance: object,
) -> dict[str, object]:
    token: dict[str, object] = {
        "surface": surface,
        "lexicon": lexicon,
        "dictionary_sourced": dictionary_sourced,
    }
    token.update(provenance)
    return token


def _item(
    item_id: str,
    tokens: list[dict[str, object]],
    text_role: str = "display",
) -> dict[str, object]:
    return {
        "id": item_id,
        "text_role": text_role,
        "tokens": tokens,
    }


def _pass(item_id: str) -> LintResult:
    return LintResult(item_id=item_id, rule_id="HA", span=Span(0, 0), status="pass")


@pytest.mark.parametrize(
    ("hook", "plain"),
    [
        ("ɓ", "b"),
        ("ɗ", "d"),
        ("ƙ", "k"),
        ("ƴ", "y"),
        ("ʼ", "\u0027"),
        ("Ƙ", "K"),
        ("Ɓ", "b"),
    ],
)
def test_P4_043_AC1_plain_hook_replacement_fails(hook: str, plain: str) -> None:
    item = _item("item-hook-1", [_token(plain, hook, dictionary_sourced=False)])
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_HOOKED_LETTER"
    assert result.item_id == "item-hook-1"
    assert plain[result.span.start : result.span.end] == plain


def test_P4_043_AC1_correct_hooks_pass() -> None:
    item = _item(
        "item-hook-ok",
        [_token(_CORRECT_HOOKS, _CORRECT_HOOKS, dictionary_sourced=False)],
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-hook-ok")


def test_P4_043_AC1_ci_exit_code_blocks_failure() -> None:
    failing = _item("item-ci-fail", [_token("b", "ɓ", dictionary_sourced=False)])
    fail_results = run_linters(failing, _KIT, [lint_hausa])
    assert fail_results[0].rule_id == "HA_HOOKED_LETTER"
    assert exit_code(fail_results) == 1

    passing = _item(
        "item-ci-pass",
        [_token(_CORRECT_HOOKS, _CORRECT_HOOKS, dictionary_sourced=False)],
    )
    pass_results = run_linters(passing, _KIT, [lint_hausa])
    assert exit_code(pass_results) == 0


@pytest.mark.parametrize(
    ("surface", "mark"),
    [
        ("à", _GRAVE),
        ("a" + _MACRON, _MACRON),
    ],
)
def test_P4_043_AC2_display_tone_or_length_fails(surface: str, mark: str) -> None:
    item = _item(
        "item-display-mark",
        [_token(surface, surface, dictionary_sourced=True)],
        text_role="display",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_DISPLAY_MARKED"
    sliced = surface[result.span.start : result.span.end]
    assert mark in unicodedata.normalize("NFD", sliced)


def test_P4_043_AC2_display_hooks_without_marks_pass() -> None:
    item = _item(
        "item-display-hooks",
        [_token(_CORRECT_HOOKS, _CORRECT_HOOKS, dictionary_sourced=False)],
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-display-hooks")


def test_P4_043_AC3_unsourced_mark_fails() -> None:
    item = _item(
        "item-unsourced",
        [_token("à", "à", dictionary_sourced=False)],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_MARK_NO_DICT"


def test_P4_043_AC3_sourced_form_missing_mark_fails() -> None:
    item = _item(
        "item-sourced-missing",
        [_token("à", "a", dictionary_sourced=True)],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_MARK_NO_DICT"


def test_P4_043_AC3_sourced_matching_mark_passes() -> None:
    item = _item(
        "item-sourced-ok",
        [_token("à", "a" + _GRAVE, dictionary_sourced=True)],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-sourced-ok")


def test_P4_043_AC3_dictionary_lexicon_provenance_passes() -> None:
    item = _item(
        "item-dict-entry",
        [
            _token(
                "à",
                "a" + _GRAVE,
                dictionary_sourced=False,
                dictionary_entry="lex-ha-001",
            )
        ],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-dict-entry")


@pytest.mark.parametrize(
    "person_field",
    ["author_id", "native_speaker_id", "reviewer_id"],
)
def test_P4_043_AC3_native_author_provenance_passes(person_field: str) -> None:
    item = _item(
        "item-native-ok",
        [
            _token(
                "à",
                "a" + _GRAVE,
                dictionary_sourced=False,
                review_date="2026-01-15",
                **{person_field: "speaker-1"},
            )
        ],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-native-ok")


@pytest.mark.parametrize(
    "span_field",
    ["timestamp", "time_span", "span"],
)
def test_P4_043_AC3_import_media_provenance_passes(span_field: str) -> None:
    item = _item(
        "item-media-ok",
        [
            _token(
                "à",
                "a" + _GRAVE,
                dictionary_sourced=False,
                media_id="media-1",
                **{span_field: "00:01.200"},
            )
        ],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-media-ok")


def test_P4_043_AC3_native_author_without_review_date_fails() -> None:
    item = _item(
        "item-native-no-date",
        [_token("à", "a" + _GRAVE, dictionary_sourced=False, author_id="author-1")],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_MARK_NO_DICT"


def test_P4_043_AC3_import_media_without_span_fails() -> None:
    item = _item(
        "item-media-no-span",
        [_token("à", "a" + _GRAVE, dictionary_sourced=False, media_id="media-1")],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_MARK_NO_DICT"


def test_P4_043_AC3_native_author_mark_not_on_form_fails() -> None:
    item = _item(
        "item-native-mark-mismatch",
        [
            _token(
                "à",
                "a",
                dictionary_sourced=False,
                author_id="author-1",
                review_date="2026-01-15",
            )
        ],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_MARK_NO_DICT"


def test_P4_043_AC3_teaching_without_marks_passes() -> None:
    item = _item(
        "item-teach-plain",
        [_token("ɓa", "ɓa", dictionary_sourced=False)],
        text_role="teaching",
    )
    result = lint_hausa(item, _KIT)
    assert result == _pass("item-teach-plain")


def test_P4_043_hook_fails_before_display_mark() -> None:
    item = _item(
        "item-order",
        [_token("bà", "ɓà", dictionary_sourced=False)],
        text_role="display",
    )
    result = lint_hausa(item, _KIT)
    assert result.status == "fail"
    assert result.rule_id == "HA_HOOKED_LETTER"


def test_P4_043_missing_key_raises() -> None:
    item = {
        "id": "item-missing",
        "tokens": [_token("ɓ", "ɓ")],
    }
    with pytest.raises(KeyError):
        lint_hausa(item, _KIT)


def test_P4_043_kit_must_be_mapping() -> None:
    item = _item("item-kit", [_token("ɓ", "ɓ")])
    with pytest.raises(TypeError):
        lint_hausa(item, ["not-a-mapping"])  # type: ignore[arg-type]


def test_P4_043_bad_text_role_raises() -> None:
    item = _item("item-role", [_token("ɓ", "ɓ")], text_role="learner")
    with pytest.raises(ValueError):
        lint_hausa(item, _KIT)
