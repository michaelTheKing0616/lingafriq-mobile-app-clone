"""Stage 1 all-in content cost rollup (P5-094, CURRICULUM §9.4:L846-L850)."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.audio.interim_tts_cost_verify import (
    CHARACTERS_MAX as TTS_CHARS_MAX,
    CHARACTERS_MIN as TTS_CHARS_MIN,
    evaluate_interim_tts_cost,
    load_ledger as load_interim_tts_ledger,
)
from tools.content.data_licence_cost_verify import (
    USD_STAGE1_MAX as DATA_LIC_STAGE1_MAX,
    USD_STAGE1_MIN as DATA_LIC_STAGE1_MIN,
    evaluate_data_licence_cost,
    load_ledger as load_data_licence_ledger,
    load_quotes,
    validate_quotes,
)
from tools.content.llm_generation_cost_verify import (
    ITEMS_PER_LANGUAGE_MAX,
    ITEMS_PER_LANGUAGE_MIN,
    evaluate_stage1_llm_cost,
    load_ledger as load_llm_ledger,
    pass_profiles_from_ledger,
)
from tools.content.placeholder_linter import repo_root
from tools.content.reference_books_cost_verify import (
    USD_STAGE1_MAX as REF_BOOKS_STAGE1_MAX,
    USD_STAGE1_MIN as REF_BOOKS_STAGE1_MIN,
    evaluate_reference_purchases,
    load_purchases,
    validate_purchases,
)

CARD_ID = "P5-094"
GATE_ID = "G5"
LEDGER_REL = "assets/content/stage1_all_in_cost_ledger.json"
DEPENDS_ON = ("P5-088", "P5-089", "P5-090", "P5-091", "P5-092", "P5-093", "P5-070")

# CURRICULUM §9.4:L847-L850 — planning rule-of-thumb bands [estimate].
ALL_IN_STAGE1_MIN = 65_000
ALL_IN_STAGE1_MAX = 195_000
LATER_LANGUAGE_MIN = 4_000
LATER_LANGUAGE_MAX = 15_000

# §9.4:L833-L834 — linguist (P5-089; EXT-11 blocks verified quotes).
LINGUIST_STAGE1_MIN = 21_000
LINGUIST_STAGE1_MAX = 84_000
LINGUIST_PER_LANGUAGE_MIN = 3_000
LINGUIST_PER_LANGUAGE_MAX = 12_000

# §9.4:L834 — calibration / blind sampling first year (P5-090; EXT-11).
CALIBRATION_MONTHS_FIRST_YEAR = 12
CALIBRATION_STAGE1_MONTHLY_MIN = 1_000
CALIBRATION_STAGE1_MONTHLY_MAX = 1_200
CALIBRATION_PER_LANGUAGE_MONTHLY_MIN = 100
CALIBRATION_PER_LANGUAGE_MONTHLY_MAX = 200

# §9.4:L840 — isiXhosa custom voice (P5-070; EXT-12).
XH_VOICE_STAGE1_MIN = 10_000
XH_VOICE_STAGE1_MAX = 25_000

BLOCKED_EXTERNAL = (
    {"card_id": "P5-089", "blocker": "EXT-11", "title": "linguist review cost"},
    {"card_id": "P5-090", "blocker": "EXT-11", "title": "calibration and sampling cost"},
    {"card_id": "P5-070", "blocker": "EXT-12", "title": "isiXhosa custom voice quote"},
)


class Stage1AllInCostError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class CostSpan:
    usd_min: float
    usd_max: float
    source_card: str
    verification: str
    note: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return {
            "source_card": self.source_card,
            "usd_min": round(self.usd_min, 2),
            "usd_max": round(self.usd_max, 2),
            "verification": self.verification,
            "note": self.note,
        }


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise Stage1AllInCostError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise Stage1AllInCostError("LEDGER_INVALID", "ledger root must be an object")
    return data


def _span_from_known(known: float, source_card: str, verification: str) -> CostSpan:
    return CostSpan(known, known, source_card, verification)


def _llm_span(root: Path | None = None) -> CostSpan:
    ledger = load_llm_ledger(root)
    profiles = pass_profiles_from_ledger(ledger)
    low = evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MIN)
    high = evaluate_stage1_llm_cost(profiles, items_per_language=ITEMS_PER_LANGUAGE_MAX)
    return CostSpan(
        float(low["stage1"]["usd_total"]),
        float(high["stage1"]["usd_total"]),
        "P5-088",
        "model_pricing_verified",
    )


def _interim_tts_span(root: Path | None = None) -> CostSpan:
    load_interim_tts_ledger(root)
    low = evaluate_interim_tts_cost(characters=TTS_CHARS_MIN)
    high = evaluate_interim_tts_cost(characters=TTS_CHARS_MAX)
    return CostSpan(
        float(low["known_total_usd"]),
        float(high["known_total_usd"]),
        "P5-091",
        low["verification"],
        note="Intron excluded while quote pending",
    )


def _data_licence_span(root: Path | None = None) -> CostSpan:
    ledger = load_data_licence_ledger(root)
    rate = float(ledger.get("eur_usd_rate_for_optional_hcs", 1.08))
    items = validate_quotes(load_quotes(root))
    result = evaluate_data_licence_cost(items, eur_usd_rate=rate)
    if result["verification"] == "quotes_pending_required":
        return CostSpan(
            DATA_LIC_STAGE1_MIN,
            DATA_LIC_STAGE1_MAX,
            "P5-092",
            "planning_band_pending_quotes",
            note=f"pending: {result.get('pending_required_blockers')}",
        )
    known = float(result["known_total_usd"])
    return _span_from_known(known, "P5-092", result["verification"])


def _reference_books_span(root: Path | None = None) -> CostSpan:
    items = validate_purchases(load_purchases(root))
    result = evaluate_reference_purchases(items)
    if result["verification"] == "purchases_pending_required":
        return CostSpan(
            REF_BOOKS_STAGE1_MIN,
            REF_BOOKS_STAGE1_MAX,
            "P5-093",
            "planning_band_pending_purchases",
            note="EXT-22 purchases pending",
        )
    known = float(result["known_total_usd"])
    return _span_from_known(known, "P5-093", result["verification"])


def _linguist_span() -> CostSpan:
    return CostSpan(
        LINGUIST_STAGE1_MIN,
        LINGUIST_STAGE1_MAX,
        "P5-089",
        "blocked_external_planning_band",
        note="EXT-11",
    )


def _calibration_span() -> CostSpan:
    stage_min = CALIBRATION_STAGE1_MONTHLY_MIN * CALIBRATION_MONTHS_FIRST_YEAR
    stage_max = CALIBRATION_STAGE1_MONTHLY_MAX * CALIBRATION_MONTHS_FIRST_YEAR
    return CostSpan(
        stage_min,
        stage_max,
        "P5-090",
        "blocked_external_planning_band",
        note="EXT-11; first-year sampling",
    )


def _xh_voice_span() -> CostSpan:
    return CostSpan(
        XH_VOICE_STAGE1_MIN,
        XH_VOICE_STAGE1_MAX,
        "P5-070",
        "blocked_external_planning_band",
        note="EXT-12 quote pending",
    )


def _bands_overlap(
    span_min: float,
    span_max: float,
    band_min: float,
    band_max: float,
) -> bool:
    return span_min <= band_max and span_max >= band_min


def _rollup_verification(total_min: float, total_max: float) -> str:
    if total_min >= ALL_IN_STAGE1_MIN and total_max <= ALL_IN_STAGE1_MAX:
        return "confirmed_within_all_in_band"
    if _bands_overlap(total_min, total_max, ALL_IN_STAGE1_MIN, ALL_IN_STAGE1_MAX):
        return "estimate_overlaps_all_in_band"
    return "delta_recorded"


def collect_component_spans(root: Path | None = None) -> tuple[CostSpan, ...]:
    return (
        _llm_span(root),
        _linguist_span(),
        _calibration_span(),
        _interim_tts_span(root),
        _xh_voice_span(),
        _data_licence_span(root),
        _reference_books_span(root),
    )


def evaluate_stage1_all_in_rollup(
    components: Sequence[CostSpan],
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    if not components:
        raise Stage1AllInCostError("COMPONENTS", "at least one cost component required")

    total_min = round(sum(c.usd_min for c in components), 2)
    total_max = round(sum(c.usd_max for c in components), 2)
    pending_external = [row for row in BLOCKED_EXTERNAL]
    pending_quotes = [
        c.source_card
        for c in components
        if c.verification in ("planning_band_pending_quotes", "planning_band_pending_purchases")
    ]

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    verification = _rollup_verification(total_min, total_max)
    if pending_external or pending_quotes:
        verification = f"{verification}_with_pending_inputs"

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "components": [c.as_dict() for c in components],
        "stage1_all_in_usd_min": total_min,
        "stage1_all_in_usd_max": total_max,
        "all_in_planning_band_min": ALL_IN_STAGE1_MIN,
        "all_in_planning_band_max": ALL_IN_STAGE1_MAX,
        "all_in_verification": verification,
        "blocked_external_logged": pending_external,
        "pending_quote_cards": pending_quotes,
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L846-L850",
        "estimate": True,
        "engineering_excluded": True,
    }


def evaluate_later_language_rollup(
    root: Path | None = None,
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    """Shared-tooling marginal language once licences exist (§9.4:L849-L850)."""
    profiles = pass_profiles_from_ledger(load_llm_ledger(root))
    llm_low = evaluate_stage1_llm_cost(
        profiles,
        items_per_language=ITEMS_PER_LANGUAGE_MIN,
    )["per_language"]["usd_total"]
    llm_high = evaluate_stage1_llm_cost(
        profiles,
        items_per_language=ITEMS_PER_LANGUAGE_MAX,
    )["per_language"]["usd_total"]
    tts_low = evaluate_interim_tts_cost(characters=TTS_CHARS_MIN)["known_total_usd"]
    tts_high = evaluate_interim_tts_cost(characters=TTS_CHARS_MAX)["known_total_usd"]
    cal_min = CALIBRATION_PER_LANGUAGE_MONTHLY_MIN * CALIBRATION_MONTHS_FIRST_YEAR
    cal_max = CALIBRATION_PER_LANGUAGE_MONTHLY_MAX * CALIBRATION_MONTHS_FIRST_YEAR
    ref_min = 200.0
    ref_max = 600.0

    total_min = round(
        float(llm_low) + LINGUIST_PER_LANGUAGE_MIN + cal_min + float(tts_low) + ref_min,
        2,
    )
    total_max = round(
        float(llm_high) + LINGUIST_PER_LANGUAGE_MAX + cal_max + float(tts_high) + ref_max,
        2,
    )
    verification = _rollup_verification(total_min, total_max)
    if verification == "delta_recorded":
        verification = "later_language_delta_recorded"
    else:
        verification = f"later_language_{verification}"

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "later_language_usd_min": total_min,
        "later_language_usd_max": total_max,
        "later_language_band_min": LATER_LANGUAGE_MIN,
        "later_language_band_max": LATER_LANGUAGE_MAX,
        "later_language_verification": verification,
        "excludes_one_off_licences": True,
        "excludes_xhosa_voice_commission": True,
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L849-L850",
        "estimate": True,
    }


def evaluate_p5_094(root: Path | None = None, *, as_of: datetime | None = None) -> dict[str, Any]:
    components = collect_component_spans(root)
    stage1 = evaluate_stage1_all_in_rollup(components, as_of=as_of)
    later = evaluate_later_language_rollup(root, as_of=as_of)
    overall = stage1["all_in_verification"]
    if later["later_language_verification"].endswith("delta_recorded"):
        overall = "delta_recorded"
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": stage1["evaluated_on"],
        "stage1_all_in": stage1,
        "later_language": later,
        "verification": overall,
    }


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise Stage1AllInCostError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band_all_in")
    if not isinstance(planning, dict):
        raise Stage1AllInCostError("PLANNING", "planning_band_all_in object required")
    if planning.get("usd_stage1_min") != ALL_IN_STAGE1_MIN:
        raise Stage1AllInCostError("PLANNING_FROZEN", "usd_stage1_min must match §9.4")
    if planning.get("usd_stage1_max") != ALL_IN_STAGE1_MAX:
        raise Stage1AllInCostError("PLANNING_FROZEN", "usd_stage1_max must match §9.4")

    later = data.get("planning_band_later_language")
    if not isinstance(later, dict):
        raise Stage1AllInCostError("PLANNING", "planning_band_later_language object required")
    if later.get("usd_min") != LATER_LANGUAGE_MIN:
        raise Stage1AllInCostError("PLANNING_FROZEN", "later usd_min must match §9.4")
    if later.get("usd_max") != LATER_LANGUAGE_MAX:
        raise Stage1AllInCostError("PLANNING_FROZEN", "later usd_max must match §9.4")

    evaluate_p5_094()

    verifications = data.get("stage1_all_in_cost_verifications")
    if verifications is not None and not isinstance(verifications, list):
        raise Stage1AllInCostError("VERIFICATIONS", "stage1_all_in_cost_verifications must be a list")


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise Stage1AllInCostError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")

    verifications = store.setdefault("stage1_all_in_cost_verifications", [])
    if not isinstance(verifications, list):
        raise Stage1AllInCostError("STORE_INVALID", "stage1_all_in_cost_verifications must be a list")

    stage1 = result.get("stage1_all_in", {})
    later = result.get("later_language", {})
    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": result.get("evaluated_on"),
        "verification": result.get("verification"),
        "stage1_usd_min": stage1.get("stage1_all_in_usd_min"),
        "stage1_usd_max": stage1.get("stage1_all_in_usd_max"),
        "all_in_verification": stage1.get("all_in_verification"),
        "later_language_verification": later.get("later_language_verification"),
        "blocked_external_logged": stage1.get("blocked_external_logged"),
    }
    verifications.append(summary)
    store["latest_evaluation"] = dict(result)
    return summary
