"""Two-native plus linguist validation stage (P4-122, D1, ELEVATION §6.4.1)."""

from __future__ import annotations

import json
from copy import deepcopy
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from jsonschema import Draft202012Validator

from tools.content_engine.pipeline.tone_agreement import has_tone_or_teaching_mark

CARD_ID = "P4-122"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_REVIEW_RECORD_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "review_record.schema.json"

BETA_EXCLUDED_CONTEXTS: frozenset[str] = frozenset(
    {"checkpoint", "placement_test", "credential", "children_mode"}
)

_SENSITIVE_CLAIM_KINDS = frozenset({"tone", "cultural"})
_PERSONA_KEYS = frozenset({"persona_id", "persona_fact", "persona_facts"})


class NativeValidationError(Exception):
    """Native validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_review_record_schema() -> dict[str, Any]:
    return json.loads(_REVIEW_RECORD_SCHEMA_PATH.read_text(encoding="utf-8"))


def review_record_validator() -> Draft202012Validator:
    schema = load_review_record_schema()
    return Draft202012Validator(schema)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise NativeValidationError(code, f"{label} must be a mapping")
    return value


def _reviewer_rows(review: object) -> list[Mapping[str, Any]]:
    if review is None:
        return []
    block = _require_mapping(review, "REVIEW_INVALID", "review")
    reviewers = block.get("reviewers")
    if reviewers is None:
        return []
    if not isinstance(reviewers, Sequence) or isinstance(reviewers, (str, bytes)):
        raise NativeValidationError("REVIEW_INVALID", "review.reviewers must be a sequence")
    rows: list[Mapping[str, Any]] = []
    for index, row in enumerate(reviewers):
        rows.append(_require_mapping(row, "REVIEW_INVALID", f"review.reviewers[{index}]"))
    return rows


def distinct_approved_native_ids(reviewers: Sequence[Mapping[str, Any]]) -> set[str]:
    """Count distinct natives with approved=True (AC5: duplicate reviewer_id counts once)."""
    native_ids: set[str] = set()
    for row in reviewers:
        if row.get("approved") is not True or row.get("role") != "native":
            continue
        rid = row.get("reviewer_id")
        if isinstance(rid, str) and rid.strip():
            native_ids.add(rid.strip())
    return native_ids


def linguist_approved(reviewers: Sequence[Mapping[str, Any]]) -> bool:
    for row in reviewers:
        if row.get("approved") is not True or row.get("role") != "linguist":
            continue
        rid = row.get("reviewer_id")
        if isinstance(rid, str) and rid.strip():
            return True
    return False


def missing_native_verified_approvals(reviewers: Sequence[Mapping[str, Any]]) -> list[str]:
    missing: list[str] = []
    natives = distinct_approved_native_ids(reviewers)
    if len(natives) < 1:
        missing.append("native_reviewer_1")
    if len(natives) < 2:
        missing.append("native_reviewer_2")
    if not linguist_approved(reviewers):
        missing.append("linguist_adjudication")
    return missing


def _has_ai_only_provenance(reviewers: Sequence[Mapping[str, Any]]) -> bool:
    if not reviewers:
        return True
    for row in reviewers:
        if row.get("approved") is not True:
            continue
        prov = row.get("provenance")
        if prov is None or prov == "human":
            return False
    return True


def requires_human_validation(content: Mapping[str, Any]) -> bool:
    """True when tone, diacritics, culture, persona, or audio need human sign-off (AC2)."""
    claims = content.get("claims")
    if isinstance(claims, Sequence) and not isinstance(claims, (str, bytes)):
        for claim in claims:
            if not isinstance(claim, Mapping):
                continue
            kind = claim.get("kind")
            if kind in _SENSITIVE_CLAIM_KINDS:
                return True
    risk_tags = content.get("risk_tags")
    if isinstance(risk_tags, list) and len(risk_tags) > 0:
        return True
    audio = content.get("audio")
    if isinstance(audio, list) and len(audio) > 0:
        return True
    for key in _PERSONA_KEYS:
        if key in content and content.get(key):
            return True
    for field in ("learner_facing_text", "text", "body", "title"):
        raw = content.get(field)
        if isinstance(raw, str) and has_tone_or_teaching_mark(raw):
            return True
    stimulus = content.get("stimulus")
    if isinstance(stimulus, Mapping):
        text = stimulus.get("text")
        if isinstance(text, str) and has_tone_or_teaching_mark(text):
            return True
    return False


def assert_not_ai_only_approval(content: Mapping[str, Any], review: object) -> None:
    """Reject when sensitive content has only AI provenance on review records (AC2)."""
    if not requires_human_validation(content):
        return
    provenance = content.get("provenance")
    ai_assisted = (
        isinstance(provenance, Mapping) and provenance.get("ai_assisted") is True
    )
    reviewers = _reviewer_rows(review)
    human_signed = not _has_ai_only_provenance(reviewers)
    if ai_assisted and (not reviewers or not human_signed):
        raise NativeValidationError(
            "AI_ONLY_FORBIDDEN",
            "tone, cultural, persona, or audio content cannot be approved with AI-only provenance",
        )
    for row in reviewers:
        if row.get("approved") is True and row.get("provenance") == "ai":
            raise NativeValidationError(
                "AI_ONLY_FORBIDDEN",
                "approved review rows must carry human provenance for gated content",
            )


def validate_review_record(record: Mapping[str, Any]) -> None:
    errors = sorted(review_record_validator().iter_errors(record), key=lambda e: list(e.path))
    if errors:
        raise NativeValidationError("REVIEW_RECORD_INVALID", errors[0].message)


def request_promotion_to_native_verified(content: Mapping[str, Any]) -> dict[str, Any]:
    """Promote label to native_verified when two natives and a linguist approved (AC1)."""
    if not isinstance(content, Mapping):
        raise NativeValidationError("CONTENT_INVALID", "content must be a mapping")
    reviewers = _reviewer_rows(content.get("review"))
    missing = missing_native_verified_approvals(reviewers)
    if missing:
        return {
            "card_id": CARD_ID,
            "promoted": False,
            "code": "PROMOTION_REJECTED",
            "missing_approvals": missing,
            "label": content.get("label"),
        }
    assert_not_ai_only_approval(content, content.get("review"))
    updated = deepcopy(dict(content))
    updated["label"] = "native_verified"
    return {
        "card_id": CARD_ID,
        "promoted": True,
        "code": "PROMOTED",
        "label": "native_verified",
        "content": updated,
        "native_reviewer_ids": sorted(distinct_approved_native_ids(reviewers)),
    }


def beta_delivery_policy(content: Mapping[str, Any]) -> dict[str, Any]:
    """Interim Beta publish envelope: label beta and D1 exclusion contexts (AC4)."""
    label = content.get("label")
    if label != "beta":
        raise NativeValidationError(
            "BETA_LABEL_REQUIRED",
            "interim publish before native review must keep label beta",
        )
    return {
        "card_id": CARD_ID,
        "label": "beta",
        "display_label": "Beta",
        "excluded_from": sorted(BETA_EXCLUDED_CONTEXTS),
    }


def natives_disagree(native_a: Mapping[str, Any], native_b: Mapping[str, Any]) -> bool:
    if native_a.get("approved") != native_b.get("approved"):
        return True
    note_a = native_a.get("variant_note")
    note_b = native_b.get("variant_note")
    if isinstance(note_a, str) and isinstance(note_b, str) and note_a.strip() != note_b.strip():
        return True
    return False


def adjudicate_native_disagreement(
    content: Mapping[str, Any],
    review_record: MutableMapping[str, Any],
    *,
    linguist_id: str,
    decision: str,
    summary: str,
) -> dict[str, Any]:
    """Store dialect disagreement; never mutate learner-facing content (AC3)."""
    before = deepcopy(dict(content))
    reviewers = review_record.get("reviewers")
    if not isinstance(reviewers, list) or len(reviewers) < 2:
        raise NativeValidationError("REVIEW_INVALID", "two native reviewers required for adjudication")
    natives = [r for r in reviewers if isinstance(r, Mapping) and r.get("role") == "native"]
    if len(natives) < 2:
        raise NativeValidationError("REVIEW_INVALID", "two native reviewers required for adjudication")
    if not natives_disagree(natives[0], natives[1]):
        raise NativeValidationError("NO_DISAGREEMENT", "native reviewers already agree")
    if decision not in ("uphold_a", "uphold_b", "both_valid_dialect"):
        raise NativeValidationError("ADJUDICATION_INVALID", "decision must be uphold_a, uphold_b, or both_valid_dialect")
    if not isinstance(linguist_id, str) or not linguist_id.strip():
        raise NativeValidationError("ADJUDICATION_INVALID", "linguist_id is required")
    recorded_at = datetime.now(UTC).isoformat()
    native_ids = []
    for row in natives[:2]:
        rid = row.get("reviewer_id")
        if isinstance(rid, str) and rid.strip():
            native_ids.append(rid.strip())
    dialect_note = {
        "native_ids": native_ids,
        "note": summary.strip(),
        "recorded_at": recorded_at,
    }
    notes = review_record.get("dialect_notes")
    if notes is None:
        review_record["dialect_notes"] = [dialect_note]
    elif isinstance(notes, list):
        notes.append(dialect_note)
    else:
        raise NativeValidationError("REVIEW_RECORD_INVALID", "dialect_notes must be a list")
    review_record["adjudication"] = {
        "linguist_id": linguist_id.strip(),
        "decision": decision,
        "recorded_at": recorded_at,
        "summary": summary.strip(),
    }
    review_record["status"] = "disagreement_recorded"
    validate_review_record(review_record)
    after = deepcopy(dict(content))
    if before != after:
        raise NativeValidationError("CONTENT_MUTATED", "content must not be edited during adjudication")
    return {
        "card_id": CARD_ID,
        "content_unchanged": True,
        "review_record": dict(review_record),
    }


def run_native_validation_stage(
    content: Mapping[str, Any],
    *,
    action: str = "promote",
) -> dict[str, Any]:
    """Stage contract: promotion, beta policy, or AI-only gate."""
    try:
        if action == "promote":
            return request_promotion_to_native_verified(content)
        if action == "beta_policy":
            return beta_delivery_policy(content)
        if action == "ai_only_gate":
            assert_not_ai_only_approval(content, content.get("review"))
            return {"card_id": CARD_ID, "status": "passed", "code": "HUMAN_REVIEW_OK"}
        raise NativeValidationError("ACTION_INVALID", f"unknown action {action}")
    except NativeValidationError as exc:
        return {
            "card_id": CARD_ID,
            "status": "blocked",
            "code": exc.code,
            "message": str(exc),
        }
