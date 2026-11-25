"""ADR-021 conformance: north-star metric and guardrails (P10-934)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-021-analytics-north-star.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"


def test_adr_021_exists_and_defines_north_star() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "new can-do" in text.lower() or "new can-do" in text
    assert "counting window" in text.lower() or "ISO week" in text
    assert "Exclusion" in text or "Exclusions" in text
    assert "streak" in text.lower()
    assert "never" in text.lower() and "sole" in text.lower()
    assert "99.5" in text
    assert "D1" in text and "D7" in text and "D30" in text


def test_decisions_md_records_adr_021() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "ADR-021" in text
    assert "north-star" in text.lower() or "north star" in text.lower()
