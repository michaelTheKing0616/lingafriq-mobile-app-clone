"""Stage 1 dialect policy ADR artefact (P4-115, ELEVATION §6.4.1)."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Mapping

from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS

CARD_ID = "P4-115"

_TAG_RE = re.compile(r"^[a-z0-9_-]{2,64}$")

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DECISION_PATH = _REPO_ROOT / "assets/content/dialect_policy_decision.json"


class DialectPolicyError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def decision_path() -> Path:
    return _DECISION_PATH


def load_dialect_policy_decision(path: Path | None = None) -> dict[str, Any]:
    p = path or _DECISION_PATH
    if not p.is_file():
        raise DialectPolicyError("DECISION_MISSING", f"dialect policy decision not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise DialectPolicyError("DECISION_INVALID", "decision root must be an object")
    return data


def _validate_variant(row: Mapping[str, Any], *, language_id: str) -> None:
    tag = row.get("dialect_tag")
    if not isinstance(tag, str) or not _TAG_RE.match(tag):
        raise DialectPolicyError("VARIANT_TAG_INVALID", f"{language_id} dialect_tag invalid")
    if tag == "standard":
        raise DialectPolicyError("VARIANT_TAG_RESERVED", f"{language_id} must not use reserved tag standard")
    if row.get("must_mark_in_content") is not True:
        raise DialectPolicyError("VARIANT_UNMARKED", f"{language_id}/{tag} must set must_mark_in_content true")


def validate_dialect_policy_decision(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise DialectPolicyError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    hook = data.get("dialect_preference_hook")
    if not isinstance(hook, dict):
        raise DialectPolicyError("HOOK_MISSING", "dialect_preference_hook required")
    if not hook.get("mapping_owner") or not hook.get("review_date"):
        raise DialectPolicyError("HOOK_INCOMPLETE", "mapping_owner and review_date required on hook")
    stage = data.get("stage_1")
    if not isinstance(stage, list) or not stage:
        raise DialectPolicyError("STAGE1_MISSING", "stage_1 list required")
    seen: set[str] = set()
    for entry in stage:
        if not isinstance(entry, dict):
            raise DialectPolicyError("STAGE1_INVALID", "stage_1 entry must be an object")
        lang_id = entry.get("language_id")
        if not isinstance(lang_id, str) or lang_id not in WAVE_1_LANGUAGE_IDS:
            raise DialectPolicyError("LANGUAGE_INVALID", f"unknown or non–Stage-1 language_id {lang_id!r}")
        if lang_id in seen:
            raise DialectPolicyError("DUPLICATE_LANGUAGE", f"duplicate language_id {lang_id}")
        seen.add(lang_id)
        standard = entry.get("standard_taught")
        if not isinstance(standard, str) or not standard.strip():
            raise DialectPolicyError("STANDARD_MISSING", f"{lang_id} standard_taught required")
        if entry.get("standard_dialect_tag") != "standard":
            raise DialectPolicyError("STANDARD_TAG", f"{lang_id} standard_dialect_tag must be standard")
        variants = entry.get("regional_variants")
        if not isinstance(variants, list) or not variants:
            raise DialectPolicyError("VARIANTS_MISSING", f"{lang_id} regional_variants required")
        for var in variants:
            if not isinstance(var, dict):
                raise DialectPolicyError("VARIANT_INVALID", f"{lang_id} variant must be an object")
            _validate_variant(var, language_id=lang_id)
    if seen != WAVE_1_LANGUAGE_IDS:
        missing = WAVE_1_LANGUAGE_IDS - seen
        extra = seen - WAVE_1_LANGUAGE_IDS
        raise DialectPolicyError(
            "STAGE1_INCOMPLETE",
            f"Stage 1 must cover {sorted(WAVE_1_LANGUAGE_IDS)}; missing={sorted(missing)} extra={sorted(extra)}",
        )


def stage_1_by_language(data: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    validate_dialect_policy_decision(data)
    out: dict[str, Mapping[str, Any]] = {}
    for entry in data["stage_1"]:
        out[entry["language_id"]] = entry
    return out
