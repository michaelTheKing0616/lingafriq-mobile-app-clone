"""Yoruba source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "yo" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_EXCLUSIONS = _ENGINE / "licences" / "exclusions.yaml"

_LEXICON_IDS = (
    "oxford-languages",
    "wiktionary-kaikki",
    "abraham-yoruba-1958",
)
_CORPORA_AUDIO_IDS = (
    "leipzig-corpora",
    "biblica-yoruba",
    "common-voice-yo",
    "fleurs",
)
_REGISTER_IDS = (
    "fsi-yoruba",
    "wiktionary-kaikki",
    "ud-yoruba-ytb",
    "leipzig-corpora",
    "biblica-yoruba",
    "common-voice-yo",
    "fleurs",
)
_EXCLUDED_IDS = ("oxford-languages", "abraham-yoruba-1958")
_NOT_REGISTER_IDS = ("naijaml", "spitch")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("yo sources.yaml must be a mapping")
    return data


def _register_ids() -> set[str]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return {row["source_id"] for row in csv.DictReader(handle) if row.get("source_id")}


def _exclusion_ids() -> set[str]:
    with _EXCLUSIONS.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    return set(sources)


def _bamgbose(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["grammar"]:
        if row.get("author") == "Bámgbóṣé":
            return row
    raise AssertionError("Bámgbóṣé grammar row missing")


def test_lexicon_source_ids_order() -> None:
    stack = _load_stack()
    assert [row["source_id"] for row in stack["lexicon"]] == list(_LEXICON_IDS)
    oxford, wiktionary, abraham = stack["lexicon"]
    assert oxford["role"] == "licensed"
    assert oxford["held"] is False
    assert wiktionary["role"] == "cross-check"
    assert abraham["role"] == "reference"


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["standard"] == "standard Yoruba"
    assert ortho["tone_marking"] == "full tone marking for pedagogy"
    assert ortho["nerdc_status"] == "unverified"


def test_fsi_grammar_public_domain_courses() -> None:
    fsi = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "fsi-yoruba"
    )
    assert fsi["licence"] == "public-domain"
    assert fsi["courses"] == ["Basic", "Intermediate"]


def test_bamgbose_not_purchased_not_web_verified() -> None:
    row = _bamgbose(_load_stack())
    assert row["title"] == "A Grammar of Yoruba"
    assert row["purchased"] is False
    assert row["web_verified"] is False


def test_corpora_audio_ids() -> None:
    assert _load_stack()["corpora_audio"] == list(_CORPORA_AUDIO_IDS)


def test_naijaml_independent_check() -> None:
    naijaml = _load_stack()["tools"]["naijaml"]
    assert naijaml["licence"] == "Apache-2.0"
    assert naijaml["full_tone_word_accuracy"] == "80.3%"
    assert naijaml["dot_below_accuracy"] == "93.3%"
    assert naijaml["use"] == "independent-check"


def test_spitch_pending_not_enabled() -> None:
    spitch = _load_stack()["tools"]["spitch"]
    assert spitch["enabled"] is False
    assert spitch["ext01_status"] == "pending"
    assert spitch["citation"] == "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md"


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_excluded_lexicon_ids_in_exclusions() -> None:
    ids = _exclusion_ids()
    for source_id in _EXCLUDED_IDS:
        assert source_id in ids


def test_tools_and_bamgbose_not_register_rows() -> None:
    ids = _register_ids()
    for source_id in _NOT_REGISTER_IDS:
        assert source_id not in ids
    bamgbose = _bamgbose(_load_stack())
    assert "source_id" not in bamgbose
    assert bamgbose["author"] not in ids
    assert bamgbose["title"] not in ids
