"""ADR-033 conformance: forced aligner routing (P11-031)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-033.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"
_STACK = _REPO_ROOT / "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md"

STAGE1 = ("ha", "ig", "pcm", "sw", "xh", "yo", "zu")


def test_adr_033_accepted_with_per_language_primary_fallback() -> None:
    text = _ADR.read_text(encoding="utf-8")
    lower = text.lower()
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "omnilingual ctc" in lower
    assert "montreal forced aligner" in lower or "mfa" in lower
    assert "tts-native" in lower or "azure tts viseme" in lower
    assert "not provisional" in lower
    for lang in STAGE1:
        assert f"`{lang}`" in text
    assert "apache-2.0" in lower
    assert "mit" in lower


def test_adr_033_cites_ext_01_section_3_8() -> None:
    adr = _ADR.read_text(encoding="utf-8")
    assert "LINGAFRIQ_AI_MODEL_STACK" in adr
    assert "§3.8" in adr
    stack = _STACK.read_text(encoding="utf-8")
    assert "3.8 Lip-sync" in stack or "3.8 Lip-sync and visemes" in stack


def test_decisions_md_records_p11_031() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P11-031" in text
    assert "ADR-033" in text
