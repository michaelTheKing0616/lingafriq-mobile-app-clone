"""ADR-002 conformance: document exists and names D6 / C2 verification checks (P0 ADR-002 AC7)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-002.md"


def test_adr_002_exists_and_records_tone_beta_rule() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-21" in text
    for phrase in (
        "CONFLICTS C2",
        "three-way agreement",
        "lexicon anchor",
        "Expert-reviewed",
        "never Beta",
        "tone_agreement.py",
        "crosscheck.py",
        "backtranslate.py",
        "stage_lint.py",
        "confidence",
        "0.90",
        "0.70",
        "highrisk.py",
        "EXT-04",
        "EXT-05",
        "EXT-06",
        "EXT-11",
        "EXT-03",
        "Curriculum Studio",
        "LINGAFRIQ_AI_MODEL_STACK",
    ):
        assert phrase in text


def test_adr_002_names_pipeline_conformance_checks() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "routing.py" in text
    assert "publish.py" in text
