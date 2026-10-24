"""Claims and banned generic-template lint."""

from __future__ import annotations

import re
from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

_SECTIONS_NEED_CITATION = frozenset({"explanation", "culture_note"})
_RULE_PASS = "CLAIMS"
_RULE_NO_CITATION = "CLAIM_NO_CITATION"
_RULE_GENERIC = "GENERIC_TEMPLATE"

_GENERIC_PATTERNS = (
    re.compile(r"affixes carry tense and person", re.IGNORECASE),
    re.compile(
        r"pattern:\s*subject\s*(?:→|->)\s*verb\s*(?:→|->)",
        re.IGNORECASE,
    ),
)


def lint_claims(item: Mapping, kit: Mapping) -> LintResult:
    """Fail generic templates first; then require citations on fact sections."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    section = item["section"]
    text = item["text"]
    citation_id = item.get("citation_id")

    for pattern in _GENERIC_PATTERNS:
        match = pattern.search(text)
        if match is not None:
            return LintResult(
                item_id=item_id,
                rule_id=_RULE_GENERIC,
                span=Span(match.start(), match.end()),
                status="fail",
            )

    citation_missing = (
        not isinstance(citation_id, str) or not citation_id.strip()
    )
    if (
        section in _SECTIONS_NEED_CITATION
        and text.strip()
        and citation_missing
    ):
        return LintResult(
            item_id=item_id,
            rule_id=_RULE_NO_CITATION,
            span=Span(0, len(text)),
            status="fail",
        )

    return LintResult(
        item_id=item_id,
        rule_id=_RULE_PASS,
        span=Span(0, 0),
        status="pass",
    )
