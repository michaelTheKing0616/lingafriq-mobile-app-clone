"""P5-011 label exclusion rules for assembled content pools."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.label_rules import (  # noqa: E402
    LabelRuleViolation,
    lint_all_pools,
    lint_content_pool,
    lint_item_in_pool,
)


def _base_item(**overrides: object) -> dict:
    body: dict = {
        "id": "yo.item.fixture",
        "label": "expert",
        "risk_tags": ["tone"],
    }
    body.update(overrides)
    return body


@pytest.mark.parametrize(
    "pool_context",
    ["checkpoint", "placement_test", "credential"],
)
def test_beta_forbidden_in_high_stakes_pools(pool_context: str) -> None:
    item = _base_item(label="beta")
    with pytest.raises(LabelRuleViolation) as exc:
        lint_item_in_pool(item, pool_context)
    assert exc.value.rule == "BETA_FORBIDDEN_POOL"
    assert exc.value.item_id == "yo.item.fixture"


def test_beta_allowed_in_lesson_pool() -> None:
    lint_item_in_pool(_base_item(label="beta"), "lesson")


@pytest.mark.parametrize(
    "pool_context",
    ["checkpoint", "placement_test", "credential"],
)
def test_expert_allowed_in_high_stakes_pools(pool_context: str) -> None:
    lint_item_in_pool(_base_item(label="expert"), pool_context)


def test_grammar_explanation_beta_fails_even_in_lesson() -> None:
    item = _base_item(label="beta", risk_tags=["grammar_explanation"])
    with pytest.raises(LabelRuleViolation) as exc:
        lint_item_in_pool(item, "lesson")
    assert exc.value.rule == "GRAMMAR_CULTURE_NOT_BETA"


def test_culture_explanation_beta_fails() -> None:
    item = _base_item(label="beta", risk_tags=["culture_history_religion"])
    with pytest.raises(LabelRuleViolation) as exc:
        lint_content_pool("lesson", [item])
    assert exc.value.rule == "GRAMMAR_CULTURE_NOT_BETA"


def test_children_mode_rejects_beta() -> None:
    item = _base_item(label="beta")
    with pytest.raises(LabelRuleViolation) as exc:
        lint_item_in_pool(item, "children_mode")
    assert exc.value.rule == "CHILDREN_MINIMUM_LABEL"


def test_children_mode_accepts_expert_and_native() -> None:
    lint_item_in_pool(_base_item(label="expert"), "children_mode")
    lint_item_in_pool(_base_item(label="native"), "children_mode")


def test_lint_all_pools_stops_at_first_violation() -> None:
    pools = [
        ("checkpoint", [_base_item(label="expert")]),
        ("credential", [_base_item(label="beta")]),
    ]
    with pytest.raises(LabelRuleViolation) as exc:
        lint_all_pools(pools)
    assert exc.value.rule == "BETA_FORBIDDEN_POOL"
