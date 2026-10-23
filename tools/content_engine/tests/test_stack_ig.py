"""Igbo source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "ig" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_EXCLUSIONS = _ENGINE / "licences" / "exclusions.yaml"

_LEXICON_IDS = (
    "igboapi",
    "oxford-languages",
    "wiktionary-kaikki",
)
_CORPORA_AUDIO_IDS = (
    "leipzig-corpora",
    "common-voice-ig",
    "fleurs",
)
_REGISTER_IDS = (
    "fsi-igbo",
    "wiktionary-kaikki",
    "leipzig-corpora",
    "common-voice-ig",
    "fleurs",
)
_EXCLUDED_IDS = ("igboapi", "oxford-languages")
_NOT_REGISTER_IDS = ("igbo-tone-restorer",)


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("ig sources.yaml must be a mapping")
    return data


def _register_ids() -> set[str]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return {row["source_id"] for row in csv.DictReader(handle) if row.get("source_id")}


def _exclusion_ids() -> set[str]:
    with _EXCLUSIONS.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    return set(sources)


def _emenanjo(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["grammar"]:
        if row.get("author") == "Emenanjo":
            return row
    raise AssertionError("Emenanjo grammar row missing")


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["standard"] == "Standard Igbo (Ọnwụ)"
    assert ortho["onwu_status"] == "unverified"
    assert ortho["dialect_policy"] == "Central Igbo plus Onitsha and Owerri notes"


def test_lexicon_source_ids_order() -> None:
    stack = _load_stack()
    assert [row["source_id"] for row in stack["lexicon"]] == list(_LEXICON_IDS)
    igboapi, oxford, wiktionary = stack["lexicon"]
    assert igboapi["role"] == "licensed"
    assert igboapi["held"] is False
    assert oxford["role"] == "licensed"
    assert oxford["held"] is False
    assert oxford["dataset"] == "Igbo"
    assert wiktionary["role"] == "cross-check"


def test_fsi_grammar_public_domain_basic_tape_1_missing() -> None:
    fsi = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "fsi-igbo"
    )
    assert fsi["licence"] == "public-domain"
    assert fsi["course"] == "Basic"
    assert fsi["tape_1"] == "missing"


def test_emenanjo_not_purchased_not_verified() -> None:
    row = _emenanjo(_load_stack())
    assert row["title"] == "Igbo grammar"
    assert row["purchased"] is False
    assert row["verified"] is False


def test_corpora_audio_ids() -> None:
    assert _load_stack()["corpora_audio"] == list(_CORPORA_AUDIO_IDS)


def test_igbo_tone_restorer_advisory() -> None:
    restorer = _load_stack()["tools"]["igbo-tone-restorer"]
    assert restorer["tone_mark_accuracy"] == "61.6%"
    assert restorer["use"] == "advisory"
    assert restorer["tone_policy"] == "lexicon match plus human check"
    assert restorer["generator"] is False
    assert restorer["approves_tone_mark"] is False


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_excluded_lexicon_ids_in_exclusions() -> None:
    ids = _exclusion_ids()
    for source_id in _EXCLUDED_IDS:
        assert source_id in ids


def test_emenanjo_and_restorer_not_register_rows() -> None:
    ids = _register_ids()
    for source_id in _NOT_REGISTER_IDS:
        assert source_id not in ids
    emenanjo = _emenanjo(_load_stack())
    assert "source_id" not in emenanjo
    assert emenanjo["author"] not in ids
    assert emenanjo["title"] not in ids
