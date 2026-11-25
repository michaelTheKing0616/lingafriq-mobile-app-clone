"""Per-language syllabus spec and corpora licence gate (P4-130, ELEVATION §6.6)."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

from tools.content_engine.licences.register_schema import (
    LicenceRegisterError,
    load_register_csv,
    register_index,
    validate_row,
)
from tools.content_engine.linters.exclusion_enforce import (
    ExclusionEnforceError,
    scan_manifest,
)

CARD_ID = "P4-130"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_SCHEMA_PATH = _REPO_ROOT / "schemas/v2/syllabus.schema.json"
_REGISTER_CSV = _REPO_ROOT / "tools/content_engine/licences/register.csv"

_SPECIAL_CORPUS_KINDS = frozenset({"masakhane", "jw300_alternative"})


class SyllabusSpecError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def schema_path() -> Path:
    return _SCHEMA_PATH


def load_syllabus_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def syllabus_validator() -> Draft202012Validator:
    schema = load_syllabus_schema()
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def _parse_use_flag(raw: str) -> bool:
    return raw.strip().lower() == "true"


def _is_jw300_blocked(corpus: Mapping[str, Any]) -> bool:
    source_id = str(corpus.get("source_id", "")).strip()
    if source_id == "jw300" or "jw300" in source_id.lower():
        return True
    derived = corpus.get("derived_from")
    if isinstance(derived, str) and derived.strip().lower() == "jw300":
        return True
    return False


def _requires_explicit_licence_field(corpus: Mapping[str, Any]) -> bool:
    kind = corpus.get("kind")
    if isinstance(kind, str) and kind in _SPECIAL_CORPUS_KINDS:
        return True
    source_id = str(corpus.get("source_id", "")).casefold()
    if "masakhane" in source_id:
        return True
    if "jw300" in source_id and "alternative" in source_id:
        return True
    return False


def build_can_do_index(units: Sequence[Mapping[str, Any]]) -> dict[str, list[str]]:
    index: dict[str, list[str]] = {}
    for position, unit in enumerate(units):
        if not isinstance(unit, Mapping):
            raise SyllabusSpecError("UNIT_INVALID", f"units[{position}] must be an object")
        unit_id = unit.get("unit_id")
        can_do = unit.get("can_do_ids")
        if not isinstance(unit_id, str) or not unit_id.strip():
            raise SyllabusSpecError("UNIT_INVALID", f"units[{position}].unit_id required")
        if not isinstance(can_do, list) or len(can_do) < 1:
            raise SyllabusSpecError("UNIT_INVALID", f"units[{position}].can_do_ids required")
        cleaned: list[str] = []
        for cid in can_do:
            if not isinstance(cid, str) or not cid.strip():
                raise SyllabusSpecError("UNIT_INVALID", f"units[{position}].can_do_ids has empty id")
            cleaned.append(cid.strip())
        index[unit_id.strip()] = cleaned
    return index


def assert_source_licensed_for_corpus(
    source_id: str,
    register_rows: Sequence[Mapping[str, str]],
) -> Mapping[str, str]:
    index = register_index(register_rows)
    row = index.get(source_id)
    if row is None:
        raise SyllabusSpecError(
            "SOURCE_UNLICENSED",
            f"source_id not in licence register: {source_id}",
        )
    if row.get("discovery_only", "").strip() == "true":
        raise SyllabusSpecError(
            "SOURCE_UNLICENSED",
            f"source {source_id!r} is discovery-only",
        )
    try:
        validate_row(row)
    except LicenceRegisterError as exc:
        raise SyllabusSpecError("SOURCE_UNLICENSED", str(exc)) from exc
    licence = row.get("licence", "")
    if not isinstance(licence, str) or not licence.strip():
        raise SyllabusSpecError(
            "SOURCE_UNLICENSED",
            f"register row {source_id} has no licence",
        )
    display = _parse_use_flag(row.get("display", "false"))
    evidence = _parse_use_flag(row.get("evidence", "false"))
    training = _parse_use_flag(row.get("training", "false"))
    if not display and not evidence and not training:
        raise SyllabusSpecError(
            "SOURCE_UNLICENSED",
            f"source {source_id!r} has no permitted use in register",
        )
    return row


def check_corpus_licence(
    corpus: Mapping[str, Any],
    register_rows: Sequence[Mapping[str, str]],
) -> dict[str, Any]:
    if _is_jw300_blocked(corpus):
        raise SyllabusSpecError(
            "JW300_DERIVED_DATA",
            "JW300-derived corpora cannot be referenced in a syllabus",
        )
    source_id = corpus.get("source_id")
    if not isinstance(source_id, str) or not source_id.strip():
        raise SyllabusSpecError("CORPUS_INVALID", "corpus source_id required")
    sid = source_id.strip()
    row = assert_source_licensed_for_corpus(sid, register_rows)
    register_licence = row.get("licence", "")
    merged = dict(corpus)
    merged["register_licence"] = register_licence
    if _requires_explicit_licence_field(corpus):
        explicit = corpus.get("licence")
        if not isinstance(explicit, str) or not explicit.strip():
            raise SyllabusSpecError(
                "SOURCE_UNLICENSED",
                f"corpus {sid!r} requires an explicit licence field",
            )
        if explicit.strip() != register_licence.strip():
            raise SyllabusSpecError(
                "SOURCE_UNLICENSED",
                f"corpus licence must match register for {sid}",
            )
    cited = corpus.get("licence")
    if cited is not None and isinstance(cited, str) and cited.strip():
        if cited.strip() != register_licence.strip():
            raise SyllabusSpecError(
                "SOURCE_UNLICENSED",
                f"corpus licence does not match register for {sid}",
            )
    merged["licence"] = register_licence
    return merged


def check_corpora_licences(
    corpora: Sequence[Mapping[str, Any]],
    register_rows: Sequence[Mapping[str, str]],
) -> list[dict[str, Any]]:
    manifest_items: list[dict[str, Any]] = []
    checked: list[dict[str, Any]] = []
    for index, corpus in enumerate(corpora):
        if not isinstance(corpus, Mapping):
            raise SyllabusSpecError("CORPUS_INVALID", f"corpora[{index}] must be an object")
        merged = check_corpus_licence(corpus, register_rows)
        checked.append(merged)
        manifest_items.append(
            {
                "source_id": merged["source_id"],
                "layer": "corpus",
                "derived_from": merged.get("derived_from"),
            }
        )
    try:
        scan_manifest(manifest_items, load_exclusions_rows())
    except ExclusionEnforceError as exc:
        raise SyllabusSpecError(exc.code, str(exc)) from exc
    return checked


def load_exclusions_rows() -> dict[str, Any]:
    from tools.content_engine.linters.exclusion_enforce import load_exclusions

    return load_exclusions()


def validate_syllabus_shape(syllabus: Mapping[str, Any]) -> None:
    validator = syllabus_validator()
    try:
        validator.validate(syllabus)
    except ValidationError as exc:
        raise SyllabusSpecError("SYLLABUS_INVALID", exc.message) from exc
    if syllabus.get("card_id") != CARD_ID:
        raise SyllabusSpecError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    linguist = syllabus.get("applied_linguist")
    if not isinstance(linguist, Mapping):
        raise SyllabusSpecError("LINGUIST_MISSING", "applied_linguist required")
    if linguist.get("role") != "applied_linguist":
        raise SyllabusSpecError("LINGUIST_INVALID", "applied_linguist.role must be applied_linguist")


def submit_syllabus(
    syllabus: Mapping[str, Any],
    *,
    register_rows: Sequence[Mapping[str, str]] | None = None,
) -> dict[str, Any]:
    """Validate syllabus, licence-check corpora, record can-do map, mark submitted."""
    validate_syllabus_shape(syllabus)
    rows = register_rows if register_rows is not None else load_register_csv(_REGISTER_CSV)
    units = syllabus.get("units")
    if not isinstance(units, list):
        raise SyllabusSpecError("UNIT_INVALID", "units must be an array")
    can_do_index = build_can_do_index(units)
    corpora = syllabus.get("corpora")
    if corpora is None:
        corpora_list: list[Mapping[str, Any]] = []
    elif not isinstance(corpora, list):
        raise SyllabusSpecError("CORPUS_INVALID", "corpora must be an array")
    else:
        corpora_list = [c for c in corpora if isinstance(c, Mapping)]
    checked_corpora = check_corpora_licences(corpora_list, rows)
    out: dict[str, Any] = deepcopy(dict(syllabus))
    out["can_do_index"] = can_do_index
    out["corpora"] = checked_corpora
    out["status"] = "submitted"
    linguist = out.get("applied_linguist")
    if isinstance(linguist, MutableMapping):
        linguist["recorded_at_submit"] = True
    return out
