"""Nigerian Pidgin source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "pcm" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"

_STACK_SECTIONS = (
    "orthography",
    "lexicon",
    "grammar",
    "corpora",
    "tools",
)
_NOT_REGISTER_IDS = ("Faraclas", "nsc-speech", "intron")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("pcm sources.yaml must be a mapping")
    return data


def _register_ids() -> set[str]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return {row["source_id"] for row in csv.DictReader(handle) if row.get("source_id")}


def _lexicon_sources(stack: dict[str, Any]) -> list[dict[str, Any]]:
    sources = stack["lexicon"]["sources"]
    if not isinstance(sources, list):
        raise AssertionError("pcm lexicon.sources must be a list")
    return sources


def _faraclas(stack: dict[str, Any]) -> dict[str, Any]:
    for row in _lexicon_sources(stack):
        if row.get("author") == "Faraclas":
            return row
    raise AssertionError("Faraclas lexicon row missing")


def _ud_naija_lexicon(stack: dict[str, Any]) -> dict[str, Any]:
    for row in _lexicon_sources(stack):
        if row.get("source_id") == "ud-naija-nsc":
            return row
    raise AssertionError("ud-naija-nsc lexicon row missing")


def _nsc_speech(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["corpora"]:
        if row.get("id") == "nsc-speech":
            return row
    raise AssertionError("nsc-speech corpus row missing")


def test_stack_sections() -> None:
    stack = _load_stack()
    for key in _STACK_SECTIONS:
        assert key in stack


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["authority"] == "Naija Langwej Akademi"
    assert ortho["guide"] == "IFRA"
    assert ortho["script"] == "phonetic Latin"
    assert ortho["high_tone"] == "marked only in scientific use"


def test_commercial_dictionary_false_faraclas_not_purchased() -> None:
    stack = _load_stack()
    assert stack["lexicon"]["commercial_dictionary"] is False
    faraclas = _faraclas(stack)
    assert faraclas["title"] == "Nigerian Pidgin"
    assert faraclas["year"] == 1996
    assert faraclas["purchased"] is False


def test_ud_naija_nsc_licence_evidence_not_lexicon_copy() -> None:
    stack = _load_stack()
    ud = _ud_naija_lexicon(stack)
    assert ud["licence"] == "CC BY-SA 4.0"
    assert ud["role"] == "evidence"
    assert ud["role"] != "lexicon"
    grammar = next(
        row
        for row in stack["grammar"]
        if row.get("source_id") == "ud-naija-nsc"
    )
    assert grammar["licence"] == "CC BY-SA 4.0"
    assert grammar["role"] == "evidence-only"


def test_nsc_speech_uses_false_licence_unverified() -> None:
    corpus = _nsc_speech(_load_stack())
    assert corpus["licence_status"] == "unverified"
    assert corpus["display"] is False
    assert corpus["evidence"] is False
    assert corpus["training"] is False


def test_intron_disabled_ext01_pending() -> None:
    intron = _load_stack()["tools"]["intron"]
    assert intron["use"] == "ASR"
    assert intron["enabled"] is False
    assert intron["ext01_status"] == "pending"
    assert intron["citation"] == "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md"


def test_anglicisation_detector_card() -> None:
    detector = _load_stack()["tools"]["anglicisation-detector"]
    assert detector["card"] == "P4-048"
    assert detector["enabled"] is False


def test_ud_naija_nsc_in_register() -> None:
    assert "ud-naija-nsc" in _register_ids()


def test_faraclas_nsc_speech_intron_not_register_rows() -> None:
    ids = _register_ids()
    for source_id in _NOT_REGISTER_IDS:
        assert source_id not in ids
    faraclas = _faraclas(_load_stack())
    assert "source_id" not in faraclas
    assert faraclas["author"] not in ids
    assert faraclas["title"] not in ids
