"""Compute anchored, single-source, and conflicted lexeme status (CURRICULUM §3.1).

Agreement is equality of tone_pattern, ipa, pos, noun_class, and plural.
high_frequency is a caller flag; missing or false is not held.
No language data.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

_AGREE_FIELDS = ("tone_pattern", "ipa", "pos", "noun_class", "plural")


class AnchoringError(Exception):
    """Anchoring validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _is_blank_string(value: Any) -> bool:
    return isinstance(value, str) and value.strip() == ""


def _require_sources(lexeme: Mapping[str, Any]) -> Sequence[Any]:
    if not isinstance(lexeme, Mapping) or "sources" not in lexeme:
        raise AnchoringError(
            "SOURCE_MISSING",
            "required lexeme field missing: sources",
        )
    sources = lexeme["sources"]
    if isinstance(sources, (str, bytes)) or not isinstance(sources, Sequence):
        raise AnchoringError(
            "SOURCE_MISSING",
            "required lexeme field missing: sources",
        )
    if len(sources) == 0:
        raise AnchoringError(
            "SOURCE_MISSING",
            "required lexeme field missing: sources",
        )
    return sources


def _agreement_key(source: Any) -> tuple[Any, ...]:
    if not isinstance(source, Mapping):
        raise AnchoringError(
            "SOURCE_FIELD_MISSING",
            "required source field missing: mapping",
        )
    values: list[Any] = []
    for field in _AGREE_FIELDS:
        if field not in source:
            raise AnchoringError(
                "SOURCE_FIELD_MISSING",
                f"required source field missing: {field}",
            )
        value = source[field]
        if value is None or _is_blank_string(value):
            raise AnchoringError(
                "SOURCE_FIELD_MISSING",
                f"required source field missing: {field}",
            )
        values.append(value)
    return tuple(values)


def compute_lexeme_status(
    lexeme: Mapping[str, Any],
    high_frequency: bool = False,
) -> dict[str, Any]:
    """Return anchored, single-source, or conflicted status for one lexeme."""
    sources = _require_sources(lexeme)
    keys = [_agreement_key(source) for source in sources]
    held = False
    if len(keys) == 1:
        status = "single-source"
        held = bool(high_frequency)
        available = True
    elif len(set(keys)) == 1:
        status = "anchored"
        available = True
    else:
        status = "conflicted"
        available = False
    return {
        "status": status,
        "held": held,
        "available_to_generation": available,
    }
