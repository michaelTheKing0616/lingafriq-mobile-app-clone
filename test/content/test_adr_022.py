"""ADR-022 conformance: contributor payment vs benefit-sharing (P10-924 AC1–AC2)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-022-contributor-benefit-sharing.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"


def test_adr_022_exists_and_records_benefit_sharing_decision() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "Benefit-sharing" in text or "benefit-sharing" in text
    assert "Payment" in text or "payment" in text
    assert "Neither" in text
    assert "NDPA" in text or "counsel" in text
    assert "P10-923" in text
    assert "contributor_benefit_pool_percent" in text


def test_decisions_md_records_p10_924() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P10-924" in text
    assert "ADR-022" in text
