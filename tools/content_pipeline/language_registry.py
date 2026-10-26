"""Language registry: waves, scripts, readiness and consent gates (P4-112, ELEVATION §6.4)."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Mapping, MutableMapping

from tools.content_pipeline.readiness import READINESS_LEVELS
from tools.content_pipeline.wave_roster_decision import (
    WAVE_1_LANGUAGE_IDS,
    WaveRosterError,
    load_wave_roster_decision,
    validate_wave_roster_decision,
    wave_language_ids,
)

CARD_ID = "P4-112"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_REGISTRY_PATH = _REPO_ROOT / "assets/content/language_registry.json"
_SCHEMA_PATH = _REPO_ROOT / "schemas/v2/language_registry.schema.json"

_MULTI_SCRIPT_WAVE_3: dict[str, tuple[str, ...]] = {
    "ff": ("Latn", "Adlm"),
    "bm": ("Latn", "Nkoo"),
    "tzm": ("Tfng", "Latn"),
}

_PLANNING_TARGETS: dict[str, str | int] = {
    "wave_1": 7,
    "wave_2_cumulative": "~21",
    "wave_3_cumulative": "~46",
    "wave_4_cumulative": "95+",
    "note": "Planning targets from ELEVATION §6.4; not shipped language counts.",
    "kind": "planning_target",
}


class LanguageRegistryError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def registry_path() -> Path:
    return _REGISTRY_PATH


def load_language_registry(path: Path | None = None) -> dict[str, Any]:
    p = path or _REGISTRY_PATH
    if not p.is_file():
        raise LanguageRegistryError("REGISTRY_MISSING", f"language registry not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise LanguageRegistryError("REGISTRY_INVALID", "registry root must be an object")
    return data


def _entries(data: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    raw = data.get("entries")
    if not isinstance(raw, list) or not raw:
        raise LanguageRegistryError("ENTRIES_MISSING", "entries must be a non-empty array")
    out: list[Mapping[str, Any]] = []
    for row in raw:
        if not isinstance(row, dict):
            raise LanguageRegistryError("ENTRY_INVALID", "each entry must be an object")
        out.append(row)
    return out


def _require_str(row: Mapping[str, Any], key: str, code: str) -> str:
    val = row.get(key)
    if not isinstance(val, str) or not val.strip():
        raise LanguageRegistryError(code, f"{key} required on registry entry")
    return val


def validate_language_registry(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise LanguageRegistryError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    targets = data.get("planning_targets")
    if not isinstance(targets, dict):
        raise LanguageRegistryError("TARGETS_MISSING", "planning_targets object required")
    if targets.get("kind") != "planning_target":
        raise LanguageRegistryError("TARGET_KIND", "planning_targets.kind must be planning_target")
    if targets.get("wave_1") != 7:
        raise LanguageRegistryError("TARGET_WAVE1", "planning_targets.wave_1 must be 7")

    roster = load_wave_roster_decision()
    validate_wave_roster_decision(roster)

    entries = _entries(data)
    seen_entry: set[str] = set()
    wave1_ids: set[str] = set()
    wave2_ids: set[str] = set()
    wave3_lang_ids: set[str] = set()

    for row in entries:
        entry_id = _require_str(row, "entry_id", "ENTRY_ID_MISSING")
        if entry_id in seen_entry:
            raise LanguageRegistryError("DUPLICATE_ENTRY", f"duplicate entry_id {entry_id}")
        seen_entry.add(entry_id)

        language_id = _require_str(row, "language_id", "LANGUAGE_ID_MISSING")
        wave = row.get("wave")
        if not isinstance(wave, int) or wave not in (1, 2, 3, 4):
            raise LanguageRegistryError("WAVE_INVALID", f"{entry_id} wave must be 1–4")

        level = row.get("readiness_level")
        if level is not None and level not in READINESS_LEVELS:
            raise LanguageRegistryError("READINESS_INVALID", f"{entry_id} invalid readiness_level")

        script = row.get("script")
        if not isinstance(script, str) or not script.strip():
            raise LanguageRegistryError("SCRIPT_MISSING", f"{entry_id} script required")

        if wave == 1:
            if language_id not in WAVE_1_LANGUAGE_IDS:
                raise LanguageRegistryError("WAVE1_ID", f"{language_id} not in Wave 1 roster")
            wave1_ids.add(language_id)
        elif wave == 2:
            wave2_ids.add(language_id)
        elif wave == 3:
            wave3_lang_ids.add(language_id)

        consent_req = row.get("community_consent_required")
        if consent_req is not None and not isinstance(consent_req, bool):
            raise LanguageRegistryError("CONSENT_FLAG_INVALID", f"{entry_id} consent flag must be boolean")

    if wave1_ids != WAVE_1_LANGUAGE_IDS:
        missing = WAVE_1_LANGUAGE_IDS - wave1_ids
        extra = wave1_ids - WAVE_1_LANGUAGE_IDS
        raise LanguageRegistryError(
            "WAVE1_INCOMPLETE",
            f"Wave 1 must cover {sorted(WAVE_1_LANGUAGE_IDS)}; missing={sorted(missing)} extra={sorted(extra)}",
        )

    expected_w2 = set(wave_language_ids(roster, 2))
    if wave2_ids != expected_w2:
        raise LanguageRegistryError("WAVE2_MISMATCH", "Wave 2 language_ids must match P4-111 roster")

    expected_w3 = set(wave_language_ids(roster, 3))
    if wave3_lang_ids != expected_w3:
        raise LanguageRegistryError("WAVE3_MISMATCH", "Wave 3 language_ids must match P4-111 roster")

    for lang_id, scripts in _MULTI_SCRIPT_WAVE_3.items():
        found = {row["script"] for row in entries if row.get("language_id") == lang_id}
        if found != set(scripts):
            raise LanguageRegistryError(
                "MULTI_SCRIPT",
                f"{lang_id} must have script entries {scripts}, got {sorted(found)}",
            )
        if len([row for row in entries if row.get("language_id") == lang_id]) != len(scripts):
            raise LanguageRegistryError("MULTI_SCRIPT_COUNT", f"{lang_id} script entry count wrong")

    arabic = roster["egyptian_arabic_moroccan_darija"]
    for lid in (arabic["egyptian_arabic_id"], arabic["moroccan_darija_id"]):
        w4_rows = [r for r in entries if r.get("language_id") == lid and r.get("wave") == 4]
        if len(w4_rows) != 1:
            raise LanguageRegistryError("WAVE4_ARABIC", f"Wave 4 must include one entry for {lid}")


def planning_target_totals() -> dict[str, str | int]:
    """ELEVATION §6.4 planning targets — never treat as shipped counts."""
    return dict(_PLANNING_TARGETS)


def registry_entry_counts(data: Mapping[str, Any]) -> dict[str, int]:
    """Actual registry row counts per wave (for ops dashboards, not planning promises)."""
    counts = {1: 0, 2: 0, 3: 0, 4: 0}
    for row in _entries(data):
        wave = row.get("wave")
        if isinstance(wave, int) and wave in counts:
            counts[wave] += 1
    return counts


def set_readiness(
    data: MutableMapping[str, Any],
    entry_id: str,
    level: str,
) -> None:
    if level not in READINESS_LEVELS:
        raise LanguageRegistryError("READINESS_INVALID", f"unsupported level {level}")
    raw = data.get("entries")
    if not isinstance(raw, list):
        raise LanguageRegistryError("ENTRIES_MISSING", "entries must be an array")
    for row in raw:
        if isinstance(row, dict) and row.get("entry_id") == entry_id:
            row["readiness_level"] = level
            return
    raise LanguageRegistryError("ENTRY_NOT_FOUND", f"unknown entry_id {entry_id}")


def assert_kit_creation_allowed(
    entry: Mapping[str, Any],
    *,
    consent_recorded: bool,
    benefit_sharing_terms: str | None,
) -> None:
    if entry.get("community_consent_required"):
        if not consent_recorded:
            raise LanguageRegistryError(
                "CONSENT_MISSING",
                "community consent must be recorded before kit creation",
            )
        if not isinstance(benefit_sharing_terms, str) or not benefit_sharing_terms.strip():
            raise LanguageRegistryError(
                "CONSENT_MISSING",
                "benefit-sharing terms must be recorded before kit creation",
            )


def assert_wave2_l0_allowed(
    entry: Mapping[str, Any],
    wave1_readiness: Mapping[str, str],
    *,
    target_level: str = "L0",
) -> None:
    """Refuse starting Wave 2 L0 until every Stage-1 language has reached L1."""
    if entry.get("wave") != 2 or target_level != "L0":
        return
    for lang_id in sorted(WAVE_1_LANGUAGE_IDS):
        level = wave1_readiness.get(lang_id)
        if level not in ("L1", "L2", "L3"):
            raise LanguageRegistryError(
                "WAVE_GATE_NOT_MET",
                f"Wave 2 L0 blocked until Wave 1 language {lang_id} reaches L1; got {level!r}",
            )


def try_wave_roster() -> dict[str, Any]:
    try:
        return load_wave_roster_decision()
    except WaveRosterError as exc:
        raise LanguageRegistryError(exc.code, str(exc)) from exc


def with_updated_readiness(data: Mapping[str, Any], entry_id: str, level: str) -> dict[str, Any]:
    copy = deepcopy(dict(data))
    set_readiness(copy, entry_id, level)
    return copy
