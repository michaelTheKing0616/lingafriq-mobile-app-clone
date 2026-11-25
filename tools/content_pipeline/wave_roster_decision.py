"""Wave 2–4 roster ADR artefact (P4-111, ELEVATION §6.4)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

CARD_ID = "P4-111"

_CRITERIA = (
    "speakers",
    "diaspora_demand",
    "reviewer_voice_availability",
    "ai_coverage",
    "partner_support",
    "mission_value",
)

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DECISION_PATH = _REPO_ROOT / "assets/content/wave_roster_decision.json"

WAVE_1_LANGUAGE_IDS: frozenset[str] = frozenset(
    {"yo", "ig", "ha", "pcm", "sw", "xh", "zu"}
)


class WaveRosterError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def decision_path() -> Path:
    return _DECISION_PATH


def load_wave_roster_decision(path: Path | None = None) -> dict[str, Any]:
    p = path or _DECISION_PATH
    if not p.is_file():
        raise WaveRosterError("DECISION_MISSING", f"wave roster decision not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise WaveRosterError("DECISION_INVALID", "decision root must be an object")
    return data


def _wave_entries(data: Mapping[str, Any], wave_key: str) -> list[Mapping[str, Any]]:
    raw = data.get(wave_key)
    if not isinstance(raw, list) or not raw:
        raise WaveRosterError("ROSTER_MISSING", f"{wave_key} roster missing or empty")
    out: list[Mapping[str, Any]] = []
    for row in raw:
        if not isinstance(row, dict):
            raise WaveRosterError("ROSTER_INVALID", f"{wave_key} entry must be an object")
        out.append(row)
    return out


def _validate_language_row(row: Mapping[str, Any], *, wave_key: str) -> None:
    lang_id = row.get("language_id")
    if not isinstance(lang_id, str) or not lang_id.strip():
        raise WaveRosterError("ROSTER_INVALID", f"{wave_key} language_id required")
    if lang_id in WAVE_1_LANGUAGE_IDS:
        raise WaveRosterError("ROSTER_OVERLAP", f"{lang_id} must not repeat Wave 1")
    scores = row.get("scores")
    if not isinstance(scores, dict):
        raise WaveRosterError("SCORES_MISSING", f"{lang_id} scores object required")
    for key in _CRITERIA:
        if key not in scores:
            raise WaveRosterError("SCORES_INCOMPLETE", f"{lang_id} missing criterion {key}")
        val = scores[key]
        if val is None:
            continue
        if not isinstance(val, int) or val < 1 or val > 5:
            raise WaveRosterError("SCORE_OUT_OF_RANGE", f"{lang_id}.{key} must be 1–5 or null")


def validate_wave_roster_decision(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise WaveRosterError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    w2 = _wave_entries(data, "wave_2")
    w3 = _wave_entries(data, "wave_3")
    if len(w2) != 14:
        raise WaveRosterError("WAVE2_COUNT", f"Wave 2 must list 14 languages, got {len(w2)}")
    if len(w3) != 25:
        raise WaveRosterError("WAVE3_COUNT", f"Wave 3 must list 25 languages, got {len(w3)}")
    seen: set[str] = set()
    for wave_key, entries in (("wave_2", w2), ("wave_3", w3)):
        for row in entries:
            _validate_language_row(row, wave_key=wave_key)
            lid = row["language_id"]
            if lid in seen:
                raise WaveRosterError("DUPLICATE_LANGUAGE", f"duplicate language_id {lid}")
            seen.add(lid)
    arabic = data.get("egyptian_arabic_moroccan_darija")
    if not isinstance(arabic, dict):
        raise WaveRosterError("ARABIC_DECISION_MISSING", "Arabic/Darija block required")
    if arabic.get("included") is not True:
        raise WaveRosterError("ARABIC_NOT_INCLUDED", "D15 requires inclusion in Wave 4")
    if arabic.get("wave") != 4:
        raise WaveRosterError("ARABIC_WAVE", "Arabic/Darija must be Wave 4 per D15")
    rule = data.get("wave_4_start_rule")
    if not isinstance(rule, dict) or not rule.get("summary"):
        raise WaveRosterError("WAVE4_RULE_MISSING", "wave_4_start_rule.summary required")


def wave_language_ids(data: Mapping[str, Any], wave: int) -> tuple[str, ...]:
    key = f"wave_{wave}"
    if wave not in (2, 3):
        raise WaveRosterError("WAVE_UNKNOWN", f"unsupported wave {wave}")
    return tuple(row["language_id"] for row in _wave_entries(data, key))


def scored_total(row: Mapping[str, Any]) -> int | None:
    scores = row.get("scores")
    if not isinstance(scores, dict):
        return None
    values = [v for v in scores.values() if isinstance(v, int)]
    if not values:
        return None
    return sum(values)
