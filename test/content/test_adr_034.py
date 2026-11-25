"""ADR-034 conformance: avatar renderer choice (P11-032)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-034.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"
_INTEGRATION = _REPO_ROOT / "assets/rive/lingafriq/AVATAR_DIRECTOR_INTEGRATION.md"


def test_adr_034_accepted_rive_renderer_with_budget_math() -> None:
    text = _ADR.read_text(encoding="utf-8")
    lower = text.lower()
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "rive renderer" in lower
    assert "impeller" in lower
    assert "0.147" in text
    assert "2 ms" in text or "2.0" in text
    assert "1.82" in text or "1.853" in text
    assert "software gl" in lower
    assert "rejected" in lower or "do not" in lower


def test_adr_034_measurement_traceable_to_integration_note() -> None:
    adr = _ADR.read_text(encoding="utf-8")
    assert "AVATAR_DIRECTOR_INTEGRATION" in adr
    note = _INTEGRATION.read_text(encoding="utf-8")
    assert "0.147 ms" in note
    assert "4.2 ms" in note


def test_decisions_md_records_p11_032() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P11-032" in text
    assert "ADR-034" in text
