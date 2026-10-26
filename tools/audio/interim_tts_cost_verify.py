"""Interim TTS cost verification for Stage 1 (P5-091, CURRICULUM §9.4)."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping

from tools.audio.intron_tts_quote import (
    IntronTtsQuoteError,
    load_intron_tts_quote,
    validate_intron_tts_quote,
)
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-091"
GATE_ID = "G5"
LEDGER_REL = "assets/content/interim_tts_cost_ledger.json"
DEPENDS_ON = ("P5-071", "EXT-01")

# CURRICULUM §9.4:L835 — planning estimates [rough estimates; get quotes].
CHARACTERS_MIN = 1_000_000
CHARACTERS_MAX = 2_000_000
AZURE_USD_PER_MILLION_CHARS = 16.0
AZURE_USD_CEILING = 100.0
AZURE_SOURCE_ANCHOR = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#§3.5:L98"


class InterimTtsCostError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise InterimTtsCostError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise InterimTtsCostError("LEDGER_INVALID", "ledger root must be an object")
    return data


def azure_usd_for_characters(characters: int, rate_usd_per_million: float) -> float:
    if characters < 0:
        raise InterimTtsCostError("CHARACTERS", "characters must be non-negative")
    return round((characters / 1_000_000) * rate_usd_per_million, 2)


def intron_usd_for_characters(
    characters: int,
    quote: Mapping[str, Any],
) -> dict[str, Any]:
    status = quote.get("status")
    if status == "pending":
        return {
            "vendor": "intron",
            "status": "pending",
            "usd_total": None,
            "note": "Intron quote pending (P5-071); cost excluded until received.",
        }
    if status == "received":
        ppc = quote.get("price_per_character")
        if ppc is None:
            raise InterimTtsCostError("INTRON_PRICE", "received quote missing price_per_character")
        usd = round(float(ppc) * characters, 2)
        return {
            "vendor": "intron",
            "status": "received",
            "usd_total": usd,
            "price_per_character": float(ppc),
        }
    raise InterimTtsCostError("INTRON_STATUS", "quote.status must be pending or received")


def _azure_band_flags(usd: float) -> dict[str, Any]:
    within = usd < AZURE_USD_CEILING
    return {
        "azure_usd_ceiling": AZURE_USD_CEILING,
        "within_azure_ceiling": within,
        "delta_usd_vs_ceiling": round(usd - AZURE_USD_CEILING, 2) if not within else 0.0,
        "azure_verification": "confirmed_under_ceiling" if within else "delta_recorded",
    }


def evaluate_interim_tts_cost(
    *,
    characters: int,
    azure_rate_usd_per_million: float = AZURE_USD_PER_MILLION_CHARS,
    intron_quote: Mapping[str, Any] | None = None,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    if not CHARACTERS_MIN <= characters <= CHARACTERS_MAX:
        raise InterimTtsCostError(
            "CHARACTERS",
            f"characters must be within CURRICULUM §9.4 band {CHARACTERS_MIN}-{CHARACTERS_MAX}",
        )

    quote = intron_quote
    if quote is None:
        quote = load_intron_tts_quote()["quote"]

    azure_usd = azure_usd_for_characters(characters, azure_rate_usd_per_million)
    azure_flags = _azure_band_flags(azure_usd)
    intron = intron_usd_for_characters(characters, quote)

    known_total = azure_usd
    if intron.get("usd_total") is not None:
        known_total = round(azure_usd + float(intron["usd_total"]), 2)

    if intron["status"] == "pending":
        overall = "azure_confirmed_intron_quote_pending"
    elif known_total < AZURE_USD_CEILING:
        overall = "confirmed_within_band"
    else:
        overall = "delta_recorded"

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "characters": characters,
        "azure": {
            "provider": "azure_neural_tts",
            "usd_per_million_chars": azure_rate_usd_per_million,
            "usd_total": azure_usd,
            **azure_flags,
            "source_anchor": AZURE_SOURCE_ANCHOR,
        },
        "intron": intron,
        "known_total_usd": known_total,
        "intron_quote_pending": intron["status"] == "pending",
        "verification": overall,
        "pricing_source": "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md (EXT-01)",
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L835",
        "estimate": True,
    }


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise InterimTtsCostError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band")
    if not isinstance(planning, dict):
        raise InterimTtsCostError("PLANNING", "planning_band object required")
    if planning.get("characters_min") != CHARACTERS_MIN:
        raise InterimTtsCostError("PLANNING_FROZEN", "characters_min must match §9.4")
    if planning.get("characters_max") != CHARACTERS_MAX:
        raise InterimTtsCostError("PLANNING_FROZEN", "characters_max must match §9.4")
    if planning.get("azure_usd_per_million_chars") != AZURE_USD_PER_MILLION_CHARS:
        raise InterimTtsCostError("PLANNING_FROZEN", "azure rate must match EXT-01")
    if planning.get("azure_usd_ceiling") != AZURE_USD_CEILING:
        raise InterimTtsCostError("PLANNING_FROZEN", "azure_usd_ceiling must match §9.4")

    try:
        validate_intron_tts_quote(load_intron_tts_quote())
    except IntronTtsQuoteError as exc:
        raise InterimTtsCostError("INTRON_LEDGER", str(exc)) from exc

    rate = float(data.get("azure_rate_usd_per_million", AZURE_USD_PER_MILLION_CHARS))
    for chars in (CHARACTERS_MIN, CHARACTERS_MAX):
        evaluate_interim_tts_cost(characters=chars, azure_rate_usd_per_million=rate)

    verifications = data.get("interim_tts_cost_verifications")
    if verifications is not None and not isinstance(verifications, list):
        raise InterimTtsCostError("VERIFICATIONS", "interim_tts_cost_verifications must be a list")


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise InterimTtsCostError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")

    verifications = store.setdefault("interim_tts_cost_verifications", [])
    if not isinstance(verifications, list):
        raise InterimTtsCostError("STORE_INVALID", "interim_tts_cost_verifications must be a list")

    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": result.get("evaluated_on"),
        "characters": result.get("characters"),
        "azure_usd": result.get("azure", {}).get("usd_total"),
        "azure_within_ceiling": result.get("azure", {}).get("within_azure_ceiling"),
        "intron_status": result.get("intron", {}).get("status"),
        "known_total_usd": result.get("known_total_usd"),
        "verification": result.get("verification"),
    }
    verifications.append(summary)
    store["latest_evaluation"] = dict(result)
    return summary
