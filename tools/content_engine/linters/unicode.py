"""Unicode NFC, allowed code points, and look-alike lint (CURRICULUM §3.3)."""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

# Explicit look-alike table. Not a downloaded confusables file.
# Keys are the forbidden look-alike; values are the Latin letter they impersonate.
_LOOKALIKES: dict[str, str] = {
    "\u03b5": "\u025b",  # GREEK SMALL LETTER EPSILON vs LATIN SMALL LETTER OPEN E
    "\u0395": "E",  # GREEK CAPITAL LETTER EPSILON vs LATIN CAPITAL LETTER E
    "\u0430": "a",  # CYRILLIC SMALL LETTER A vs LATIN SMALL LETTER A
    "\u0410": "A",  # CYRILLIC CAPITAL LETTER A vs LATIN CAPITAL LETTER A
}


def lint_unicode(item: Mapping, kit: Mapping) -> LintResult:
    """Fail the first of: not NFC, look-alike, or a code point outside the kit."""
    item_id = item["id"]
    text = item["text"]
    character_set = kit["character_set"]

    nfc = unicodedata.normalize("NFC", text)
    if nfc != text:
        return LintResult(
            item_id=item_id,
            rule_id="UNICODE_NOT_NFC",
            span=_first_nfc_diff_span(text, nfc),
            status="fail",
        )

    allowed = _allowed_chars(character_set)
    for index, char in enumerate(text):
        if char in _LOOKALIKES:
            return LintResult(
                item_id=item_id,
                rule_id="LOOKALIKE_CHAR",
                span=Span(index, index + 1),
                status="fail",
            )
        if char not in allowed:
            return LintResult(
                item_id=item_id,
                rule_id="CODEPOINT_NOT_ALLOWED",
                span=Span(index, index + 1),
                status="fail",
            )

    return LintResult(
        item_id=item_id,
        rule_id="UNICODE",
        span=Span(0, len(text)),
        status="pass",
    )


def _allowed_chars(character_set: object) -> set[str]:
    allowed: set[str] = set()
    for chunk in character_set:  # type: ignore[attr-defined]
        allowed.update(chunk)
    return allowed


def _first_nfc_diff_span(text: str, nfc: str) -> Span:
    for index, char in enumerate(text):
        if index >= len(nfc) or char != nfc[index]:
            return Span(index, index + 1)
    return Span(0, 0)
