"""Hausa source stack (CURRICULUM §2.4)."""

from __future__ import annotations

import csv
import sys
from pathlib import Path
from typing import Any

import yaml

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

_ENGINE = Path(__file__).resolve().parents[1]
_SOURCES = _ENGINE / "kits" / "ha" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_EXCLUSIONS = _ENGINE / "licences" / "exclusions.yaml"

_SPECIAL_CHARACTERS = ("ɓ", "ɗ", "ƙ", "ƴ", "\u02bc")
_LEXICON_IDS = (
    "oxford-languages",
    "wiktionary-kaikki",
    "bargery-hausa-1934",
)
_CORPORA_AUDIO_IDS = (
    "leipzig-corpora",
    "biblica-hausa",
    "common-voice-ha",
    "fleurs",
)
_REGISTER_IDS = (
    "fsi-hausa",
    "peace-corps-hausa",
    "wiktionary-kaikki",
    "leipzig-corpora",
    "biblica-hausa",
    "common-voice-ha",
    "fleurs",
)
_EXCLUDED_IDS = ("oxford-languages", "bargery-hausa-1934")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("ha sources.yaml must be a mapping")
    return data


def _register_ids() -> set[str]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return {row["source_id"] for row in csv.DictReader(handle) if row.get("source_id")}


def _exclusion_ids() -> set[str]:
    with _EXCLUSIONS.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    return set(sources)


def _newman(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["grammar"]:
        if row.get("author") == "Newman":
            return row
    raise AssertionError("Newman grammar row missing")


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["standard"] == "standard Boko"
    assert ortho["special_characters"] == list(_SPECIAL_CHARACTERS)
    assert ortho["special_characters"][-1] == "\u02bc"
    assert ortho["tone_and_length"] == "unwritten in normal text"
    assert ortho["pedagogical_marking"] == "dictionary-lookup"
    assert ortho["model_generation"] is False


def test_lexicon_source_ids_order() -> None:
    stack = _load_stack()
    assert [row["source_id"] for row in stack["lexicon"]] == list(_LEXICON_IDS)
    oxford, wiktionary, bargery = stack["lexicon"]
    assert oxford["role"] == "licensed"
    assert oxford["held"] is False
    assert oxford["dataset"] == "Hausa"
    assert wiktionary["role"] == "cross-check"
    assert bargery["role"] == "reference"


def test_fsi_grammar_public_domain_basic() -> None:
    fsi = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "fsi-hausa"
    )
    assert fsi["licence"] == "public-domain"
    assert fsi["course"] == "Basic"


def test_peace_corps_pd_status_unconfirmed() -> None:
    peace = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "peace-corps-hausa"
    )
    assert peace["pd_status"] == "unconfirmed"


def test_newman_not_purchased() -> None:
    row = _newman(_load_stack())
    assert row["title"] == "The Hausa Language"
    assert row["publisher"] == "Yale"
    assert row["year"] == 2000
    assert row["purchased"] is False


def test_corpora_audio_ids() -> None:
    assert _load_stack()["corpora_audio"] == list(_CORPORA_AUDIO_IDS)


def test_lexicon_lookup_no_model_generation() -> None:
    tool = _load_stack()["tools"]["lexicon-lookup"]
    assert tool["use"] == "tone and length marks"
    assert tool["model_generation"] is False


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_excluded_lexicon_ids_in_exclusions() -> None:
    ids = _exclusion_ids()
    for source_id in _EXCLUDED_IDS:
        assert source_id in ids


def test_newman_not_register_row() -> None:
    ids = _register_ids()
    newman = _newman(_load_stack())
    assert "source_id" not in newman
    assert newman["author"] not in ids
    assert newman["title"] not in ids
