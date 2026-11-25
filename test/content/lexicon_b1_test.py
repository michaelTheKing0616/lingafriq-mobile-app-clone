"""P5-082 B1 cumulative lexicon selection tests."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.lexicon_select import (  # noqa: E402
    B1_DEFAULT_CUMULATIVE_TARGET,
    B1_MAX_CUMULATIVE,
    B1_MIN_CUMULATIVE,
    CARD_ID_B1,
    LexiconCountGateError,
    assert_b1_cumulative_gate,
    build_b1_language_manifest,
    select_b1_cumulative_lexemes,
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


def _a2_row(item_id: str, lemma: str, stage: str = "A2") -> dict:
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
        "lexicon_stage": stage,
    }


def test_P5_082_cumulative_gate_bounds() -> None:
    assert_b1_cumulative_gate(B1_MIN_CUMULATIVE, "sw")
    assert_b1_cumulative_gate(B1_MAX_CUMULATIVE, "sw")
    with pytest.raises(LexiconCountGateError):
        assert_b1_cumulative_gate(B1_MIN_CUMULATIVE - 1, "ha")


def test_P5_082_select_merges_a2_and_ranked_b1() -> None:
    a2 = [_a2_row(f"pcm.lex.a{i}", f"a{i}") for i in range(1500)]
    b1_items = [_lexeme(item_id=f"pcm.lex.c{i}", lemma=f"c{i}", rank=i) for i in range(1, 1501)]
    pack = {"lang": "pcm", "level": "B1", "items": b1_items}
    combined, added = select_b1_cumulative_lexemes(
        a2,
        pack,
        lang="pcm",
        register=_REGISTER,
        cumulative_target=B1_DEFAULT_CUMULATIVE_TARGET,
    )
    assert len(combined) == 2750
    assert added == 1250
    assert combined[-1]["lexicon_stage"] == "B1"
    assert combined[-1]["id"] == "pcm.lex.c1250"


def test_P5_082_insufficient_b1_lexemes_fails_gate() -> None:
    a2 = [_a2_row(f"zu.lex.a{i}", f"a{i}") for i in range(1500)]
    b1_items = [_lexeme(item_id=f"zu.lex.c{i}", lemma=f"c{i}", rank=i) for i in range(1, 201)]
    pack = {"lang": "zu", "level": "B1", "items": b1_items}
    with pytest.raises(LexiconCountGateError):
        select_b1_cumulative_lexemes(
            a2,
            pack,
            lang="zu",
            register=_REGISTER,
            cumulative_target=B1_DEFAULT_CUMULATIVE_TARGET,
        )


def test_P5_082_tonal_unanchored_not_beta() -> None:
    a2 = [_a2_row(f"yo.lex.a{i}", f"a{i}") for i in range(1500)]
    b1_items = [
        _lexeme(item_id="yo.lex.c1", lemma="oko", rank=1, tone_marked=False),
        *[
            _lexeme(item_id=f"yo.lex.c{i}", lemma=f"c{i}", rank=i, tone_marked=True)
            for i in range(2, 1300)
        ],
    ]
    pack = {"lang": "yo", "level": "B1", "items": b1_items}
    combined, _ = select_b1_cumulative_lexemes(
        a2,
        pack,
        lang="yo",
        register=_REGISTER,
        cumulative_target=B1_DEFAULT_CUMULATIVE_TARGET,
    )
    unanchored = next(row for row in combined if row.get("id") == "yo.lex.c1")
    assert unanchored["linguist_review"] is True
    assert unanchored["beta_eligible"] is False


def test_P5_082_build_language_manifest_from_canonical_pack() -> None:
    doc = build_b1_language_manifest("yo", _REPO_ROOT)
    assert doc["card"] == CARD_ID_B1
    assert doc["count"] == B1_DEFAULT_CUMULATIVE_TARGET
    assert doc["a2_count"] == 1500
    assert doc["b1_added"] == 1250
    assert all(row.get("licence_id") == "leipzig" for row in doc["lexemes"])
