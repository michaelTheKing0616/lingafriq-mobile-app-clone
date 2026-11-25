"""ZulMorph lint for Zulu forms. Off by default; absence fails loud."""

from __future__ import annotations

import importlib
from collections.abc import Mapping
from typing import Any

from tools.content_engine.linters.types import LintResult, Span

_AUTO_PUBLISH = False


def _decide(item: Mapping[str, Any], kit: Mapping[str, Any]) -> tuple[LintResult, dict[str, Any]]:
    """Shared lint/report decision. Callers must not branch separately."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    language = item["language"]
    form = item["form"]
    if language != "zu":
        raise ValueError(f"language must be 'zu', got {language!r}")

    form_span = Span(0, len(form))
    if "external_zulmorph_fixture" in kit:
        if kit["external_zulmorph_fixture"](form):
            return (
                LintResult(
                    item_id=item_id,
                    rule_id="ZULMORPH",
                    span=Span(0, 0),
                    status="pass",
                ),
                {"route": "parsed", "auto_publish": _AUTO_PUBLISH},
            )
        return (
            LintResult(
                item_id=item_id,
                rule_id="ZULMORPH_PARSE_FAIL",
                span=form_span,
                status="fail",
            ),
            {"route": "human_review", "auto_publish": _AUTO_PUBLISH},
        )

    try:
        importlib.import_module("zulmorph")
    except ImportError:
        return (
            LintResult(
                item_id=item_id,
                rule_id="ZULMORPH_UNAVAILABLE",
                span=form_span,
                status="fail",
            ),
            {"route": "unavailable", "auto_publish": _AUTO_PUBLISH},
        )
    raise RuntimeError("ZulMorph imported unexpectedly; this card does not parse")


def lint_zulmorph(item: Mapping[str, Any], kit: Mapping[str, Any]) -> LintResult:
    """Lint a Zulu form. Fixture, loud unavailability, or unexpected import."""
    result, _ = _decide(item, kit)
    return result


def zulmorph_report(item: Mapping[str, Any], kit: Mapping[str, Any]) -> dict[str, Any]:
    """Report for the same decision as lint_zulmorph. Never auto-publishes."""
    _, report = _decide(item, kit)
    return report
