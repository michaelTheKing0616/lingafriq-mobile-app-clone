"""Spec tests for Pidgin NLA spelling lint (P4-047)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
import yaml

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.pidgin_nla import lint_pidgin_nla  # noqa: E402
from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402

_PCM_KIT_PATH = _REPO_ROOT / "tools/content_engine/kits/pcm/kit.yaml"
_ENGLISH = "ENGLISH_SPELLING"
_NLA = "NLA_FORM"
_FIXTURE_ROW = {"english": _ENGLISH, "nla": _NLA}
_USABLE_KIT: dict[str, object] = {
    "nla_normalisation": {
        "table_included": True,
        "rows": [_FIXTURE_ROW],
    }
}


def _item(item_id: str, text: str, language: str = "pcm") -> dict[str, str]:
    return {"id": item_id, "language": language, "text": text}


def _load_pcm_kit() -> object:
    with _PCM_KIT_PATH.open(encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def test_P4_047_AC1_english_spelling_flags_nla_form() -> None:
    text = f"see {_ENGLISH} now"
    result = lint_pidgin_nla(_item("item-en", text), _USABLE_KIT)
    assert result.status == "fail"
    assert result.rule_id == "PCM_ENGLISH_SPELLING"
    assert result.nla_form == _NLA
    assert text[result.span.start : result.span.end] == _ENGLISH


def test_P4_047_AC2_nla_form_raises_no_flag() -> None:
    result = lint_pidgin_nla(_item("item-nla", _NLA), _USABLE_KIT)
    assert result.status == "pass"
    assert result.rule_id == "PCM_NLA"


def test_P4_047_token_absent_from_table_passes() -> None:
    result = lint_pidgin_nla(_item("item-other", "OTHER_TOKEN"), _USABLE_KIT)
    assert result.status == "pass"
    assert result.rule_id == "PCM_NLA"


def test_P4_047_shipped_kit_missing_table_fails() -> None:
    result = lint_pidgin_nla(_item("item-shipped", _NLA), _load_pcm_kit())
    assert result.status == "fail"
    assert result.rule_id == "PCM_NLA_TABLE_MISSING"
    assert result.nla_form == ""


def test_P4_047_empty_rows_fail() -> None:
    kit = {"nla_normalisation": {"table_included": True, "rows": []}}
    result = lint_pidgin_nla(_item("item-empty", _NLA), kit)
    assert result.status == "fail"
    assert result.rule_id == "PCM_NLA_TABLE_MISSING"
    assert result.nla_form == ""


def test_P4_047_table_included_false_ignores_rows() -> None:
    kit = {
        "nla_normalisation": {
            "table_included": False,
            "rows": [_FIXTURE_ROW],
        }
    }
    result = lint_pidgin_nla(_item("item-off", _ENGLISH), kit)
    assert result.status == "fail"
    assert result.rule_id == "PCM_NLA_TABLE_MISSING"
    assert result.nla_form == ""


def test_P4_047_AC1_ci_exit_code_blocks_failure() -> None:
    english = _item("item-ci-en", f"see {_ENGLISH} now")
    assert exit_code(run_linters(english, _USABLE_KIT, [lint_pidgin_nla])) == 1

    shipped = _item("item-ci-kit", _NLA)
    assert exit_code(run_linters(shipped, _load_pcm_kit(), [lint_pidgin_nla])) == 1

    nla = _item("item-ci-nla", _NLA)
    assert exit_code(run_linters(nla, _USABLE_KIT, [lint_pidgin_nla])) == 0


def test_P4_047_duplicate_english_raises() -> None:
    kit = {
        "nla_normalisation": {
            "table_included": True,
            "rows": [_FIXTURE_ROW, {"english": _ENGLISH, "nla": _NLA}],
        }
    }
    with pytest.raises(ValueError):
        lint_pidgin_nla(_item("item-dup", _NLA), kit)


def test_P4_047_bad_language_raises() -> None:
    with pytest.raises(ValueError):
        lint_pidgin_nla(_item("item-lang", _NLA, language="en"), _USABLE_KIT)


def test_P4_047_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_pidgin_nla(_item("item-kit", _NLA), ["not-a-mapping"])  # type: ignore[arg-type]
