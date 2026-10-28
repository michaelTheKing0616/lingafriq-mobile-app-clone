"""ADR-038 conformance: realtime stack decision (P9-900 AC)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-038-realtime-stack.md"


def test_adr_038_exists_and_records_decision() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-28" in text
    for phrase in (
        "Socket.IO",
        "Redis adapter",
        "10k",
        "100k",
        "Ably",
        "Pusher",
        "Stream Chat",
        "MLS",
        "Reversal trigger",
        "Doppler",
    ):
        assert phrase in text


def test_adr_038_compares_residency_moderation_and_e2ee() -> None:
    text = _ADR.read_text(encoding="utf-8")
    for phrase in (
        "Data residency",
        "under-18",
        "moderation",
        "self-hosted",
        "[estimate]",
    ):
        assert phrase in text
