"""Xhosa source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "xh" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_CHECKLIST = _ENGINE / "licences" / "compat_checklist.yaml"
_EXCLUSIONS = _ENGINE / "licences" / "exclusions.yaml"

_STACK_SECTIONS = (
    "orthography",
    "lexicon",
    "grammar",
    "corpora_audio",
    "tools",
)
_LEXICON_IDS = (
    "oxford-languages",
    "wiktionary-kaikki",
)
_CORPORA_AUDIO_IDS = (
    "sadilar-xhosa-annotated",
    "nchlt",
    "fleurs",
    "waxal-other",
    "african-storybook",
)
_REGISTER_IDS = (
    "sadilar-xhosa-annotated",
    "nchlt",
    "fleurs",
    "waxal-other",
    "african-storybook",
    "wiktionary-kaikki",
)
_TIER_KEYS = ("T1", "T2", "T3", "T4a", "T4b", "T5")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("xh sources.yaml must be a mapping")
    return data


def _register_rows() -> list[dict[str, str]]:
    with _REGISTER.open(newline="", encoding="utf-8") as handle:
        return [row for row in csv.DictReader(handle) if row.get("source_id")]


def _register_ids() -> set[str]:
    return {row["source_id"] for row in _register_rows()}


def _register_row(source_id: str) -> dict[str, str]:
    for row in _register_rows():
        if row["source_id"] == source_id:
            return row
    raise AssertionError(f"register row missing: {source_id}")


def _exclusion_sources() -> dict[str, Any]:
    with _EXCLUSIONS.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    if not isinstance(sources, dict):
        raise AssertionError("exclusions sources must be a mapping")
    return sources


def _checklist_sources() -> dict[str, Any]:
    with _CHECKLIST.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    sources = data.get("sources", {})
    if not isinstance(sources, dict):
        raise AssertionError("compat_checklist sources must be a mapping")
    return sources


def _tier_answer(raw: Any) -> str:
    if isinstance(raw, str):
        return raw
    if isinstance(raw, dict):
        return str(raw.get("answer", raw.get("value", "")))
    raise AssertionError(f"unexpected checklist value: {raw!r}")


def _tier_reason(raw: Any) -> str:
    if isinstance(raw, dict):
        return str(raw.get("reason", ""))
    return ""


def test_stack_sections() -> None:
    stack = _load_stack()
    for key in _STACK_SECTIONS:
        assert key in stack


def test_orthography_fields() -> None:
    ortho = _load_stack()["orthography"]
    assert ortho["authority"] == "PanSALB revised rules"
    assert ortho["gazette"] == "same Gazette"
    assert ortho["gazette_date"] == "6 Jul 2023"


def test_lexicon_source_ids_order() -> None:
    lexicon = _load_stack()["lexicon"]
    assert [row["source_id"] for row in lexicon] == list(_LEXICON_IDS)
    oxford, wiktionary = lexicon
    assert oxford["role"] == "licensed"
    assert oxford["held"] is False
    assert oxford["dataset"] == "isiXhosa"
    assert oxford["ext04_status"] == "Open"
    assert wiktionary["role"] == "cross-check"


def test_grammar_pending_linguist_choice() -> None:
    grammar = _load_stack()["grammar"]
    assert grammar["status"] == "pending-linguist-choice"
    assert grammar["title"] == ""
    assert grammar["edition"] == ""
    assert grammar["purchased"] is False
    assert not grammar.get("author")


def test_corpora_audio_ids() -> None:
    corpora = _load_stack()["corpora_audio"]
    ids = [row["source_id"] for row in corpora]
    assert ids == list(_CORPORA_AUDIO_IDS)
    assert "waxal-ghana" not in ids
    sadilar = next(row for row in corpora if row["source_id"] == "sadilar-xhosa-annotated")
    assert sadilar["tokens"] == 46465
    assert isinstance(sadilar["tokens"], int)
    assert sadilar["licence"] == "CC BY 4.0"
    nchlt = next(row for row in corpora if row["source_id"] == "nchlt")
    assert nchlt["licence"] == "CC BY 2.5 ZA"


def test_concord_checker_enabled_analyser_gap() -> None:
    tools = _load_stack()["tools"]
    checker = tools["concord-checker"]
    assert checker["kind"] == "rule-based"
    assert checker["enabled"] is True
    assert checker["card"] == "P4-045"
    analyser = tools["analyser"]
    assert analyser["confirmed"] is False
    assert analyser["enabled"] is False
    assert "no mature open Xhosa analyser confirmed" in analyser["risk"]


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_oxford_languages_not_register_row() -> None:
    assert "oxford-languages" not in _register_ids()


def test_oxford_languages_licence_required_in_exclusions() -> None:
    row = _exclusion_sources()["oxford-languages"]
    assert row["status"] == "licence-required"
    assert "oxford-languages" not in _register_ids()


def test_sadilar_xhosa_register_fields() -> None:
    row = _register_row("sadilar-xhosa-annotated")
    assert row["url"] == "CURRICULUM.md#§2.4:L447-L449"
    assert row["licence"] == "CC BY 4.0"
    assert row["version_or_date"] == "46465"
    assert row["display"] == "false"
    assert row["evidence"] == "true"
    assert row["training"] == "false"
    assert row.get("owner_signoff", "") == ""
    assert row.get("counsel_status", "") == ""
    assert row["languages"] == "xh"
    assert "SADiLaR annotated corpus" in row["attribution_text"]
    assert "46465" in row["attribution_text"]
    assert "tokens" in row["attribution_text"]


def test_sadilar_xhosa_checklist_entry() -> None:
    entry = _checklist_sources()["sadilar-xhosa-annotated"]
    for key in _TIER_KEYS:
        assert key in entry
    assert _tier_answer(entry["T2"]) == "yes"
    assert _tier_reason(entry["T2"]) == "CC BY 4.0 is attribution only."
    for key in ("T1", "T3", "T4a", "T4b", "T5"):
        assert _tier_answer(entry[key]) == "no"
