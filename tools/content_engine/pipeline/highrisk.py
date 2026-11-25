"""Detect and enforce §3.4 high-risk tags (never AI-only) (P4-065)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.pipeline.routing import run_routing_stage
from tools.content_engine.pipeline.tone_agreement import has_tone_or_teaching_mark

CARD_ID = "P4-065"
PUBLISH_LABEL_BETA = "Beta"

TAG_TONE = "tone"
TAG_IDIOM = "idiom"
TAG_PROVERB = "proverb"
TAG_CULTURE = "culture_history_religion"
TAG_HONORIFIC = "honorific"
TAG_GRAMMAR = "grammar_explanation"
TAG_CHILD = "child_audience"

_CANONICAL_TAGS = frozenset(
    {
        TAG_TONE,
        TAG_IDIOM,
        TAG_PROVERB,
        TAG_CULTURE,
        TAG_HONORIFIC,
        TAG_GRAMMAR,
        TAG_CHILD,
        "anglicised_pidgin",
    }
)

_CONTENT_KIND_TAGS: dict[str, str] = {
    "idiom": TAG_IDIOM,
    "proverb": TAG_PROVERB,
}

_CULTURE_TOPICS = frozenset({"culture", "history", "religion"})


class HighRiskError(Exception):
    """High-risk gate failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _normalize_tag_list(tags: Sequence[str] | None) -> list[str]:
    if tags is None:
        return []
    if not isinstance(tags, Sequence) or isinstance(tags, (str, bytes)):
        raise HighRiskError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be a sequence of strings")
    out: list[str] = []
    seen: set[str] = set()
    for tag in tags:
        if not isinstance(tag, str) or not tag.strip():
            raise HighRiskError("HIGH_RISK_TAGS_INVALID", "high_risk_tags must be non-empty strings")
        value = tag.strip()
        if value not in seen:
            seen.add(value)
            out.append(value)
    return out


def _claim_texts(claims: object) -> list[tuple[str, Mapping[str, Any]]]:
    if claims is None:
        return []
    if not isinstance(claims, Sequence) or isinstance(claims, (str, bytes)):
        raise HighRiskError("ITEM_INVALID", "claims must be a list when present")
    rows: list[tuple[str, Mapping[str, Any]]] = []
    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise HighRiskError("ITEM_INVALID", f"claim {index}: must be a mapping")
        section = claim.get("section")
        if not isinstance(section, str):
            raise HighRiskError("ITEM_INVALID", f"claim {index}: section required")
        rows.append((section, claim))
    return rows


def _detect_from_tokens(tokens: object) -> bool:
    if tokens is None:
        return False
    if not isinstance(tokens, Sequence) or isinstance(tokens, (str, bytes)):
        raise HighRiskError("ITEM_INVALID", "tokens must be a list when present")
    for index, token in enumerate(tokens):
        if not isinstance(token, Mapping):
            raise HighRiskError("ITEM_INVALID", f"token {index}: must be a mapping")
        matched = token.get("matched")
        if matched is False:
            surface = token.get("generator", token.get("surface", ""))
            if isinstance(surface, str) and has_tone_or_teaching_mark(surface):
                return True
    return False


def _honorific_in_text(text: str, surfaces: Sequence[str]) -> bool:
    normalized = text.casefold()
    for surface in surfaces:
        if isinstance(surface, str) and surface.strip() and surface.casefold() in normalized:
            return True
    return False


def detect_high_risk_tags(item: Mapping[str, Any]) -> list[str]:
    """Return sorted unique high-risk tags for a curriculum item (AC1)."""
    if not isinstance(item, Mapping):
        raise HighRiskError("ITEM_INVALID", "item must be a mapping")

    tags = _normalize_tag_list(item.get("high_risk_tags"))

    kind = item.get("content_kind")
    if isinstance(kind, str):
        mapped = _CONTENT_KIND_TAGS.get(kind.strip().casefold())
        if mapped and mapped not in tags:
            tags.append(mapped)

    if _detect_from_tokens(item.get("tokens")) and TAG_TONE not in tags:
        tags.append(TAG_TONE)

    honorific_surfaces = item.get("honorific_surfaces")
    if honorific_surfaces is not None:
        if not isinstance(honorific_surfaces, Sequence) or isinstance(honorific_surfaces, (str, bytes)):
            raise HighRiskError("ITEM_INVALID", "honorific_surfaces must be a sequence of strings")
        surfaces = [s for s in honorific_surfaces if isinstance(s, str)]

        for section, claim in _claim_texts(item.get("claims")):
            text = claim.get("text")
            if isinstance(text, str) and _honorific_in_text(text, surfaces):
                if TAG_HONORIFIC not in tags:
                    tags.append(TAG_HONORIFIC)
                break

    for section, claim in _claim_texts(item.get("claims")):
        if section == "grammar_note" and TAG_GRAMMAR not in tags:
            tags.append(TAG_GRAMMAR)
        if section == "culture_note" and TAG_CULTURE not in tags:
            tags.append(TAG_CULTURE)
        topic = claim.get("topic")
        if isinstance(topic, str) and topic.strip().casefold() in _CULTURE_TOPICS:
            if TAG_CULTURE not in tags:
                tags.append(TAG_CULTURE)

    audience = item.get("audience")
    if audience == "child" or item.get("child_audience") is True:
        if TAG_CHILD not in tags:
            tags.append(TAG_CHILD)

    return sorted(tags)


def validate_publish_with_high_risk(
    *,
    high_risk_tags: Sequence[str],
    publish_label: str | None,
    reviewer_id: str | None,
) -> None:
    """High-risk items never auto-Beta; publish requires a reviewer id (AC2)."""
    tags = _normalize_tag_list(list(high_risk_tags))
    if not tags:
        return
    if publish_label == PUBLISH_LABEL_BETA:
        raise HighRiskError(
            "HIGH_RISK_BETA_FORBIDDEN",
            "high-risk items cannot publish with Beta label",
        )
    if publish_label is not None and publish_label.strip():
        if not isinstance(reviewer_id, str) or not reviewer_id.strip():
            raise HighRiskError(
                "HIGH_RISK_REVIEWER_REQUIRED",
                "high-risk items require reviewer_id before publish",
            )


def enforce_never_ai_only_route(decision: Mapping[str, Any]) -> dict[str, Any]:
    """If routing returned Beta while high-risk tags are present, force linguist queue."""
    if not isinstance(decision, Mapping):
        raise HighRiskError("DECISION_INVALID", "decision must be a mapping")
    tags = decision.get("high_risk_tags")
    if not isinstance(tags, Sequence) or isinstance(tags, (str, bytes)):
        return dict(decision)
    if not tags:
        return dict(decision)
    if decision.get("route") == "publish_beta":
        patched = dict(decision)
        patched["route"] = "linguist"
        patched["publish_label"] = None
        patched["can_publish"] = False
        patched["queue"] = "linguist"
        patched["reject_reason"] = "high_risk_never_ai_only"
        return patched
    return dict(decision)


def run_highrisk_stage(item: Mapping[str, Any]) -> dict[str, Any]:
    """Tag an item and report whether human review is mandatory."""
    tags = detect_high_risk_tags(item)
    return {
        "card_id": CARD_ID,
        "high_risk_tags": tags,
        "requires_human": bool(tags),
        "queue": "linguist" if tags else None,
        "never_ai_only": bool(tags),
    }


def run_highrisk_routing_stage(
    item: Mapping[str, Any],
    *,
    lint_stage: Mapping[str, Any] | None = None,
    regeneration_count: int = 0,
    extra_high_risk_tags: Sequence[str] | None = None,
) -> dict[str, Any]:
    """Detect tags, route via P4-064, and enforce never-AI-only (stage contract)."""
    detected = detect_high_risk_tags(item)
    merged = _normalize_tag_list([*detected, *(extra_high_risk_tags or ())])
    routed = run_routing_stage(
        item,
        lint_stage=lint_stage,
        regeneration_count=regeneration_count,
        high_risk_tags=merged,
    )
    enforced = enforce_never_ai_only_route(routed)
    validate_publish_with_high_risk(
        high_risk_tags=merged,
        publish_label=enforced.get("publish_label"),
        reviewer_id=item.get("reviewer_id"),
    )
    return {
        **enforced,
        "high_risk_stage": run_highrisk_stage(item),
        "high_risk_tags": merged,
    }
