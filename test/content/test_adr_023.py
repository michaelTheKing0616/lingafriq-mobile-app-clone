"""ADR-023 conformance: efficacy-study language pair (P10-937)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-023-efficacy-study-languages.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"


def test_adr_023_names_tonal_wa_and_bantu_stage1() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    lower = text.lower()
    assert "yoruba" in lower
    assert "isi zulu" in lower.replace("-", " ") or "isizulu" in lower or "`zu`" in text
    assert "tonal west african" in lower or "tonal west" in lower
    assert "bantu" in lower
    assert "no efficacy statistics" in lower or "no efficacy" in lower
    assert "ext-20" in lower


def test_decisions_md_records_p10_937() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P10-937" in text
    assert "ADR-023" in text
    assert "`yo`" in text and "`zu`" in text
