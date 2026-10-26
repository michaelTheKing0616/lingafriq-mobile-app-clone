"""Intron TTS quote ledger and AI-stack §3.5 cross-check (P5-071)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping, Sequence

CARD_ID = "P5-071"
STACK_SECTION = "3.5"

# Frozen excerpt of LINGAFRIQ_AI_MODEL_STACK.md §3.5 routing (EXT-01); do not invent vendors.
_EXPECTED_ROUTING: tuple[tuple[str, str, tuple[str, ...]], ...] = (
    ("yo", "intron", ("spitch",)),
    ("ig", "intron", ("spitch",)),
    ("ha", "intron", ("spitch", "elevenlabs_v3")),
    ("pcm", "intron", ("spitch",)),
    ("sw", "intron", ("google_chirp3_hd_sw_ke", "azure_sw_ke", "elevenlabs_v3", "gemini_tts")),
    ("zu", "azure_zu_za", ("custom_voice",)),
    ("xh", "custom_trained_voice", ()),
)

_REPO_ROOT = Path(__file__).resolve().parents[2]
_QUOTE_PATH = _REPO_ROOT / "assets/data/audio/intron_tts_quote.json"


class IntronTtsQuoteError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def quote_path() -> Path:
    return _QUOTE_PATH


def load_intron_tts_quote(path: Path | None = None) -> dict[str, Any]:
    p = path or _QUOTE_PATH
    if not p.is_file():
        raise IntronTtsQuoteError("QUOTE_MISSING", f"Intron TTS quote ledger not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise IntronTtsQuoteError("QUOTE_INVALID", "quote root must be an object")
    return data


def _routing_row(
    rows: Sequence[Mapping[str, Any]], language_id: str
) -> Mapping[str, Any]:
    for row in rows:
        if row.get("language_id") == language_id:
            return row
    raise IntronTtsQuoteError("ROUTING_MISSING", f"no routing row for {language_id}")


def validate_intron_tts_quote(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise IntronTtsQuoteError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    if data.get("stack_section") != STACK_SECTION:
        raise IntronTtsQuoteError("SECTION_MISMATCH", f"expected stack section {STACK_SECTION}")

    quote = data.get("quote")
    if not isinstance(quote, dict):
        raise IntronTtsQuoteError("QUOTE_OBJ", "quote object required")
    if quote.get("vendor") != "intron":
        raise IntronTtsQuoteError("VENDOR", "vendor must be intron")
    status = quote.get("status")
    if status not in ("pending", "received"):
        raise IntronTtsQuoteError("QUOTE_STATUS", "quote.status must be pending or received")
    if status == "pending":
        if quote.get("price_per_character") is not None:
            raise IntronTtsQuoteError("PRICE_INVENTED", "pending quote must not record a price")
        if quote.get("terms_recorded") is True:
            raise IntronTtsQuoteError("TERMS", "terms cannot be recorded without a received quote")
    elif status == "received":
        if quote.get("price_per_character") is None:
            raise IntronTtsQuoteError("PRICE_MISSING", "received quote must record price_per_character")
        if quote.get("terms_recorded") is not True:
            raise IntronTtsQuoteError("TERMS", "received quote must set terms_recorded true")

    gate = data.get("server_gate")
    if not isinstance(gate, dict):
        raise IntronTtsQuoteError("GATE", "server_gate required")
    if gate.get("client_exposure_forbidden") is not True:
        raise IntronTtsQuoteError("GATE", "INTRON_API_KEY must not ship in the client")
    if status == "pending" and gate.get("expected_until_quote") is not False:
        raise IntronTtsQuoteError("GATE", "Intron must stay off until quote and server enablement")

    routing = data.get("interim_tts_routing")
    if not isinstance(routing, list):
        raise IntronTtsQuoteError("ROUTING", "interim_tts_routing must be a list")

    for lang, primary, fallbacks in _EXPECTED_ROUTING:
        row = _routing_row(routing, lang)
        if row.get("primary") != primary:
            raise IntronTtsQuoteError(
                "STACK_MISMATCH",
                f"{lang} primary {row.get('primary')} != stack §3.5 {primary}",
            )
        got = tuple(row.get("fallbacks") or ())
        if got != fallbacks:
            raise IntronTtsQuoteError(
                "STACK_MISMATCH",
                f"{lang} fallbacks {got} != stack §3.5 {fallbacks}",
            )

    xh = _routing_row(routing, "xh")
    if xh.get("procurement_blocker") != "EXT-12":
        raise IntronTtsQuoteError("EXT12", "xh row must cite EXT-12 for custom voice")

    cross = data.get("cross_check")
    if not isinstance(cross, dict):
        raise IntronTtsQuoteError("CROSS_CHECK", "cross_check object required")
    if cross.get("vendor_map_matches_stack_section_3_5") is not True:
        raise IntronTtsQuoteError("CROSS_CHECK", "§3.5 vendor map must match before Done")
    if cross.get("status") != "passed":
        raise IntronTtsQuoteError("CROSS_CHECK", "cross_check.status must be passed")


def intron_tts_quote_pending(data: Mapping[str, Any] | None = None) -> bool:
    doc = data if data is not None else load_intron_tts_quote()
    validate_intron_tts_quote(doc)
    return doc["quote"]["status"] == "pending"


def intron_enabled_allowed(data: Mapping[str, Any] | None = None) -> bool:
    doc = data if data is not None else load_intron_tts_quote()
    validate_intron_tts_quote(doc)
    return doc["quote"]["status"] == "received" and doc["server_gate"].get("expected_until_quote") is not True
