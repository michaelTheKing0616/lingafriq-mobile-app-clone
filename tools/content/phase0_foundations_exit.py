"""Phase 0 foundations exit gate (P5-076, CURRICULUM §9.2)."""

from __future__ import annotations

import json
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_engine.kits.loader import load_kit
from tools.content_engine.legacy.salvage import (
    MANIFEST_BASENAME,
    pipeline_input_dir,
)
from tools.content_engine.licences.check_register import g4_counsel_gate
from tools.content_engine.licences.register_schema import load_register_csv
from tools.content.placeholder_linter import MANIFEST_REL, repo_root
from tools.content_pipeline.language_registry import load_language_registry

CARD_ID = "P5-076"
GATE_ID = "G5"
LEDGER_REL = "assets/content/phase0_foundations_ledger.json"
REGISTER_REL = "tools/content_engine/licences/register.csv"
KIT_DIR_REL = "tools/content_engine/kits"

_LICENCE_OK_STATUSES = frozenset({"requested", "received", "waived_not_needed"})

_STUDIO_MVP_PATHS: tuple[str, ...] = (
    "../lingafriq-admin/src/pages/CurriculumStudio/index.tsx",
    "../lingafriq-admin/src/pages/CurriculumStudio/routes.tsx",
    "../node-backend/src/routes/studio.routes.ts",
    "../node-backend/src/middleware/studioAuth.ts",
)

_LINTER_PATHS: tuple[str, ...] = (
    "tools/content_pipeline/validate_content.py",
    "tools/content/placeholder_linter.py",
    "tools/content_engine/pipeline/stage_lint.py",
    "tools/content/label_rules.py",
)


class Phase0ExitError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _wave1_language_ids(registry: Mapping[str, Any]) -> list[str]:
    entries = registry.get("entries")
    if not isinstance(entries, list):
        raise Phase0ExitError("REGISTRY_INVALID", "language_registry entries missing")
    ids: list[str] = []
    for row in entries:
        if not isinstance(row, Mapping):
            continue
        if row.get("wave") == 1:
            lid = row.get("language_id")
            if isinstance(lid, str) and lid.strip():
                ids.append(lid.strip().lower())
    if len(ids) != 7:
        raise Phase0ExitError("REGISTRY_INVALID", f"expected 7 wave-1 languages, got {len(ids)}")
    return sorted(ids)


def load_ledger(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    path = base / LEDGER_REL
    if not path.is_file():
        raise Phase0ExitError("LEDGER_MISSING", f"missing {LEDGER_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise Phase0ExitError("LEDGER_INVALID", "ledger root must be an object")
    return data


def _check_ac1_counsel_and_licences(
    base: Path,
    ledger: Mapping[str, Any],
) -> dict[str, Any]:
    register_path = base / REGISTER_REL
    rows = load_register_csv(register_path)
    counsel = g4_counsel_gate(rows)
    counsel_signed = bool(ledger.get("counsel_register_signed")) and counsel.get("status") == "Pass"

    requests = ledger.get("licence_requests")
    if not isinstance(requests, list):
        raise Phase0ExitError("LEDGER_INVALID", "licence_requests must be a list")

    pending_required: list[str] = []
    for item in requests:
        if not isinstance(item, Mapping):
            continue
        if item.get("optional") is True:
            continue
        status = str(item.get("status", "")).strip()
        blocker = str(item.get("blocker", "")).strip()
        if status not in _LICENCE_OK_STATUSES:
            pending_required.append(blocker or "unknown")

    ac1_passed = counsel_signed and not pending_required
    failure_codes: list[str] = []
    if not counsel_signed:
        failure_codes.append(str(ledger.get("counsel_blocker") or counsel.get("blocker") or "EXT-03"))
    failure_codes.extend(pending_required)

    return {
        "counsel_gate": counsel,
        "counsel_register_signed": counsel_signed,
        "licences_pending_blockers": pending_required,
        "ac1_passed": ac1_passed,
        "failure_codes": failure_codes,
    }


def _check_ac2_reviewer_panels(ledger: Mapping[str, Any], language_ids: Sequence[str]) -> dict[str, Any]:
    panels = ledger.get("reviewer_panels")
    if not isinstance(panels, list):
        raise Phase0ExitError("LEDGER_INVALID", "reviewer_panels must be a list")

    by_lang: dict[str, int] = {}
    for row in panels:
        if not isinstance(row, Mapping):
            continue
        lid = str(row.get("language_id", "")).strip().lower()
        if not lid:
            continue
        try:
            by_lang[lid] = int(row.get("contracted_linguists") or 0)
        except (TypeError, ValueError):
            by_lang[lid] = 0

    shortfalls: list[str] = []
    for lid in language_ids:
        target = 2
        for row in panels:
            if isinstance(row, Mapping) and str(row.get("language_id", "")).strip().lower() == lid:
                try:
                    target = int(row.get("target") or 2)
                except (TypeError, ValueError):
                    target = 2
                break
        if by_lang.get(lid, 0) < target:
            shortfalls.append(lid)

    return {
        "shortfall_languages": shortfalls,
        "ac2_passed": not shortfalls,
    }


def _check_ac3_foundations_artifacts(base: Path, language_ids: Sequence[str]) -> dict[str, Any]:
    kit_dir = base / KIT_DIR_REL
    kits_ok: list[str] = []
    kits_missing: list[str] = []
    for lid in language_ids:
        kit_path = kit_dir / lid / "kit.yaml"
        if not kit_path.is_file():
            kits_missing.append(lid)
            continue
        try:
            load_kit(lid, kit_dir)
            kits_ok.append(lid)
        except Exception:
            kits_missing.append(lid)

    linters_missing = [rel for rel in _LINTER_PATHS if not (base / rel).is_file()]
    studio_missing = [rel for rel in _STUDIO_MVP_PATHS if not (base / rel).is_file()]

    quarantine_path = base / MANIFEST_REL
    quarantine_ok = False
    publishable_lessons: int | None = None
    if quarantine_path.is_file():
        payload = json.loads(quarantine_path.read_text(encoding="utf-8"))
        if isinstance(payload, Mapping):
            publishable_lessons = int(payload.get("publishable_lessons", -1))
            quarantine_ok = publishable_lessons == 0

    salvage_ok = (pipeline_input_dir(base) / MANIFEST_BASENAME).is_file()

    ac3_passed = (
        not kits_missing
        and not linters_missing
        and not studio_missing
        and quarantine_ok
        and salvage_ok
    )

    return {
        "language_kits_valid": kits_ok,
        "language_kits_missing": kits_missing,
        "linters_missing": linters_missing,
        "studio_mvp_missing": studio_missing,
        "legacy_quarantine_ok": quarantine_ok,
        "publishable_lessons": publishable_lessons,
        "legacy_salvage_manifest_ok": salvage_ok,
        "ac3_passed": ac3_passed,
    }


def verify_phase0_foundations_exit(
    *,
    root: Path | None = None,
    as_of: date | None = None,
) -> dict[str, Any]:
    """Return a measured foundations exit report; gate_passed is false while EXT blockers remain."""
    base = repo_root(root)
    registry = load_language_registry(base / "assets/content/language_registry.json")
    language_ids = _wave1_language_ids(registry)
    ledger = load_ledger(base)

    ac1 = _check_ac1_counsel_and_licences(base, ledger)
    ac2 = _check_ac2_reviewer_panels(ledger, language_ids)
    ac3 = _check_ac3_foundations_artifacts(base, language_ids)

    gate_passed = ac1["ac1_passed"] and ac2["ac2_passed"] and ac3["ac3_passed"]
    failure_code: str | None = None
    if not gate_passed:
        if not ac1["ac1_passed"]:
            failure_code = "PHASE0_LICENCE_OR_COUNSEL"
        elif not ac2["ac2_passed"]:
            failure_code = "PHASE0_REVIEWER_PANELS"
        else:
            failure_code = "PHASE0_ARTIFACTS"

    measured_on = as_of or datetime.now(UTC).date()

    return {
        "card_id": CARD_ID,
        "gate": GATE_ID,
        "measurement_status": "measured_checklist",
        "measured_on": measured_on.isoformat(),
        "wave_1_languages": list(language_ids),
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
        raise Phase0ExitError("RESULT_INVALID", "result.card_id must be P5-076")
    rows = store.setdefault("phase0_foundations_verifications", [])
    if not isinstance(rows, list):
        raise Phase0ExitError("STORE_INVALID", "phase0_foundations_verifications must be a list")
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
