"""Pattern, dialogue and unit schemas (P4-102)."""

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

from tools.content_engine.legacy.structure import audio_content_hash  # noqa: E402
from tools.content_pipeline.schema_loader import (  # noqa: E402
    SYNTHETIC_VOICE_TAG,
    CommonSchemaError,
    validate_content_envelope,
)

_SCHEMA_DIR = _REPO_ROOT / "schemas" / "v2" / "content"
_FIXTURE_DIR = Path(__file__).resolve().parent / "fixtures"

_PATTERN_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.pat\.[a-z0-9]+$")
_DIALOGUE_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.dlg\.[a-z0-9]+$")
_UNIT_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.unit\.[a-z0-9._-]+$")
_TONAL_LANGS = frozenset({"yo", "ig", "ha"})
_AUDIO_URI_RE = re.compile(r"^audio/[a-z]{2,3}/([0-9a-f]{8,64})\.[a-z0-9]+$")
_REVIEWED_LABELS = frozenset({"expert_reviewed", "native_verified"})


class ContentSchemaError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _lang_from_pattern_id(pattern_id: str) -> str:
    match = _PATTERN_ID_RE.match(pattern_id)
    if not match:
        raise ContentSchemaError("PATTERN_INVALID", "id must match <lang>.pat.<slug>")
    return match.group("lang")


def _lang_from_dialogue_id(dialogue_id: str) -> str:
    match = _DIALOGUE_ID_RE.match(dialogue_id)
    if not match:
        raise ContentSchemaError("DIALOGUE_INVALID", "id must match <lang>.dlg.<slug>")
    return match.group("lang")


def _schema_registry(*schema_names: str):
    from referencing import Registry, Resource

    common = json.loads((_SCHEMA_DIR / "common.schema.json").read_text(encoding="utf-8"))
    resources: list[tuple[str, Any]] = [
        (common["$id"], Resource.from_contents(common)),
        ("common.schema.json", Resource.from_contents(common)),
    ]
    for name in schema_names:
        doc = json.loads((_SCHEMA_DIR / name).read_text(encoding="utf-8"))
        resources.append((doc["$id"], Resource.from_contents(doc)))
        resources.append((name, Resource.from_contents(doc)))
    return Registry().with_resources(resources)


def _validator(schema_name: str) -> Draft202012Validator:
    doc = json.loads((_SCHEMA_DIR / schema_name).read_text(encoding="utf-8"))
    return Draft202012Validator(doc, registry=_schema_registry(schema_name))


def _nfc_text(value: object, code: str, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ContentSchemaError(code, f"{label} is required")
    normalised = unicodedata.normalize("NFC", value)
    if normalised != value:
        raise ContentSchemaError(code, f"{label} must be NFC-normalised")
    return value


def _run_jsonschema(obj: Mapping[str, Any], validator: Draft202012Validator, code: str) -> None:
    errors = sorted(validator.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise ContentSchemaError(code, errors[0].message)


def validate_pattern(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    if not isinstance(obj, Mapping):
        raise ContentSchemaError("PATTERN_INVALID", "pattern must be a mapping")
    pattern_id = obj.get("id")
    if not isinstance(pattern_id, str):
        raise ContentSchemaError("PATTERN_INVALID", "id is required")
    _lang_from_pattern_id(pattern_id)
    _nfc_text(obj.get("description_l1"), "PATTERN_INVALID", "description_l1")
    _nfc_text(obj.get("form"), "PATTERN_INVALID", "form")
    for field in ("examples", "contrasts", "common_errors"):
        rows = obj.get(field)
        if not isinstance(rows, list):
            raise ContentSchemaError("PATTERN_INVALID", f"{field} must be a list")
        if field == "examples" and len(rows) < 1:
            raise ContentSchemaError("PATTERN_INVALID", "examples must be non-empty")
        for index, row in enumerate(rows):
            _nfc_text(row, "PATTERN_INVALID", f"{field}[{index}]")
    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise ContentSchemaError(exc.code, str(exc)) from exc
    label = obj.get("label")
    if label == "beta":
        raise ContentSchemaError("PATTERN_BETA_REJECTED", "grammar patterns reject label beta (C1)")
    _run_jsonschema(obj, validator or _validator("pattern.schema.json"), "PATTERN_INVALID")


def _check_turn_audio(text: str, audio: object) -> None:
    if not isinstance(audio, Mapping):
        raise ContentSchemaError("AUDIO_MISMATCH", "turn.audio must be a mapping")
    uri = audio.get("uri")
    if not isinstance(uri, str) or not _AUDIO_URI_RE.match(uri):
        raise ContentSchemaError("AUDIO_MISMATCH", "turn.audio.uri must be a content-hash path")
    uri_hash = _AUDIO_URI_RE.match(uri).group(1)
    text_hash = audio.get("text_hash")
    if not isinstance(text_hash, str) or not text_hash:
        raise ContentSchemaError("AUDIO_MISMATCH", "turn.audio.text_hash is required")
    expected = audio_content_hash(text)
    if text_hash != expected or uri_hash != expected:
        raise ContentSchemaError("AUDIO_MISMATCH", "audio text_hash must match turn text")
    kind = audio.get("kind")
    if kind not in ("human", "tts_synthetic"):
        raise ContentSchemaError("AUDIO_MISMATCH", "turn.audio.kind is invalid")
    if kind == "tts_synthetic" and audio.get("synthetic_voice_tag") != SYNTHETIC_VOICE_TAG:
        raise ContentSchemaError("AUDIO_MISMATCH", "tts_synthetic requires synthetic_voice_tag")


def validate_dialogue(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    if not isinstance(obj, Mapping):
        raise ContentSchemaError("DIALOGUE_INVALID", "dialogue must be a mapping")
    dialogue_id = obj.get("id")
    if not isinstance(dialogue_id, str):
        raise ContentSchemaError("DIALOGUE_INVALID", "id is required")
    lang = _lang_from_dialogue_id(dialogue_id)
    _nfc_text(obj.get("scene"), "DIALOGUE_INVALID", "scene")
    roles = obj.get("roles")
    if not isinstance(roles, list) or len(roles) < 1:
        raise ContentSchemaError("DIALOGUE_INVALID", "roles must be a non-empty list")
    role_ids: set[str] = set()
    for index, role in enumerate(roles):
        if not isinstance(role, Mapping):
            raise ContentSchemaError("DIALOGUE_INVALID", f"roles[{index}] must be a mapping")
        role_id = role.get("role_id")
        if not isinstance(role_id, str) or not role_id:
            raise ContentSchemaError("DIALOGUE_INVALID", f"roles[{index}].role_id is required")
        role_ids.add(role_id)
        if not isinstance(role.get("display_name"), str) or not role.get("display_name"):
            raise ContentSchemaError("DIALOGUE_INVALID", f"roles[{index}].display_name is required")
    can_do = obj.get("can_do_ids")
    if not isinstance(can_do, list) or len(can_do) < 1:
        raise ContentSchemaError("DIALOGUE_INVALID", "can_do_ids must be non-empty")
    turns = obj.get("turns")
    if not isinstance(turns, list) or len(turns) < 1:
        raise ContentSchemaError("DIALOGUE_INVALID", "turns must be non-empty")
    for index, turn in enumerate(turns):
        if not isinstance(turn, Mapping):
            raise ContentSchemaError("DIALOGUE_INVALID", f"turns[{index}] must be a mapping")
        speaker = turn.get("speaker")
        if speaker not in role_ids:
            raise ContentSchemaError("DIALOGUE_INVALID", f"turns[{index}].speaker must be a declared role")
        text = _nfc_text(turn.get("text"), "DIALOGUE_INVALID", f"turns[{index}].text")
        _nfc_text(turn.get("gloss"), "DIALOGUE_INVALID", f"turns[{index}].gloss")
        tone = turn.get("tone_pattern")
        if lang in _TONAL_LANGS:
            if not isinstance(tone, list) or len(tone) < 1:
                raise ContentSchemaError("DIALOGUE_INVALID", "tone_pattern is required for tonal languages")
        _check_turn_audio(text, turn.get("audio"))
    comprehension = obj.get("comprehension_items")
    if not isinstance(comprehension, list):
        raise ContentSchemaError("DIALOGUE_INVALID", "comprehension_items must be a list")
    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise ContentSchemaError(exc.code, str(exc)) from exc
    _run_jsonschema(obj, validator or _validator("dialogue.schema.json"), "DIALOGUE_INVALID")


def _collect_unit_refs(obj: Mapping[str, Any]) -> list[str]:
    refs: list[str] = []
    input_block = obj.get("input")
    if isinstance(input_block, Mapping):
        ref = input_block.get("ref")
        if isinstance(ref, str):
            refs.append(ref)
    for field in ("patterns", "lexemes", "items"):
        rows = obj.get(field)
        if isinstance(rows, list):
            refs.extend(row for row in rows if isinstance(row, str))
    culture = obj.get("culture_card")
    if isinstance(culture, str):
        refs.append(culture)
    checkpoint = obj.get("checkpoint")
    if isinstance(checkpoint, Mapping):
        item_ids = checkpoint.get("item_ids")
        if isinstance(item_ids, list):
            refs.extend(row for row in item_ids if isinstance(row, str))
    return refs


def validate_unit(
    obj: Mapping[str, Any],
    *,
    object_registry: Mapping[str, Mapping[str, Any]] | None = None,
    validator: Draft202012Validator | None = None,
) -> None:
    if not isinstance(obj, Mapping):
        raise ContentSchemaError("UNIT_INVALID", "unit must be a mapping")
    unit_id = obj.get("id")
    if not isinstance(unit_id, str) or not _UNIT_ID_RE.match(unit_id):
        raise ContentSchemaError("UNIT_INVALID", "id must match <lang>.unit.<slug>")
    can_do = obj.get("can_do_ids")
    if not isinstance(can_do, list) or len(can_do) < 1:
        raise ContentSchemaError("UNIT_INVALID", "can_do_ids must be non-empty")
    speaking = obj.get("speaking_tasks")
    if not isinstance(speaking, list):
        raise ContentSchemaError("UNIT_INVALID", "speaking_tasks must be a list")
    for index, task in enumerate(speaking):
        if not isinstance(task, Mapping):
            raise ContentSchemaError("UNIT_INVALID", f"speaking_tasks[{index}] must be a mapping")
        for field in ("task_id", "prompt_en", "can_do_id"):
            if not isinstance(task.get(field), str) or not task.get(field):
                raise ContentSchemaError("UNIT_INVALID", f"speaking_tasks[{index}].{field} is required")
    checkpoint = obj.get("checkpoint")
    if not isinstance(checkpoint, Mapping):
        raise ContentSchemaError("UNIT_INVALID", "checkpoint is required")
    item_ids = checkpoint.get("item_ids")
    if not isinstance(item_ids, list) or len(item_ids) < 1:
        raise ContentSchemaError("UNIT_INVALID", "checkpoint.item_ids must be non-empty")
    threshold = checkpoint.get("pass_threshold")
    if not isinstance(threshold, (int, float)) or threshold < 0 or threshold > 1:
        raise ContentSchemaError("UNIT_INVALID", "checkpoint.pass_threshold must be in [0, 1]")
    unit_items = obj.get("items")
    if isinstance(unit_items, list):
        missing = [item_id for item_id in item_ids if item_id not in unit_items]
        if missing:
            raise ContentSchemaError("UNIT_INVALID", f"checkpoint references items not in unit.items: {missing}")
    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise ContentSchemaError(exc.code, str(exc)) from exc
    registry = object_registry or {}
    for ref_id in _collect_unit_refs(obj):
        entry = registry.get(ref_id)
        if entry is None:
            raise ContentSchemaError("UNREVIEWED_REFERENCE", f"missing registry entry for {ref_id}")
        label = entry.get("label")
        if label not in _REVIEWED_LABELS:
            raise ContentSchemaError("UNREVIEWED_REFERENCE", f"{ref_id} is not reviewed (label={label!r})")
    _run_jsonschema(obj, validator or _validator("unit.schema.json"), "UNIT_INVALID")


def _load_fixture(name: str) -> dict[str, Any]:
    return json.loads((_FIXTURE_DIR / name).read_text(encoding="utf-8"))


def _unit_registry() -> dict[str, Mapping[str, Any]]:
    pattern = _load_fixture("pattern_yo_copula.json")
    dialogue = _load_fixture("dialogue_yo_market.json")
    return {
        pattern["id"]: pattern,
        dialogue["id"]: dialogue,
        "yo.lex.ọkọ.vehicle": {"label": "expert_reviewed"},
        "yo.item.dlg_market_q1": {"label": "expert_reviewed"},
        "yo.item.market_vocab_1": {"label": "expert_reviewed"},
        "yo.culture.market_etiquette": {"label": "expert_reviewed"},
    }


def test_pattern_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(json.loads((_SCHEMA_DIR / "pattern.schema.json").read_text()))


def test_dialogue_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(json.loads((_SCHEMA_DIR / "dialogue.schema.json").read_text()))


def test_unit_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(json.loads((_SCHEMA_DIR / "unit.schema.json").read_text()))


def test_pattern_fixture_passes() -> None:
    validate_pattern(_load_fixture("pattern_yo_copula.json"))


def test_pattern_rejects_beta_label() -> None:
    raw = _load_fixture("pattern_yo_copula.json")
    raw["label"] = "beta"
    with pytest.raises(ContentSchemaError) as exc:
        validate_pattern(raw)
    assert exc.value.code == "PATTERN_BETA_REJECTED"


def test_dialogue_fixture_passes() -> None:
    validate_dialogue(_load_fixture("dialogue_yo_market.json"))


def test_dialogue_audio_mismatch() -> None:
    raw = _load_fixture("dialogue_yo_market.json")
    raw["turns"][0]["audio"]["text_hash"] = "deadbeefdeadbeef"
    with pytest.raises(ContentSchemaError) as exc:
        validate_dialogue(raw)
    assert exc.value.code == "AUDIO_MISMATCH"


def test_dialogue_audio_missing_hash() -> None:
    raw = _load_fixture("dialogue_yo_market.json")
    del raw["turns"][0]["audio"]["text_hash"]
    with pytest.raises(ContentSchemaError) as exc:
        validate_dialogue(raw)
    assert exc.value.code == "AUDIO_MISMATCH"


def test_unit_fixture_passes() -> None:
    validate_unit(_load_fixture("unit_yo_a1_market.json"), object_registry=_unit_registry())


def test_unit_unreviewed_reference() -> None:
    raw = _load_fixture("unit_yo_a1_market.json")
    registry = _unit_registry()
    registry = dict(registry)
    registry["yo.pat.copulapresent"] = {"label": "beta"}
    with pytest.raises(ContentSchemaError) as exc:
        validate_unit(raw, object_registry=registry)
    assert exc.value.code == "UNREVIEWED_REFERENCE"
