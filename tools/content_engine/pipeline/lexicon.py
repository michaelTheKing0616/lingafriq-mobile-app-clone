"""Lexicon frequency list and lexeme store (CURRICULUM §3.1).

Caller-supplied corpus counts and G2P IPA only. No download, no invented
forms, no G2P engine, no tone convention, no language data.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.licences.register_schema import (
    leipzig_use,
    register_index,
    validate_row,
)

_LEIPZIG_SOURCE_ID = "leipzig-corpora"
_LEIPZIG_FREQUENCY_USE = "frequency"
_USE_FLAGS = ("display", "evidence", "training")
_STORED_STRING_FIELDS = (
    "form",
    "tone_pattern",
    "ipa",
    "pos",
    "noun_class",
    "plural",
)
_RETURN_FIELDS = _STORED_STRING_FIELDS + ("sources",)


class LexiconError(Exception):
    """Lexicon validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _is_blank_string(value: Any) -> bool:
    return isinstance(value, str) and value.strip() == ""


def _require_register_row(
    source_id: str,
    index: Mapping[str, Mapping[str, str]],
) -> Mapping[str, str]:
    row = index.get(source_id)
    if row is None:
        raise LexiconError(
            "LICENCE_UNREGISTERED",
            f"source_id not in licence register: {source_id}",
        )
    validate_row(row)
    if all(row.get(flag) == "false" for flag in _USE_FLAGS):
        raise LexiconError(
            "LICENCE_USE_FORBIDDEN",
            f"all uses are false for source_id {source_id}",
        )
    return row


def _require_lexeme_string_fields(lexeme: Mapping[str, Any]) -> None:
    for field in _STORED_STRING_FIELDS:
        if field not in lexeme:
            raise LexiconError(
                "LEXEME_FIELD_MISSING",
                f"required lexeme field missing: {field}",
            )
        value = lexeme[field]
        if value is None or _is_blank_string(value):
            raise LexiconError(
                "LEXEME_FIELD_MISSING",
                f"required lexeme field missing: {field}",
            )


def _require_sources(lexeme: Mapping[str, Any]) -> Sequence[Any]:
    if "sources" not in lexeme:
        raise LexiconError(
            "LEXEME_FIELD_MISSING",
            "required lexeme field missing: sources",
        )
    sources = lexeme["sources"]
    if isinstance(sources, (str, bytes)) or not isinstance(sources, Sequence):
        raise LexiconError(
            "LEXEME_FIELD_MISSING",
            "required lexeme field missing: sources",
        )
    if len(sources) == 0:
        raise LexiconError(
            "LEXEME_FIELD_MISSING",
            "required lexeme field missing: sources",
        )
    return sources


def _require_g2p_ipa(lexeme: Mapping[str, Any]) -> None:
    g2p = lexeme.get("g2p")
    if not isinstance(g2p, Mapping) or g2p.get("ipa") != lexeme["ipa"]:
        raise LexiconError(
            "LEXEME_FIELD_MISSING",
            "ipa must come from g2p result",
        )


def build_frequency_list(
    corpus_entries: Sequence[Mapping[str, Any]],
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
) -> list[dict[str, Any]]:
    """Build a frequency list from caller-supplied corpus entries.

    Each entry keeps its own form, count, and source_id. Rows that share a
    form are not merged. Sort is count descending, then form, then source_id.
    """
    index = register_index(register_rows)
    rows: list[dict[str, Any]] = []
    for entry in corpus_entries:
        source_id = entry["source_id"]
        if source_id == _LEIPZIG_SOURCE_ID:
            leipzig_use(_LEIPZIG_FREQUENCY_USE)
        _require_register_row(source_id, index)
        rows.append(
            {
                "form": entry["form"],
                "count": entry["count"],
                "source_id": source_id,
            }
        )
    rows.sort(key=lambda row: (-row["count"], row["form"], row["source_id"]))
    return rows


def store_lexeme(
    lexeme: Mapping[str, Any],
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
) -> dict[str, Any]:
    """Store a lexeme with tone, G2P IPA, POS, noun class, plural, and sources."""
    _require_lexeme_string_fields(lexeme)
    sources = _require_sources(lexeme)
    _require_g2p_ipa(lexeme)
    index = register_index(register_rows)
    for source_id in sources:
        _require_register_row(source_id, index)
    return {field: lexeme[field] for field in _RETURN_FIELDS}
