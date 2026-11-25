"""Zulu source stack (CURRICULUM §2.4)."""

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
_SOURCES = _ENGINE / "kits" / "zu" / "sources.yaml"
_REGISTER = _ENGINE / "licences" / "register.csv"
_CHECKLIST = _ENGINE / "licences" / "compat_checklist.yaml"

_STACK_SECTIONS = (
    "orthography",
    "lexicon",
    "grammar",
    "corpora_audio",
    "tools",
)
_CORPORA_AUDIO_IDS = (
    "nchlt",
    "fleurs",
    "waxal-other",
    "african-storybook",
)
_REGISTER_IDS = (
    "sadilar-zulu-morph",
    "nchlt",
    "fleurs",
    "waxal-other",
    "african-storybook",
    "wiktionary-kaikki",
    "peace-corps-zulu",
)
_EVIDENCE_ONLY_IDS = ("sadilar-zulu-morph", "nchlt")
_TIER_KEYS = ("T1", "T2", "T3", "T4a", "T4b", "T5")


def _load_stack() -> dict[str, Any]:
    with _SOURCES.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError("zu sources.yaml must be a mapping")
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


def _poulos(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["grammar"]:
        if row.get("author") == "Poulos & Msimang":
            return row
    raise AssertionError("Poulos & Msimang grammar row missing")


def _zulmorph(stack: dict[str, Any]) -> dict[str, Any]:
    for row in stack["tools"]:
        if row.get("id") == "zulmorph":
            return row
    raise AssertionError("zulmorph tool missing")


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
    assert ortho["authority"] == "PanSALB revised spelling and orthography rules"
    assert ortho["gazette_date"] == "6 Jul 2023"


def test_lexicon_fields() -> None:
    lexicon = _load_stack()["lexicon"]
    assert lexicon["oxford_api_zulu"] is False
    assert lexicon["commercial_licence_status"] == "pending"
    assert lexicon["publisher"] == (
        "Doke–Vilakazi publisher / isiZulu National Lexicography Unit"
    )
    assert lexicon["publisher_status"] == "unverified"
    assert lexicon["ext06_status"] == "Open"
    assert lexicon["request_sent"] is False
    assert lexicon["source_id"] == "wiktionary-kaikki"
    assert lexicon["role"] == "cross-check"


def test_peace_corps_pd_status_unconfirmed() -> None:
    peace = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "peace-corps-zulu"
    )
    assert peace["pd_status"] == "unconfirmed"
    assert peace.get("purchased") is not True


def test_poulos_msimang_not_purchased() -> None:
    row = _poulos(_load_stack())
    assert row["purchased"] is False
    assert "source_id" not in row


def test_sadilar_grammar_tokens_and_licence() -> None:
    sadilar = next(
        row
        for row in _load_stack()["grammar"]
        if row.get("source_id") == "sadilar-zulu-morph"
    )
    assert sadilar["tokens"] == 45933
    assert isinstance(sadilar["tokens"], int)
    assert sadilar["licence"] == "CC BY 4.0"


def test_corpora_audio_ids() -> None:
    corpora = _load_stack()["corpora_audio"]
    assert [row["source_id"] for row in corpora] == list(_CORPORA_AUDIO_IDS)
    assert "waxal-ghana" not in [row["source_id"] for row in corpora]
    nchlt = next(row for row in corpora if row["source_id"] == "nchlt")
    assert nchlt["licence"] == "CC BY 2.5 ZA"


def test_zulmorph_disabled_unverified_terms() -> None:
    tool = _zulmorph(_load_stack())
    assert tool["licence"] == "Apache-2.0"
    assert tool["local_use_terms"] == "unverified"
    assert tool["enabled"] is False


def test_register_contains_licensed_stack_ids() -> None:
    ids = _register_ids()
    for source_id in _REGISTER_IDS:
        assert source_id in ids


def test_poulos_msimang_not_register_row() -> None:
    ids = _register_ids()
    poulos = _poulos(_load_stack())
    assert "source_id" not in poulos
    assert poulos["author"] not in ids
    assert "Poulos & Msimang" not in ids


def test_sadilar_and_nchlt_evidence_only() -> None:
    for source_id in _EVIDENCE_ONLY_IDS:
        row = _register_row(source_id)
        assert row["display"] == "false"
        assert row["evidence"] == "true"
        assert row["training"] == "false"
        assert row.get("owner_signoff", "") == ""
        assert row.get("counsel_status", "") == ""


def test_sadilar_register_fields() -> None:
    row = _register_row("sadilar-zulu-morph")
    assert row["licence"] == "CC BY 4.0"
    assert row["url"] == "CURRICULUM.md#§2.4:L425-L429"
    assert row["languages"] == "zu"
    assert row["version_or_date"] == "45933"
    assert "45933" in row["attribution_text"]
    assert "tokens" in row["attribution_text"]


def test_nchlt_register_fields() -> None:
    row = _register_row("nchlt")
    assert row["licence"] == "CC BY 2.5 ZA"
    assert row["url"] == "CURRICULUM.md#§2.4:L430-L436"
    assert row.get("languages", "") == ""


def test_new_checklist_entries() -> None:
    sources = _checklist_sources()
    expected_reasons = {
        "sadilar-zulu-morph": "CC BY 4.0 is attribution only.",
        "nchlt": "CC BY 2.5 ZA is attribution only.",
    }
    for source_id, reason in expected_reasons.items():
        entry = sources[source_id]
        for key in _TIER_KEYS:
            assert key in entry
        assert _tier_answer(entry["T2"]) == "yes"
        assert _tier_reason(entry["T2"]) == reason
        for key in ("T1", "T3", "T4a", "T4b", "T5"):
            assert _tier_answer(entry[key]) == "no"
