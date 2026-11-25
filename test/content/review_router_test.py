"""P5-044 paid linguist review routing (CURRICULUM §5)."""

from __future__ import annotations

import random
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.review_router import (  # noqa: E402
    AUTO_BETA_SAMPLE_MAX,
    AUTO_BETA_SAMPLE_MIN,
    CARD_ID,
    ROUTE_MANDATORY,
    ReviewRouterError,
    assert_qualified_linguist_reviewer,
    build_linguist_review_plan,
    is_qualified_linguist_reviewer,
    load_core_lexicon_ids,
    record_review_throughput,
    route_item_for_linguist_review,
    sample_rate_for_auto_beta,
    select_auto_beta_sample,
)


def _item(**overrides: object) -> dict:
    body: dict = {"id": "yo.item.fixture", "label": "expert", "risk_tags": []}
    body.update(overrides)
    return body


def test_high_risk_routes_mandatory_linguist() -> None:
    item = _item(risk_tags=["grammar_explanation"])
    decision = route_item_for_linguist_review(item, core_lexicon_ids=frozenset())
    assert decision.route == ROUTE_MANDATORY
    assert decision.queue == "linguist_paid"
    assert decision.mandatory is True


def test_core_lexicon_id_routes_mandatory() -> None:
    core = frozenset({"yo.lex.b26da58d1800"})
    item = _item(id="yo.lex.b26da58d1800", label="beta")
    decision = route_item_for_linguist_review(item, core_lexicon_ids=core)
    assert decision.mandatory is True
    assert decision.reason == "core_lexicon"


def test_auto_beta_sample_rate_in_band() -> None:
    rng = random.Random(42)
    for _ in range(20):
        rate = sample_rate_for_auto_beta(rng)
        assert AUTO_BETA_SAMPLE_MIN <= rate <= AUTO_BETA_SAMPLE_MAX


def test_auto_beta_sample_size_between_ten_and_fifteen_percent() -> None:
    rng = random.Random(7)
    items = [_item(id=f"yo.beta.{i}", label="beta") for i in range(100)]
    sampled = select_auto_beta_sample(items, rng=rng)
    assert 10 <= len(sampled) <= 15


def test_high_risk_coverage_hundred_percent_in_plan() -> None:
    rng = random.Random(1)
    items = [
        _item(id="yo.hr.1", risk_tags=["proverb"]),
        _item(id="yo.hr.2", high_risk_tags=["idiom"]),
        _item(id="yo.safe", label="beta"),
    ]
    plan = build_linguist_review_plan(items, language_id="yo", rng=rng)
    assert plan["coverage"]["high_risk_percent"] == 100.0
    assert plan["counts"]["high_risk"] == 2
    mandatory_ids = {row["item_id"] for row in plan["mandatory"]}
    assert mandatory_ids == {"yo.hr.1", "yo.hr.2"}


def test_core_lexicon_from_a1_pack() -> None:
    ids = load_core_lexicon_ids("yo")
    assert len(ids) >= 600
    first = next(iter(ids))
    item = _item(id=first, label="beta")
    decision = route_item_for_linguist_review(item, core_lexicon_ids=ids)
    assert decision.mandatory and decision.reason == "core_lexicon"


def test_qualified_linguist_reviewer() -> None:
    good = {
        "reviewer_id": "ling-yo-1",
        "role": "linguist",
        "paid_linguist": True,
        "credential": "academic",
        "african_language_linguistics": True,
    }
    assert is_qualified_linguist_reviewer(good)
    assert_qualified_linguist_reviewer(good)
    bad = dict(good, credential="undergraduate")
    assert not is_qualified_linguist_reviewer(bad)
    with pytest.raises(ReviewRouterError) as exc:
        assert_qualified_linguist_reviewer(bad)
    assert exc.value.code == "LINGUIST_UNQUALIFIED"


def test_throughput_planning_band() -> None:
    log = record_review_throughput(items_reviewed=120, elapsed_seconds=3600.0, item_type="lexeme")
    assert log["card_id"] == CARD_ID
    assert log["items_per_hour"] == 120.0
    assert log["within_planning_band"] is True


def test_throughput_outside_band_flagged() -> None:
    log = record_review_throughput(items_reviewed=30, elapsed_seconds=3600.0, item_type="dialogue")
    assert log["within_planning_band"] is False
