"""CI label exclusion rules for assembled content pools (P5-011, CURRICULUM §5–§6)."""

from __future__ import annotations

from typing import Any, Mapping, Sequence

BETA_EXCLUDED_POOLS: frozenset[str] = frozenset(
    {"checkpoint", "placement_test", "credential"}
)
CHILDREN_MODE_POOL = "children_mode"
_ALL_POOL_CONTEXTS = BETA_EXCLUDED_POOLS | {CHILDREN_MODE_POOL}

_GRAMMAR_CULTURE_RISK_TAGS: frozenset[str] = frozenset(
    {"grammar_explanation", "culture_history_religion"}
)
_EXPERT_OR_BETTER: frozenset[str] = frozenset({"expert", "native"})


class LabelRuleViolation(Exception):
    """A content pool violates label placement rules."""

    def __init__(self, rule: str, item_id: str, message: str) -> None:
        self.rule = rule
        self.item_id = item_id
        self.message = message
        super().__init__(f"LabelRuleViolation[{rule}] item={item_id}: {message}")


def _require_item_id(item: Mapping[str, Any]) -> str:
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise LabelRuleViolation("ITEM_ID_MISSING", "<unknown>", "item id is required")
    return item_id.strip()


def _item_label(item: Mapping[str, Any]) -> str | None:
    label = item.get("label")
    if label is None:
        return None
    if not isinstance(label, str):
        return None
    return label.strip()


def _risk_tags(item: Mapping[str, Any]) -> frozenset[str]:
    raw = item.get("risk_tags")
    if not isinstance(raw, list):
        return frozenset()
    tags: set[str] = set()
    for entry in raw:
        if isinstance(entry, str) and entry.strip():
            tags.add(entry.strip())
    return frozenset(tags)


def is_grammar_or_culture_explanation(item: Mapping[str, Any]) -> bool:
    """True when the item carries grammar or culture explanation risk."""
    return bool(_risk_tags(item) & _GRAMMAR_CULTURE_RISK_TAGS)


def assert_beta_allowed_in_pool(item: Mapping[str, Any], pool_context: str) -> None:
    """Beta items are forbidden in checkpoint, placement, and credential pools."""
    if pool_context not in BETA_EXCLUDED_POOLS:
        return
    item_id = _require_item_id(item)
    if _item_label(item) == "beta":
        raise LabelRuleViolation(
            "BETA_FORBIDDEN_POOL",
            item_id,
            f"beta items cannot appear in {pool_context} pools",
        )


def assert_grammar_culture_not_beta(item: Mapping[str, Any]) -> None:
    """Grammar and culture explanations are never Beta (CURRICULUM §5)."""
    if not is_grammar_or_culture_explanation(item):
        return
    item_id = _require_item_id(item)
    if _item_label(item) == "beta":
        raise LabelRuleViolation(
            "GRAMMAR_CULTURE_NOT_BETA",
            item_id,
            "grammar and culture explanation items cannot be beta",
        )


def assert_children_mode_minimum(item: Mapping[str, Any], pool_context: str) -> None:
    """Children's mode requires Expert-reviewed or better."""
    if pool_context != CHILDREN_MODE_POOL:
        return
    item_id = _require_item_id(item)
    label = _item_label(item)
    if label not in _EXPERT_OR_BETTER:
        raise LabelRuleViolation(
            "CHILDREN_MINIMUM_LABEL",
            item_id,
            "children_mode requires expert or native label",
        )


def lint_item_in_pool(item: Mapping[str, Any], pool_context: str) -> None:
    """Run all label rules that apply to one item within a pool context."""
    if pool_context not in _ALL_POOL_CONTEXTS and pool_context != "lesson":
        # Lesson pools still enforce grammar/culture-not-beta globally.
        assert_grammar_culture_not_beta(item)
        return
    assert_beta_allowed_in_pool(item, pool_context)
    assert_grammar_culture_not_beta(item)
    assert_children_mode_minimum(item, pool_context)


def lint_content_pool(pool_context: str, items: Sequence[Mapping[str, Any]]) -> None:
    """Validate every item in an assembled pool; raises on first violation."""
    for item in items:
        if not isinstance(item, Mapping):
            raise LabelRuleViolation(
                "ITEM_INVALID",
                "<unknown>",
                "pool entries must be item mappings",
            )
        lint_item_in_pool(item, pool_context)


def lint_all_pools(pools: Sequence[tuple[str, Sequence[Mapping[str, Any]]]]) -> None:
    """Validate multiple pools (checkpoint, placement, credentials, children's, etc.)."""
    for pool_context, items in pools:
        lint_content_pool(pool_context, items)
