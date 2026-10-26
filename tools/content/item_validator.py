"""CURRICULUM §4 item schema validation and publish gates (P5-008)."""

from __future__ import annotations

import hashlib
import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Mapping

from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "item.schema.json"

_LABELS = frozenset({"beta", "expert", "native"})
_AUDIO_KINDS = frozenset({"human", "tts"})
_CONTENT_KEYS = frozenset(
    {
        "type",
        "stimulus",
        "answer_spec",
        "distractors",
        "skill_tags",
        "irt",
        "claims",
        "confidence",
        "risk_tags",
        "label",
    }
)


class SchemaError(Exception):
    """P5 item schema or publish gate failure."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_item_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def item_validator() -> Draft202012Validator:
    schema = load_item_schema()
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def _require_mapping(value: object, code: str, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise SchemaError(code, f"{label} must be a mapping")
    return value


def _check_claims_publishable(claims: object) -> None:
    if not isinstance(claims, list) or len(claims) < 1:
        raise SchemaError("CLAIM_INVALID", "claims must be a non-empty list to publish")
    for index, claim in enumerate(claims):
        row = _require_mapping(claim, "CLAIM_INVALID", f"claims[{index}]")
        for field in ("text", "source_id", "locator"):
            val = row.get(field)
            if not isinstance(val, str) or not val.strip():
                raise SchemaError(
                    "CLAIM_INVALID",
                    f"claims[{index}].{field} is required to publish",
                )


def _check_provenance_publishable(provenance: object) -> None:
    prov = _require_mapping(provenance, "PROVENANCE_MISSING", "provenance")
    sources = prov.get("sources")
    if not isinstance(sources, list) or len(sources) < 1:
        raise SchemaError("PROVENANCE_MISSING", "provenance.sources must have at least one entry to publish")


def _check_label_and_audio(obj: Mapping[str, Any]) -> None:
    label = obj.get("label")
    if label not in _LABELS:
        raise SchemaError("LABEL_INVALID", "label must be beta, expert, or native")
    audio = obj.get("audio")
    if not isinstance(audio, list):
        raise SchemaError("AUDIO_KIND_INVALID", "audio must be a list")
    for index, entry in enumerate(audio):
        row = _require_mapping(entry, "AUDIO_KIND_INVALID", f"audio[{index}]")
        kind = row.get("kind")
        if kind not in _AUDIO_KINDS:
            raise SchemaError("AUDIO_KIND_INVALID", f"audio[{index}].kind must be tts or human")


def validate_item_schema(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    """Validate structure against schemas/v2/item.schema.json."""
    if not isinstance(obj, Mapping):
        raise SchemaError("ITEM_INVALID", "item must be a mapping")
    _check_label_and_audio(obj)
    v = validator or item_validator()
    errors = sorted(v.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise SchemaError("ITEM_INVALID", errors[0].message)


def assert_publishable(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    """Schema validation plus gates that block publish (AC3)."""
    _check_provenance_publishable(obj.get("provenance"))
    _check_claims_publishable(obj.get("claims"))
    validate_item_schema(obj, validator=validator)


def _fingerprint(payload: Mapping[str, Any], keys: frozenset[str]) -> str:
    subset = {key: payload.get(key) for key in sorted(keys)}
    encoded = json.dumps(subset, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def content_fingerprint(item: Mapping[str, Any]) -> str:
    return _fingerprint(item, _CONTENT_KEYS)


def audio_fingerprint(item: Mapping[str, Any]) -> str:
    audio = item.get("audio")
    encoded = json.dumps(audio, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def bump_item_version(
    previous: Mapping[str, Any] | None,
    updated: Mapping[str, Any],
) -> int:
    """Return the next monotonic version when content or audio changes (AC4)."""
    base = int(updated.get("version", 1))
    if previous is None:
        return max(1, base)
    prev_version = int(previous.get("version", 1))
    if content_fingerprint(previous) != content_fingerprint(updated):
        return prev_version + 1
    if audio_fingerprint(previous) != audio_fingerprint(updated):
        return prev_version + 1
    return prev_version


def apply_version_bump(
    previous: Mapping[str, Any] | None,
    updated: Mapping[str, Any],
) -> dict[str, Any]:
    """Copy `updated` with `version` set from `bump_item_version`."""
    row = deepcopy(dict(updated))
    row["version"] = bump_item_version(previous, updated)
    return row
