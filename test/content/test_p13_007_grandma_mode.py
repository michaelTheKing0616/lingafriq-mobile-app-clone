"""P13-007 Grandma Mode family dialect design (RM-MS-03 / RM-MS-12)."""

from __future__ import annotations

import json
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DESIGN = _REPO_ROOT / "docs/build/moonshot/grandma_mode_design.md"
_MANIFEST = _REPO_ROOT / "docs/build/moonshot/grandma_mode_build_cards.json"


def test_design_requires_consent_and_licence_before_storage() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "consent_record_id" in text
    assert "licence_register_id" in text
    assert "before blob upload" in text.casefold() or "before storage" in text.casefold()
    assert "voice-consent.service.ts" in text


def test_family_sourced_label_and_native_review_gate() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "family_sourced" in text
    assert "native_validation.py" in text
    assert "wider" in text.casefold()


def test_minor_guardian_and_moderation_rules() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "guardian" in text.casefold()
    assert "E-P9-SAFETY" in text
    assert "face_blur" in text or "P7-911" in text


def test_withdrawal_purge_period_documented() -> None:
    text = _DESIGN.read_text(encoding="utf-8")
    assert "30" in text
    assert "withdraw" in text.casefold()
    assert "purge" in text.casefold()


def test_build_cards_manifest_matches_acceptance() -> None:
    doc = json.loads(_MANIFEST.read_text(encoding="utf-8"))
    assert doc["card_id"] == "P13-007"
    assert doc["consent_before_storage"] is True
    assert doc["licence_choice_required"] is True
    assert doc["withdraw_purge_days"] == 30
    assert doc["provenance_tag"] == "family_sourced"
    cards = doc["proposed_build_cards"]
    assert len(cards) >= 4
    for row in cards:
        assert row["id"]
        assert row["title"]
        assert row["size"] in {"S", "M", "L", "XL"}
