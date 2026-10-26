"""P5-040 Pidgin corpus anchoring and anglicisation detector."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.pidgin_anglicisation import (  # noqa: E402
    CODE_ANGLICISED,
    CODE_CORPUS_UNANCHORED,
    CODE_NATIVE_QUEUE_BLOCKED,
    PidginCheckError,
    corpus_anchor_ok,
    detect_anglicisation,
    load_ud_naija_anchor_phrases,
    native_validation_priority,
    schedule_native_validation,
    validate_pcm_item,
)

_ENGLISH = "ENGLISH_SPELLING"
_NLA = "NLA_FORM"


def _pcm_item(text: str, **overrides: object) -> dict:
    body: dict = {
        "id": "pcm.item.drill.a",
        "version": 1,
        "type": "multiple_choice",
        "stimulus": {"text": text},
        "answer_spec": {"correct": text},
        "provenance": {
            "sources": [
                {
                    "name": "UD Nigerian Pidgin NSC treebank",
                    "licence": "CC BY-SA 4.0",
                    "uri_or_citation": "register:ud-naija-nsc; test",
                }
            ]
        },
    }
    body.update(overrides)
    return body


def test_anchor_phrases_load_from_registered_assets() -> None:
    anchors = load_ud_naija_anchor_phrases(str(_REPO_ROOT))
    assert "i de chop" in anchors
    assert "oga, how you dey?" in anchors


def test_corpus_anchor_via_register_citation() -> None:
    ok, detail = corpus_anchor_ok(_pcm_item("I go come tomorrow"))
    assert ok is True
    assert detail == "register:ud-naija-nsc"


def test_corpus_anchor_via_phrase_overlap_without_provenance() -> None:
    item = _pcm_item("I de chop", provenance={"sources": []})
    ok, detail = corpus_anchor_ok(item)
    assert ok is True
    assert detail == "anchor:exact"


def test_corpus_unanchored_raises_finding() -> None:
    item = _pcm_item("Totally novel unrelated phrase here", provenance={"sources": []})
    ok, _ = corpus_anchor_ok(item)
    assert ok is False
    report = validate_pcm_item(item, validators_ready=False)
    codes = {f["code"] for f in report["findings"]}
    assert CODE_CORPUS_UNANCHORED in codes


def test_anglicisation_flags_english_modal() -> None:
    findings = detect_anglicisation(_pcm_item("I will go tomorrow"))
    assert any(f.code == CODE_ANGLICISED for f in findings)


def test_anglicisation_passes_pattern_gold() -> None:
    findings = detect_anglicisation(_pcm_item("I go come tomorrow"))
    assert findings == []


def test_anglicisation_nla_table_fixture(monkeypatch: pytest.MonkeyPatch) -> None:
    from tools.content import pidgin_anglicisation as mod

    kit = {
        "nla_normalisation": {
            "table_included": True,
            "rows": [{"english": _ENGLISH, "nla": _NLA}],
        }
    }
    monkeypatch.setattr(mod, "load_pcm_kit", lambda root=None: kit)
    findings = detect_anglicisation(_pcm_item(f"see {_ENGLISH} now"))
    assert len(findings) == 1
    assert findings[0].code == CODE_ANGLICISED


def test_native_priority_pcm_early() -> None:
    assert native_validation_priority("pcm") < native_validation_priority("yo")
    row = schedule_native_validation(_pcm_item("I de chop"), validators_ready=False)
    assert row["native_check_priority"] is True
    assert row["validators_blocked"] is True
    assert row["code"] == CODE_NATIVE_QUEUE_BLOCKED
    ready = schedule_native_validation(_pcm_item("I de chop"), validators_ready=True)
    assert ready["validators_blocked"] is False


def test_validate_pcm_item_clean_gold() -> None:
    report = validate_pcm_item(_pcm_item("Dem dey waka"), validators_ready=True)
    assert report["anchor_ok"] is True
    assert report["findings"] == []
    assert report["schedule"]["native_check_priority"] is True


def test_wrong_language_raises() -> None:
    item = _pcm_item("hello")
    item["id"] = "yo.item.x"
    with pytest.raises(PidginCheckError):
        corpus_anchor_ok(item)
