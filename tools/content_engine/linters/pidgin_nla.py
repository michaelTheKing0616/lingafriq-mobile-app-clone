"""Pidgin NLA spelling lint against the kit normalisation table."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass

from tools.content_engine.linters.types import LintResult, Span

_LANGUAGE = "pcm"
_RULE_PASS = "PCM_NLA"
_RULE_ENGLISH = "PCM_ENGLISH_SPELLING"
_RULE_TABLE_MISSING = "PCM_NLA_TABLE_MISSING"


@dataclass(frozen=True)
class PidginNlaResult(LintResult):
    nla_form: str = ""


def lint_pidgin_nla(item: Mapping, kit: Mapping) -> PidginNlaResult:
    """Flag the first whitespace token that matches a table english spelling."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")
    language = item["language"]
    if language != _LANGUAGE:
        raise ValueError(f"language must be {_LANGUAGE!r}, got {language!r}")

    item_id = item["id"]
    text = item["text"]
    english_to_nla = _usable_english_to_nla(kit)
    if english_to_nla is None:
        return PidginNlaResult(
            item_id=item_id,
            rule_id=_RULE_TABLE_MISSING,
            span=Span(0, len(text)),
            status="fail",
            nla_form="",
        )

    for token, start, end in _whitespace_tokens(text):
        nla_form = english_to_nla.get(token)
        if nla_form is not None:
            return PidginNlaResult(
                item_id=item_id,
                rule_id=_RULE_ENGLISH,
                span=Span(start, end),
                status="fail",
                nla_form=nla_form,
            )

    return PidginNlaResult(
        item_id=item_id,
        rule_id=_RULE_PASS,
        span=Span(0, 0),
        status="pass",
        nla_form="",
    )


def _usable_english_to_nla(kit: Mapping) -> dict[str, str] | None:
    """Return english→nla only for a complete, non-duplicate table. Else None."""
    block = kit.get("nla_normalisation")
    if not isinstance(block, Mapping) or block.get("table_included") is not True:
        return None
    rows = block.get("rows")
    if not isinstance(rows, list) or not rows:
        return None

    english_to_nla: dict[str, str] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            return None
        english = row.get("english")
        nla = row.get("nla")
        if isinstance(english, str) and english and english in english_to_nla:
            raise ValueError("duplicate english in nla_normalisation rows")
        if not isinstance(english, str) or not english:
            return None
        if not isinstance(nla, str) or not nla:
            return None
        english_to_nla[english] = nla
    return english_to_nla


def _whitespace_tokens(text: str) -> list[tuple[str, int, int]]:
    """Tokens and spans from the same whitespace split as str.split()."""
    tokens: list[tuple[str, int, int]] = []
    index = 0
    length = len(text)
    while index < length:
        while index < length and text[index].isspace():
            index += 1
        if index >= length:
            break
        start = index
        while index < length and not text[index].isspace():
            index += 1
        tokens.append((text[start:index], start, index))
    return tokens
