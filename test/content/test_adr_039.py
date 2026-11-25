"""ADR-039 conformance: MLS vs Signal E2EE decision (P9-937 AC)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-039-e2ee-protocol.md"


def test_adr_039_exists_and_records_mls_decision() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-28" in text
    for phrase in (
        "MLS",
        "RFC 9420",
        "Signal",
        "libsignal",
        "openmls",
        "3.3.0",
        "@wireapp/openmls-js",
        "0.1.0",
        "MIT",
        "GPL",
    ):
        assert phrase in text


def test_adr_039_covers_comparison_axes_and_audit_plan() -> None:
    text = _ADR.read_text(encoding="utf-8")
    for phrase in (
        "Group size",
        "Multi-device",
        "Server cost",
        "Key recovery",
        "Dart",
        "Node",
        "Crypto audit",
        "EXT-17",
        "under-18",
        "ciphertext",
        "Doppler",
    ):
        assert phrase in text
