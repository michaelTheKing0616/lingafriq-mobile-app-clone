"""Stage 1 vendor coverage, feature lookup, and readiness target report (P4-113)."""

from __future__ import annotations

import json
from calendar import monthrange
from datetime import date
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_pipeline.readiness import READINESS_LEVELS
from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS

CARD_ID = "P4-113"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_COVERAGE_PATH = _REPO_ROOT / "assets/content/stage1_coverage.json"
_SCHEMA_PATH = _REPO_ROOT / "schemas/v2/vendor_coverage.schema.json"

_FEATURE_KEYS = frozenset({"asr", "dynamic_tts", "realtime_voice", "tone_scoring"})
_GEMINI_LIVE_LANGS = frozenset({"yo", "ha", "sw", "zu"})
_CASCADE_LANGS = frozenset({"ig", "pcm", "xh"})
_INTRON_TTS_LANGS = frozenset({"yo", "ig", "ha", "pcm", "sw"})


class CoverageError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def coverage_path() -> Path:
    return _COVERAGE_PATH


def schema_path() -> Path:
    return _SCHEMA_PATH


def load_stage1_coverage(path: Path | None = None) -> dict[str, Any]:
    p = path or _COVERAGE_PATH
    if not p.is_file():
        raise CoverageError("COVERAGE_MISSING", f"stage1 coverage not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise CoverageError("COVERAGE_INVALID", "coverage root must be an object")
    return data


def _languages(data: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    raw = data.get("languages")
    if not isinstance(raw, list) or len(raw) != 7:
        raise CoverageError("LANGUAGES_INVALID", "languages must be an array of seven entries")
    out: list[Mapping[str, Any]] = []
    for index, row in enumerate(raw):
        if not isinstance(row, dict):
            raise CoverageError("LANGUAGE_INVALID", f"languages[{index}] must be an object")
        out.append(row)
    return out


def _by_language_id(data: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    return {str(row["language_id"]): row for row in _languages(data)}


def _add_months(anchor: date, months: int) -> date:
    year = anchor.year + (anchor.month - 1 + months) // 12
    month = (anchor.month - 1 + months) % 12 + 1
    day = min(anchor.day, monthrange(year, month)[1])
    return date(year, month, day)


def level_due_date(data: Mapping[str, Any], target_level: str) -> date:
    targets = data.get("level_targets")
    if not isinstance(targets, dict):
        raise CoverageError("TARGETS_MISSING", "level_targets object required")
    start_raw = targets.get("program_start")
    if not isinstance(start_raw, str):
        raise CoverageError("TARGETS_INVALID", "program_start must be an ISO date string")
    start = date.fromisoformat(start_raw)
    if target_level == "L1":
        quarters = targets.get("l1_due_quarters")
    elif target_level == "L2":
        quarters = targets.get("l2_due_quarters")
    else:
        raise CoverageError("TARGET_LEVEL", "only L1 and L2 due dates are defined")
    if not isinstance(quarters, int) or quarters < 1:
        raise CoverageError("TARGETS_INVALID", "due quarter count must be a positive integer")
    return _add_months(start, quarters * 3)


def _readiness_index(level: str | None) -> int:
    if level is None:
        return -1
    if level not in READINESS_LEVELS:
        raise CoverageError("READINESS_INVALID", f"unknown readiness level {level}")
    return READINESS_LEVELS.index(level)


def validate_stage1_coverage(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise CoverageError("CARD_MISMATCH", f"expected card_id {CARD_ID}")

    by_id = _by_language_id(data)
    if set(by_id) != WAVE_1_LANGUAGE_IDS:
        missing = WAVE_1_LANGUAGE_IDS - set(by_id)
        extra = set(by_id) - WAVE_1_LANGUAGE_IDS
        raise CoverageError(
            "LANGUAGE_SET",
            f"languages must be exactly Stage 1 ids; missing={sorted(missing)} extra={sorted(extra)}",
        )

    for lang_id, row in sorted(by_id.items()):
        asr = row.get("asr")
        if not isinstance(asr, dict) or asr.get("vendor") != "intron":
            raise CoverageError("ASR_VENDOR", f"{lang_id} ASR must use intron")
        cs = asr.get("code_switching")
        if lang_id == "xh":
            if cs is not False:
                raise CoverageError("ASR_CS", "xh ASR must not use code_switching")
        elif cs is not True:
            raise CoverageError("ASR_CS", f"{lang_id} ASR must use code_switching")

        tts = row.get("dynamic_tts")
        if not isinstance(tts, dict):
            raise CoverageError("TTS_INVALID", f"{lang_id} dynamic_tts required")
        if lang_id in _INTRON_TTS_LANGS:
            if tts.get("vendor") != "intron" or tts.get("enabled") is not True:
                raise CoverageError("TTS_VENDOR", f"{lang_id} dynamic TTS must be intron and enabled")
        elif lang_id == "zu":
            if tts.get("vendor") != "azure" or tts.get("enabled") is not True:
                raise CoverageError("TTS_VENDOR", "zu dynamic TTS must be azure and enabled")
        elif lang_id == "xh":
            if tts.get("vendor") != "custom_voice_required" or tts.get("enabled") is not False:
                raise CoverageError("TTS_XH", "xh dynamic TTS must be custom_voice_required and disabled")
            reason = tts.get("disabled_reason")
            if not isinstance(reason, str) or "EXT-12" not in reason:
                raise CoverageError("TTS_XH", "xh disabled_reason must cite EXT-12")

        rt = row.get("realtime_voice")
        if not isinstance(rt, dict):
            raise CoverageError("REALTIME_INVALID", f"{lang_id} realtime_voice required")
        mode = rt.get("mode")
        if lang_id in _GEMINI_LIVE_LANGS and mode != "gemini_live":
            raise CoverageError("REALTIME_MODE", f"{lang_id} must use gemini_live")
        if lang_id in _CASCADE_LANGS and mode != "cascade":
            raise CoverageError("REALTIME_MODE", f"{lang_id} must use cascade")

        tone = row.get("tone_scoring")
        if not isinstance(tone, dict) or tone.get("vendor") != "inhouse":
            raise CoverageError("TONE_VENDOR", f"{lang_id} tone_scoring must be inhouse")


def lookup_feature(
    data: Mapping[str, Any],
    language_id: str,
    feature: str,
) -> dict[str, Any]:
    """Return vendor coverage for a feature, or UNCOVERED when the language is absent."""
    if feature not in _FEATURE_KEYS:
        raise CoverageError("FEATURE_UNKNOWN", f"unknown feature {feature}")
    by_id = _by_language_id(data)
    if language_id not in by_id:
        return {
            "card_id": CARD_ID,
            "language_id": language_id,
            "feature": feature,
            "code": "UNCOVERED",
            "available": False,
        }
    row = by_id[language_id]
    block = row.get(feature)
    if not isinstance(block, Mapping):
        return {
            "card_id": CARD_ID,
            "language_id": language_id,
            "feature": feature,
            "code": "UNCOVERED",
            "available": False,
        }
    payload: dict[str, Any] = {
        "card_id": CARD_ID,
        "language_id": language_id,
        "feature": feature,
        "code": "COVERED",
        "available": True,
        "vendor_plan": dict(block),
    }
    if feature == "dynamic_tts" and block.get("enabled") is False:
        payload["available"] = False
        payload["code"] = "FEATURE_DISABLED"
        reason = block.get("disabled_reason")
        if isinstance(reason, str) and reason.strip():
            payload["disabled_reason"] = reason.strip()
    return payload


def list_l3_candidates(data: Mapping[str, Any]) -> list[str]:
    """Languages that passed realtime and persona evals (AC4)."""
    out: list[str] = []
    for row in _languages(data):
        lang_id = str(row["language_id"])
        evals = row.get("stage_evals")
        if not isinstance(evals, Mapping):
            continue
        if evals.get("realtime_voice") == "pass" and evals.get("persona") == "pass":
            out.append(lang_id)
    return sorted(out)


def overdue_readiness_gates(
    coverage: Mapping[str, Any],
    registry_entries: Sequence[Mapping[str, Any]],
    *,
    as_of: date,
) -> list[dict[str, Any]]:
    """Missed L1/L2 quarter targets for Wave 1 languages (AC3)."""
    l1_due = level_due_date(coverage, "L1")
    l2_due = level_due_date(coverage, "L2")
    wave1 = {e.get("language_id") for e in registry_entries if e.get("wave") == 1}
    overdue: list[dict[str, Any]] = []
    for entry in registry_entries:
        if entry.get("wave") != 1:
            continue
        lang_id = entry.get("language_id")
        if not isinstance(lang_id, str) or lang_id not in wave1:
            continue
        current = entry.get("readiness_level")
        idx = _readiness_index(current if isinstance(current, str) or current is None else None)
        if as_of > l1_due and idx < READINESS_LEVELS.index("L1"):
            overdue.append(
                {
                    "language_id": lang_id,
                    "gate": "L1",
                    "due_date": l1_due.isoformat(),
                    "readiness_level": current,
                    "code": "READINESS_GATE_OVERDUE",
                }
            )
        if as_of > l2_due and idx < READINESS_LEVELS.index("L2"):
            overdue.append(
                {
                    "language_id": lang_id,
                    "gate": "L2",
                    "due_date": l2_due.isoformat(),
                    "readiness_level": current,
                    "code": "READINESS_GATE_OVERDUE",
                }
            )
    return overdue


def readiness_coverage_report(
    coverage: Mapping[str, Any],
    registry_entries: Sequence[Mapping[str, Any]],
    *,
    as_of: date,
) -> dict[str, Any]:
    return {
        "card_id": CARD_ID,
        "as_of": as_of.isoformat(),
        "l1_due": level_due_date(coverage, "L1").isoformat(),
        "l2_due": level_due_date(coverage, "L2").isoformat(),
        "overdue_gates": overdue_readiness_gates(coverage, registry_entries, as_of=as_of),
        "l3_candidates": list_l3_candidates(coverage),
    }


def with_stage_eval(
    data: MutableMapping[str, Any],
    language_id: str,
    *,
    realtime_voice: str | None = None,
    persona: str | None = None,
) -> dict[str, Any]:
    """Update eval status on a copy (for tests and future tooling)."""
    copy = json.loads(json.dumps(data))
    by_id = _by_language_id(copy)
    if language_id not in by_id:
        raise CoverageError("LANGUAGE_MISSING", f"no coverage for {language_id}")
    evals = by_id[language_id].get("stage_evals")
    if not isinstance(evals, dict):
        raise CoverageError("EVAL_INVALID", "stage_evals missing")
    if realtime_voice is not None:
        evals["realtime_voice"] = realtime_voice
    if persona is not None:
        evals["persona"] = persona
    return copy
