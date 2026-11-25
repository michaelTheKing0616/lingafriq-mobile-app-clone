"""P5-046 weekly blind sampling (CURRICULUM §5)."""

from __future__ import annotations

import random
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.blind_sampler import (  # noqa: E402
    CARD_ID,
    ERROR_DEFINITION,
    MONTHLY_ITEMS_PER_LANGUAGE,
    WEEKLY_ITEMS_PER_LANGUAGE,
    BlindSamplerError,
    aggregate_blind_error_rate,
    is_learner_visible_error,
    is_live_item,
    pilot_tier_targets_for_language,
    sample_weekly_blind_batch,
    to_blind_review_payload,
)


def _live_item(
    item_id: str,
    label: str,
    lang: str = "sw",
) -> dict:
    return {
        "id": item_id,
        "language_id": lang,
        "label": label,
        "content_status": "live",
        "prompt": {"text": "habari"},
    }


def test_weekly_target_matches_monthly_pace() -> None:
    assert WEEKLY_ITEMS_PER_LANGUAGE * 4 == MONTHLY_ITEMS_PER_LANGUAGE


def test_blind_payload_hides_label() -> None:
    payload = to_blind_review_payload(_live_item("sw.1", "beta"))
    assert "label" not in payload
    assert payload["blind_review"] is True
    assert payload["item_id"] == "sw.1"


def test_stratified_sample_size_and_strata() -> None:
    items = []
    for i in range(80):
        items.append(_live_item(f"sw.b{i}", "beta"))
    for i in range(40):
        items.append(_live_item(f"sw.e{i}", "expert_reviewed"))
    for i in range(20):
        items.append(_live_item(f"sw.n{i}", "native_verified"))

    batch = sample_weekly_blind_batch("sw", items, rng=random.Random(7))
    assert batch["card_id"] == CARD_ID
    assert batch["sample_size"] == WEEKLY_ITEMS_PER_LANGUAGE
    strata = {row["stratum"] for row in batch["items"]}
    assert strata <= {"beta", "expert_reviewed", "native_verified"}


def test_sample_shortfall_when_stratum_too_small() -> None:
    items = [_live_item(f"yo.b{i}", "beta", lang="yo") for i in range(5)]
    items += [_live_item("yo.e0", "expert_reviewed", lang="yo")]
    batch = sample_weekly_blind_batch("yo", items, weekly_target=20, rng=random.Random(0))
    assert batch["shortfalls"]
    sf = next(s for s in batch["shortfalls"] if s["stratum"] == "expert_reviewed")
    assert sf["type"] == "SampleShortfall"
    assert sf["requested"] > sf["available"]


def test_pilot_targets_not_measured_results() -> None:
    targets = pilot_tier_targets_for_language("sw")
    assert targets["tier"] == "A"
    assert targets["measurement_status"] == "pilot_target"
    assert targets["beta_error_target"] == 0.03


def test_error_definition_categories() -> None:
    assert is_learner_visible_error({"has_error": True})
    assert is_learner_visible_error({"error_category": "tone_mark"})
    assert not is_learner_visible_error({"has_error": False})
    batch = sample_weekly_blind_batch(
        "sw",
        [_live_item("sw.1", "beta")],
        weekly_target=1,
        rng=random.Random(1),
    )
    assert batch["error_definition"] == ERROR_DEFINITION


def test_aggregate_error_rate_by_language_and_label() -> None:
    reviews = [
        {"language_id": "sw", "stratum": "beta", "has_error": False},
        {"language_id": "sw", "stratum": "beta", "has_error": True},
        {"language_id": "sw", "stratum": "expert_reviewed", "has_error": False},
    ]
    out = aggregate_blind_error_rate(reviews)
    beta = next(g for g in out["groups"] if g["stratum"] == "beta")
    assert beta["sample_size"] == 2
    assert beta["error_count"] == 1
    assert beta["error_rate"] == 0.5


def test_no_live_items_raises() -> None:
    draft = {"id": "sw.1", "language_id": "sw", "label": "beta", "content_status": "draft"}
    with pytest.raises(BlindSamplerError) as exc:
        sample_weekly_blind_batch("sw", [draft])
    assert exc.value.code == "NO_LIVE_ITEMS"


def test_is_live_item_flags() -> None:
    assert is_live_item({"live": True})
    assert is_live_item({"content_status": "live"})
    assert not is_live_item({"content_status": "draft"})
