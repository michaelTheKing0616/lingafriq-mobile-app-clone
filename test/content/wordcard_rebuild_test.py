"""P5-004 Word Card rebuild and WC-001/002 lint."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.wordcard_rebuild import (  # noqa: E402
    CARD_ID,
    RULE_WC001,
    RULE_WC002,
    is_p0_17_flagged,
    is_truncated_topic,
    lint_word_card,
    lint_word_cards,
    rebuild_game_words,
    rebuild_word_card,
    run_rebuild,
)

_FIXTURE_IPA = "/ɛ.kú.à.á.ɾɔ̀/"
_FIXTURE_PATTERN = "fixture-H-L"


def _lookup(kit_lang: str, form: str) -> dict[str, str] | None:
    if kit_lang == "yo" and form == "Ẹ kú àárọ̀":
        return {"tone_pattern": _FIXTURE_PATTERN, "ipa": _FIXTURE_IPA}
    return None


def test_wc001_rejects_copied_phonetic_equals_tonal() -> None:
    word = {
        "id": 99,
        "language": "yoruba",
        "word": "test",
        "phonetic_guide": "same",
        "tonal_note": "same",
    }
    rules = {f.rule_id for f in lint_word_card(word)}
    assert RULE_WC001 in rules


def test_wc002_rejects_truncated_topic() -> None:
    word = {"id": 1, "topic": "Good morning (to elders"}
    rules = {f.rule_id for f in lint_word_card(word)}
    assert RULE_WC002 in rules


def test_P5_004_AC1_rebuild_phonetic_from_ipa_or_null() -> None:
    word = {
        "id": 12,
        "language": "yoruba",
        "word": "Ẹ kú àárọ̀",
        "phonetic_guide": "copied",
        "tonal_note": "copied",
    }
    rebuilt, _ = rebuild_word_card(word, _lookup)
    assert rebuilt["phonetic_guide"] == _FIXTURE_IPA
    assert lint_word_card(rebuilt) == ()

    no_lex, _ = rebuild_word_card(word, None)
    assert no_lex["phonetic_guide"] is None
    assert lint_word_card(no_lex) == ()


def test_P5_004_AC2_clears_p0_17_and_lexicon_anchors_tone() -> None:
    word = {
        "id": 1,
        "language": "yoruba",
        "word": "Ẹ kú àárọ̀",
        "tonal_note": "àárọ̀ carries low tones; respect comes from the honorific Ẹ.",
        "tone_citation": "elevation audit P0-17",
        "topic": "Good morning (to elders",
    }
    assert is_p0_17_flagged(word)
    rebuilt, counts = rebuild_word_card(word, _lookup)
    assert counts["p0_17_cleared"] == 1
    assert counts["topics_restored"] == 1
    assert "tone_citation" not in rebuilt
    assert rebuilt["tonal_note"] == f"tone_pattern: {_FIXTURE_PATTERN}"
    assert rebuilt["topic"] == "Good morning (to elders/group)"
    assert is_truncated_topic(rebuilt["topic"]) is False


def test_P5_004_AC3_truncated_topics_restored_or_lint_fails() -> None:
    broken = [
        {"id": 454, "language": "zulu", "topic": "Hello (to many", "english_meaning": "Hello (to many / respect)"},
        {"id": 589, "language": "xhosa", "topic": "Hello (plural", "english_meaning": "Hello (plural/respect)"},
    ]
    rebuilt, stats = rebuild_game_words(broken)
    assert stats.topics_restored == 2
    assert lint_word_cards(rebuilt) == ()
    for row in rebuilt:
        assert ")" in row["topic"]


def test_P5_004_relints_shipped_game_content_in_memory() -> None:
    game_path = _REPO_ROOT / "assets/data/game_content.json"
    if not game_path.is_file():
        pytest.skip("game_content.json not present")
    data = json.loads(game_path.read_text(encoding="utf-8"))
    words = data.get("words")
    assert isinstance(words, list)
    assert len(words) == 1409
    rebuilt, stats = rebuild_game_words(words, _lookup)
    findings = lint_word_cards(rebuilt)
    assert findings == (), f"lint failures after rebuild: {findings[:5]}"
    w1 = next(w for w in rebuilt if w.get("id") == 1)
    assert "P0-17" not in json.dumps(w1)
    assert stats.topics_restored >= 3


def test_run_rebuild_dry_run_does_not_write(tmp_path: Path) -> None:
    payload = {
        "meta": {"version": "test"},
        "words": [
            {
                "id": 1,
                "language": "yoruba",
                "word": "Ẹ kú àárọ̀",
                "topic": "Good morning (to elders",
                "tonal_note": "note",
                "tone_citation": "elevation audit P0-17",
            }
        ],
    }
    path = tmp_path / "game_content.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    before = path.read_text(encoding="utf-8")
    stats, findings, _ = run_rebuild(tmp_path, dry_run=True, game_path=path, lexicon_lookup=_lookup)
    assert path.read_text(encoding="utf-8") == before
    assert stats.topics_restored == 1
    assert findings == ()


def test_card_id_constant() -> None:
    assert CARD_ID == "P5-004"


def test_lint_only_cli_on_broken_fixture(tmp_path: Path) -> None:
    from tools.content.wordcard_rebuild import main

    path = tmp_path / "game_content.json"
    path.write_text(
        json.dumps(
            {
                "words": [
                    {
                        "id": 1,
                        "phonetic_guide": "x",
                        "tonal_note": "x",
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    assert main(["--lint-only", "--game-content", str(path)]) == 1
