"""LLM generation cost verification for Stage 1 (P5-088, CURRICULUM §9.4)."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping

from tools.content.lexicon_select import STAGE1_LANGS
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-088"
GATE_ID = "G5"
LEDGER_REL = "assets/content/llm_generation_cost_ledger.json"

# CURRICULUM §9.4:L830-L832 — planning estimates [rough estimates; get quotes].
ITEMS_PER_LANGUAGE_MIN = 10_000
ITEMS_PER_LANGUAGE_MAX = 12_000
MODEL_PASSES_PER_ITEM = 4
USD_PER_LANGUAGE_MIN = 500
USD_PER_LANGUAGE_MAX = 1_500
USD_STAGE1_MIN = 4_000
USD_STAGE1_MAX = 10_000
STAGE1_LANGUAGE_COUNT = len(STAGE1_LANGS)


class LlmGenerationCostError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ModelRateUsdPerMillion:
    """Per-million-token rates from EXT-01 (frozen in ledger)."""

    input_usd: float
    output_usd: float
    model_id: str
    source_anchor: str


@dataclass(frozen=True)
class PassTokenProfile:
    """Engineering estimate for one pipeline pass per generated item."""

    pass_id: str
    model: ModelRateUsdPerMillion
    input_tokens: int
    output_tokens: int
    pipeline_step: str


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise LlmGenerationCostError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise LlmGenerationCostError("LEDGER_INVALID", "ledger root must be an object")
    return data


def _parse_rate(row: Mapping[str, Any]) -> ModelRateUsdPerMillion:
    try:
        return ModelRateUsdPerMillion(
            input_usd=float(row["input_usd_per_million"]),
            output_usd=float(row["output_usd_per_million"]),
            model_id=str(row["model_id"]),
            source_anchor=str(row["source_anchor"]),
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise LlmGenerationCostError("RATE_INVALID", f"invalid model rate row: {exc}") from exc


def pass_profiles_from_ledger(data: Mapping[str, Any]) -> tuple[PassTokenProfile, ...]:
    rates = data.get("ext01_model_rates")
    if not isinstance(rates, dict):
        raise LlmGenerationCostError("RATES", "ext01_model_rates object required")

    profiles_raw = data.get("token_profile_per_pass")
    if not isinstance(profiles_raw, list) or not profiles_raw:
        raise LlmGenerationCostError("PROFILE", "token_profile_per_pass must be a non-empty list")

    profiles: list[PassTokenProfile] = []
    for row in profiles_raw:
        if not isinstance(row, Mapping):
            raise LlmGenerationCostError("PROFILE", "each pass profile must be an object")
        model_key = row.get("model_key")
        if model_key not in rates:
            raise LlmGenerationCostError("PROFILE", f"unknown model_key {model_key}")
        try:
            profiles.append(
                PassTokenProfile(
                    pass_id=str(row["pass_id"]),
                    model=_parse_rate(rates[model_key]),
                    input_tokens=int(row["input_tokens"]),
                    output_tokens=int(row["output_tokens"]),
                    pipeline_step=str(row["pipeline_step"]),
                )
            )
        except (KeyError, TypeError, ValueError) as exc:
            raise LlmGenerationCostError("PROFILE", f"invalid pass profile: {exc}") from exc

    if len(profiles) != MODEL_PASSES_PER_ITEM:
        raise LlmGenerationCostError(
            "PROFILE",
            f"expected {MODEL_PASSES_PER_ITEM} passes per CURRICULUM §9.4 item assumption",
        )
    return tuple(profiles)


def cost_usd_for_pass(profile: PassTokenProfile, items: int) -> float:
    if items < 0:
        raise LlmGenerationCostError("ITEMS", "items must be non-negative")
    in_m = (profile.input_tokens * items) / 1_000_000
    out_m = (profile.output_tokens * items) / 1_000_000
    return in_m * profile.model.input_usd + out_m * profile.model.output_usd


def compute_per_language_usd(
    items: int,
    profiles: tuple[PassTokenProfile, ...],
) -> dict[str, Any]:
    if items < 0:
        raise LlmGenerationCostError("ITEMS", "items must be non-negative")
    by_pass: list[dict[str, Any]] = []
    total = 0.0
    for profile in profiles:
        usd = cost_usd_for_pass(profile, items)
        total += usd
        by_pass.append(
            {
                "pass_id": profile.pass_id,
                "pipeline_step": profile.pipeline_step,
                "model_id": profile.model.model_id,
                "input_tokens_per_item": profile.input_tokens,
                "output_tokens_per_item": profile.output_tokens,
                "usd": round(usd, 2),
            }
        )
    return {
        "items": items,
        "model_passes_per_item": MODEL_PASSES_PER_ITEM,
        "usd_total": round(total, 2),
        "by_pass": by_pass,
    }


def _band_flags(usd: float, low: float, high: float) -> dict[str, Any]:
    within = low <= usd <= high
    delta_usd = 0.0
    if usd < low:
        delta_usd = round(usd - low, 2)
    elif usd > high:
        delta_usd = round(usd - high, 2)
    return {
        "within_planning_band": within,
        "planning_band_usd_min": low,
        "planning_band_usd_max": high,
        "delta_usd_vs_band": delta_usd,
        "verification": "confirmed_within_band" if within else "delta_recorded",
    }


def evaluate_stage1_llm_cost(
    profiles: tuple[PassTokenProfile, ...],
    *,
    items_per_language: int = ITEMS_PER_LANGUAGE_MIN,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    """Cost one language and roll up Stage 1 (seven parallel languages)."""
    if not ITEMS_PER_LANGUAGE_MIN <= items_per_language <= ITEMS_PER_LANGUAGE_MAX:
        raise LlmGenerationCostError(
            "ITEMS",
            f"items_per_language must be within CURRICULUM §9.4 band "
            f"{ITEMS_PER_LANGUAGE_MIN}-{ITEMS_PER_LANGUAGE_MAX}",
        )

    per_lang = compute_per_language_usd(items_per_language, profiles)
    lang_band = _band_flags(per_lang["usd_total"], USD_PER_LANGUAGE_MIN, USD_PER_LANGUAGE_MAX)

    stage1_usd = round(per_lang["usd_total"] * STAGE1_LANGUAGE_COUNT, 2)
    stage_band = _band_flags(stage1_usd, USD_STAGE1_MIN, USD_STAGE1_MAX)

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "items_per_language": items_per_language,
        "language_ids": list(STAGE1_LANGS),
        "per_language": {**per_lang, **lang_band},
        "stage1": {
            "language_count": STAGE1_LANGUAGE_COUNT,
            "usd_total": stage1_usd,
            **stage_band,
        },
        "pricing_source": "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md (EXT-01)",
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L830-L832",
        "estimate": True,
    }


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise LlmGenerationCostError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band")
    if not isinstance(planning, dict):
        raise LlmGenerationCostError("PLANNING", "planning_band object required")
    if planning.get("items_per_language_min") != ITEMS_PER_LANGUAGE_MIN:
        raise LlmGenerationCostError("PLANNING_FROZEN", "items_per_language_min must match §9.4")
    if planning.get("items_per_language_max") != ITEMS_PER_LANGUAGE_MAX:
        raise LlmGenerationCostError("PLANNING_FROZEN", "items_per_language_max must match §9.4")
    if planning.get("model_passes_per_item") != MODEL_PASSES_PER_ITEM:
        raise LlmGenerationCostError("PLANNING_FROZEN", "model_passes_per_item must be 4 per §9.4")
    if planning.get("usd_per_language_min") != USD_PER_LANGUAGE_MIN:
        raise LlmGenerationCostError("PLANNING_FROZEN", "usd_per_language_min must match §9.4")
    if planning.get("usd_per_language_max") != USD_PER_LANGUAGE_MAX:
        raise LlmGenerationCostError("PLANNING_FROZEN", "usd_per_language_max must match §9.4")
    if planning.get("usd_stage1_min") != USD_STAGE1_MIN:
        raise LlmGenerationCostError("PLANNING_FROZEN", "usd_stage1_min must match §9.4")
    if planning.get("usd_stage1_max") != USD_STAGE1_MAX:
        raise LlmGenerationCostError("PLANNING_FROZEN", "usd_stage1_max must match §9.4")

    profiles = pass_profiles_from_ledger(data)
    for items in (ITEMS_PER_LANGUAGE_MIN, ITEMS_PER_LANGUAGE_MAX):
        evaluate_stage1_llm_cost(profiles, items_per_language=items)

    verifications = data.get("llm_generation_cost_verifications")
    if verifications is not None and not isinstance(verifications, list):
        raise LlmGenerationCostError("VERIFICATIONS", "llm_generation_cost_verifications must be a list")


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise LlmGenerationCostError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")

    verifications = store.setdefault("llm_generation_cost_verifications", [])
    if not isinstance(verifications, list):
        raise LlmGenerationCostError("STORE_INVALID", "llm_generation_cost_verifications must be a list")

    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": result.get("evaluated_on"),
        "items_per_language": result.get("items_per_language"),
        "per_language_usd": result.get("per_language", {}).get("usd_total"),
        "per_language_within_band": result.get("per_language", {}).get("within_planning_band"),
        "per_language_verification": result.get("per_language", {}).get("verification"),
        "stage1_usd": result.get("stage1", {}).get("usd_total"),
        "stage1_within_band": result.get("stage1", {}).get("within_planning_band"),
        "stage1_verification": result.get("stage1", {}).get("verification"),
    }
    verifications.append(summary)
    store["latest_evaluation"] = dict(result)
    return summary
