"""Spec tests for publish with quality labels (P4-067). Mode A."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.pipeline.publish import (  # noqa: E402
    CARD_ID,
    QUALITY_LABEL_BETA,
    QUALITY_LABEL_NATIVE_VERIFIED,
    QUALITY_LABEL_REVIEWED,
    PublishError,
    publish_item,
    run_publish_stage,
)
from tools.content_engine.pipeline.routing import route_scored_item  # noqa: E402


def _item(**overrides: Any) -> dict[str, Any]:
    base: dict[str, Any] = {
        "item_id": "item-fixture-1",
        "language": "yo",
        "review_required": False,
        "approved": False,
        "high_risk_tags": [],
    }
    base.update(overrides)
    return base


def test_P4_067_AC1_reviewer_approve_publishes_label_and_id() -> None:
    routing = route_scored_item(score=0.75, linters_pass=True)
    item = _item(review_required=True, approved=True)
    result = publish_item(
        item,
        routing_stage=routing,
        reviewer_id="rev-42",
        quality_label=QUALITY_LABEL_REVIEWED,
    )
    assert result["card_id"] == CARD_ID
    assert result["status"] == "published"
    assert result["quality_label"] == QUALITY_LABEL_REVIEWED
    assert result["reviewer_id"] == "rev-42"
    assert result["published"] is True


def test_P4_067_AC1_native_verified_label() -> None:
    routing = route_scored_item(score=0.75, linters_pass=True, high_risk_tags=["idiom"])
    item = _item(approved=True, high_risk_tags=["idiom"])
    result = publish_item(
        item,
        routing_stage=routing,
        reviewer_id="native-rev",
        quality_label=QUALITY_LABEL_NATIVE_VERIFIED,
    )
    assert result["quality_label"] == QUALITY_LABEL_NATIVE_VERIFIED


def test_P4_067_AC2_review_required_when_not_approved() -> None:
    routing = route_scored_item(score=0.75, linters_pass=True)
    item = _item(review_required=True, approved=False)
    with pytest.raises(PublishError) as exc:
        publish_item(
            item,
            routing_stage=routing,
            reviewer_id="rev-1",
            quality_label=QUALITY_LABEL_REVIEWED,
        )
    assert exc.value.code == "REVIEW_REQUIRED"


def test_P4_067_auto_beta_without_reviewer() -> None:
    routing = route_scored_item(score=0.95, linters_pass=True)
    assert routing["route"] == "publish_beta"
    result = publish_item(_item(), routing_stage=routing)
    assert result["quality_label"] == QUALITY_LABEL_BETA
    assert result["reviewer_id"] is None


def test_stage_contract_happy_path() -> None:
    routing = route_scored_item(score=0.95, linters_pass=True)
    stage = run_publish_stage(_item(), routing_stage=routing)
    assert stage["published"] is True
    assert stage["can_publish"] is True


def test_stage_contract_typed_error_path() -> None:
    routing = route_scored_item(score=0.75, linters_pass=True)
    item = _item(review_required=True, approved=False)
    stage = run_publish_stage(
        item,
        routing_stage=routing,
        reviewer_id="rev-1",
        quality_label=QUALITY_LABEL_REVIEWED,
    )
    assert stage["published"] is False
    assert stage["code"] == "REVIEW_REQUIRED"
