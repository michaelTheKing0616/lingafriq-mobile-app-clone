"""Data licence cost verification for Stage 1 (P5-092, CURRICULUM §9.4)."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-092"
GATE_ID = "G5"
LEDGER_REL = "assets/content/data_licence_cost_ledger.json"
QUOTES_REL = "assets/content/data_licence_quotes.json"
DEPENDS_ON = ("P5-076",)

# CURRICULUM §9.4:L841-L843 — planning band [rough estimates; get quotes].
USD_STAGE1_MIN = 15_000
USD_STAGE1_MAX = 60_000

_QUOTE_OK_STATUSES = frozenset({"received"})
_QUOTE_PENDING = frozenset({"pending", "not_requested", "requested"})


class DataLicenceCostError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise DataLicenceCostError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise DataLicenceCostError("LEDGER_INVALID", "ledger root must be an object")
    return data


def load_quotes(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / QUOTES_REL
    if not path.is_file():
        raise DataLicenceCostError("QUOTES_MISSING", f"missing {QUOTES_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise DataLicenceCostError("QUOTES_INVALID", "quotes root must be an object")
    return data


def _line_usd(
    row: Mapping[str, Any],
    eur_usd_rate: float,
) -> float | None:
    status = str(row.get("status", "")).strip()
    if status not in _QUOTE_OK_STATUSES:
        return None
    usd = row.get("usd_amount")
    if usd is not None:
        return round(float(usd), 2)
    eur = row.get("eur_amount")
    if eur is not None:
        return round(float(eur) * eur_usd_rate, 2)
    raise DataLicenceCostError(
        "QUOTE_AMOUNT",
        f"{row.get('blocker')}: received quote must set usd_amount or eur_amount",
    )


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


def evaluate_data_licence_cost(
    line_items: Sequence[Mapping[str, Any]],
    *,
    eur_usd_rate: float = 1.08,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    if eur_usd_rate <= 0:
        raise DataLicenceCostError("FX", "eur_usd_rate must be positive")

    pending_required: list[str] = []
    line_summaries: list[dict[str, Any]] = []
    known_total = 0.0
    has_known = False

    for row in line_items:
        if not isinstance(row, Mapping):
            raise DataLicenceCostError("LINE_ITEM", "each line item must be an object")
        blocker = str(row.get("blocker", "")).strip()
        optional = row.get("optional") is True or row.get("required") is False
        status = str(row.get("status", "")).strip()
        usd_line = _line_usd(row, eur_usd_rate)

        if not optional and status in _QUOTE_PENDING:
            pending_required.append(blocker or "unknown")

        if usd_line is not None:
            has_known = True
            known_total = round(known_total + usd_line, 2)

        line_summaries.append(
            {
                "blocker": blocker,
                "vendor": row.get("vendor"),
                "optional": optional,
                "status": status,
                "usd_included": usd_line,
            }
        )

    evaluated_on = (as_of or datetime.now(UTC)).date().isoformat()

    if pending_required:
        return {
            "card_id": CARD_ID,
            "gate": GATE_ID,
            "evaluated_on": evaluated_on,
            "line_items": line_summaries,
            "known_total_usd": known_total if has_known else None,
            "pending_required_blockers": pending_required,
            "verification": "quotes_pending_required",
            "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L841-L843",
            "estimate": True,
        }

    band = _band_flags(known_total, USD_STAGE1_MIN, USD_STAGE1_MAX)
    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": evaluated_on,
        "line_items": line_summaries,
        "known_total_usd": known_total,
        "pending_required_blockers": [],
        **band,
        "curriculum_source": "docs/source/CURRICULUM.md#§9.4:L841-L843",
        "estimate": False,
    }


def validate_quotes(data: Mapping[str, Any]) -> list[dict[str, Any]]:
    if data.get("card_id") != CARD_ID:
        raise DataLicenceCostError("CARD_MISMATCH", f"expected quotes card_id {CARD_ID}")
    items = data.get("line_items")
    if not isinstance(items, list) or not items:
        raise DataLicenceCostError("LINE_ITEMS", "line_items must be a non-empty list")
    required_blockers = {"EXT-04", "EXT-05", "EXT-06"}
    seen: set[str] = set()
    parsed: list[dict[str, Any]] = []
    for row in items:
        if not isinstance(row, Mapping):
            raise DataLicenceCostError("LINE_ITEM", "each line item must be an object")
        blocker = str(row.get("blocker", "")).strip()
        if blocker:
            seen.add(blocker)
        parsed.append(dict(row))
    if not required_blockers.issubset(seen):
        missing = sorted(required_blockers - seen)
        raise DataLicenceCostError("LINE_ITEMS", f"missing required blockers: {missing}")
    return parsed


def validate_ledger(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise DataLicenceCostError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    planning = data.get("planning_band")
    if not isinstance(planning, dict):
        raise DataLicenceCostError("PLANNING", "planning_band object required")
    if planning.get("usd_stage1_min") != USD_STAGE1_MIN:
        raise DataLicenceCostError("PLANNING_FROZEN", "usd_stage1_min must match §9.4")
    if planning.get("usd_stage1_max") != USD_STAGE1_MAX:
        raise DataLicenceCostError("PLANNING_FROZEN", "usd_stage1_max must match §9.4")

    rate = float(data.get("eur_usd_rate_for_optional_hcs", 1.08))
    items = validate_quotes(load_quotes())
    evaluate_data_licence_cost(items, eur_usd_rate=rate)

    verifications = data.get("data_licence_cost_verifications")
    if verifications is not None and not isinstance(verifications, list):
        raise DataLicenceCostError("VERIFICATIONS", "data_licence_cost_verifications must be a list")


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise DataLicenceCostError("RESULT_INVALID", f"result.card_id must be {CARD_ID}")

    verifications = store.setdefault("data_licence_cost_verifications", [])
    if not isinstance(verifications, list):
        raise DataLicenceCostError("STORE_INVALID", "data_licence_cost_verifications must be a list")

    summary = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "evaluated_on": result.get("evaluated_on"),
        "known_total_usd": result.get("known_total_usd"),
        "within_planning_band": result.get("within_planning_band"),
        "verification": result.get("verification"),
        "pending_required_blockers": result.get("pending_required_blockers"),
    }
    verifications.append(summary)
    store["latest_evaluation"] = dict(result)
    return summary
