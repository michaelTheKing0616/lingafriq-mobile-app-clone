"""Route curriculum items by confidence threshold and regeneration cap (P4-064, CURRICULUM §3.4)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.pipeline.generation_guard import (
    MAX_REGENERATION_ATTEMPTS,
    may_regenerate,
    next_regeneration_count,
)
from tools.content_engine.pipeline.scoring import score_item_features

CARD_ID = "P4-064"
THRESHOLD_AUTO_BETA = 0.90
THRESHOLD_REVIEW = 0.70


class RoutingError(Exception):
    """Routing validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _normalize_tags(tags: Sequence[str] | None) -> tuple[str, ...]:
    if tags is None:
        return ()
    if not isinstance(tags, Sequence) or isinstance(tags, (str, bytes)):
        raise RoutingError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be a sequence of strings")
    out: list[str] = []
    for tag in tags:
        if not isinstance(tag, str) or not tag.strip():
            raise RoutingError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be non-empty strings")
        out.append(tag.strip())
    return tuple(out)


def _reject_path(
    *,
    regeneration_count: int,
    reason: str,
) -> dict[str, Any]:
    if may_regenerate(regeneration_count):
        new_count = next_regeneration_count(regeneration_count)
        return {
            "card_id": CARD_ID,
            "route": "regenerate",
            "publish_label": None,
            "can_publish": False,
            "queue": None,
            "regeneration_count": new_count,
            "may_regenerate": may_regenerate(new_count),
            "reject_reason": reason,
        }
    return {
        "card_id": CARD_ID,
        "route": "park",
        "publish_label": None,
        "can_publish": False,
        "queue": "human_park",
        "regeneration_count": regeneration_count,
        "may_regenerate": False,
        "reject_reason": reason,
    }


def route_scored_item(
    *,
    score: float,
    linters_pass: bool,
    high_risk_tags: Sequence[str] | None = None,
    hard_linter_failure: bool = False,
    regeneration_count: int = 0,
) -> dict[str, Any]:
    """Apply §3.4 routing table to a calibrated score and gate signals."""
    if regeneration_count < 0:
        raise RoutingError("REGENERATION_INVALID", "regeneration count cannot be negative")
    if not isinstance(score, (int, float)) or isinstance(score, bool):
        raise RoutingError("SCORE_INVALID", "score must be a number")
    numeric = float(score)
    if numeric != numeric or numeric in (float("inf"), float("-inf")):
        raise RoutingError("SCORE_INVALID", "score must be finite")

    tags = _normalize_tags(high_risk_tags)

    if hard_linter_failure or numeric < THRESHOLD_REVIEW:
        reason = "hard_linter_failure" if hard_linter_failure else "score_below_review"
        return _reject_path(regeneration_count=regeneration_count, reason=reason)

    if tags:
        return {
            "card_id": CARD_ID,
            "route": "linguist",
            "publish_label": None,
            "can_publish": False,
            "queue": "linguist",
            "high_risk_tags": list(tags),
            "regeneration_count": regeneration_count,
            "may_regenerate": may_regenerate(regeneration_count),
            "reject_reason": None,
        }

    if numeric >= THRESHOLD_AUTO_BETA and linters_pass:
        return {
            "card_id": CARD_ID,
            "route": "publish_beta",
            "publish_label": "Beta",
            "can_publish": True,
            "queue": None,
            "high_risk_tags": [],
            "regeneration_count": regeneration_count,
            "may_regenerate": may_regenerate(regeneration_count),
            "reject_reason": None,
        }

    if numeric >= THRESHOLD_REVIEW:
        return {
            "card_id": CARD_ID,
            "route": "linguist",
            "publish_label": None,
            "can_publish": False,
            "queue": "linguist",
            "high_risk_tags": [],
            "regeneration_count": regeneration_count,
            "may_regenerate": may_regenerate(regeneration_count),
            "reject_reason": None,
        }

    return _reject_path(regeneration_count=regeneration_count, reason="score_below_review")


def run_routing_stage(
    item: Mapping[str, Any],
    *,
    lint_stage: Mapping[str, Any] | None = None,
    regeneration_count: int = 0,
    high_risk_tags: Sequence[str] | None = None,
) -> dict[str, Any]:
    """Score an item and route using optional lint-stage hard-failure signal."""
    if not isinstance(item, Mapping):
        raise RoutingError("ITEM_INVALID", "item must be a mapping")

    scored = score_item_features(item)
    if not scored.get("complete"):
        raise RoutingError("SCORE_INCOMPLETE", "confidence score is incomplete; cannot route")

    score = scored.get("score")
    if not isinstance(score, (int, float)):
        raise RoutingError("SCORE_MISSING", "scored item missing numeric score")

    hard_failure = False
    linters_pass = True
    if lint_stage is not None:
        if not isinstance(lint_stage, Mapping):
            raise RoutingError("LINT_STAGE_INVALID", "lint_stage must be a mapping")
        hard_failure = lint_stage.get("status") == "fail" or lint_stage.get("can_publish") is False
        linters_pass = not hard_failure

    tags = high_risk_tags
    if tags is None:
        raw = item.get("high_risk_tags")
        if raw is not None:
            if not isinstance(raw, Sequence) or isinstance(raw, (str, bytes)):
                raise RoutingError("HIGH_RISK_TAGS_INVALID", "item.high_risk_tags must be a sequence")
            tags = tuple(str(t) for t in raw if isinstance(t, str))

    decision = route_scored_item(
        score=float(score),
        linters_pass=linters_pass,
        high_risk_tags=tags,
        hard_linter_failure=hard_failure,
        regeneration_count=regeneration_count,
    )
    return {
        **decision,
        "score": float(score),
        "max_regeneration_attempts": MAX_REGENERATION_ATTEMPTS,
        "thresholds": {
            "auto_beta": THRESHOLD_AUTO_BETA,
            "review": THRESHOLD_REVIEW,
        },
    }
