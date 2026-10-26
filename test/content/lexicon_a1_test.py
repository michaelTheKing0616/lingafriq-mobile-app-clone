"""P5-016 A1 lexicon selection tests."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.lexicon_select import (  # noqa: E402
    DEFAULT_TARGET,
    LicenceUnregistered,
    LexiconCountGateError,
    MAX_LEXEMES,
    MIN_LEXEMES,
    adjusted_rank,
    assert_count_gate,
    build_language_manifest,
    learner_needs_boost,
    rank_lexemes,
    select_a1_lexemes,
)

_REGISTER = {
    "leipzig": {"id": "leipzig", "licence": "CC BY", "use": "ship"},
    "kaikki": {"id": "kaikki", "licence": "CC BY-SA 4.0", "use": "cross-check only"},
}


def _lexeme(
    *,
    item_id: str,
    lemma: str,
    rank: int,
    source_id: str = "leipzig",
    gloss: str | None = None,
    tone_marked: bool = False,
) -> dict:
    orthography = {
        "standard": lemma,
        "ascii_fallback": lemma,
        "script": "Latn",
        "tone_marked": tone_marked,
    }
    senses = [{"gloss_en": gloss, "gloss_status": "needs-review"}] if gloss else []
    return {
        "id": item_id,
        "type": "lexeme",
        "text": lemma,
        "orthography": orthography,
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
        "senses": senses,
    }


def _pack(lang: str, items: list[dict]) -> dict:
    return {"lang": lang, "level": "A1", "items": items}


def test_P5_016_ranking_learner_boost_moves_market_gloss() -> None:
    plain = _lexeme(item_id="yo.lex.a", lemma="ni", rank=10)
    boosted = _lexeme(item_id="yo.lex.b", lemma="oja", rank=11, gloss="market stall")
    ranked = rank_lexemes([plain, boosted], lang="yo", register=_REGISTER)
    assert ranked[0].id == "yo.lex.b"
    assert ranked[0].learner_boosted is True
    assert adjusted_rank(11, True) < adjusted_rank(10, False)


def test_P5_016_licence_unregistered() -> None:
    bad = _lexeme(item_id="yo.lex.x", lemma="x", rank=1, source_id="not-in-register")
    with pytest.raises(LicenceUnregistered):
        rank_lexemes([bad], lang="yo", register=_REGISTER)


def test_P5_016_tonal_without_anchor_routes_linguist_not_beta() -> None:
    item = _lexeme(item_id="yo.lex.plain", lemma="baba", rank=5, tone_marked=False)
    row = rank_lexemes([item], lang="yo", register=_REGISTER)[0]
    assert row.lexicon_anchor is None
    assert row.linguist_review is True
    assert row.beta_eligible is False


def test_P5_016_tonal_with_marked_anchor_is_beta() -> None:
    item = _lexeme(item_id="yo.lex.toned", lemma="bàbá", rank=5, tone_marked=True)
    row = rank_lexemes([item], lang="yo", register=_REGISTER)[0]
    assert row.lexicon_anchor == "bàbá"
    assert row.linguist_review is False
    assert row.beta_eligible is True


def test_P5_016_pcm_not_tonal_gets_anchor() -> None:
    item = _lexeme(item_id="pcm.lex.a", lemma="dey", rank=3)
    row = rank_lexemes([item], lang="pcm", register=_REGISTER)[0]
    assert row.lexicon_anchor == "dey"
    assert row.linguist_review is False


def test_P5_016_count_gate() -> None:
    assert_count_gate(MIN_LEXEMES, "yo")
    assert_count_gate(MAX_LEXEMES, "ha")
    with pytest.raises(LexiconCountGateError):
        assert_count_gate(MIN_LEXEMES - 1, "ig")


def test_P5_016_select_respects_target_and_gate() -> None:
    items = [
        _lexeme(item_id=f"sw.lex.{i}", lemma=f"w{i}", rank=i)
        for i in range(1, MAX_LEXEMES + 1)
    ]
    selected = select_a1_lexemes(_pack("sw", items), lang="sw", register=_REGISTER, target=650)
    assert len(selected) == 650
    assert selected[0].frequency_rank == 1


def test_P5_016_build_language_manifest_from_canonical_pack() -> None:
    doc = build_language_manifest("pcm", _REPO_ROOT, target=DEFAULT_TARGET)
    assert doc["lang"] == "pcm"
    assert MIN_LEXEMES <= doc["count"] <= MAX_LEXEMES
    assert doc["lexemes"][0]["licence_id"] == "leipzig"


def test_P5_016_learner_needs_boost_helper() -> None:
    assert learner_needs_boost(_lexeme(item_id="x", lemma="a", rank=1, gloss="family greeting"))
    assert not learner_needs_boost(_lexeme(item_id="y", lemma="b", rank=2))
