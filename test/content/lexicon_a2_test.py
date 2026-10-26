"""P5-081 A2 cumulative lexicon selection tests."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.lexicon_select import (  # noqa: E402
    A2_DEFAULT_CUMULATIVE_TARGET,
    A2_MAX_CUMULATIVE,
    A2_MIN_CUMULATIVE,
    CARD_ID_A2,
    LexiconCountGateError,
    assert_a2_cumulative_gate,
    build_a2_language_manifest,
    select_a2_cumulative_lexemes,
)

_REGISTER = {
    "leipzig": {"id": "leipzig", "licence": "CC BY", "use": "ship"},
}


def _lexeme(
    *,
    item_id: str,
    lemma: str,
    rank: int,
    source_id: str = "leipzig",
    tone_marked: bool = False,
) -> dict:
    return {
        "id": item_id,
        "type": "lexeme",
        "text": lemma,
        "orthography": {
            "standard": lemma,
            "ascii_fallback": lemma,
            "script": "Latn",
            "tone_marked": tone_marked,
        },
        "frequency_rank": rank,
        "provenance": {
            "sources": [
                {
                    "source_id": source_id,
                    "licence": "CC BY",
                    "locator": "corpus frequency",
                    "role": "shipped_text",
                }
            ]
        },
        "senses": [],
    }


def _a1_row(item_id: str, lemma: str) -> dict:
    return {
        "id": item_id,
        "lemma": lemma,
        "frequency_rank": 1,
        "adjusted_rank": 1,
        "frequency_source_id": "leipzig",
        "licence_id": "leipzig",
        "lexicon_anchor": lemma,
        "linguist_review": False,
        "beta_eligible": True,
        "learner_boosted": False,
    }


def test_P5_081_cumulative_gate_bounds() -> None:
    assert_a2_cumulative_gate(A2_MIN_CUMULATIVE, "sw")
    assert_a2_cumulative_gate(A2_MAX_CUMULATIVE, "sw")
    with pytest.raises(LexiconCountGateError):
        assert_a2_cumulative_gate(A2_MIN_CUMULATIVE - 1, "ha")


def test_P5_081_select_merges_a1_and_ranked_a2() -> None:
    a1 = [_a1_row(f"pcm.lex.a{i}", f"a{i}") for i in range(700)]
    a2_items = [_lexeme(item_id=f"pcm.lex.b{i}", lemma=f"b{i}", rank=i) for i in range(1, 801)]
    pack = {"lang": "pcm", "level": "A2", "items": a2_items}
    combined, added = select_a2_cumulative_lexemes(
        a1,
        pack,
        lang="pcm",
        register=_REGISTER,
        cumulative_target=A2_DEFAULT_CUMULATIVE_TARGET,
    )
    assert len(combined) == 1500
    assert added == 800
    assert sum(1 for row in combined if row.get("lexicon_stage") == "A1") == 700
    assert combined[-1]["id"] == "pcm.lex.b800"


def test_P5_081_hausa_shortfall_fails_gate() -> None:
    a1 = [_a1_row(f"ha.lex.a{i}", f"a{i}") for i in range(700)]
    a2_items = [_lexeme(item_id=f"ha.lex.b{i}", lemma=f"b{i}", rank=i) for i in range(1, 241)]
    pack = {"lang": "ha", "level": "A2", "items": a2_items}
    with pytest.raises(LexiconCountGateError):
        select_a2_cumulative_lexemes(
            a1,
            pack,
            lang="ha",
            register=_REGISTER,
            cumulative_target=A2_DEFAULT_CUMULATIVE_TARGET,
        )


def test_P5_081_build_language_manifest_from_canonical_pack() -> None:
    doc = build_a2_language_manifest("yo", _REPO_ROOT)
    assert doc["card"] == CARD_ID_A2
    assert doc["count"] == A2_DEFAULT_CUMULATIVE_TARGET
    assert doc["a1_count"] == 700
    assert doc["a2_added"] == 800
    assert all(row.get("licence_id") == "leipzig" for row in doc["lexemes"])
