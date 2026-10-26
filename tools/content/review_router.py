"""Route content to paid linguist review by risk (P5-044, CURRICULUM §5, §3.4)."""

from __future__ import annotations

import json
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.pipeline.highrisk import detect_high_risk_tags

CARD_ID = "P5-044"
CORE_LEXICON_HEADWORD_CAP = 1500
AUTO_BETA_SAMPLE_MIN = 0.10
AUTO_BETA_SAMPLE_MAX = 0.15
THROUGHPUT_ITEMS_PER_HOUR_MIN = 60
THROUGHPUT_ITEMS_PER_HOUR_MAX = 150

QUEUE_LINGUIST_PAID = "linguist_paid"
ROUTE_MANDATORY = "linguist_mandatory"
ROUTE_BETA_SAMPLE = "linguist_beta_sample"
ROUTE_NONE = "none"

_QUALIFIED_LINGUIST_CREDENTIALS = frozenset({"academic", "postgraduate"})
_RISK_TAG_HIGH = frozenset(
    {
        "tone",
        "tone_teaching",
        "idiom",
        "proverb",
        "culture_history_religion",
        "honorific",
        "honorific_register",
        "grammar_explanation",
        "child_audience",
        "anglicised_pidgin",
    }
)


class ReviewRouterError(Exception):
    """Review routing failed. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def repo_root(root: Path | None = None) -> Path:
    if root is not None:
        return root.resolve()
    return Path(__file__).resolve().parents[2]


def _item_id(item: Mapping[str, Any]) -> str:
    raw = item.get("id")
    if not isinstance(raw, str) or not raw.strip():
        raise ReviewRouterError("ITEM_ID_MISSING", "item id is required")
    return raw.strip()


def _risk_tags_on_item(item: Mapping[str, Any]) -> frozenset[str]:
    raw = item.get("risk_tags")
    if not isinstance(raw, list):
        return frozenset()
    return frozenset(s.strip() for s in raw if isinstance(s, str) and s.strip())


def item_high_risk_tags(item: Mapping[str, Any]) -> list[str]:
    """Union schema risk_tags with §3.4 high-risk detection."""
    detected = detect_high_risk_tags(item)
    from_schema = sorted(_risk_tags_on_item(item) & _RISK_TAG_HIGH)
    merged: set[str] = set(detected)
    merged.update(from_schema)
    return sorted(merged)


def is_high_risk_item(item: Mapping[str, Any]) -> bool:
    return bool(item_high_risk_tags(item))


def load_core_lexicon_ids(lang: str, root: Path | None = None) -> frozenset[str]:
    """A1 pack ids plus any row with frequency_rank ≤ CORE_LEXICON_HEADWORD_CAP (§5 A1–A2 core)."""
    base = repo_root(root)
    path = base / "assets/data/lexicon/a1" / f"{lang.strip().lower()}.json"
    if not path.is_file():
        return frozenset()
    doc = json.loads(path.read_text(encoding="utf-8"))
    lexemes = doc.get("lexemes")
    if not isinstance(lexemes, list):
        return frozenset()
    ids: set[str] = set()
    for row in lexemes:
        if not isinstance(row, Mapping):
            continue
        rank = row.get("frequency_rank")
        if isinstance(rank, int) and rank > CORE_LEXICON_HEADWORD_CAP:
            continue
        lid = row.get("id")
        if isinstance(lid, str) and lid.strip():
            ids.add(lid.strip())
    return frozenset(ids)


def is_core_lexicon_item(item: Mapping[str, Any], core_ids: frozenset[str]) -> bool:
    if not core_ids:
        return False
    iid = _item_id(item)
    if iid in core_ids:
        return True
    for key in ("lexeme_id", "linked_lexeme_id", "headword_id"):
        ref = item.get(key)
        if isinstance(ref, str) and ref.strip() in core_ids:
            return True
    rank = item.get("frequency_rank")
    if isinstance(rank, int) and 1 <= rank <= CORE_LEXICON_HEADWORD_CAP:
        return True
    return item.get("core_lexicon") is True


def is_auto_beta_item(item: Mapping[str, Any]) -> bool:
    label = item.get("label")
    if isinstance(label, str) and label.strip().casefold() == "beta":
        return True
    route = item.get("machine_route")
    return route == "publish_beta"


@dataclass(frozen=True)
class LinguistRouteDecision:
    item_id: str
    route: str
    queue: str | None
    reason: str
    mandatory: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "card_id": CARD_ID,
            "item_id": self.item_id,
            "route": self.route,
            "queue": self.queue,
            "reason": self.reason,
            "mandatory": self.mandatory,
        }


def route_item_for_linguist_review(
    item: Mapping[str, Any],
    *,
    core_lexicon_ids: frozenset[str],
) -> LinguistRouteDecision:
    """Decide whether an item must enter the paid linguist queue (AC1–AC3)."""
    iid = _item_id(item)
    if is_high_risk_item(item):
        return LinguistRouteDecision(
            item_id=iid,
            route=ROUTE_MANDATORY,
            queue=QUEUE_LINGUIST_PAID,
            reason="high_risk",
            mandatory=True,
        )
    if is_core_lexicon_item(item, core_lexicon_ids):
        return LinguistRouteDecision(
            item_id=iid,
            route=ROUTE_MANDATORY,
            queue=QUEUE_LINGUIST_PAID,
            reason="core_lexicon",
            mandatory=True,
        )
    if is_auto_beta_item(item):
        return LinguistRouteDecision(
            item_id=iid,
            route=ROUTE_BETA_SAMPLE,
            queue=None,
            reason="auto_beta_pool",
            mandatory=False,
        )
    return LinguistRouteDecision(
        item_id=iid,
        route=ROUTE_NONE,
        queue=None,
        reason="no_linguist_route",
        mandatory=False,
    )


def sample_rate_for_auto_beta(rng: random.Random) -> float:
    """Pick a review sample rate in the 10–15% planning band (AC3)."""
    return rng.uniform(AUTO_BETA_SAMPLE_MIN, AUTO_BETA_SAMPLE_MAX)


def select_auto_beta_sample(
    items: Sequence[Mapping[str, Any]],
    *,
    rng: random.Random,
    core_lexicon_ids: frozenset[str] | None = None,
) -> list[LinguistRouteDecision]:
    """Sample 10–15% of Auto-Beta items that are not already mandatory (AC3)."""
    core = core_lexicon_ids if core_lexicon_ids is not None else frozenset()
    pool: list[Mapping[str, Any]] = []
    for item in items:
        if not isinstance(item, Mapping):
            raise ReviewRouterError("ITEM_INVALID", "items must be mappings")
        decision = route_item_for_linguist_review(item, core_lexicon_ids=core)
        if decision.route == ROUTE_BETA_SAMPLE:
            pool.append(item)
    if not pool:
        return []
    rate = sample_rate_for_auto_beta(rng)
    count = max(1, int(len(pool) * rate + 0.999)) if len(pool) > 0 else 0
    count = min(count, len(pool))
    chosen = rng.sample(pool, count)
    return [
        LinguistRouteDecision(
            item_id=_item_id(row),
            route=ROUTE_BETA_SAMPLE,
            queue=QUEUE_LINGUIST_PAID,
            reason="auto_beta_sample",
            mandatory=False,
        )
        for row in chosen
    ]


def is_qualified_linguist_reviewer(reviewer: Mapping[str, Any]) -> bool:
    """Paid linguists must be academics or postgrads in African-language linguistics (AC5)."""
    if reviewer.get("role") != "linguist":
        return False
    if reviewer.get("paid_linguist") is not True:
        return False
    cred = reviewer.get("credential")
    if isinstance(cred, str) and cred.strip().casefold() in _QUALIFIED_LINGUIST_CREDENTIALS:
        return reviewer.get("african_language_linguistics") is True
    return False


def assert_qualified_linguist_reviewer(reviewer: Mapping[str, Any]) -> None:
    rid = reviewer.get("reviewer_id")
    label = rid if isinstance(rid, str) else "<unknown>"
    if not is_qualified_linguist_reviewer(reviewer):
        raise ReviewRouterError(
            "LINGUIST_UNQUALIFIED",
            f"reviewer {label} must be a paid academic or postgraduate in African-language linguistics",
        )


def record_review_throughput(
    *,
    items_reviewed: int,
    elapsed_seconds: float,
    item_type: str,
) -> dict[str, Any]:
    """Log items/hour against the 60–150 planning range (AC4)."""
    if items_reviewed < 0:
        raise ReviewRouterError("THROUGHPUT_INVALID", "items_reviewed cannot be negative")
    if elapsed_seconds <= 0:
        raise ReviewRouterError("THROUGHPUT_INVALID", "elapsed_seconds must be positive")
    hours = elapsed_seconds / 3600.0
    rate = items_reviewed / hours
    in_band = THROUGHPUT_ITEMS_PER_HOUR_MIN <= rate <= THROUGHPUT_ITEMS_PER_HOUR_MAX
    return {
        "card_id": CARD_ID,
        "item_type": item_type,
        "items_reviewed": items_reviewed,
        "elapsed_seconds": elapsed_seconds,
        "items_per_hour": round(rate, 2),
        "planning_band_min": THROUGHPUT_ITEMS_PER_HOUR_MIN,
        "planning_band_max": THROUGHPUT_ITEMS_PER_HOUR_MAX,
        "within_planning_band": in_band,
    }


def build_linguist_review_plan(
    items: Sequence[Mapping[str, Any]],
    *,
    language_id: str,
    rng: random.Random,
) -> dict[str, Any]:
    """Full §5 routing: mandatory high-risk + core lexicon, plus Auto-Beta sample."""
    core_ids = load_core_lexicon_ids(language_id)
    mandatory: list[dict[str, Any]] = []
    beta_pool = 0
    for item in items:
        if not isinstance(item, Mapping):
            raise ReviewRouterError("ITEM_INVALID", "items must be mappings")
        decision = route_item_for_linguist_review(item, core_lexicon_ids=core_ids)
        if decision.mandatory:
            mandatory.append(decision.to_dict())
        elif decision.route == ROUTE_BETA_SAMPLE:
            beta_pool += 1
    sampled = [d.to_dict() for d in select_auto_beta_sample(items, rng=rng, core_lexicon_ids=core_ids)]
    all_routed_ids = {row["item_id"] for row in mandatory} | {row["item_id"] for row in sampled}
    high_risk_total = sum(1 for item in items if is_high_risk_item(item))
    core_total = sum(1 for item in items if is_core_lexicon_item(item, core_ids))
    return {
        "card_id": CARD_ID,
        "language_id": language_id.strip().lower(),
        "mandatory": mandatory,
        "beta_sample": sampled,
        "counts": {
            "items": len(items),
            "high_risk": high_risk_total,
            "core_lexicon": core_total,
            "auto_beta_pool": beta_pool,
            "routed_to_linguist": len(all_routed_ids),
        },
        "coverage": {
            "high_risk_percent": 100.0 if high_risk_total == 0 else round(100.0 * sum(1 for m in mandatory if m["reason"] == "high_risk") / high_risk_total, 2),
            "core_lexicon_percent": 100.0 if core_total == 0 else round(100.0 * sum(1 for m in mandatory if m["reason"] == "core_lexicon") / core_total, 2),
            "beta_sample_rate": round(len(sampled) / beta_pool, 4) if beta_pool else None,
        },
    }
