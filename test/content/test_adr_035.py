"""ADR-035 conformance: scarification and tribal marks policy (P11-033)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-035.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"
_CHARACTER_BIBLE = _REPO_ROOT / "assets/rive/lingafriq/CHARACTER_BIBLE.md"


def test_adr_035_accepted_opt_in_adults_v1_excluded() -> None:
    text = _ADR.read_text(encoding="utf-8")
    lower = text.lower()
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "opt-in" in lower
    assert "18+" in text or "adults" in lower
    assert "v1" in lower
    assert "ext-14" in lower
    assert "consultant" in lower
    assert "loot" in lower and "rejected" in lower
    assert "one tap" in lower or "one-tap" in lower


def test_adr_035_aligns_with_character_bible_section_8() -> None:
    adr = _ADR.read_text(encoding="utf-8").lower()
    bible = _CHARACTER_BIBLE.read_text(encoding="utf-8").lower()
    assert "accessory/marks_" in adr
    assert "accessory/marks_" in bible
    assert "vitiligo" in adr
    assert "never shown on hosts" in bible or "hosts or guides" in bible


def test_decisions_md_records_p11_033() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P11-033" in text
    assert "ADR-035" in text
