"""ADR-036 conformance: flagship consolidation (P8-916)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-036-flagship-game-consolidation.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"


def test_adr_036_lists_six_flagship_pairs() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    for card in ("P8-920", "P8-922", "P8-923", "P8-924", "P8-928", "P8-929"):
        assert card in text
    assert "drum_word_game.dart" in text
    assert "drum_rhythm" in text
    assert "No-Cut" in text or "no-cut" in text.lower()


def test_decisions_md_records_p8_916() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P8-916" in text
    assert "ADR-036" in text
