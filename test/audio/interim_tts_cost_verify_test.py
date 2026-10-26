"""P5-091 interim TTS cost vs EXT-01 Azure rate and P5-071 Intron quote (CURRICULUM §9.4)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.interim_tts_cost_verify import (  # noqa: E402
    AZURE_USD_CEILING,
    AZURE_USD_PER_MILLION_CHARS,
    CARD_ID,
    CHARACTERS_MAX,
    CHARACTERS_MIN,
    InterimTtsCostError,
    append_verification_ledger_row,
    azure_usd_for_characters,
    evaluate_interim_tts_cost,
    load_ledger,
    validate_ledger,
)


def test_ledger_validates() -> None:
    data = load_ledger()
    validate_ledger(data)
    assert data["card_id"] == CARD_ID
    band = data["planning_band"]
    assert band["characters_min"] == CHARACTERS_MIN
    assert band["azure_usd_per_million_chars"] == AZURE_USD_PER_MILLION_CHARS


def test_azure_under_ceiling_at_curriculum_character_bands() -> None:
    low = evaluate_interim_tts_cost(characters=CHARACTERS_MIN)
    high = evaluate_interim_tts_cost(characters=CHARACTERS_MAX)

    assert low["azure"]["usd_total"] == azure_usd_for_characters(CHARACTERS_MIN, AZURE_USD_PER_MILLION_CHARS)
    assert high["azure"]["usd_total"] == 32.0
    assert high["azure"]["within_azure_ceiling"] is True
    assert high["azure"]["usd_total"] < AZURE_USD_CEILING
    assert low["verification"] == "azure_confirmed_intron_quote_pending"
    assert high["verification"] == "azure_confirmed_intron_quote_pending"
    assert low["intron"]["status"] == "pending"
    assert low["intron"]["usd_total"] is None


def test_received_intron_quote_adds_to_known_total() -> None:
    quote = {
        "vendor": "intron",
        "status": "received",
        "price_per_character": 0.00001,
        "terms_recorded": True,
    }
    result = evaluate_interim_tts_cost(characters=CHARACTERS_MAX, intron_quote=quote)
    assert result["intron"]["usd_total"] == 20.0
    assert result["known_total_usd"] == 52.0
    assert result["verification"] == "confirmed_within_band"


def test_append_row_updates_store() -> None:
    result = evaluate_interim_tts_cost(characters=CHARACTERS_MIN)
    store = load_ledger()
    before = len(store.get("interim_tts_cost_verifications", []))
    append_verification_ledger_row(store, result)
    assert len(store["interim_tts_cost_verifications"]) == before + 1
    assert store["latest_evaluation"]["card_id"] == CARD_ID


def test_rejects_characters_outside_curriculum_band() -> None:
    with pytest.raises(InterimTtsCostError) as exc:
        evaluate_interim_tts_cost(characters=CHARACTERS_MIN - 1)
    assert exc.value.code == "CHARACTERS"


def test_azure_delta_when_above_ceiling() -> None:
    quote = {"vendor": "intron", "status": "pending"}
    result = evaluate_interim_tts_cost(
        characters=CHARACTERS_MAX,
        azure_rate_usd_per_million=60.0,
        intron_quote=quote,
    )
    assert result["azure"]["within_azure_ceiling"] is False
    assert result["azure"]["azure_verification"] == "delta_recorded"
