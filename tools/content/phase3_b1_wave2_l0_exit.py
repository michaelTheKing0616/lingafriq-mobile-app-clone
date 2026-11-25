"""Phase 3 Stage-1 B1 + Wave 2 L0 exit gate (P5-079, CURRICULUM §9.2)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.lexicon_select import assert_b1_cumulative_gate, STAGE1_LANGS
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-079"
GATE_ID = "G7"
LEDGER_REL = "assets/content/phase3_b1_wave2_l0_ledger.json"
WAVE_ROSTER_REL = "assets/content/wave_roster_decision.json"
LEXICON_B1_REL = "assets/data/lexicon/b1"
CANDO_MAP_REL = "assets/data/cando_map.json"
KIT_REL_TEMPLATE = "tools/content_engine/kits/{lang}/kit.yaml"
PATTERN_LEVEL = "B1"
_MIN_B1_UNITS_PER_LANGUAGE = 6
_WAVE2_ROSTER_SIZE = 14


class Phase3ExitError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise Phase3ExitError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise Phase3ExitError("LEDGER_INVALID", "ledger root must be an object")
    return data


def wave_2_language_ids(root: Path | None = None) -> list[str]:
    base = repo_root(root)
    path = base / WAVE_ROSTER_REL
    if not path.is_file():
        raise Phase3ExitError("WAVE_ROSTER_MISSING", f"missing {WAVE_ROSTER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data.get("wave_2")
    if not isinstance(rows, list):
        raise Phase3ExitError("WAVE_ROSTER_INVALID", "wave_2 must be a list")
    ids: list[str] = []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        lang = str(row.get("language_id", "")).strip().lower()
        if lang:
            ids.append(lang)
    if len(ids) != _WAVE2_ROSTER_SIZE:
        raise Phase3ExitError(
            "WAVE2_ROSTER_SIZE",
            f"expected {_WAVE2_ROSTER_SIZE} Wave 2 languages, got {len(ids)}",
        )
    return ids


def _b1_units_in_cando(base: Path, language_ids: Sequence[str]) -> dict[str, int]:
    cando_path = base / CANDO_MAP_REL
    if not cando_path.is_file():
        raise Phase3ExitError("CANDO_MAP_MISSING", f"missing {CANDO_MAP_REL}")
    cando = json.loads(cando_path.read_text(encoding="utf-8"))
    units = cando.get("units")
    if not isinstance(units, Mapping):
        raise Phase3ExitError("CANDO_MAP_INVALID", "cando_map.units must be a mapping")

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


def _b1_lexicon_gate(base: Path, language_ids: Sequence[str]) -> dict[str, Any]:
    missing_manifest: list[str] = []
    count_shortfalls: list[str] = []
    gate_errors: list[str] = []
    by_lang: dict[str, dict[str, Any]] = {}

    for lang in language_ids:
        path = base / LEXICON_B1_REL / f"{lang}.json"
        if not path.is_file():
            missing_manifest.append(lang)
            by_lang[lang] = {"manifest": False, "count": None}
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, Mapping):
            raise Phase3ExitError("LEXICON_INVALID", f"B1 lexicon for {lang} must be an object")
        lexemes = payload.get("lexemes")
        count = len(lexemes) if isinstance(lexemes, list) else 0
        by_lang[lang] = {"manifest": True, "count": count}
        try:
            assert_b1_cumulative_gate(count, lang)
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


def _check_ac1_b1_published(
    base: Path,
    ledger: Mapping[str, Any],
    language_ids: Sequence[str],
) -> dict[str, Any]:
    cando_counts = _b1_units_in_cando(base, language_ids)
    unit_shortfalls = [
        lang for lang in language_ids if cando_counts.get(lang, 0) < _MIN_B1_UNITS_PER_LANGUAGE
    ]
    lexicon = _b1_lexicon_gate(base, language_ids)

    rows = ledger.get("b1_units_published")
    if not isinstance(rows, list):
        raise Phase3ExitError("LEDGER_INVALID", "b1_units_published must be a list")

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
        "b1_units_in_cando_by_lang": cando_counts,
        "b1_unit_shortfalls": unit_shortfalls,
        "b1_lexicon": lexicon,
        "b1_unpublished_languages": unpublished,
        "ac1_passed": ac1_passed,
    }


def _kit_exists(base: Path, language_id: str) -> bool:
    rel = KIT_REL_TEMPLATE.format(lang=language_id)
    return (base / rel).is_file()


def _check_ac2_wave2_l0_taste(
    base: Path,
    ledger: Mapping[str, Any],
    wave2_ids: Sequence[str],
) -> dict[str, Any]:
    rows = ledger.get("wave2_l0_taste")
    if not isinstance(rows, list):
        raise Phase3ExitError("LEDGER_INVALID", "wave2_l0_taste must be a list")

    incomplete: list[str] = []
    missing_kit: list[str] = []
    missing_lexicon_source: list[str] = []
    not_expert: list[str] = []

    for lang in wave2_ids:
        row_match: Mapping[str, Any] | None = None
        for row in rows:
            if not isinstance(row, Mapping):
                continue
            if str(row.get("language_id", "")).strip().lower() == lang:
                row_match = row
                break
        if row_match is None:
            incomplete.append(lang)
            continue

        kit_ok = row_match.get("kit_exists") is True and _kit_exists(base, lang)
        if not kit_ok:
            missing_kit.append(lang)

        lex_src = row_match.get("lexicon_source_registered")
        if lex_src is not True:
            missing_lexicon_source.append(lang)

        expert = row_match.get("l0_taste_expert_reviewed")
        if expert is not True:
            not_expert.append(lang)

        if not (kit_ok and lex_src is True and expert is True):
            incomplete.append(lang)

    ac2_passed = not incomplete
    return {
        "wave2_roster_size": len(wave2_ids),
        "wave2_incomplete": incomplete,
        "wave2_missing_kit": missing_kit,
        "wave2_missing_lexicon_source": missing_lexicon_source,
        "wave2_not_expert_reviewed": not_expert,
        "ac2_passed": ac2_passed,
    }


def verify_phase3_b1_wave2_l0_exit(
    *,
    root: Path | None = None,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Return a measured Phase 3 exit report; gate_passed stays false until ledger + content close."""
    base = repo_root(root)
    stage1 = list(STAGE1_LANGS)
    wave2 = wave_2_language_ids(base)
    ledger = load_ledger(base)

    ac1 = _check_ac1_b1_published(base, ledger, stage1)
    ac2 = _check_ac2_wave2_l0_taste(base, ledger, wave2)

    gate_passed = ac1["ac1_passed"] and ac2["ac2_passed"]
    failure_code: str | None = None
    if not gate_passed:
        if not ac1["ac1_passed"]:
            failure_code = "PHASE3_B1_NOT_PUBLISHED"
        else:
            failure_code = "PHASE3_WAVE2_L0_INCOMPLETE"

    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measurement_status": "measured_checklist",
        "measured_on": measured_on.isoformat(),
        "stage_1_languages": stage1,
        "wave_2_languages": wave2,
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
        raise Phase3ExitError("RESULT_INVALID", "result.card_id must be P5-079")
    rows = store.setdefault("phase3_b1_wave2_l0_verifications", [])
    if not isinstance(rows, list):
        raise Phase3ExitError("STORE_INVALID", "phase3_b1_wave2_l0_verifications must be a list")
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
