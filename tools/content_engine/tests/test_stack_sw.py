"""Swahili source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "sw" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_EXCLUSIONS = _ENGINE / "licences" / "exclusions.yaml"

_LEXICON_IDS = (
    "oxford-languages",
    "wiktionary-kaikki",
    "kamusi",
)
_CORPORA_AUDIO_IDS = (
    "leipzig-corpora",
    "common-voice-sw",
    "fleurs",
    "african-storybook",
)
_REGISTER_IDS = (
    "fsi-swahili",
    "peace-corps-kiswahili",
    "wiktionary-kaikki",
    "leipzig-corpora",
    "common-voice-sw",
    "fleurs",
    "african-storybook",
)
_EXCLUDED_IDS = ("oxford-languages", "kamusi")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("sw sources.yaml must be a mapping")
    return data


def _register_ids() -> set[str]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return {row["source_id"] for row in csv.DictReader(handle) if row.get("source_id")}


def _exclusion_ids() -> set[str]:
    with _EXCLUSIONS.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    return set(sources)


def _ashton(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["grammar"]:
        if row.get("author") == "Ashton":
            return row
    raise AssertionError("Ashton grammar row missing")


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["standard"] == "Kiswahili Sanifu"
    assert ortho["authority"] == "BAKITA, Tanzania"
    assert ortho["citation_status"] == "unverified"
    assert ortho["kenyan_notes"] == "unverified"


def test_lexicon_source_ids_order() -> None:
    stack = _load_stack()
    assert [row["source_id"] for row in stack["lexicon"]] == list(_LEXICON_IDS)
    oxford, wiktionary, kamusi = stack["lexicon"]
    assert oxford["role"] == "licensed"
    assert oxford["held"] is False
    assert oxford["api"] == "Swahili"
    assert wiktionary["role"] == "cross-check"
    assert kamusi["optional"] is True
    assert kamusi["status"] == "excluded"
    assert kamusi["request_sent"] is False


def test_fsi_grammar_public_domain_basic_units() -> None:
    fsi = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "fsi-swahili"
    )
    assert fsi["licence"] == "public-domain"
    assert fsi["course"] == "Basic"
    assert fsi["units"] == 150


def test_peace_corps_pd_status_unconfirmed() -> None:
    peace = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "peace-corps-kiswahili"
    )
    assert peace["pd_status"] == "unconfirmed"


def test_ashton_not_purchased() -> None:
    row = _ashton(_load_stack())
    assert row["title"] == "Swahili Grammar"
    assert row["purchased"] is False


def test_corpora_audio_ids() -> None:
    corpora = _load_stack()["corpora_audio"]
    assert [row["source_id"] for row in corpora] == list(_CORPORA_AUDIO_IDS)


def test_common_voice_sw_recorded_hours() -> None:
    cv = next(
        row
        for row in _load_stack()["corpora_audio"]
        if row.get("source_id") == "common-voice-sw"
    )
    assert cv["recorded_hours"] == 1065
    assert isinstance(cv["recorded_hours"], int)


def test_noun_class_concord_checker_card() -> None:
    checker = _load_stack()["tools"]["noun-class-concord-checker"]
    assert checker["card"] == "P4-044"
    assert checker["enabled"] is False


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_excluded_lexicon_ids_in_exclusions() -> None:
    ids = _exclusion_ids()
    for source_id in _EXCLUDED_IDS:
        assert source_id in ids


def test_ashton_not_register_row() -> None:
    ids = _register_ids()
    ashton = _ashton(_load_stack())
    assert "source_id" not in ashton
    assert ashton["author"] not in ids
    assert ashton["title"] not in ids
