"""P4-046 Mode A: loud failure when ZulMorph is off or cannot parse."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.runner import exit_code, run_linters  # noqa: E402
from tools.content_engine.linters.types import Span  # noqa: E402
from tools.content_engine.linters.zulmorph import (  # noqa: E402
    lint_zulmorph,
    zulmorph_report,
)

_ITEM = {"id": "zu-p4-046", "language": "zu", "form": "hamba"}
_FORM = "hamba"


def test_P4_046_AC1_parse_fail_is_human_review() -> None:
    # labelled fixture of the external analyser, not a mock of lint_zulmorph
    kit = {"external_zulmorph_fixture": lambda form: False}
    result = lint_zulmorph(_ITEM, kit)
    assert result.status == "fail"
    assert result.rule_id == "ZULMORPH_PARSE_FAIL"
    assert result.item_id == "zu-p4-046"
    assert result.span == Span(0, len(_FORM))
    assert zulmorph_report(_ITEM, kit) == {
        "route": "human_review",
        "auto_publish": False,
    }
    assert result.status != "pass"
    assert exit_code(run_linters(_ITEM, kit, [lint_zulmorph])) == 1


def test_P4_046_AC1_parsed_form_does_not_auto_publish() -> None:
    # labelled fixture of the external analyser, not a mock of lint_zulmorph
    kit = {"external_zulmorph_fixture": lambda form: True}
    result = lint_zulmorph(_ITEM, kit)
    assert result.status == "pass"
    assert result.rule_id == "ZULMORPH"
    assert zulmorph_report(_ITEM, kit) == {"route": "parsed", "auto_publish": False}


def test_P4_046_AC2_unavailable_fails_loud() -> None:
    kit = {"lang": "zu"}
    result = lint_zulmorph(_ITEM, kit)
    assert result.status == "fail"
    assert result.rule_id == "ZULMORPH_UNAVAILABLE"
    assert result.status != "pass"
    assert zulmorph_report(_ITEM, kit) == {
        "route": "unavailable",
        "auto_publish": False,
    }
    assert exit_code(run_linters(_ITEM, kit, [lint_zulmorph])) == 1


def test_P4_046_bad_language_raises() -> None:
    item = {"id": "zu-p4-046", "language": "xh", "form": "hamba"}
    with pytest.raises(ValueError):
        lint_zulmorph(item, {"lang": "zu"})


def test_P4_046_kit_must_be_mapping() -> None:
    with pytest.raises(TypeError):
        lint_zulmorph(_ITEM, None)  # type: ignore[arg-type]


def test_P4_046_missing_key_raises() -> None:
    with pytest.raises(KeyError):
        lint_zulmorph({"id": "zu-p4-046", "language": "zu"}, {"lang": "zu"})


def test_P4_046_source_does_not_enable() -> None:
    source = (_REPO_ROOT / "tools/content_engine/linters/zulmorph.py").read_text(
        encoding="utf-8"
    )
    assert "AI_ZULMORPH_ENABLED = True" not in source
    assert "enabled = True" not in source
