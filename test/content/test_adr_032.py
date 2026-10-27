"""ADR-032 conformance: avatar economy and identity (P11-030)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-032-avatar-economy-identity.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"


def test_adr_032_accepted_with_item_classes_and_minor_rules() -> None:
    text = _ADR.read_text(encoding="utf-8")
    lower = text.lower()
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "mastery (earned)" in lower or "mastery" in lower
    assert "cosmetic_avatar" in lower
    assert "fiat_cosmetic" in lower or "fiat cosmetic" in lower
    assert "loot box" in lower or "loot boxes" in lower
    assert "minor" in lower
    assert "server-verified" in lower or "server verified" in lower


def test_adr_032_links_cowries_sink_and_no_gacha() -> None:
    text = _ADR.read_text(encoding="utf-8").lower()
    assert "adr-020" in text
    assert "gacha" in text or "loot box" in text
    assert "demonstrated skill" in text or "can-do" in text


def test_decisions_md_records_p11_030() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P11-030" in text
    assert "ADR-032" in text
