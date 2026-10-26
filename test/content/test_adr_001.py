"""ADR-001 conformance: document exists and names D1 verification checks (P0 ADR-001 AC7)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-001.md"


def test_adr_001_exists_and_records_d1_policy() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-21" in text
    for phrase in (
        "Beta",
        "Expert-reviewed",
        "Native-verified",
        "CONFLICTS C1",
        "Synthetic voice",
        "Report a mistake",
        "checkpoint",
        "placement",
        "credential",
        "children",
        "Grammar",
        "culture",
        "12 weeks",
        "USD 4k",
        "RM-STOP-04",
    ):
        assert phrase in text


def test_adr_001_names_pipeline_conformance_checks() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "label enum" in text.lower() or "Label enum" in text
    assert "Beta-exclusion" in text
    assert "Synthetic-voice" in text or "synthetic_voice_tag" in text
