"""P13-005 Living Archive path design (RM-MS-01 / RM-MS-08)."""

from __future__ import annotations

import json
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DESIGN = _REPO_ROOT / "docs/build/moonshot/living_archive_path.md"
_MANIFEST = _REPO_ROOT / "docs/build/moonshot/living_archive_build_cards.json"


def test_design_doc_community_admission_uses_p13_001_and_p13_003() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "later_wave_language.yaml" in text
    assert "P13-001" in text
    assert "lexicon_gate.py" in text
    assert "P13-003" in text


def test_design_doc_no_native_reviewers_stays_l0_with_honest_label() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    lower = text.casefold()
    assert "l0" in lower
    assert "native_verified" in lower
    assert "community-built" in lower or "community-built" in text
    assert "content_label" in text


def test_design_doc_lists_credit_licence_and_goal_not_claim() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "95" in text
    assert "not a product claim" in text.casefold() or "not a product claim" in text
    assert "contributor" in text.casefold()
    assert "licence" in text.casefold() or "license" in text.casefold()
    assert "ADR-022" in text


def test_build_cards_manifest_matches_acceptance() -> None:
    doc = json.loads(_MANIFEST.read_text(encoding="utf-8"))
    assert doc["card_id"] == "P13-005"
    assert doc["goal_languages"] >= 95
    assert doc["goal_is_claim"] is False
    assert doc["admission_template"].endswith("later_wave_language.yaml")
    assert "later_wave_admission.py" in doc["admission_validator"]
    assert "lexicon_gate.py" in doc["lexicon_gate"]
    assert doc["no_native_reviewers_max_readiness"] == "L0"
    cards = doc["proposed_build_cards"]
    assert len(cards) >= 4
    for row in cards:
        assert row["id"]
        assert row["title"]
        assert row["size"] in {"S", "M", "L", "XL"}
