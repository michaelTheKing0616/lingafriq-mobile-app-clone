"""Language kit schema (CURRICULUM §3.1).

A kit is once per language. Missing or invalid sections fail loud; no
generation runs without a valid kit.
"""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

REQUIRED_SECTIONS: tuple[str, ...] = (
    "character_set",
    "nfc",
    "tone_marking",
    "phone_inventory",
    "g2p",
    "noun_class",
    "concord",
    "dialect",
    "honorifics",
)

_LIST_OR_MAPPING_SECTIONS = frozenset(
    {"g2p", "noun_class", "concord", "honorifics"}
)
_STRING_SECTIONS = frozenset({"tone_marking", "dialect"})


class KitError(Exception):
    """Kit load or validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _is_nonempty_list(value: Any) -> bool:
    return isinstance(value, list) and len(value) > 0


def _is_nonempty_mapping(value: Any) -> bool:
    return isinstance(value, Mapping) and not isinstance(value, (str, list)) and len(value) > 0


def _is_nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and value != ""


def _section_valid(key: str, value: Any) -> bool:
    if key == "character_set":
        return _is_nonempty_list(value) and all(isinstance(item, str) for item in value)
    if key == "nfc":
        return value == "NFC"
    if key in _STRING_SECTIONS:
        return _is_nonempty_string(value)
    if key == "phone_inventory":
        return _is_nonempty_list(value)
    if key in _LIST_OR_MAPPING_SECTIONS:
        return _is_nonempty_list(value) or _is_nonempty_mapping(value)
    return False


def validate_kit(data: Any) -> dict[str, Any]:
    """Validate a parsed kit mapping.

    Inputs: YAML-loaded kit document.
    Outputs: a dict of the validated kit.
    Side effects: none. Raises KitError with code KIT_SECTION_MISSING for the
    first required section that is absent, empty, or the wrong shape.
    """
    if not isinstance(data, Mapping):
        raise KitError(
            "KIT_SECTION_MISSING",
            "Required kit section missing or invalid: character_set",
        )
    for key in REQUIRED_SECTIONS:
        if key not in data or not _section_valid(key, data[key]):
            raise KitError(
                "KIT_SECTION_MISSING",
                f"Required kit section missing or invalid: {key}",
            )
    return dict(data)
