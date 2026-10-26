"""Run deterministic language linters and analysers as a pipeline stage (P4-060)."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from tools.content_engine.linters.claims import lint_claims
from tools.content_engine.linters.concord_sw import lint_concord_sw
from tools.content_engine.linters.concord_zux import lint_concord_zux
from tools.content_engine.linters.hausa import lint_hausa
from tools.content_engine.linters.pidgin_nla import lint_pidgin_nla
from tools.content_engine.linters.placeholders import lint_placeholders
from tools.content_engine.linters.runner import Linter, run_linters
from tools.content_engine.linters.types import LintResult
from tools.content_engine.linters.unicode import lint_unicode
from tools.content_engine.linters.yoruba import lint_yoruba
from tools.content_engine.linters.zulmorph import lint_zulmorph

CARD_ID = "P4-060"

_COMMON_LINTER_IDS: tuple[str, ...] = ("unicode", "claims", "placeholders")

_LANGUAGE_LINTER_IDS: dict[str, tuple[str, ...]] = {
    "yo": ("yoruba",),
    "ha": ("hausa",),
    "pcm": ("pidgin_nla",),
    "sw": ("concord_sw",),
    "zu": ("concord_zux", "zulmorph"),
    "xh": ("concord_zux",),
    # Igbo dotted-vowel lint (P4-042) stays off while that card is Draft.
    "ig": (),
}

_LINTER_BY_ID: dict[str, Linter] = {
    "unicode": lint_unicode,
    "claims": lint_claims,
    "placeholders": lint_placeholders,
    "yoruba": lint_yoruba,
    "hausa": lint_hausa,
    "pidgin_nla": lint_pidgin_nla,
    "concord_sw": lint_concord_sw,
    "concord_zux": lint_concord_zux,
    "zulmorph": lint_zulmorph,
}


class StageLintError(Exception):
    """Stage lint validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def planned_linter_ids(language: str) -> tuple[str, ...]:
    """Linter ids that must run for a kit language code (AC1)."""
    if not isinstance(language, str) or not language.strip():
        raise StageLintError("LANGUAGE_INVALID", "language must be a non-empty string")
    lang = language.strip()
    extra = _LANGUAGE_LINTER_IDS.get(lang)
    if extra is None:
        raise StageLintError("LANGUAGE_UNSUPPORTED", f"unsupported language: {lang}")
    return _COMMON_LINTER_IDS + extra


def _result_row(linter_id: str, result: LintResult) -> dict[str, Any]:
    return {
        "linter_id": linter_id,
        "rule_id": result.rule_id,
        "status": result.status,
        "span": {"start": result.span.start, "end": result.span.end},
    }


def _is_hard_failure(result: LintResult) -> bool:
    return result.status != "pass"


def run_lint_stage(stage: Mapping[str, Any], kit: Mapping[str, Any]) -> dict[str, Any]:
    """Execute planned linters; hard failures route to Reject (AC2)."""
    if not isinstance(stage, Mapping):
        raise StageLintError("STAGE_INVALID", "stage must be a mapping")
    if not isinstance(kit, Mapping):
        raise StageLintError("KIT_INVALID", "kit must be a mapping")

    language = stage.get("language")
    if not isinstance(language, str):
        raise StageLintError("LANGUAGE_INVALID", "stage.language required")

    payloads = stage.get("lint_payloads")
    if not isinstance(payloads, Mapping):
        raise StageLintError("LINT_PAYLOADS_INVALID", "stage.lint_payloads must be a mapping")

    planned = planned_linter_ids(language)
    rows: list[dict[str, Any]] = []
    hard_failure = False

    for linter_id in planned:
        linter = _LINTER_BY_ID.get(linter_id)
        if linter is None:
            raise StageLintError("LINTER_UNKNOWN", f"unknown linter id: {linter_id}")
        payload = payloads.get(linter_id)
        if not isinstance(payload, Mapping):
            raise StageLintError(
                "LINT_PAYLOAD_MISSING",
                f"missing lint payload for {linter_id}",
            )
        results = run_linters(payload, kit, (linter,))
        if len(results) != 1:
            raise StageLintError("LINT_INTERNAL", f"expected one result for {linter_id}")
        result = results[0]
        rows.append(_result_row(linter_id, result))
        if _is_hard_failure(result):
            hard_failure = True

    linter_score = 0.0 if hard_failure else 1.0
    return {
        "card_id": CARD_ID,
        "status": "ok" if not hard_failure else "fail",
        "route": "Reject" if hard_failure else None,
        "can_publish": not hard_failure,
        "executed_linters": list(planned),
        "linter_results": rows,
        "features": {"linter_results": linter_score},
    }


def linter_results_feature(stage_result: Mapping[str, Any]) -> float | None:
    """Read the blended linter feature from a stage result."""
    features = stage_result.get("features")
    if not isinstance(features, Mapping):
        return None
    value = features.get("linter_results")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    return None
