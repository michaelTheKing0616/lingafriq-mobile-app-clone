"""Weekly stratified blind sampling of live items (P5-046, CURRICULUM §5–§6)."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from datetime import UTC, date, datetime
from typing import Any, Mapping, MutableMapping, Sequence

CARD_ID = "P5-046"
MONTHLY_ITEMS_PER_LANGUAGE = 200
SAMPLING_WEEKS_PER_MONTH = 4
WEEKLY_ITEMS_PER_LANGUAGE = MONTHLY_ITEMS_PER_LANGUAGE // SAMPLING_WEEKS_PER_MONTH

ERROR_DEFINITION = (
    "learner-visible mistake that changes meaning, misspells, mis-marks tone, "
    "or is clearly unnatural"
)
ERROR_CATEGORIES = frozenset(
    {"wrong_meaning", "misspelling", "tone_mark", "unnatural", "offensive"}
)

_STRATA_LABELS = ("beta", "expert_reviewed", "native_verified")
_LABEL_ALIASES: dict[str, str] = {
    "beta": "beta",
    "expert": "expert_reviewed",
    "expert_reviewed": "expert_reviewed",
    "native": "native_verified",
    "native_verified": "native_verified",
}

_LANGUAGE_TIER: dict[str, str] = {
    "sw": "A",
    "zu": "B",
    "xh": "B",
    "ha": "B",
    "pcm": "B",
    "yo": "C",
    "ig": "C",
}

_PILOT_TIER_TARGETS: dict[str, dict[str, Any]] = {
    "A": {
        "beta_error_target": 0.03,
        "expert_reviewed_error_target": 0.01,
        "measurement_status": "pilot_target",
    },
    "B": {
        "beta_error_target": 0.05,
        "expert_reviewed_error_target": 0.015,
        "measurement_status": "pilot_target",
    },
    "C": {
        "beta_error_target": 0.05,
        "expert_reviewed_error_target": 0.015,
        "measurement_status": "pilot_target",
    },
}


class BlindSamplerError(Exception):
    """Blind sampling failed. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class SampleShortfall:
    """A stratum could not supply its proportional weekly quota (AC4)."""

    language_id: str
    stratum: str
    requested: int
    available: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "type": "SampleShortfall",
            "language_id": self.language_id,
            "stratum": self.stratum,
            "requested": self.requested,
            "available": self.available,
        }


def normalize_quality_label(raw: Any) -> str | None:
    if not isinstance(raw, str) or not raw.strip():
        return None
    return _LABEL_ALIASES.get(raw.strip().casefold())


def is_live_item(item: Mapping[str, Any]) -> bool:
    """Live catalog items eligible for ongoing blind sampling."""
    if item.get("live") is True:
        return True
    status = item.get("content_status")
    return isinstance(status, str) and status.strip().casefold() == "live"


def _item_id(item: Mapping[str, Any]) -> str:
    raw = item.get("id")
    if not isinstance(raw, str) or not raw.strip():
        raise BlindSamplerError("ITEM_ID_MISSING", "item id is required")
    return raw.strip()


def _language_id(item: Mapping[str, Any]) -> str:
    raw = item.get("language_id") or item.get("language")
    if not isinstance(raw, str) or not raw.strip():
        raise BlindSamplerError("LANGUAGE_INVALID", "language_id is required")
    return raw.strip().lower()


def pilot_tier_targets_for_language(language_id: str) -> dict[str, Any]:
    """Tier error ceilings are pilot targets until measured (AC3)."""
    lang = language_id.strip().lower()
    tier = _LANGUAGE_TIER.get(lang, "B")
    row = dict(_PILOT_TIER_TARGETS[tier])
    row.update({"card_id": CARD_ID, "language_id": lang, "tier": tier})
    return row


def is_learner_visible_error(judgment: Mapping[str, Any]) -> bool:
    """Whether a blind review counts as an error (AC2)."""
    if not isinstance(judgment, Mapping):
        raise BlindSamplerError("JUDGMENT_INVALID", "judgment must be a mapping")
    flagged = judgment.get("has_error")
    if isinstance(flagged, bool):
        return flagged
    category = judgment.get("error_category")
    if isinstance(category, str) and category.strip() in ERROR_CATEGORIES:
        return True
    return False


def to_blind_review_payload(item: Mapping[str, Any]) -> dict[str, Any]:
    """Strip quality label so review is blind."""
    item_id = _item_id(item)
    payload = {k: v for k, v in item.items() if k != "label"}
    payload["item_id"] = item_id
    payload["blind_review"] = True
    return payload


def _stratify_live_items(
    items: Sequence[Mapping[str, Any]],
    language_id: str,
) -> dict[str, list[Mapping[str, Any]]]:
    lang = language_id.strip().lower()
    buckets: dict[str, list[Mapping[str, Any]]] = {s: [] for s in _STRATA_LABELS}
    for item in items:
        if not isinstance(item, Mapping):
            continue
        if not is_live_item(item):
            continue
        if _language_id(item) != lang:
            continue
        label = normalize_quality_label(item.get("label"))
        if label is None or label not in buckets:
            continue
        buckets[label].append(item)
    return buckets


def _allocate_stratum_counts(
    stratum_sizes: Mapping[str, int],
    weekly_target: int,
) -> dict[str, int]:
    total = sum(stratum_sizes.values())
    if total <= 0:
        return {k: 0 for k in stratum_sizes}
    raw: dict[str, float] = {
        s: weekly_target * (stratum_sizes[s] / total) for s in stratum_sizes
    }
    floors = {s: int(math.floor(raw[s])) for s in stratum_sizes}
    assigned = sum(floors.values())
    remainder = weekly_target - assigned
    order = sorted(stratum_sizes.keys(), key=lambda s: (raw[s] - floors[s]), reverse=True)
    counts = dict(floors)
    for index, stratum in enumerate(order):
        if remainder <= 0:
            break
        if stratum_sizes[stratum] > counts[stratum]:
            counts[stratum] += 1
            remainder -= 1
        elif index == len(order) - 1 and remainder > 0:
            counts[stratum] += remainder
            remainder = 0
    return counts


def sample_weekly_blind_batch(
    language_id: str,
    live_items: Sequence[Mapping[str, Any]],
    *,
    week_of: date | None = None,
    rng: random.Random | None = None,
    weekly_target: int = WEEKLY_ITEMS_PER_LANGUAGE,
) -> dict[str, Any]:
    """Stratified random weekly sample for blind review (AC1)."""
    lang = language_id.strip().lower()
    if weekly_target <= 0:
        raise BlindSamplerError("TARGET_INVALID", "weekly_target must be positive")

    buckets = _stratify_live_items(live_items, lang)
    sizes = {s: len(buckets[s]) for s in _STRATA_LABELS}
    total_live = sum(sizes.values())
    if total_live == 0:
        raise BlindSamplerError("NO_LIVE_ITEMS", f"no live items for language {lang}")

    target = min(weekly_target, total_live)
    quotas = _allocate_stratum_counts(sizes, target)
    picker = rng or random.Random()
    shortfalls: list[dict[str, Any]] = []
    selected: list[dict[str, Any]] = []

    for stratum in _STRATA_LABELS:
        pool = list(buckets[stratum])
        want = quotas.get(stratum, 0)
        ideal = (
            int(math.ceil(weekly_target * sizes[stratum] / total_live))
            if sizes[stratum]
            else 0
        )
        if ideal > len(pool):
            shortfalls.append(
                SampleShortfall(lang, stratum, ideal, len(pool)).to_dict(),
            )
        if want > len(pool):
            want = len(pool)
        if want <= 0:
            continue
        picked = picker.sample(pool, want)
        for item in picked:
            blind = to_blind_review_payload(item)
            blind["stratum"] = stratum
            blind["language_id"] = lang
            selected.append(blind)

    week = week_of or datetime.now(UTC).date()
    return {
        "card_id": CARD_ID,
        "language_id": lang,
        "week_of": week.isoformat(),
        "weekly_target": weekly_target,
        "sample_size": len(selected),
        "monthly_pace_items": MONTHLY_ITEMS_PER_LANGUAGE,
        "error_definition": ERROR_DEFINITION,
        "pilot_tier_targets": pilot_tier_targets_for_language(lang),
        "shortfalls": shortfalls,
        "items": selected,
    }


def aggregate_blind_error_rate(
    reviews: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    """Summarise blind judgments by language and label stratum."""
    by_key: dict[tuple[str, str], list[bool]] = {}
    for row in reviews:
        if not isinstance(row, Mapping):
            raise BlindSamplerError("REVIEW_INVALID", "review row must be a mapping")
        lang = row.get("language_id")
        stratum = row.get("stratum") or normalize_quality_label(row.get("label"))
        if not isinstance(lang, str) or not isinstance(stratum, str):
            raise BlindSamplerError("REVIEW_INVALID", "language_id and stratum required")
        key = (lang.strip().lower(), stratum.strip())
        by_key.setdefault(key, []).append(is_learner_visible_error(row))

    groups: list[dict[str, Any]] = []
    for (lang, stratum), flags in sorted(by_key.items()):
        n = len(flags)
        errors = sum(1 for f in flags if f)
        groups.append(
            {
                "language_id": lang,
                "stratum": stratum,
                "sample_size": n,
                "error_count": errors,
                "error_rate": (errors / n) if n else None,
                "pilot_tier_targets": pilot_tier_targets_for_language(lang),
            },
        )
    return {"card_id": CARD_ID, "groups": groups}


def append_weekly_sample_record(
    store: MutableMapping[str, Any],
    batch: Mapping[str, Any],
) -> None:
    """Persist the latest weekly draw under store['weekly_batches']."""
    lang = batch.get("language_id")
    if not isinstance(lang, str):
        raise BlindSamplerError("BATCH_INVALID", "batch.language_id is required")
    weekly = store.setdefault("weekly_batches", {})
    if not isinstance(weekly, MutableMapping):
        raise BlindSamplerError("STORE_INVALID", "weekly_batches must be a mapping")
    weekly[lang.strip().lower()] = dict(batch)
