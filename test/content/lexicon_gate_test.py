"""P13-003 lexicon gate for later-wave languages beyond L0."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.content.lexicon_gate import (  # noqa: E402
    CARD_ID,
    LexiconGateError,
    assess_lexicon_source,
    assert_promotion_above_l0_allowed,
    gate_promotion_request,
    reconcile_readiness_after_lexicon_check,
)

_FIXTURE_REGISTER = [
    {
        "id": "fsi",
        "source": "FSI courses",
        "licence": "Public Domain (US Government)",
        "use": "ship",
    },
    {
        "id": "removed_lex",
        "source": "Former lexicon",
        "licence": "CC BY 4.0",
        "use": "exclude",
    },
]


def _admission(language_id: str = "ff", *, lexicon_register: str = "fsi", lexicon_title: str = "FSI Fulfulde") -> dict:
    return {
        "card_id": "P13-001",
        "language_id": language_id,
        "display_name": "Fulfulde",
        "admission": {
            "orthography_authority": {"title": "x", "register_id": "fsi", "licence": "Public Domain"},
            "lexicon": {
                "title": lexicon_title,
                "register_id": lexicon_register,
                "licence": "Public Domain (US Government)",
            },
            "reference_grammar": {"title": "x", "register_id": "fsi", "licence": "Public Domain"},
            "corpus": {"title": "x", "register_id": "fsi", "licence": "CC BY 4.0"},
        },
    }


def test_assess_passes_with_licensed_lexicon() -> None:
    result = assess_lexicon_source(_admission(), register_rows=_FIXTURE_REGISTER)
    assert result["ok"] is True
    assert result["language_id"] == "ff"


def test_promotion_above_l0_rejects_missing_lexicon_title() -> None:
    doc = _admission()
    doc["admission"]["lexicon"]["title"] = ""
    with pytest.raises(LexiconGateError) as exc:
        assert_promotion_above_l0_allowed(
            doc,
            target_readiness_level="L1",
            register_rows=_FIXTURE_REGISTER,
        )
    assert exc.value.code == "LEXICON_SOURCE_MISSING"
    assert exc.value.language_id == "ff"
    assert "ff" in str(exc.value)


def test_promotion_l0_allowed_without_lexicon() -> None:
    doc = _admission()
    doc["admission"]["lexicon"]["title"] = ""
    assert_promotion_above_l0_allowed(
        doc,
        target_readiness_level="L0",
        register_rows=_FIXTURE_REGISTER,
    )


def test_gate_promotion_request_passes_other_gates_still_separate() -> None:
    manifest = {"readiness_level": "L0", "language_id": "ff"}
    out = gate_promotion_request(
        manifest,
        _admission(),
        target_readiness_level="L1",
        register_rows=_FIXTURE_REGISTER,
    )
    assert out["card_id"] == CARD_ID
    assert out["lexicon_gate_passed"] is True


def test_reconcile_demotes_when_register_excluded() -> None:
    doc = _admission(lexicon_register="removed_lex")
    manifest = {"readiness_level": "L2", "language_id": "ff"}
    result = reconcile_readiness_after_lexicon_check(
        manifest,
        doc,
        register_rows=_FIXTURE_REGISTER,
    )
    assert result["demoted"] is True
    assert manifest["readiness_level"] == "L0"
    assert manifest["lexicon_gate_flags"]
    assert result["code"] == "LEXICON_REGISTER_EXCLUDED"


def test_reconcile_leaves_l0_when_lexicon_removed() -> None:
    doc = _admission(lexicon_register="unknown_id")
    manifest = {"readiness_level": "L0", "language_id": "ff"}
    result = reconcile_readiness_after_lexicon_check(
        manifest,
        doc,
        register_rows=_FIXTURE_REGISTER,
    )
    assert result["demoted"] is False
    assert manifest["readiness_level"] == "L0"
    assert result["code"] == "LEXICON_REGISTER_REMOVED"
