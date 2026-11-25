"""P5-071 Intron TTS quote ledger and §3.5 cross-check."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.intron_tts_quote import (  # noqa: E402
    CARD_ID,
    IntronTtsQuoteError,
    intron_enabled_allowed,
    intron_tts_quote_pending,
    load_intron_tts_quote,
    validate_intron_tts_quote,
)


def test_quote_ledger_validates() -> None:
    data = load_intron_tts_quote()
    validate_intron_tts_quote(data)
    assert data["card_id"] == CARD_ID


def test_quote_pending_no_invented_price() -> None:
    assert intron_tts_quote_pending() is True
    assert intron_enabled_allowed() is False


def test_xh_cites_ext12() -> None:
    rows = load_intron_tts_quote()["interim_tts_routing"]
    xh = next(r for r in rows if r["language_id"] == "xh")
    assert xh["procurement_blocker"] == "EXT-12"
    assert xh["primary"] == "custom_trained_voice"


def test_pending_with_price_fails() -> None:
    data = load_intron_tts_quote()
    bad = dict(data)
    quote = dict(data["quote"])
    quote["price_per_character"] = 0.001
    bad["quote"] = quote
    with pytest.raises(IntronTtsQuoteError) as exc:
        validate_intron_tts_quote(bad)
    assert exc.value.code == "PRICE_INVENTED"


def test_wrong_yo_primary_fails() -> None:
    data = load_intron_tts_quote()
    routing = [dict(r) for r in data["interim_tts_routing"]]
    yo = next(r for r in routing if r["language_id"] == "yo")
    yo["primary"] = "azure"
    bad = dict(data)
    bad["interim_tts_routing"] = routing
    with pytest.raises(IntronTtsQuoteError) as exc:
        validate_intron_tts_quote(bad)
    assert exc.value.code == "STACK_MISMATCH"
