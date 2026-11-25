"""ADR-007 conformance: AI Gateway runtime and transports (P6-001 AC)."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-007-ai-gateway.md"


def test_adr_007_exists_and_records_gateway_runtime() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    for phrase in (
        "node-backend",
        "TypeScript",
        "Python",
        "GPU",
        "lingafriq-voice-service",
        "Doppler",
        "LINGAFRIQ_AI_MODEL_STACK",
        "OpenAPI",
        "ai.gateway",
        "No provider API keys",
    ):
        assert phrase in text


def test_adr_007_lists_transports_per_mode() -> None:
    text = _ADR.read_text(encoding="utf-8")
    for phrase in (
        "HTTPS",
        "SSE",
        "WebRTC",
        "LiveKit",
        "Polie",
        "P6-002",
        "P6-075",
        "Intron",
    ):
        assert phrase in text
