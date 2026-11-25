"""Exercise item schema with matching rules and IRT params (P4-103)."""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any, Mapping

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.schema_loader import (  # noqa: E402
    CommonSchemaError,
    validate_content_envelope,
)

_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "content" / "item.schema.json"
_SCHEMA_DIR = _SCHEMA_PATH.parent

_ITEM_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.item\.[a-z0-9._-]+$")
_SKILL_TAG_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]{1,80}$")
_MATCH_RULES = frozenset({"strict", "tone_lenient", "diacritic_insensitive"})
_MC_TYPES = frozenset({"multiple_choice", "listen_and_choose", "tone_identification", "picture_matching"})
_FORBIDDEN_BETA_PACKS = frozenset(
    {"checkpoint", "placement_test", "credential", "children_mode"}
)


class ItemSchemaError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_item_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def _item_validator() -> Draft202012Validator:
    from referencing import Registry, Resource

    common = json.loads((_SCHEMA_DIR / "common.schema.json").read_text(encoding="utf-8"))
    item = load_item_schema()
    registry = Registry().with_resources(
        [
            (common["$id"], Resource.from_contents(common)),
            ("common.schema.json", Resource.from_contents(common)),
            (item["$id"], Resource.from_contents(item)),
            ("item.schema.json", Resource.from_contents(item)),
        ]
    )
    return Draft202012Validator(item, registry=registry)


def _nfc_text(value: object, code: str, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ItemSchemaError(code, f"{label} is required")
    if value != unicodedata.normalize("NFC", value):
        raise ItemSchemaError(code, f"{label} must be NFC-normalised")
    return value


def _check_answer_spec(answer_spec: object) -> None:
    if not isinstance(answer_spec, Mapping):
        raise ItemSchemaError("ITEM_INVALID", "answer_spec must be a mapping")
    _nfc_text(answer_spec.get("correct"), "ITEM_INVALID", "answer_spec.correct")
    rule = answer_spec.get("diacritic_matching")
    if rule not in _MATCH_RULES:
        raise ItemSchemaError(
            "MATCH_RULE_MISSING",
            "answer_spec.diacritic_matching must be strict, tone_lenient, or diacritic_insensitive",
        )
    variants = answer_spec.get("accepted_variants")
    if not isinstance(variants, list):
        raise ItemSchemaError("ITEM_INVALID", "answer_spec.accepted_variants must be a list")
    for index, variant in enumerate(variants):
        if not isinstance(variant, str) or not variant:
            raise ItemSchemaError("ITEM_INVALID", f"answer_spec.accepted_variants[{index}] is invalid")


def _check_distractors(item_type: str, distractors: object) -> None:
    if item_type not in _MC_TYPES:
        return
    if not isinstance(distractors, list) or len(distractors) < 1:
        raise ItemSchemaError("ITEM_INVALID", "distractors must be a non-empty list for choice items")
    for index, row in enumerate(distractors):
        if not isinstance(row, Mapping):
            raise ItemSchemaError("DISTRACTOR_RATIONALE_MISSING", f"distractors[{index}] must be a mapping")
        _nfc_text(row.get("text"), "DISTRACTOR_RATIONALE_MISSING", f"distractors[{index}].text")
        rationale = row.get("rationale")
        if not isinstance(rationale, str) or not rationale.strip():
            raise ItemSchemaError(
                "DISTRACTOR_RATIONALE_MISSING",
                f"distractors[{index}].rationale is required",
            )


def _check_irt(irt: object) -> None:
    if not isinstance(irt, Mapping):
        raise ItemSchemaError("ITEM_INVALID", "irt must be a mapping")
    status = irt.get("irt_status")
    if status == "uncalibrated":
        if "a" in irt or "b" in irt:
            raise ItemSchemaError("ITEM_INVALID", "uncalibrated items must not carry IRT a or b")
        return
    if status != "calibrated":
        raise ItemSchemaError("ITEM_INVALID", "irt.irt_status must be calibrated or uncalibrated")
    a = irt.get("a")
    b = irt.get("b")
    if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
        raise ItemSchemaError("ITEM_INVALID", "calibrated items require numeric irt.a and irt.b")
    if a <= 0:
        raise ItemSchemaError("ITEM_INVALID", "irt.a must be greater than 0")


def _check_skill_tags(tags: object) -> None:
    if not isinstance(tags, list) or len(tags) < 1:
        raise ItemSchemaError("ITEM_INVALID", "skill_tags must be a non-empty list")
    for index, tag in enumerate(tags):
        if not isinstance(tag, str) or not _SKILL_TAG_RE.match(tag):
            raise ItemSchemaError("ITEM_INVALID", f"skill_tags[{index}] must be ASCII graph node id")


def validate_item(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    if not isinstance(obj, Mapping):
        raise ItemSchemaError("ITEM_INVALID", "item must be a mapping")
    item_id = obj.get("id")
    if not isinstance(item_id, str) or not _ITEM_ID_RE.match(item_id):
        raise ItemSchemaError("ITEM_INVALID", "id must match <lang>.item.<slug>")
    item_type = obj.get("type")
    if not isinstance(item_type, str):
        raise ItemSchemaError("ITEM_INVALID", "type is required")
    stimulus = obj.get("stimulus")
    if not isinstance(stimulus, Mapping):
        raise ItemSchemaError("ITEM_INVALID", "stimulus must be a mapping")
    refs = stimulus.get("refs")
    if not isinstance(refs, list) or len(refs) < 1:
        raise ItemSchemaError("ITEM_INVALID", "stimulus.refs must be non-empty")
    if "text" in stimulus:
        _nfc_text(stimulus.get("text"), "ITEM_INVALID", "stimulus.text")
    _check_answer_spec(obj.get("answer_spec"))
    _check_distractors(item_type, obj.get("distractors"))
    _check_irt(obj.get("irt"))
    _check_skill_tags(obj.get("skill_tags"))
    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise ItemSchemaError(exc.code, str(exc)) from exc
    v = validator or _item_validator()
    errors = sorted(v.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise ItemSchemaError("ITEM_INVALID", errors[0].message)


def assert_item_allowed_in_pack(item: Mapping[str, Any], pack_context: str) -> None:
    if pack_context not in _FORBIDDEN_BETA_PACKS:
        return
    if item.get("label") == "beta":
        raise ItemSchemaError(
            "BETA_FORBIDDEN_CONTEXT",
            f"beta items cannot be used in {pack_context} packs (D1)",
        )


def _sample_item(**overrides: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": "yo.item.tone.aar",
        "type": "multiple_choice",
        "stimulus": {
            "refs": ["yo.lex.ọkọ.vehicle", "audio/yo/9f2c1a4b5e6d7c8a.ogg"],
            "text": "àárọ̀",
        },
        "answer_spec": {
            "correct": "àárọ̀",
            "accepted_variants": ["aaro", "àárọ"],
            "diacritic_matching": "tone_lenient",
        },
        "distractors": [
            {
                "text": "ọkọ̀",
                "rationale": "That word means vehicle or husband, not morning.",
            }
        ],
        "skill_tags": ["yo.lex.aaro.morning"],
        "irt": {"irt_status": "calibrated", "a": 1.2, "b": -0.4},
        "label": "expert_reviewed",
        "provenance": {
            "author": "content-studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "Yoruba item bank draft",
                    "licence": "CC BY 4.0",
                    "uri_or_citation": "curriculum/items/yo/tone-aar",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        "claims": [{"kind": "linguistic", "source_ref": "lexicon:yo:aaro"}],
        "confidence": 0.9,
        "risk_tags": [],
        "audio": [],
    }
    body.update(overrides)
    return body


def test_item_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(load_item_schema())


def test_complete_item_passes() -> None:
    validate_item(_sample_item())


def test_match_rule_missing() -> None:
    broken = _sample_item()
    broken["answer_spec"] = {
        "correct": "àárọ̀",
        "accepted_variants": [],
        "diacritic_matching": "loose",
    }
    with pytest.raises(ItemSchemaError) as exc:
        validate_item(broken)
    assert exc.value.code == "MATCH_RULE_MISSING"


def test_distractor_rationale_missing() -> None:
    broken = _sample_item()
    broken["distractors"] = [{"text": "ọkọ̀"}]
    with pytest.raises(ItemSchemaError) as exc:
        validate_item(broken)
    assert exc.value.code == "DISTRACTOR_RATIONALE_MISSING"


def test_uncalibrated_irt_without_defaults() -> None:
    row = _sample_item(irt={"irt_status": "uncalibrated"})
    validate_item(row)
    assert "a" not in row["irt"]


def test_uncalibrated_rejects_silent_irt_params() -> None:
    broken = _sample_item(irt={"irt_status": "uncalibrated", "a": 1.0, "b": 0.0})
    with pytest.raises(ItemSchemaError) as exc:
        validate_item(broken)
    assert exc.value.code == "ITEM_INVALID"


def test_beta_forbidden_in_checkpoint_pack() -> None:
    row = _sample_item(label="beta")
    validate_item(row)
    with pytest.raises(ItemSchemaError) as exc:
        assert_item_allowed_in_pack(row, "checkpoint")
    assert exc.value.code == "BETA_FORBIDDEN_CONTEXT"


def test_beta_allowed_in_practice_pack() -> None:
    row = _sample_item(label="beta")
    assert_item_allowed_in_pack(row, "lesson_practice") is None
