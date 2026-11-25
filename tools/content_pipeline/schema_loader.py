"""Load and validate the shared content envelope schema (P4-100)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

_REPO_ROOT = Path(__file__).resolve().parents[2]
_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "content" / "common.schema.json"

SYNTHETIC_VOICE_TAG = "Synthetic voice"

_CLAIM_KINDS = frozenset({"tone", "cultural", "linguistic", "factual"})
_LABELS = frozenset({"beta", "expert_reviewed", "native_verified"})
_AUDIO_KINDS = frozenset({"human", "tts_synthetic"})
_RISK_TAGS = frozenset(
    {
        "tone",
        "idiom",
        "proverb",
        "culture_history_religion",
        "honorific",
        "grammar_explanation",
        "child_audience",
        "anglicised_pidgin",
    }
)


class CommonSchemaError(Exception):
    """Envelope validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_common_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def common_validator() -> Draft202012Validator:
    schema = load_common_schema()
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise CommonSchemaError(code, f"{label} must be a mapping")
    return value


def _check_provenance(provenance: object) -> None:
    prov = _require_mapping(provenance, "PROVENANCE_MISSING", "provenance")
    sources = prov.get("sources")
    if not isinstance(sources, list) or len(sources) < 1:
        raise CommonSchemaError("PROVENANCE_MISSING", "provenance.sources must have at least one entry")
    author = prov.get("author")
    created_at = prov.get("created_at")
    if not isinstance(author, str) or not author.strip():
        raise CommonSchemaError("PROVENANCE_MISSING", "provenance.author is required")
    if not isinstance(created_at, str) or not created_at.strip():
        raise CommonSchemaError("PROVENANCE_MISSING", "provenance.created_at is required")
    for index, entry in enumerate(sources):
        row = _require_mapping(entry, "PROVENANCE_MISSING", f"provenance.sources[{index}]")
        for field in ("name", "licence", "uri_or_citation", "retrieved_at"):
            val = row.get(field)
            if not isinstance(val, str) or not val.strip():
                raise CommonSchemaError(
                    "PROVENANCE_MISSING",
                    f"provenance.sources[{index}].{field} is required",
                )


def _check_ai_assisted(provenance: Mapping[str, Any]) -> None:
    if "ai_assisted" not in provenance:
        raise CommonSchemaError("AI_FLAG_MISSING", "provenance.ai_assisted is required")
    assisted = provenance.get("ai_assisted")
    if not isinstance(assisted, bool):
        raise CommonSchemaError("AI_FLAG_MISSING", "provenance.ai_assisted must be a boolean")
    if assisted:
        model_id = provenance.get("model_id")
        prompt_id = provenance.get("prompt_id")
        if not isinstance(model_id, str) or not model_id.strip():
            raise CommonSchemaError("AI_FLAG_MISSING", "model_id is required when ai_assisted is true")
        if not isinstance(prompt_id, str) or not prompt_id.strip():
            raise CommonSchemaError("AI_FLAG_MISSING", "prompt_id is required when ai_assisted is true")


def _check_claims(claims: object, confidence: object, risk_tags: object) -> None:
    if not isinstance(claims, list):
        raise CommonSchemaError("CLAIM_INVALID", "claims must be a list")
    for index, claim in enumerate(claims):
        row = _require_mapping(claim, "CLAIM_INVALID", f"claims[{index}]")
        kind = row.get("kind")
        if kind not in _CLAIM_KINDS:
            raise CommonSchemaError("CLAIM_INVALID", f"claims[{index}].kind is invalid")
        source_ref = row.get("source_ref")
        if not isinstance(source_ref, str) or not source_ref.strip():
            raise CommonSchemaError("CLAIM_INVALID", f"claims[{index}].source_ref is required")
    if not isinstance(confidence, (int, float)) or confidence < 0 or confidence > 1:
        raise CommonSchemaError("CLAIM_INVALID", "confidence must be a number in [0, 1]")
    if not isinstance(risk_tags, list):
        raise CommonSchemaError("CLAIM_INVALID", "risk_tags must be a list")
    for index, tag in enumerate(risk_tags):
        if tag not in _RISK_TAGS:
            raise CommonSchemaError("CLAIM_INVALID", f"risk_tags[{index}] is not in the allowlist")


def _check_label(label: object) -> str:
    if label is None or label not in _LABELS:
        raise CommonSchemaError("LABEL_MISSING", "label must be beta, expert_reviewed, or native_verified")
    return str(label)


def _check_audio(audio: object) -> None:
    if not isinstance(audio, list):
        raise CommonSchemaError("AUDIO_KIND_INVALID", "audio must be a list")
    for index, entry in enumerate(audio):
        row = _require_mapping(entry, "AUDIO_KIND_INVALID", f"audio[{index}]")
        kind = row.get("kind")
        if kind not in _AUDIO_KINDS:
            raise CommonSchemaError("AUDIO_KIND_INVALID", f"audio[{index}].kind is invalid")
        if kind == "tts_synthetic":
            tag = row.get("synthetic_voice_tag")
            if tag != SYNTHETIC_VOICE_TAG:
                raise CommonSchemaError(
                    "AUDIO_KIND_INVALID",
                    f'audio[{index}] tts_synthetic requires synthetic_voice_tag "{SYNTHETIC_VOICE_TAG}"',
                )


def _check_native_verified_review(obj: Mapping[str, Any], label: str) -> None:
    if label != "native_verified":
        return
    review = obj.get("review")
    if not isinstance(review, Mapping):
        raise CommonSchemaError(
            "NATIVE_VERIFIED_REQUIRES_TWO_NATIVES",
            "review.reviewers required for native_verified label",
        )
    reviewers = review.get("reviewers")
    if not isinstance(reviewers, list):
        raise CommonSchemaError(
            "NATIVE_VERIFIED_REQUIRES_TWO_NATIVES",
            "review.reviewers must be a list",
        )
    native_ids: set[str] = set()
    linguist_ok = False
    for row in reviewers:
        if not isinstance(row, Mapping):
            continue
        if row.get("approved") is not True:
            continue
        role = row.get("role")
        reviewer_id = row.get("reviewer_id")
        if not isinstance(reviewer_id, str) or not reviewer_id.strip():
            continue
        if role == "native":
            native_ids.add(reviewer_id.strip())
        elif role == "linguist":
            linguist_ok = True
    if len(native_ids) < 2 or not linguist_ok:
        raise CommonSchemaError(
            "NATIVE_VERIFIED_REQUIRES_TWO_NATIVES",
            "native_verified requires two distinct approved native reviewers and one linguist",
        )


def validate_content_envelope(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    """Validate a content object against the common envelope schema and semantic gates."""
    if not isinstance(obj, Mapping):
        raise CommonSchemaError("ENVELOPE_INVALID", "content object must be a mapping")

    label = _check_label(obj.get("label"))
    provenance = obj.get("provenance")
    _check_provenance(provenance)
    _check_ai_assisted(_require_mapping(provenance, "PROVENANCE_MISSING", "provenance"))
    _check_claims(obj.get("claims"), obj.get("confidence"), obj.get("risk_tags"))
    _check_audio(obj.get("audio"))

    v = validator or common_validator()
    errors = sorted(v.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise CommonSchemaError("ENVELOPE_INVALID", errors[0].message)

    _check_native_verified_review(obj, label)
