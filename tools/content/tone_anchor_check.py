"""Restrict tonal Beta to lexicon-anchored tokens with three-way agreement (P5-017)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.pipeline.tone_agreement import (
    ToneAgreementError,
    evaluate_tone_agreement,
)

CARD_ID = "P5-017"
TONAL_LANGS: frozenset[str] = frozenset({"yo", "ig", "ha"})
TIER_C_TONAL_LANGS: frozenset[str] = frozenset({"yo", "ig"})


class ToneAnchorError(Exception):
    """Tone anchor gate failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class TonePairUnsourced(ToneAnchorError):
    """A minimal pair used for tone teaching lacks a registered source."""

    def __init__(self, pair_index: int, message: str) -> None:
        self.pair_index = pair_index
        super().__init__("TonePairUnsourced", message)


def _item_language(item: Mapping[str, Any]) -> str | None:
    for key in ("language", "lang", "language_code"):
        raw = item.get(key)
        if isinstance(raw, str) and raw.strip():
            return raw.strip().lower()
    return None


def _risk_tags(item: Mapping[str, Any]) -> frozenset[str]:
    raw = item.get("risk_tags")
    if not isinstance(raw, list):
        return frozenset()
    return frozenset(t.strip() for t in raw if isinstance(t, str) and t.strip())


def is_tone_teaching_item(item: Mapping[str, Any]) -> bool:
    if item.get("content_kind") == "tone_teaching":
        return True
    if "tone_teaching" in _risk_tags(item):
        return True
    block = item.get("tone_teaching")
    return isinstance(block, Mapping) and bool(block.get("minimal_pairs"))


def _iter_tone_pairs(item: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    pairs: list[Mapping[str, Any]] = []
    block = item.get("tone_teaching")
    if isinstance(block, Mapping):
        raw = block.get("minimal_pairs")
        if isinstance(raw, list):
            for entry in raw:
                if isinstance(entry, Mapping):
                    pairs.append(entry)
    root = item.get("minimal_pairs")
    if isinstance(root, list):
        for entry in root:
            if isinstance(entry, Mapping):
                pairs.append(entry)
    return pairs


def _pair_has_source(pair: Mapping[str, Any]) -> bool:
    source_id = pair.get("source_id")
    if isinstance(source_id, str) and source_id.strip():
        return True
    sources = pair.get("sources")
    if isinstance(sources, list) and any(isinstance(s, str) and s.strip() for s in sources):
        return True
    provenance = pair.get("provenance")
    if isinstance(provenance, Mapping):
        prov_sources = provenance.get("sources")
        if isinstance(prov_sources, list) and len(prov_sources) > 0:
            return True
    return False


def assert_tone_pairs_sourced(item: Mapping[str, Any]) -> None:
    """Tone teaching content may only use minimal pairs with a recorded source (AC3)."""
    if not is_tone_teaching_item(item):
        return
    pairs = _iter_tone_pairs(item)
    if not pairs:
        return
    for index, pair in enumerate(pairs):
        if not _pair_has_source(pair):
            raise TonePairUnsourced(
                index,
                f"minimal pair {index} requires source_id or provenance.sources",
            )


def evaluate_tone_beta_gate(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
) -> dict[str, Any]:
    """Return whether a tonal-language item may carry the Beta label (AC1–AC2)."""
    if not isinstance(item, Mapping):
        raise ToneAnchorError("ITEM_INVALID", "item must be a mapping")

    lang = _item_language(item)
    assert_tone_pairs_sourced(item)

    if lang not in TONAL_LANGS:
        return {
            "card_id": CARD_ID,
            "language": lang,
            "beta_allowed": True,
            "route": "auto",
            "reason": "NOT_TONAL_LANGUAGE",
            "tone_agreement": None,
        }

    tokens = item.get("tokens")
    if not isinstance(tokens, Sequence) or isinstance(tokens, (str, bytes)) or not tokens:
        return {
            "card_id": CARD_ID,
            "language": lang,
            "beta_allowed": False,
            "route": "linguist",
            "reason": "TOKENS_MISSING",
            "tone_agreement": None,
        }

    try:
        agreement = evaluate_tone_agreement(item, kit)
    except ToneAgreementError as exc:
        return {
            "card_id": CARD_ID,
            "language": lang,
            "beta_allowed": False,
            "route": "linguist",
            "reason": exc.code,
            "tone_agreement": None,
        }

    beta_allowed = agreement.get("can_publish") is True
    return {
        "card_id": CARD_ID,
        "language": lang,
        "beta_allowed": beta_allowed,
        "route": "auto" if beta_allowed else "linguist",
        "reason": None if beta_allowed else "TONE_NOT_ANCHORED",
        "tone_agreement": agreement,
    }


def assert_beta_label_tone_anchor(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
) -> None:
    """Reject Beta label on tonal items that fail lexicon anchor + agreement."""
    label = item.get("label")
    if label != "beta":
        return
    gate = evaluate_tone_beta_gate(item, kit)
    if not gate["beta_allowed"]:
        item_id = item.get("id")
        iid = item_id if isinstance(item_id, str) else "<unknown>"
        raise ToneAnchorError(
            "BETA_TONE_NOT_ANCHORED",
            f"item {iid} cannot be beta: {gate.get('reason')}",
        )


def partition_tier_c_beta_batch(
    items: Sequence[Mapping[str, Any]],
    kit: Mapping[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    """Split a publish batch: anchored Beta goes live; failures stay under review (AC4)."""
    live: list[dict[str, Any]] = []
    under_review: list[dict[str, Any]] = []

    for raw in items:
        if not isinstance(raw, Mapping):
            raise ToneAnchorError("ITEM_INVALID", "batch entries must be mappings")
        item = dict(raw)
        label = item.get("label")
        lang = _item_language(item)

        if label != "beta" or lang not in TIER_C_TONAL_LANGS:
            live.append(item)
            continue

        try:
            assert_tone_pairs_sourced(item)
            gate = evaluate_tone_beta_gate(item, kit)
        except TonePairUnsourced as exc:
            item["publish_state"] = "under_review"
            item["review_reason"] = exc.code
            under_review.append(item)
            continue

        if gate["beta_allowed"]:
            live.append(item)
        else:
            item["publish_state"] = "under_review"
            item["review_reason"] = gate.get("reason") or "TONE_NOT_ANCHORED"
            under_review.append(item)

    return {"live": live, "under_review": under_review}
