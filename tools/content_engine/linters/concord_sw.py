"""Swahili noun-class concord lint for the §3.3 m/wa and ki/vi pairs."""

from __future__ import annotations

from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

_LEGAL_CLASS_PAIRS = frozenset({"m/wa", "ki/vi"})
_SLOTS = ("subject", "object", "adjective")


def lint_concord_sw(item: Mapping, kit: Mapping) -> LintResult:
    """Fail unknown nouns or first disagreeing subject/object/adjective marker."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    noun = item["noun"]
    in_lexicon = noun["in_lexicon"]
    class_pair = noun["class_pair"]
    markers = {slot: item[slot] for slot in _SLOTS}

    if not in_lexicon:
        return LintResult(
            item_id=item_id,
            rule_id="SW_NOUN_UNKNOWN",
            span=Span(0, 0),
            status="fail",
        )

    if class_pair not in _LEGAL_CLASS_PAIRS:
        raise ValueError(f"unsupported class_pair: {class_pair!r}")

    if "concord_table" not in kit:
        raise ValueError("missing kit key concord_table")

    pair_table = kit["concord_table"][class_pair]
    for slot in _SLOTS:
        marker = markers[slot]
        if marker is None:
            continue
        if marker not in pair_table[slot]:
            return LintResult(
                item_id=item_id,
                rule_id="SW_CONCORD",
                span=Span(0, len(marker)),
                status="fail",
            )

    return LintResult(item_id=item_id, rule_id="SW", span=Span(0, 0), status="pass")
