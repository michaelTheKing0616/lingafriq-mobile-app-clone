"""Swahili TTS blind-test decision artefact (P5-065, CP-§7-sw-01)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping, Sequence

CARD_ID = "P5-065"
LANGUAGE_ID = "sw"
LOCALE = "sw-KE"

_REQUIRED_CANDIDATE_IDS = frozenset(
    {"intron", "google_chirp3_hd_sw_ke", "azure_sw_ke"},
)

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DECISION_PATH = _REPO_ROOT / "assets/data/audio/sw_tts_decision.json"


class SwTtsDecisionError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def decision_path() -> Path:
    return _DECISION_PATH


def load_sw_tts_decision(path: Path | None = None) -> dict[str, Any]:
    p = path or _DECISION_PATH
    if not p.is_file():
        raise SwTtsDecisionError("DECISION_MISSING", f"Swahili TTS decision not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise SwTtsDecisionError("DECISION_INVALID", "decision root must be an object")
    return data


def _mean_mos(mos: Mapping[str, float]) -> float:
    vals = [float(v) for v in mos.values()]
    if not vals:
        raise SwTtsDecisionError("MOS_EMPTY", "mos_by_reviewer must not be empty")
    return round(sum(vals) / len(vals), 2)


def _pick_winner(candidates: Sequence[Mapping[str, Any]]) -> str:
    best_id = ""
    best_mean = -1.0
    for row in candidates:
        cid = row.get("id")
        if not isinstance(cid, str):
            raise SwTtsDecisionError("CANDIDATE_ID", "candidate id must be a string")
        mos = row.get("mos_by_reviewer")
        if not isinstance(mos, dict):
            raise SwTtsDecisionError("MOS_MISSING", f"{cid} mos_by_reviewer required")
        mean = _mean_mos(mos)
        recorded = row.get("mean_mos")
        if recorded is not None and abs(float(recorded) - mean) > 0.01:
            raise SwTtsDecisionError("MOS_MISMATCH", f"{cid} mean_mos does not match reviewers")
        if mean > best_mean:
            best_mean = mean
            best_id = cid
    if not best_id:
        raise SwTtsDecisionError("WINNER_MISSING", "could not determine winner")
    return best_id


def validate_sw_tts_decision(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise SwTtsDecisionError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    if data.get("language_id") != LANGUAGE_ID:
        raise SwTtsDecisionError("LANGUAGE_MISMATCH", f"expected language_id {LANGUAGE_ID}")
    if data.get("locale") != LOCALE:
        raise SwTtsDecisionError("LOCALE_MISMATCH", f"expected locale {LOCALE}")
    if data.get("scores_are_calibration_fixture") is not True:
        raise SwTtsDecisionError("FIXTURE_FLAG", "scores_are_calibration_fixture must be true until live panel")

    blind = data.get("blind_test")
    if not isinstance(blind, dict):
        raise SwTtsDecisionError("BLIND_MISSING", "blind_test object required")
    reviewers = blind.get("reviewers")
    if not isinstance(reviewers, list) or len(reviewers) < 2:
        raise SwTtsDecisionError("REVIEWERS", "at least two reviewers required")

    candidates = blind.get("candidates")
    if not isinstance(candidates, list) or len(candidates) != 3:
        raise SwTtsDecisionError("CANDIDATES", "exactly three TTS candidates required")
    seen: set[str] = set()
    for row in candidates:
        if not isinstance(row, dict):
            raise SwTtsDecisionError("CANDIDATE_INVALID", "candidate must be an object")
        cid = row.get("id")
        if not isinstance(cid, str) or cid not in _REQUIRED_CANDIDATE_IDS:
            raise SwTtsDecisionError("CANDIDATE_ID", f"unexpected candidate id {cid!r}")
        if cid in seen:
            raise SwTtsDecisionError("CANDIDATE_DUP", f"duplicate candidate {cid}")
        seen.add(cid)
        mos = row.get("mos_by_reviewer")
        if not isinstance(mos, dict):
            raise SwTtsDecisionError("MOS_MISSING", f"{cid} mos_by_reviewer required")
        for reviewer in reviewers:
            if reviewer not in mos:
                raise SwTtsDecisionError("MOS_REVIEWER", f"{cid} missing score for {reviewer}")
        _mean_mos(mos)

    if seen != _REQUIRED_CANDIDATE_IDS:
        raise SwTtsDecisionError("CANDIDATES_INCOMPLETE", "Intron, Chirp 3 HD, and Azure must be present")

    winner_id = blind.get("winner_id")
    if not isinstance(winner_id, str):
        raise SwTtsDecisionError("WINNER_INVALID", "winner_id required")
    computed = _pick_winner(candidates)
    if winner_id != computed:
        raise SwTtsDecisionError("WINNER_MISMATCH", f"winner_id must match highest mean MOS ({computed})")

    fallback = blind.get("fallback_if_tie_or_poor")
    if not isinstance(fallback, dict):
        raise SwTtsDecisionError("FALLBACK_MISSING", "fallback_if_tie_or_poor required")
    order = fallback.get("provider_order")
    if not isinstance(order, list) or len(order) < 2:
        raise SwTtsDecisionError("FALLBACK_ORDER", "provider_order must list fallbacks")
    if order[0] != "intron":
        raise SwTtsDecisionError("FALLBACK_ORDER", "EXT-01 tie-break must start with intron")

    routing = data.get("routing_for_p5_066")
    if not isinstance(routing, dict):
        raise SwTtsDecisionError("ROUTING_MISSING", "routing_for_p5_066 required for downstream wiring")
    primary = routing.get("primary_provider")
    if primary != winner_id:
        raise SwTtsDecisionError("ROUTING_PRIMARY", "primary_provider must match blind_test winner_id")


def primary_sw_tts_provider(data: Mapping[str, Any] | None = None) -> str:
    doc = data if data is not None else load_sw_tts_decision()
    validate_sw_tts_decision(doc)
    routing = doc["routing_for_p5_066"]
    primary = routing["primary_provider"]
    assert isinstance(primary, str)
    return primary


def sw_tts_fallback_order(data: Mapping[str, Any] | None = None) -> list[str]:
    doc = data if data is not None else load_sw_tts_decision()
    validate_sw_tts_decision(doc)
    order = doc["routing_for_p5_066"]["fallback_order"]
    if not isinstance(order, list):
        raise SwTtsDecisionError("ROUTING_FALLBACK", "fallback_order must be a list")
    return [str(x) for x in order]
