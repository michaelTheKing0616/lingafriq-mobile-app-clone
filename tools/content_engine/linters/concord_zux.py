"""Zulu and Xhosa noun-class concord lint from kit tables."""

from __future__ import annotations

from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

_LEGAL_LANGS = frozenset({"zu", "xh"})
_SLOTS = ("subject", "object", "adjective")
_CLASS_MIN = 1
_CLASS_MAX = 15


def lint_concord_zux(item: Mapping, kit: Mapping) -> LintResult:
    """Fail first disagreeing subject/object/adjective marker, then spaced prefixes."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    language = item["language"]
    noun_class = item["noun_class"]
    markers = {slot: item[slot] for slot in _SLOTS}
    has_prefixes = item["has_prefixes"]
    surface = item["surface"]

    if language not in _LEGAL_LANGS:
        raise ValueError(f"unsupported language: {language!r}")
    if not isinstance(noun_class, int) or noun_class < _CLASS_MIN or noun_class > _CLASS_MAX:
        raise ValueError(f"noun_class out of range: {noun_class!r}")
    if "concord_table" not in kit:
        raise ValueError("missing kit key concord_table")

    class_table = kit["concord_table"][noun_class]
    for slot in _SLOTS:
        marker = markers[slot]
        if marker is None:
            continue
        if marker not in class_table[slot]:
            return LintResult(
                item_id=item_id,
                rule_id="ZX_CONCORD",
                span=Span(0, len(marker)),
                status="fail",
            )

    if has_prefixes and any(ch.isspace() for ch in surface):
        return LintResult(
            item_id=item_id,
            rule_id="ZX_CONJUNCTIVE",
            span=Span(0, len(surface)),
            status="fail",
        )

    return LintResult(item_id=item_id, rule_id="ZX", span=Span(0, 0), status="pass")


def concord_report(item: Mapping, kit: Mapping) -> dict:
    """Return the analyser label for the item language."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")
    language = item["language"]
    if language == "xh":
        return {"analyser": "none"}
    if language == "zu":
        return {"analyser": "rule"}
    raise ValueError(f"unsupported language: {language!r}")
