"""Reference book purchases and engineering-week verification (P5-093, CURRICULUM §9.4)."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.lexicon_select import STAGE1_LANGS
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-093"
GATE_ID = "G5"
LEDGER_REL = "assets/content/reference_books_cost_ledger.json"
PURCHASES_REL = "assets/content/reference_books_purchases.json"
ENGINEERING_REL = "assets/content/reference_books_engineering.json"
DEPENDS_ON = ("P5-076",)

# CURRICULUM §9.4:L843 — print/ebook reference purchases [estimate].
USD_PER_LANGUAGE_MIN = 200
USD_PER_LANGUAGE_MAX = 600
USD_STAGE1_MIN = 2_000
USD_STAGE1_MAX = 4_000

# CURRICULUM §9.4:L844 — Studio + pipeline engineering [estimate].
ENG_WEEKS_STAGE1_MIN = 14
ENG_WEEKS_STAGE1_MAX = 20

# P4-080 card-sum decomposition (docs/build/verification/P4-080-2026-10-25.md).
STUDIO_PLANNED_ENGINEER_WEEKS = 11.5
# CURRICULUM §9.1:L789 — pipeline service [estimate].
PIPELINE_PLANNED_WEEKS_MIN = 4.0
PIPELINE_PLANNED_WEEKS_MAX = 6.0

_PURCHASE_OK = frozenset({"received"})
_PURCHASE_PENDING = frozenset({"pending", "not_requested", "requested", "not_purchased"})


class ReferenceBooksCostError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise ReferenceBooksCostError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ReferenceBooksCostError("LEDGER_INVALID", "ledger root must be an object")
    return data


def load_purchases(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / PURCHASES_REL
    if not path.is_file():
        raise ReferenceBooksCostError("PURCHASES_MISSING", f"missing {PURCHASES_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ReferenceBooksCostError("PURCHASES_INVALID", "purchases root must be an object")
    return data


def load_engineering(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / ENGINEERING_REL
    if not path.is_file():
        raise ReferenceBooksCostError("ENGINEERING_MISSING", f"missing {ENGINEERING_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ReferenceBooksCostError("ENGINEERING_INVALID", "engineering root must be an object")
    return data


def _band_flags(value: float, low: float, high: float) -> dict[str, Any]:
    within = low <= value <= high
    delta = 0.0
    if value < low:
        delta = round(value - low, 2)
    elif value > high:
        delta = round(value - high, 2)
    return {
        "within_planning_band": within,
        "planning_band_min": low,
        "planning_band_max": high,
        "delta_vs_band": delta,
        "verification": "confirmed_within_band" if within else "delta_recorded",
    }


def _line_usd(row: Mapping[str, Any]) -> float | None:
    status = str(row.get("status", "")).strip()
    if status not in _PURCHASE_OK:
        return None
    usd = row.get("usd_amount")
    if usd is None:
        raise ReferenceBooksCostError(
            "PURCHASE_AMOUNT",
            f"{row.get('language_code')}: received purchase must set usd_amount",
        )
    return round(float(usd), 2)


def evaluate_reference_purchases(
    line_items: Sequence[Mapping[str, Any]],
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    pending_required: list[str] = []
    summaries: list[dict[str, Any]] = []
    known_total = 0.0
    has_known = False
    per_lang: dict[str, float] = {}

    for row in line_items:
        if not isinstance(row, Mapping):
            raise ReferenceBooksCostError("LINE_ITEM", "each line item must be an object")
        lang = str(row.get("language_code", "")).strip()
        required = row.get("required") is True
        optional = row.get("optional") is True or row.get("required") is False
        status = str(row.get("status", "")).strip()
        usd_line = _line_usd(row)

        if required and status in _PURCHASE_PENDING:
            pending_required.append(row.get("blocker") or lang or "unknown")

        if usd_line is not None:
            has_known = True
            known_total = round(known_total + usd_line, 2)
            if lang:
                per_lang[lang] = round(per_lang.get(lang, 0.0) + usd_line, 2)

        summaries.append(
            {
                "language_code": lang,
                "title": row.get("title"),
                "blocker": row.get("blocker"),
                "required": required and not optional,
                "status": status,
                "usd_included": usd_line,
            }
        )

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    base = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "line_items": summaries,
        "known_total_usd": known_total if has_known else None,
        "per_language_usd": per_lang if per_lang else None,
        "pending_required_blockers": pending_required,
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L843",
        "estimate": True,
    }

    if pending_required:
        base["verification"] = "purchases_pending_required"
        return base

    per_lang_flags = []
    for lang, usd in per_lang.items():
        band = _band_flags(usd, USD_PER_LANGUAGE_MIN, USD_PER_LANGUAGE_MAX)
        per_lang_flags.append({"language_code": lang, "usd": usd, **band})

    stage_band = _band_flags(known_total, USD_STAGE1_MIN, USD_STAGE1_MAX)
    return {
        **base,
        "estimate": False,
        "per_language_checks": per_lang_flags,
        "pending_required_blockers": [],
        **stage_band,
    }


def evaluate_engineering_weeks(
    engineering: Mapping[str, Any],
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    studio = float(engineering.get("studio_planned_engineer_weeks", STUDIO_PLANNED_ENGINEER_WEEKS))
    pipe_min = float(engineering.get("pipeline_planned_weeks_min", PIPELINE_PLANNED_WEEKS_MIN))
    pipe_max = float(engineering.get("pipeline_planned_weeks_max", PIPELINE_PLANNED_WEEKS_MAX))
    combined_min = round(studio + pipe_min, 2)
    combined_max = round(studio + pipe_max, 2)
    combined_mid = round((combined_min + combined_max) / 2, 2)

    mid_band = _band_flags(combined_mid, ENG_WEEKS_STAGE1_MIN, ENG_WEEKS_STAGE1_MAX)
    range_within = (
        combined_min >= ENG_WEEKS_STAGE1_MIN and combined_max <= ENG_WEEKS_STAGE1_MAX
    )

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "studio_planned_engineer_weeks": studio,
        "pipeline_planned_weeks_min": pipe_min,
        "pipeline_planned_weeks_max": pipe_max,
        "combined_engineer_weeks_min": combined_min,
        "combined_engineer_weeks_max": combined_max,
        "combined_engineer_weeks_mid": combined_mid,
        "planning_band_engineer_weeks_min": ENG_WEEKS_STAGE1_MIN,
        "planning_band_engineer_weeks_max": ENG_WEEKS_STAGE1_MAX,
        "range_within_planning_band": range_within,
        "verification": "confirmed_within_band" if range_within else "delta_recorded",
        **mid_band,
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L844",
        "estimate": not range_within,
        "g4_passed": engineering.get("g4_passed") is True,
        "actual_engineer_weeks": engineering.get("actual_engineer_weeks"),
    }


def validate_purchases(data: Mapping[str, Any]) -> list[dict[str, Any]]:
    if data.get("card_id") != CARD_ID:
        raise ReferenceBooksCostError("CARD_MISMATCH", f"expected purchases card_id {CARD_ID}")
    items = data.get("line_items")
    if not isinstance(items, list) or not items:
        raise ReferenceBooksCostError("LINE_ITEMS", "line_items must be a non-empty list")
    required_langs = {lang for lang in STAGE1_LANGS if lang != "xh"}
    seen: set[str] = set()
    parsed: list[dict[str, Any]] = []
    for row in items:
        if not isinstance(row, Mapping):
            raise ReferenceBooksCostError("LINE_ITEM", "each line item must be an object")
        lang = str(row.get("language_code", "")).strip()
        if lang and row.get("required") is True:
            seen.add(lang)
        parsed.append(dict(row))
    if not required_langs.issubset(seen):
        missing = sorted(required_langs - seen)
        raise ReferenceBooksCostError("LINE_ITEMS", f"missing required language purchases: {missing}")
    return parsed


def validate_engineering(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise ReferenceBooksCostError("CARD_MISMATCH", f"expected engineering card_id {CARD_ID}")
    if data.get("studio_planned_engineer_weeks") != STUDIO_PLANNED_ENGINEER_WEEKS:
        raise ReferenceBooksCostError(
            "ENGINEERING_FROZEN",
            "studio_planned_engineer_weeks must match P4-080 decomposition",
        )


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise ReferenceBooksCostError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band_usd")
    if not isinstance(planning, dict):
        raise ReferenceBooksCostError("PLANNING", "planning_band_usd object required")
    if planning.get("usd_stage1_min") != USD_STAGE1_MIN:
        raise ReferenceBooksCostError("PLANNING_FROZEN", "usd_stage1_min must match §9.4")
    if planning.get("usd_stage1_max") != USD_STAGE1_MAX:
        raise ReferenceBooksCostError("PLANNING_FROZEN", "usd_stage1_max must match §9.4")

    eng = data.get("planning_band_engineer_weeks")
    if not isinstance(eng, dict):
        raise ReferenceBooksCostError("PLANNING", "planning_band_engineer_weeks object required")
    if eng.get("min") != ENG_WEEKS_STAGE1_MIN or eng.get("max") != ENG_WEEKS_STAGE1_MAX:
        raise ReferenceBooksCostError("PLANNING_FROZEN", "engineer-week band must match §9.4")

    validate_engineering(load_engineering())
    items = validate_purchases(load_purchases())
    evaluate_reference_purchases(items)
    evaluate_engineering_weeks(load_engineering())

    verifications = data.get("reference_books_verifications")
    if verifications is not None and not isinstance(verifications, list):
        raise ReferenceBooksCostError("VERIFICATIONS", "reference_books_verifications must be a list")


def evaluate_p5_093(
    purchases: Sequence[Mapping[str, Any]],
    engineering: Mapping[str, Any],
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    purchase_result = evaluate_reference_purchases(purchases, as_of=as_of)
    engineering_result = evaluate_engineering_weeks(engineering, as_of=as_of)
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": purchase_result["evaluated_on"],
        "purchases": purchase_result,
        "engineering": engineering_result,
        "verification": (
            "confirmed_within_band"
            if purchase_result.get("verification") == "confirmed_within_band"
            and engineering_result.get("verification") == "confirmed_within_band"
            else (
                "purchases_pending_required"
                if purchase_result.get("verification") == "purchases_pending_required"
                else "delta_recorded"
            )
        ),
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise ReferenceBooksCostError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")

    verifications = store.setdefault("reference_books_verifications", [])
    if not isinstance(verifications, list):
        raise ReferenceBooksCostError("STORE_INVALID", "reference_books_verifications must be a list")

    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": result.get("evaluated_on"),
        "verification": result.get("verification"),
        "purchases_verification": result.get("purchases", {}).get("verification"),
        "engineering_verification": result.get("engineering", {}).get("verification"),
        "pending_required_blockers": result.get("purchases", {}).get("pending_required_blockers"),
    }
    verifications.append(summary)
    store["latest_evaluation"] = dict(result)
    return summary
