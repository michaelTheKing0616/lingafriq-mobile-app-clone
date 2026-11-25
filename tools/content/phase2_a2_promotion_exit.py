"""Phase 2 Stage-1 A2 + promotion exit gate (P5-078, CURRICULUM §9.2)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.lexicon_select import assert_a2_cumulative_gate, STAGE1_LANGS
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-078"
GATE_ID = "G6"
LEDGER_REL = "assets/content/phase2_a2_promotion_ledger.json"
LEXICON_A2_REL = "assets/data/lexicon/a2"
CANDO_MAP_REL = "assets/data/cando_map.json"
PATTERN_LEVEL = "A2"
_MIN_A2_UNITS_PER_LANGUAGE = 6
_EXT13_BLOCKER = "EXT-13"


class Phase2ExitError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise Phase2ExitError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise Phase2ExitError("LEDGER_INVALID", "ledger root must be an object")
    return data


def _a2_units_in_cando(base: Path, language_ids: Sequence[str]) -> dict[str, int]:
    cando_path = base / CANDO_MAP_REL
    if not cando_path.is_file():
        raise Phase2ExitError("CANDO_MAP_MISSING", f"missing {CANDO_MAP_REL}")
    cando = json.loads(cando_path.read_text(encoding="utf-8"))
    units = cando.get("units")
    if not isinstance(units, Mapping):
        raise Phase2ExitError("CANDO_MAP_INVALID", "cando_map.units must be a mapping")

    counts: dict[str, int] = {lang: 0 for lang in language_ids}
    for row in units.values():
        if not isinstance(row, Mapping):
            continue
        if row.get("cefr_band") != PATTERN_LEVEL:
            continue
        kit_lang = str(row.get("kit_lang", "")).strip().lower()
        if kit_lang in counts:
            counts[kit_lang] += 1
    return counts


def _a2_lexicon_gate(base: Path, language_ids: Sequence[str]) -> dict[str, Any]:
    missing_manifest: list[str] = []
    count_shortfalls: list[str] = []
    gate_errors: list[str] = []
    by_lang: dict[str, dict[str, Any]] = {}

    for lang in language_ids:
        path = base / LEXICON_A2_REL / f"{lang}.json"
        if not path.is_file():
            missing_manifest.append(lang)
            by_lang[lang] = {"manifest": False, "count": None}
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, Mapping):
            raise Phase2ExitError("LEXICON_INVALID", f"A2 lexicon for {lang} must be an object")
        lexemes = payload.get("lexemes")
        count = len(lexemes) if isinstance(lexemes, list) else 0
        by_lang[lang] = {"manifest": True, "count": count}
        try:
            assert_a2_cumulative_gate(count, lang)
        except Exception as exc:  # noqa: BLE001 — surface gate code as string
            gate_errors.append(f"{lang}:{exc}")
            count_shortfalls.append(lang)

    return {
        "by_lang": by_lang,
        "missing_manifest": missing_manifest,
        "count_shortfalls": count_shortfalls,
        "gate_errors": gate_errors,
        "lexicon_ready": not missing_manifest and not count_shortfalls,
    }


def _check_ac1_a2_published(
    base: Path,
    ledger: Mapping[str, Any],
    language_ids: Sequence[str],
) -> dict[str, Any]:
    cando_counts = _a2_units_in_cando(base, language_ids)
    unit_shortfalls = [
        lang for lang in language_ids if cando_counts.get(lang, 0) < _MIN_A2_UNITS_PER_LANGUAGE
    ]
    lexicon = _a2_lexicon_gate(base, language_ids)

    rows = ledger.get("a2_units_published")
    if not isinstance(rows, list):
        raise Phase2ExitError("LEDGER_INVALID", "a2_units_published must be a list")

    unpublished: list[str] = []
    for lang in language_ids:
        published = False
        for row in rows:
            if not isinstance(row, Mapping):
                continue
            if str(row.get("language_id", "")).strip().lower() == lang:
                published = row.get("published") is True
                break
        if not published:
            unpublished.append(lang)

    ac1_passed = (
        not unit_shortfalls
        and lexicon["lexicon_ready"]
        and not unpublished
    )
    return {
        "a2_units_in_cando_by_lang": cando_counts,
        "a2_unit_shortfalls": unit_shortfalls,
        "a2_lexicon": lexicon,
        "a2_unpublished_languages": unpublished,
        "ac1_passed": ac1_passed,
    }


def _check_ac2_promotion_and_validators(
    ledger: Mapping[str, Any],
    language_ids: Sequence[str],
) -> dict[str, Any]:
    promo_rows = ledger.get("a1_high_exposure_expert_promotion")
    if not isinstance(promo_rows, list):
        raise Phase2ExitError("LEDGER_INVALID", "a1_high_exposure_expert_promotion must be a list")

    promo_incomplete: list[str] = []
    for lang in language_ids:
        complete = False
        for row in promo_rows:
            if not isinstance(row, Mapping):
                continue
            if str(row.get("language_id", "")).strip().lower() == lang:
                complete = row.get("complete") is True
                break
        if not complete:
            promo_incomplete.append(lang)

    native = ledger.get("native_validators")
    if not isinstance(native, Mapping):
        raise Phase2ExitError("LEDGER_INVALID", "native_validators must be a mapping")

    onboard = native.get("onboard") is True
    verification_started = native.get("a1_verification_started") is True
    ext13_blocker = str(native.get("blocker", "")).strip() == _EXT13_BLOCKER

    expert_promotion_passed = not promo_incomplete
    native_track_passed = onboard and verification_started
    ac2_passed = expert_promotion_passed and native_track_passed

    return {
        "a1_expert_promotion_incomplete": promo_incomplete,
        "native_validators_onboard": onboard,
        "a1_native_verification_started": verification_started,
        "ext13_gated": ext13_blocker and not onboard,
        "ac2_passed": ac2_passed,
    }


def verify_phase2_a2_promotion_exit(
    *,
    root: Path | None = None,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Return a measured Phase 2 exit report; gate_passed stays false until ledger + content close."""
    base = repo_root(root)
    language_ids = list(STAGE1_LANGS)
    ledger = load_ledger(base)

    ac1 = _check_ac1_a2_published(base, ledger, language_ids)
    ac2 = _check_ac2_promotion_and_validators(ledger, language_ids)

    gate_passed = ac1["ac1_passed"] and ac2["ac2_passed"]
    failure_code: str | None = None
    if not gate_passed:
        if not ac1["ac1_passed"]:
            failure_code = "PHASE2_A2_NOT_PUBLISHED"
        elif not ac2["ac2_passed"]:
            if ac2["a1_expert_promotion_incomplete"]:
                failure_code = "PHASE2_A1_EXPERT_PROMOTION"
            else:
                failure_code = "PHASE2_NATIVE_VALIDATORS_EXT13"

    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measurement_status": "measured_checklist",
        "measured_on": measured_on.isoformat(),
        "stage_1_languages": language_ids,
        "ac1": ac1,
        "ac2": ac2,
        "gate_passed": gate_passed,
        "failure_code": failure_code if not gate_passed else None,
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise Phase2ExitError("RESULT_INVALID", "result.card_id must be P5-078")
    rows = store.setdefault("phase2_a2_promotion_verifications", [])
    if not isinstance(rows, list):
        raise Phase2ExitError("STORE_INVALID", "phase2_a2_promotion_verifications must be a list")
    row = {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measured_on": result.get("measured_on"),
        "gate_passed": result.get("gate_passed"),
        "failure_code": result.get("failure_code"),
        "measurement_status": result.get("measurement_status"),
    }
    rows.append(row)
    return row
