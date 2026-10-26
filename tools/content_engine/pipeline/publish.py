"""Publish reviewed curriculum items with an honest quality label (P4-067, CURRICULUM §3.1)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from datetime import UTC, datetime
from typing import Any

from tools.content_engine.pipeline.highrisk import validate_publish_with_high_risk

CARD_ID = "P4-067"

QUALITY_LABEL_BETA = "Beta"
QUALITY_LABEL_REVIEWED = "Reviewed"
QUALITY_LABEL_NATIVE_VERIFIED = "Native-verified"

ALLOWED_QUALITY_LABELS: frozenset[str] = frozenset(
    {
        QUALITY_LABEL_BETA,
        QUALITY_LABEL_REVIEWED,
        QUALITY_LABEL_NATIVE_VERIFIED,
    }
)


class PublishError(Exception):
    """Publish validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _high_risk_tags(
    item: Mapping[str, Any],
    routing_stage: Mapping[str, Any],
) -> tuple[str, ...]:
    raw = routing_stage.get("high_risk_tags")
    if raw is None:
        raw = item.get("high_risk_tags")
    if raw is None:
        return ()
    if not isinstance(raw, Sequence) or isinstance(raw, (str, bytes)):
        raise PublishError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be a sequence of strings")
    out: list[str] = []
    for tag in raw:
        if not isinstance(tag, str) or not tag.strip():
            raise PublishError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be non-empty strings")
        out.append(tag.strip())
    return tuple(out)


def _auto_beta_publish(routing_stage: Mapping[str, Any]) -> bool:
    return (
        routing_stage.get("route") == "publish_beta"
        and routing_stage.get("can_publish") is True
    )


def _needs_human_approval(item: Mapping[str, Any], routing_stage: Mapping[str, Any]) -> bool:
    if item.get("review_required") is True:
        return True
    if _auto_beta_publish(routing_stage):
        return False
    return True


def validate_quality_label(label: str) -> str:
    if not isinstance(label, str) or not label.strip():
        raise PublishError("QUALITY_LABEL_INVALID", "quality label must be a non-empty string")
    normalized = label.strip()
    if normalized not in ALLOWED_QUALITY_LABELS:
        raise PublishError(
            "QUALITY_LABEL_INVALID",
            f"quality label must be one of: {', '.join(sorted(ALLOWED_QUALITY_LABELS))}",
        )
    return normalized


def publish_item(
    item: Mapping[str, Any],
    *,
    routing_stage: Mapping[str, Any],
    reviewer_id: str | None = None,
    quality_label: str | None = None,
) -> dict[str, Any]:
    """Publish when reviewed or auto-Beta; otherwise REVIEW_REQUIRED (AC2)."""
    if not isinstance(item, Mapping):
        raise PublishError("ITEM_INVALID", "item must be a mapping")
    if not isinstance(routing_stage, Mapping):
        raise PublishError("ROUTING_INVALID", "routing_stage must be a mapping")

    approved = item.get("approved") is True
    if _needs_human_approval(item, routing_stage) and not approved:
        raise PublishError(
            "REVIEW_REQUIRED",
            "item requires reviewer approval before publish",
        )

    auto_beta = _auto_beta_publish(routing_stage) and not approved

    if auto_beta:
        label = validate_quality_label(quality_label or routing_stage.get("publish_label") or QUALITY_LABEL_BETA)
        rid: str | None = None
        if reviewer_id is not None and str(reviewer_id).strip():
            rid = str(reviewer_id).strip()
    else:
        if not isinstance(reviewer_id, str) or not reviewer_id.strip():
            raise PublishError("REVIEW_REQUIRED", "reviewer id is required to publish reviewed items")
        if quality_label is None:
            raise PublishError("QUALITY_LABEL_INVALID", "quality label is required for reviewed publish")
        label = validate_quality_label(quality_label)
        rid = reviewer_id.strip()

    tags = _high_risk_tags(item, routing_stage)
    validate_publish_with_high_risk(
        high_risk_tags=tags,
        publish_label=label,
        reviewer_id=rid,
    )

    published_at = datetime.now(UTC).isoformat()
    return {
        "card_id": CARD_ID,
        "status": "published",
        "can_publish": True,
        "published": True,
        "quality_label": label,
        "reviewer_id": rid,
        "published_at": published_at,
        "item_id": item.get("item_id"),
        "high_risk_tags": list(tags),
    }


def run_publish_stage(
    item: Mapping[str, Any],
    *,
    routing_stage: Mapping[str, Any],
    reviewer_id: str | None = None,
    quality_label: str | None = None,
) -> dict[str, Any]:
    """Stage contract: apply publish rules after routing (P4-064 / P4-065)."""
    try:
        return publish_item(
            item,
            routing_stage=routing_stage,
            reviewer_id=reviewer_id,
            quality_label=quality_label,
        )
    except PublishError as exc:
        return {
            "card_id": CARD_ID,
            "status": "blocked",
            "can_publish": False,
            "published": False,
            "code": exc.code,
            "message": str(exc),
        }
