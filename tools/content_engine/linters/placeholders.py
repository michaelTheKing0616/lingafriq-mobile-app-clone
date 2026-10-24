"""Placeholder, empty-required-string, and schema lint (CURRICULUM §3.3)."""

from __future__ import annotations

import json
import re
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from tools.content_engine.linters.types import LintResult, Span

_SCHEMA_PATH = (
    Path(__file__).resolve().parents[4] / "curriculum" / "schema" / "item.schema.json"
)
if not _SCHEMA_PATH.is_file():
    raise FileNotFoundError(_SCHEMA_PATH)

_SCHEMA: dict[str, Any] = json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))
_VALIDATOR = Draft202012Validator(_SCHEMA)
_PLACEHOLDER_RE = re.compile(r"word\d|example meaning|sample|lorem|TODO", re.IGNORECASE)

_RULE_PASS = "PLACEHOLDERS"
_RULE_PLACEHOLDER = "PLACEHOLDER_TEXT"
_RULE_SCHEMA = "SCHEMA_INVALID"


def lint_placeholders(item: object, kit: object) -> LintResult:
    """Fail placeholder text first, then schema or blank required strings."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    if isinstance(item, str):
        raw = item
        try:
            item = json.loads(raw)
        except json.JSONDecodeError:
            match = _PLACEHOLDER_RE.search(raw)
            if match is not None:
                return LintResult(
                    item_id="",
                    rule_id=_RULE_PLACEHOLDER,
                    span=Span(match.start(), match.end()),
                    status="fail",
                )
            return LintResult(
                item_id="",
                rule_id=_RULE_SCHEMA,
                span=Span(0, len(raw)),
                status="fail",
            )

    if not isinstance(item, dict):
        return LintResult(
            item_id="",
            rule_id=_RULE_SCHEMA,
            span=Span(0, 0),
            status="fail",
        )

    placeholder = _placeholder_in_item(item)
    if placeholder is not None:
        return placeholder

    if not _VALIDATOR.is_valid(item) or _blank_required_string(item, _SCHEMA):
        ident = item.get("id")
        return LintResult(
            item_id=ident if isinstance(ident, str) else "",
            rule_id=_RULE_SCHEMA,
            span=Span(0, 0),
            status="fail",
        )

    return LintResult(
        item_id=item["id"],
        rule_id=_RULE_PASS,
        span=Span(0, 0),
        status="pass",
    )


def _placeholder_in_item(item: dict[str, Any]) -> LintResult | None:
    """PLACEHOLDER_TEXT before schema; text match keeps its span, others Span(0, 0)."""
    text = item.get("text")
    if isinstance(text, str):
        match = _PLACEHOLDER_RE.search(text)
        if match is not None:
            return LintResult(
                item_id=item["id"],
                rule_id=_RULE_PLACEHOLDER,
                span=Span(match.start(), match.end()),
                status="fail",
            )
    if _any_nested_placeholder(item, skip_text=True):
        return LintResult(
            item_id=item["id"],
            rule_id=_RULE_PLACEHOLDER,
            span=Span(0, 0),
            status="fail",
        )
    return None


def _any_nested_placeholder(value: object, *, skip_text: bool = False) -> bool:
    if isinstance(value, str):
        return _PLACEHOLDER_RE.search(value) is not None
    if isinstance(value, dict):
        for key, child in value.items():
            if skip_text and key == "text":
                continue
            if _any_nested_placeholder(child):
                return True
        return False
    if isinstance(value, list):
        return any(_any_nested_placeholder(child) for child in value)
    return False


def _is_string_schema(schema: object) -> bool:
    if not isinstance(schema, Mapping):
        return False
    declared = schema.get("type")
    return declared == "string" or (
        isinstance(declared, list) and "string" in declared
    )


def _blank_required_string(instance: object, schema: object) -> bool:
    """True when a schema-required string is empty or whitespace.

    jsonschema accepts whitespace-only strings that omit minLength.
    Required names are read from the schema; the field list is not hardcoded.
    """
    if not isinstance(schema, Mapping):
        return False

    properties = schema.get("properties")
    if not isinstance(properties, Mapping):
        properties = {}

    if isinstance(instance, dict):
        required = schema.get("required")
        if isinstance(required, list):
            for name in required:
                prop_schema = properties.get(name)
                value = instance.get(name)
                if (
                    _is_string_schema(prop_schema)
                    and isinstance(value, str)
                    and not value.strip()
                ):
                    return True
        for name, prop_schema in properties.items():
            if name in instance and _blank_required_string(instance[name], prop_schema):
                return True

    items_schema = schema.get("items")
    if isinstance(instance, list) and isinstance(items_schema, Mapping):
        for element in instance:
            if _blank_required_string(element, items_schema):
                return True

    return False
