"""Phase 1 Stage-1 A1 Beta exit gate (P5-077, CURRICULUM §9.2)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content.culture_linter import lint_all_culture_files
from tools.content.lexicon_select import MAX_LEXEMES, MIN_LEXEMES, STAGE1_LANGS
from tools.content.pattern_linter import lint_pattern_library, patterns_file_path
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-077"
GATE_ID = "G5"
LEDGER_REL = "assets/content/phase1_a1_beta_ledger.json"
LEXICON_REL = "assets/data/lexicon/a1"
CANDO_MAP_REL = "assets/data/cando_map.json"
PATTERN_LEVEL = "A1"
EXPERT_LABEL = "expert_reviewed"
_MIN_A1_UNITS_PER_LANGUAGE = 6
_TTS_PASS_STATUSES = frozenset({"passed", "pass", "ok"})


class Phase1ExitError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise Phase1ExitError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise Phase1ExitError("LEDGER_INVALID", "ledger root must be an object")
    return data


def _load_lexicon_manifest(base: Path, lang: str) -> dict[str, Any]:
    path = base / LEXICON_REL / f"{lang}.json"
    if not path.is_file():
        raise Phase1ExitError("LEXICON_MISSING", f"missing A1 lexicon for {lang}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise Phase1ExitError("LEXICON_INVALID", f"lexicon manifest for {lang} must be an object")
    return payload


def _check_ac1_content_anchored(base: Path, language_ids: Sequence[str]) -> dict[str, Any]:
    lexicon_by_lang: dict[str, dict[str, Any]] = {}
    lexicon_shortfalls: list[str] = []
    unanchored_lexemes: dict[str, int] = {}

    for lang in language_ids:
        manifest = _load_lexicon_manifest(base, lang)
        lexemes = manifest.get("lexemes")
        if not isinstance(lexemes, list):
            raise Phase1ExitError("LEXICON_INVALID", f"lexemes must be a list for {lang}")
        count = len(lexemes)
        if count < MIN_LEXEMES or count > MAX_LEXEMES:
            lexicon_shortfalls.append(lang)
        unanchored = sum(
            1
            for row in lexemes
            if isinstance(row, Mapping)
            and not (isinstance(row.get("lexicon_anchor"), str) and row.get("lexicon_anchor", "").strip())
        )
        if unanchored:
            unanchored_lexemes[lang] = unanchored
        lexicon_by_lang[lang] = {"count": count, "unanchored": unanchored}

    cando_path = base / CANDO_MAP_REL
    if not cando_path.is_file():
        raise Phase1ExitError("CANDO_MAP_MISSING", f"missing {CANDO_MAP_REL}")
    cando = json.loads(cando_path.read_text(encoding="utf-8"))
    units = cando.get("units")
    if not isinstance(units, Mapping):
        raise Phase1ExitError("CANDO_MAP_INVALID", "cando_map.units must be a mapping")

    a1_units_by_lang: dict[str, int] = {lang: 0 for lang in language_ids}
    for row in units.values():
        if not isinstance(row, Mapping):
            continue
        if row.get("cefr_band") != PATTERN_LEVEL:
            continue
        kit_lang = str(row.get("kit_lang", "")).strip().lower()
        if kit_lang in a1_units_by_lang:
            a1_units_by_lang[kit_lang] += 1

    unit_shortfalls = [
        lang for lang in language_ids if a1_units_by_lang.get(lang, 0) < _MIN_A1_UNITS_PER_LANGUAGE
    ]

    pattern_findings: list[str] = []
    pattern_gaps: list[str] = []
    for lang in language_ids:
        path = patterns_file_path(lang, base)
        if not path.is_file():
            pattern_gaps.append(lang)
            continue
        document = json.loads(path.read_text(encoding="utf-8"))
        findings, missing = lint_pattern_library(document, root=base)
        if missing:
            pattern_gaps.extend(f"{lang}:{m.pattern_id}" for m in missing)
        for finding in findings:
            pattern_findings.append(f"{lang}:{finding.rule_id}:{finding.pattern_id}")
        patterns = document.get("patterns")
        if isinstance(patterns, list):
            for entry in patterns:
                if not isinstance(entry, Mapping):
                    continue
                label = entry.get("label") or entry.get("quality_label")
                if label != EXPERT_LABEL:
                    pattern_findings.append(f"{lang}:label:{entry.get('id', '<unknown>')}")

    culture_findings = lint_all_culture_files(base)
    culture_issues = [f"{f.rule_id}:{f.card_id}" for f in culture_findings]

    ac1_passed = (
        not lexicon_shortfalls
        and not unanchored_lexemes
        and not unit_shortfalls
        and not pattern_gaps
        and not pattern_findings
        and not culture_issues
    )

    return {
        "lexicon_by_lang": lexicon_by_lang,
        "lexicon_count_shortfalls": lexicon_shortfalls,
        "lexicon_unanchored": unanchored_lexemes,
        "a1_units_by_lang": a1_units_by_lang,
        "a1_unit_shortfalls": unit_shortfalls,
        "pattern_gaps": pattern_gaps,
        "pattern_findings": pattern_findings,
        "culture_findings": culture_issues,
        "ac1_passed": ac1_passed,
    }


def _check_ac2_tts_gates(ledger: Mapping[str, Any], language_ids: Sequence[str]) -> dict[str, Any]:
    rows = ledger.get("tts_listen_gates")
    if not isinstance(rows, list):
        raise Phase1ExitError("LEDGER_INVALID", "tts_listen_gates must be a list")

    pending: list[str] = []
    by_lang: dict[str, str] = {}
    for lang in language_ids:
        status = "missing"
        for row in rows:
            if not isinstance(row, Mapping):
                continue
            if str(row.get("language_id", "")).strip().lower() == lang:
                status = str(row.get("status", "not_run")).strip().lower()
                break
        by_lang[lang] = status
        if status not in _TTS_PASS_STATUSES:
            pending.append(lang)

    return {
        "tts_status_by_lang": by_lang,
        "tts_pending_languages": pending,
        "ac2_passed": not pending,
    }


def _check_ac3_labels_and_blind(ledger: Mapping[str, Any], language_ids: Sequence[str]) -> dict[str, Any]:
    beta_rows = ledger.get("beta_labels_live")
    if not isinstance(beta_rows, list):
        raise Phase1ExitError("LEDGER_INVALID", "beta_labels_live must be a list")

    beta_off: list[str] = []
    for lang in language_ids:
        live = False
        for row in beta_rows:
            if not isinstance(row, Mapping):
                continue
            if str(row.get("language_id", "")).strip().lower() == lang:
                live = row.get("live") is True
                break
        if not live:
            beta_off.append(lang)

    blind = ledger.get("blind_sampling")
    if not isinstance(blind, Mapping):
        raise Phase1ExitError("LEDGER_INVALID", "blind_sampling must be a mapping")
    weekly_active = blind.get("weekly_active") is True

    ac3_passed = not beta_off and weekly_active
    return {
        "beta_not_live": beta_off,
        "blind_sampling_weekly_active": weekly_active,
        "blind_sampling_last_week": blind.get("last_draw_week"),
        "ac3_passed": ac3_passed,
    }


def verify_phase1_a1_beta_exit(
    *,
    root: Path | None = None,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Return a measured Phase 1 exit report; gate_passed stays false until ledger + anchors close."""
    base = repo_root(root)
    language_ids = list(STAGE1_LANGS)
    ledger = load_ledger(base)

    ac1 = _check_ac1_content_anchored(base, language_ids)
    ac2 = _check_ac2_tts_gates(ledger, language_ids)
    ac3 = _check_ac3_labels_and_blind(ledger, language_ids)

    gate_passed = ac1["ac1_passed"] and ac2["ac2_passed"] and ac3["ac3_passed"]
    failure_code: str | None = None
    if not gate_passed:
        if not ac1["ac1_passed"]:
            failure_code = "PHASE1_CONTENT_NOT_ANCHORED"
        elif not ac2["ac2_passed"]:
            failure_code = "PHASE1_TTS_GATES"
        else:
            failure_code = "PHASE1_BETA_OR_BLIND"

    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measurement_status": "measured_checklist",
        "measured_on": measured_on.isoformat(),
        "stage_1_languages": language_ids,
        "ac1": ac1,
        "ac2": ac2,
        "ac3": ac3,
        "gate_passed": gate_passed,
        "failure_code": failure_code if not gate_passed else None,
    }


def append_verification_ledger_row(
    store: MutableMapping[str, Any],
    result: Mapping[str, Any],
) -> dict[str, Any]:
    if result.get("card_id") != CARD_ID:
        raise Phase1ExitError("RESULT_INVALID", "result.card_id must be P5-077")
    rows = store.setdefault("phase1_a1_beta_verifications", [])
    if not isinstance(rows, list):
        raise Phase1ExitError("STORE_INVALID", "phase1_a1_beta_verifications must be a list")
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
