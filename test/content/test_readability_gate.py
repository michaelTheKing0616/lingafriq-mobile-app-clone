"""P10-939: Grade-7 readability and name continuity gates."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.copy.name_continuity import (  # noqa: E402
    CONTINUITY_PAIRS,
    check_pair,
)
from scripts.copy.readability_gate import (  # noqa: E402
    flesch_kincaid_grade,
    gate_arb,
    gate_string,
    is_probably_english,
    sample_review,
    warmth_check,
)

_EN_ARB = _REPO_ROOT / "lib" / "l10n" / "app_en.arb"


def _arb(tmp_path: Path, entries: dict[str, str]) -> Path:
    path = tmp_path / "app_en.arb"
    payload: dict = {"@@locale": "en", **entries}
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def test_grade_calc_simple_sentence() -> None:
    easy = flesch_kincaid_grade("The cat sat on the mat.")
    hard = flesch_kincaid_grade(
        "The incomprehensible methodological instrumentation demonstrated conceptualization."
    )
    assert easy < hard


def test_AC1_long_string_over_grade_fails() -> None:
    hard = (
        "The incomprehensible methodological instrumentation demonstrated "
        "extraordinary conceptualization throughout the investigation."
    )
    findings, skip = gate_string("k", hard)
    assert skip is None
    assert any(f.rule == "READABILITY_GRADE" for f in findings)


def test_AC1_short_string_skips_grade() -> None:
    findings, skip = gate_string("k", "Try again")
    assert findings == []
    assert skip is None


def test_AC4_non_english_skipped_not_passed() -> None:
    findings, skip = gate_string("k", "مرحبا بكم في التطبيق")
    assert findings == []
    assert skip is not None and skip.reason == "non_english"


def test_continuity_publish_published_pair() -> None:
    pair = next(p for p in CONTINUITY_PAIRS if p.verb == "Publish")
    ok = {"contentPublishAction": "Publish", "contentPublishDone": "Published"}
    assert check_pair(pair, ok) == []
    bad = {"contentPublishAction": "Publish", "contentPublishDone": "Live now"}
    assert any(f.rule == "CONTINUITY_PAST" for f in check_pair(pair, bad))


def test_continuity_save_saved_pair() -> None:
    pair = next(p for p in CONTINUITY_PAIRS if p.verb == "Save")
    strings = {"polieTutorSaveCard": "Save", "polieTutorSavedCards": "Saved cards"}
    assert check_pair(pair, strings) == []


def test_warmth_rejects_placeholder() -> None:
    assert any(h.rule == "COPY_PLACEHOLDER" for h in warmth_check("k", "TODO: fix copy"))


def test_integration_full_app_en_arb() -> None:
    findings, skipped = gate_arb(_EN_ARB)
    assert findings == []
    assert sample_review(_EN_ARB) == []
    assert is_probably_english("Hello friend")
