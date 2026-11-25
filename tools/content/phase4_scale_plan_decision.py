"""Phase 4 scale plan ADR artefact (P5-080, CURRICULUM §9.2)."""

from __future__ import annotations

import json
import re
from datetime import date
from pathlib import Path
from typing import Any, Mapping

from tools.content_pipeline.wave_roster_decision import (
    load_wave_roster_decision,
    wave_language_ids,
)

CARD_ID = "P5-080"
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_REQUIRED_MILESTONE_IDS = frozenset(
    {
        "wave2_a1_beta",
        "wave3_l0_taste",
        "living_archive_kits",
        "native_audio_by_exposure",
    }
)
_NATIVE_TOP_SET = 2000

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DECISION_PATH = _REPO_ROOT / "assets/content/phase4_scale_plan_decision.json"


class Phase4ScalePlanError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def decision_path() -> Path:
    return _DECISION_PATH


def load_phase4_scale_plan_decision(path: Path | None = None) -> dict[str, Any]:
    p = path or _DECISION_PATH
    if not p.is_file():
        raise Phase4ScalePlanError("DECISION_MISSING", f"phase 4 scale plan not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise Phase4ScalePlanError("DECISION_INVALID", "decision root must be an object")
    return data


def _parse_iso(value: str, field: str) -> date:
    if not _DATE_RE.match(value):
        raise Phase4ScalePlanError("DATE_INVALID", f"{field} must be YYYY-MM-DD")
    return date.fromisoformat(value)


def _validate_milestone(row: Mapping[str, Any], index: int) -> str:
    mid = row.get("id")
    if not isinstance(mid, str) or mid not in _REQUIRED_MILESTONE_IDS:
        raise Phase4ScalePlanError(
            "MILESTONE_ID",
            f"milestones[{index}].id must be one of {sorted(_REQUIRED_MILESTONE_IDS)}",
        )
    owner = row.get("owner")
    if not isinstance(owner, str) or not owner.strip():
        raise Phase4ScalePlanError("MILESTONE_OWNER", f"milestones[{index}].owner required")
    target = row.get("target_date")
    if not isinstance(target, str):
        raise Phase4ScalePlanError("MILESTONE_DATE", f"milestones[{index}].target_date required")
    _parse_iso(target, f"milestones[{index}].target_date")
    summary = row.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        raise Phase4ScalePlanError("MILESTONE_SUMMARY", f"milestones[{index}].summary required")
    return mid


def validate_phase4_scale_plan_decision(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise Phase4ScalePlanError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    if not data.get("owner") or not data.get("approved_by"):
        raise Phase4ScalePlanError("OWNER_MISSING", "owner and approved_by required")
    window = data.get("window")
    if not isinstance(window, dict):
        raise Phase4ScalePlanError("WINDOW_MISSING", "window object required")
    start_m = window.get("start_month")
    end_m = window.get("end_month")
    if start_m != 9 or end_m != 24:
        raise Phase4ScalePlanError("WINDOW_MONTHS", "Phase 4 window must be months 9–24 per CURRICULUM §9.2")
    start_d = window.get("start_date")
    end_d = window.get("end_date")
    if not isinstance(start_d, str) or not isinstance(end_d, str):
        raise Phase4ScalePlanError("WINDOW_DATES", "window start_date and end_date required")
    if _parse_iso(start_d, "window.start_date") > _parse_iso(end_d, "window.end_date"):
        raise Phase4ScalePlanError("WINDOW_ORDER", "window start_date must be on or before end_date")

    milestones = data.get("milestones")
    if not isinstance(milestones, list):
        raise Phase4ScalePlanError("MILESTONES_MISSING", "milestones list required")
    seen: set[str] = set()
    for index, row in enumerate(milestones):
        if not isinstance(row, Mapping):
            raise Phase4ScalePlanError("MILESTONE_INVALID", f"milestones[{index}] must be an object")
        mid = _validate_milestone(row, index)
        if mid in seen:
            raise Phase4ScalePlanError("MILESTONE_DUPLICATE", f"duplicate milestone id {mid}")
        seen.add(mid)
    if seen != _REQUIRED_MILESTONE_IDS:
        missing = _REQUIRED_MILESTONE_IDS - seen
        raise Phase4ScalePlanError(
            "MILESTONES_INCOMPLETE",
            f"missing milestone ids: {sorted(missing)}",
        )

    native = next(m for m in milestones if m["id"] == "native_audio_by_exposure")
    criteria = native.get("success_criteria")
    if not isinstance(criteria, Mapping):
        raise Phase4ScalePlanError("NATIVE_CRITERIA", "native_audio_by_exposure success_criteria required")
    top_set = criteria.get("initial_top_set_size")
    if top_set != _NATIVE_TOP_SET:
        raise Phase4ScalePlanError(
            "NATIVE_TOP_SET",
            f"native initial_top_set_size must be {_NATIVE_TOP_SET} per CURRICULUM §7",
        )


def milestone_by_id(data: Mapping[str, Any], milestone_id: str) -> Mapping[str, Any]:
    validate_phase4_scale_plan_decision(data)
    for row in data["milestones"]:
        if row.get("id") == milestone_id:
            return row
    raise Phase4ScalePlanError("MILESTONE_NOT_FOUND", milestone_id)


def wave2_a1_beta_language_count() -> int:
    roster = load_wave_roster_decision()
    return len(wave_language_ids(roster, 2))


def wave3_l0_language_count() -> int:
    roster = load_wave_roster_decision()
    return len(wave_language_ids(roster, 3))
