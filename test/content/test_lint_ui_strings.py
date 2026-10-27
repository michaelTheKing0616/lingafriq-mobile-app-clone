"""P10-938: UI copy linter — em dash, banned words, verb-first buttons."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.copy.lint_ui_strings import (  # noqa: E402
    lint_arb,
    lint_button_verb,
    lint_string_value,
    load_banned_words,
)

_BANNED = _REPO_ROOT / "scripts" / "copy" / "banned_words.txt"
_EN_ARB = _REPO_ROOT / "lib" / "l10n" / "app_en.arb"


def _arb(tmp_path: Path, entries: dict[str, str], meta: dict[str, dict] | None = None) -> Path:
    path = tmp_path / "app_en.arb"
    payload: dict = {"@@locale": "en", **entries}
    if meta:
        for key, block in meta.items():
            payload[f"@{key}"] = block
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def test_AC1_em_dash_fails() -> None:
    banned = load_banned_words(_BANNED)
    hits = lint_string_value("k", "Wait\u2014stop", banned)
    assert any(h.rule == "EM_DASH" for h in hits)
    assert not lint_string_value("k", "Use a hyphen - fine", banned)


def test_AC2_banned_words_case_insensitive() -> None:
    banned = load_banned_words(_BANNED)
    for sample in ("World-class app", "elite mode", "Seamless flow"):
        assert any(h.rule == "BANNED_WORD" for h in lint_string_value("k", sample, banned))


def test_AC3_button_verb_pass_and_fail() -> None:
    assert lint_button_verb("startLesson", "Start lesson") is None
    assert lint_button_verb("hearAgain", "Hear it again") is None
    bad = lint_button_verb("next", "Next")
    assert bad is not None and bad.rule == "BUTTON_NOT_VERB"


def test_AC4_banned_list_file_only() -> None:
    words = load_banned_words(_BANNED)
    assert "world-class" in words
    assert "elite" in words


def test_integration_full_app_en_arb_passes() -> None:
    findings = lint_arb(_EN_ARB, _BANNED)
    assert findings == []


def test_button_metadata_detection(tmp_path: Path) -> None:
    path = _arb(
        tmp_path,
        {"liveEnd": "End session", "homeTab": "Home"},
        meta={
            "liveEnd": {"description": "Button label to end session"},
            "homeTab": {"description": "Home tab label"},
        },
    )
    findings = lint_arb(path, _BANNED)
    assert not any(f.key == "homeTab" for f in findings)
    assert not any(f.key == "liveEnd" for f in findings)
