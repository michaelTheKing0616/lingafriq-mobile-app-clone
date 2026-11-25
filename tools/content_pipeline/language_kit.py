"""Language kit generator for week 0–1 (P4-120, ELEVATION §6.4.1)."""

from __future__ import annotations

import json
from copy import deepcopy
from datetime import date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_engine.licences.register_schema import (
    LicenceRegisterError,
    load_register_csv,
    register_index,
    validate_row,
)
from tools.content_pipeline.language_registry import (
    assert_kit_creation_allowed,
    load_language_registry,
)

CARD_ID = "P4-120"
WEEK_TARGET_DAYS = 7

_REPO_ROOT = Path(__file__).resolve().parents[2]
_SCHEMA_PATH = _REPO_ROOT / "schemas/v2/language_kit.schema.json"
_REGISTER_CSV = _REPO_ROOT / "tools/content_engine/licences/register.csv"
_KITS_README = _REPO_ROOT / "assets/content/kits/README.md"

_TONAL_LANGUAGE_IDS = frozenset({"yo", "ig", "ha"})

_KIT_SECTIONS: tuple[str, ...] = (
    "orthography",
    "dialect_standard",
    "phone_inventory",
    "tone_system",
    "phoneme_viseme_table",
    "seed_lexicon",
    "reviewer_panel",
)


class LanguageKitError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def schema_path() -> Path:
    return _SCHEMA_PATH


def kits_readme_path() -> Path:
    return _KITS_README


def is_tonal_language(language_id: str) -> bool:
    return language_id.strip().lower() in _TONAL_LANGUAGE_IDS


def _parse_iso_date(value: str) -> date:
    try:
        return date.fromisoformat(value[:10])
    except ValueError as exc:
        raise LanguageKitError("DATE_INVALID", f"started_at must be ISO date: {value}") from exc


def _section_present(kit: Mapping[str, Any], section: str) -> bool:
    if section == "seed_lexicon":
        entries = kit.get("seed_lexicon")
        return isinstance(entries, list) and len(entries) > 0
    if section == "reviewer_panel":
        panel = kit.get("reviewer_panel")
        return isinstance(panel, list) and len(panel) >= 3 and panel_meets_requirements(panel)
    if section == "tone_system":
        if not kit.get("is_tonal"):
            return True
        tone = kit.get("tone_system")
        return isinstance(tone, Mapping) and tone.get("marking_convention_ref")
    if section == "dialect_standard":
        val = kit.get("dialect_standard")
        return isinstance(val, str) and val.strip()
    if section == "phone_inventory":
        phones = kit.get("phone_inventory")
        return isinstance(phones, list) and len(phones) > 0
    if section == "phoneme_viseme_table":
        table = kit.get("phoneme_viseme_table")
        return isinstance(table, list) and len(table) > 0
    if section == "orthography":
        orth = kit.get("orthography")
        return isinstance(orth, Mapping) and orth.get("keyboard_layout")
    return False


def compute_open_tasks(kit: Mapping[str, Any]) -> list[str]:
    missing: list[str] = []
    for section in _KIT_SECTIONS:
        if not _section_present(kit, section):
            missing.append(section)
    return missing


def create_kit(
    entry: Mapping[str, Any],
    *,
    started_at: str,
    consent_recorded: bool = False,
    benefit_sharing_terms: str | None = None,
) -> dict[str, Any]:
    """Create a week 0–1 kit skeleton; missing parts appear in open_tasks."""
    assert_kit_creation_allowed(
        entry,
        consent_recorded=consent_recorded,
        benefit_sharing_terms=benefit_sharing_terms,
    )
    language_id = entry.get("language_id")
    entry_id = entry.get("entry_id")
    if not isinstance(language_id, str) or not language_id.strip():
        raise LanguageKitError("LANGUAGE_ID_MISSING", "registry entry language_id required")
    if not isinstance(entry_id, str) or not entry_id.strip():
        raise LanguageKitError("ENTRY_ID_MISSING", "registry entry entry_id required")

    kit: dict[str, Any] = {
        "charter": "v2",
        "card_id": CARD_ID,
        "language_id": language_id,
        "entry_id": entry_id,
        "status": "open",
        "week_target_days": WEEK_TARGET_DAYS,
        "started_at": started_at[:10],
        "is_tonal": is_tonal_language(language_id),
        "orthography": None,
        "dialect_standard": None,
        "phone_inventory": None,
        "tone_system": None,
        "phoneme_viseme_table": None,
        "seed_lexicon": [],
        "reviewer_panel": [],
    }
    kit["open_tasks"] = compute_open_tasks(kit)
    return kit


def create_kit_for_language(
    language_id: str,
    *,
    started_at: str,
    consent_recorded: bool = True,
    benefit_sharing_terms: str | None = "standard benefit-sharing v1",
) -> dict[str, Any]:
    """Resolve a registry entry by language_id (first match) and create a kit."""
    registry = load_language_registry()
    matches = [
        e
        for e in registry.get("entries", [])
        if isinstance(e, dict) and e.get("language_id") == language_id
    ]
    if not matches:
        raise LanguageKitError("ENTRY_NOT_FOUND", f"no registry entry for {language_id}")
    entry = matches[0]
    if entry.get("community_consent_required"):
        consent_recorded = entry.get("consent_recorded", consent_recorded)
        benefit_sharing_terms = entry.get("benefit_sharing_terms") or benefit_sharing_terms
    return create_kit(
        entry,
        started_at=started_at,
        consent_recorded=bool(consent_recorded),
        benefit_sharing_terms=benefit_sharing_terms if isinstance(benefit_sharing_terms, str) else None,
    )


def _parse_use_flag(raw: str) -> bool:
    return raw.strip().lower() == "true"


def assert_source_licensed_for_seed(
    source_id: str,
    register_rows: Sequence[Mapping[str, str]],
) -> Mapping[str, str]:
    index = register_index(register_rows)
    row = index.get(source_id)
    if row is None:
        raise LanguageKitError("SOURCE_UNLICENSED", f"source_id not in licence register: {source_id}")
    if row.get("discovery_only", "").strip() == "true":
        raise LanguageKitError(
            "SOURCE_UNLICENSED",
            f"source {source_id!r} is discovery-only",
        )
    try:
        validate_row(row)
    except LicenceRegisterError as exc:
        raise LanguageKitError("SOURCE_UNLICENSED", str(exc)) from exc
    display = _parse_use_flag(row.get("display", "false"))
    evidence = _parse_use_flag(row.get("evidence", "false"))
    if not display and not evidence:
        raise LanguageKitError(
            "SOURCE_UNLICENSED",
            f"source {source_id!r} has neither display nor evidence use in register",
        )
    return row


def enrich_provenance_from_register(
    provenance: Mapping[str, Any],
    register_rows: Sequence[Mapping[str, str]],
) -> dict[str, Any]:
    sources = provenance.get("sources")
    if not isinstance(sources, list) or not sources:
        raise LanguageKitError("PROVENANCE_MISSING", "provenance.sources required")
    out_sources: list[dict[str, Any]] = []
    for index, entry in enumerate(sources):
        if not isinstance(entry, Mapping):
            raise LanguageKitError("PROVENANCE_MISSING", f"sources[{index}] must be an object")
        source_id = entry.get("source_id")
        if not isinstance(source_id, str) or not source_id.strip():
            raise LanguageKitError("PROVENANCE_MISSING", f"sources[{index}].source_id required")
        row = assert_source_licensed_for_seed(source_id, register_rows)
        licence = row.get("licence", "")
        if not isinstance(licence, str) or not licence.strip():
            raise LanguageKitError("SOURCE_UNLICENSED", f"register row {source_id} has no licence")
        cited = entry.get("licence")
        if cited is not None and isinstance(cited, str) and cited.strip() and cited != licence:
            raise LanguageKitError(
                "SOURCE_UNLICENSED",
                f"sources[{index}] licence does not match register for {source_id}",
            )
        merged = dict(entry)
        merged["licence"] = licence
        for field in ("name", "uri_or_citation", "retrieved_at"):
            val = merged.get(field)
            if not isinstance(val, str) or not val.strip():
                raise LanguageKitError("PROVENANCE_MISSING", f"sources[{index}].{field} required")
        out_sources.append(merged)
    author = provenance.get("author")
    created_at = provenance.get("created_at")
    if not isinstance(author, str) or not author.strip():
        raise LanguageKitError("PROVENANCE_MISSING", "provenance.author required")
    if not isinstance(created_at, str) or not created_at.strip():
        raise LanguageKitError("PROVENANCE_MISSING", "provenance.created_at required")
    return {
        "author": author,
        "created_at": created_at,
        "ai_assisted": bool(provenance.get("ai_assisted", False)),
        "sources": out_sources,
    }


def import_seed_lexicon_entry(
    kit: MutableMapping[str, Any],
    entry: Mapping[str, Any],
    *,
    register_rows: Sequence[Mapping[str, str]] | None = None,
) -> None:
    lemma = entry.get("lemma")
    if not isinstance(lemma, str) or not lemma.strip():
        raise LanguageKitError("SEED_INVALID", "lemma required")
    provenance = entry.get("provenance")
    if not isinstance(provenance, Mapping):
        raise LanguageKitError("PROVENANCE_MISSING", "provenance required")
    rows = register_rows if register_rows is not None else load_register_csv(_REGISTER_CSV)
    validated_prov = enrich_provenance_from_register(provenance, rows)
    row: dict[str, Any] = {"lemma": lemma, "provenance": validated_prov}
    gloss = entry.get("gloss")
    if isinstance(gloss, str) and gloss.strip():
        row["gloss"] = gloss
    seed = kit.get("seed_lexicon")
    if not isinstance(seed, list):
        raise LanguageKitError("KIT_INVALID", "seed_lexicon must be an array")
    seed.append(row)
    kit["open_tasks"] = compute_open_tasks(kit)


def panel_meets_requirements(panel: Sequence[Mapping[str, Any]]) -> bool:
    if len(panel) < 3:
        return False
    for reviewer in panel:
        if not isinstance(reviewer, Mapping):
            return False
        for flag in ("paid_native", "consent_signed", "licence_terms_signed"):
            if reviewer.get(flag) is not True:
                return False
        rid = reviewer.get("reviewer_id")
        if not isinstance(rid, str) or not rid.strip():
            return False
    return True


def try_mark_complete(kit: MutableMapping[str, Any]) -> None:
    """Set status complete only when all sections are present and reviewers qualify."""
    kit["open_tasks"] = compute_open_tasks(kit)
    if kit["open_tasks"]:
        kit["status"] = "open"
        return
    panel = kit.get("reviewer_panel")
    if not isinstance(panel, list) or not panel_meets_requirements(panel):
        kit["status"] = "open"
        return
    kit["status"] = "complete"


def evaluate_week_timeline(
    kit: Mapping[str, Any],
    *,
    as_of: str | None = None,
) -> dict[str, Any]:
    started = _parse_iso_date(str(kit.get("started_at", "")))
    ref = _parse_iso_date(as_of[:10]) if as_of else date.today()
    days = (ref - started).days
    if days < 0:
        raise LanguageKitError("DATE_INVALID", "as_of is before started_at")
    target = int(kit.get("week_target_days", WEEK_TARGET_DAYS))
    status = kit.get("status", "open")
    overdue = status != "complete" and days > target
    return {"days_elapsed": days, "week_target_days": target, "overdue": overdue}


def apply_timeline_fields(kit: MutableMapping[str, Any], *, as_of: str | None = None) -> None:
    fields = evaluate_week_timeline(kit, as_of=as_of)
    kit["days_elapsed"] = fields["days_elapsed"]
    kit["overdue"] = fields["overdue"]


def assert_ai_bootstrap_allowed(kit: Mapping[str, Any]) -> None:
    if kit.get("is_tonal") and not _section_present(kit, "tone_system"):
        raise LanguageKitError(
            "TONE_SYSTEM_MISSING",
            "tonal language kit cannot start AI bootstrap without tone_system",
        )
    if kit.get("status") != "complete":
        raise LanguageKitError("KIT_INCOMPLETE", "kit must be complete before AI bootstrap")
    if compute_open_tasks(kit):
        raise LanguageKitError("KIT_INCOMPLETE", "open_tasks must be empty before AI bootstrap")


def validate_language_kit(kit: Mapping[str, Any]) -> None:
    if kit.get("card_id") != CARD_ID:
        raise LanguageKitError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    if kit.get("charter") != "v2":
        raise LanguageKitError("CHARTER_MISMATCH", "charter must be v2")
    if kit.get("week_target_days") != WEEK_TARGET_DAYS:
        raise LanguageKitError("WEEK_TARGET", f"week_target_days must be {WEEK_TARGET_DAYS}")
    _parse_iso_date(str(kit.get("started_at", "")))
    lang = kit.get("language_id")
    if not isinstance(lang, str) or not lang.strip():
        raise LanguageKitError("LANGUAGE_ID_MISSING", "language_id required")
    if kit.get("is_tonal") != is_tonal_language(lang):
        raise LanguageKitError("TONAL_FLAG", "is_tonal does not match language_id")
    tasks = kit.get("open_tasks")
    if not isinstance(tasks, list):
        raise LanguageKitError("OPEN_TASKS_INVALID", "open_tasks must be a list")
    expected = compute_open_tasks(kit)
    if sorted(tasks) != sorted(expected):
        raise LanguageKitError(
            "OPEN_TASKS_STALE",
            f"open_tasks out of date; expected {expected}, got {tasks}",
        )
    status = kit.get("status")
    if status == "complete" and expected:
        raise LanguageKitError("KIT_INCOMPLETE", "complete kit cannot have open_tasks")
    if status == "complete" and not panel_meets_requirements(kit.get("reviewer_panel", [])):
        raise LanguageKitError("REVIEWER_PANEL", "complete kit requires ≥3 qualified reviewers")


def load_language_kit(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise LanguageKitError("KIT_MISSING", f"language kit not found: {path}")
    with path.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise LanguageKitError("KIT_INVALID", "kit root must be an object")
    return data


def with_updated_section(
    kit: Mapping[str, Any],
    section: str,
    value: Any,
) -> dict[str, Any]:
    copy = deepcopy(dict(kit))
    if section not in _KIT_SECTIONS and section not in (
        "orthography",
        "dialect_standard",
        "phone_inventory",
        "tone_system",
        "phoneme_viseme_table",
        "reviewer_panel",
    ):
        raise LanguageKitError("SECTION_UNKNOWN", f"unknown section {section}")
    copy[section] = value
    copy["open_tasks"] = compute_open_tasks(copy)
    if isinstance(copy, MutableMapping):
        try_mark_complete(copy)
    return copy
