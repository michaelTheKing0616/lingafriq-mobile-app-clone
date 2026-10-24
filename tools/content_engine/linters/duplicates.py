"""Near-identical dialogue and repeated-line lint (CURRICULUM §3.3)."""

from __future__ import annotations

from collections import Counter
from collections.abc import Mapping, Sequence
from dataclasses import dataclass

from tools.content_engine.linters.types import LintResult, Span

_RULE_PASS = "DUPLICATES"
_RULE_DIALOGUE = "DUPLICATE_DIALOGUE"
_RULE_REPEATED = "REPEATED_LINE"


@dataclass(frozen=True)
class DuplicateResult(LintResult):
    left_id: str = ""
    right_id: str = ""


def lint_duplicates(bundle: Mapping, kit: object) -> DuplicateResult:
    """Fail near-identical dialogues first; then lines past the kit repeat cap."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    duplicate_config = kit["duplicate_config"]
    dialogue_similarity = duplicate_config["dialogue_similarity"]
    repeat_cap = duplicate_config["repeat_cap"]

    item_id = bundle["id"]
    dialogues = bundle["dialogues"]
    for index, left in enumerate(dialogues):
        left_tokens = _dialogue_tokens(left["lines"])
        for right in dialogues[index + 1 :]:
            similarity = _jaccard(left_tokens, _dialogue_tokens(right["lines"]))
            if similarity >= dialogue_similarity:
                ordered = sorted((left["id"], right["id"]))
                return DuplicateResult(
                    item_id=item_id,
                    rule_id=_RULE_DIALOGUE,
                    span=Span(0, 0),
                    status="fail",
                    left_id=ordered[0],
                    right_id=ordered[1],
                )

    for unit in bundle["units"]:
        counts = Counter(line.strip() for line in unit["lines"])
        if any(count > repeat_cap for count in counts.values()):
            return DuplicateResult(
                item_id=item_id,
                rule_id=_RULE_REPEATED,
                span=Span(0, 0),
                status="fail",
                left_id=unit["id"],
                right_id="",
            )

    return DuplicateResult(
        item_id=item_id,
        rule_id=_RULE_PASS,
        span=Span(0, 0),
        status="pass",
        left_id="",
        right_id="",
    )


def _dialogue_tokens(lines: Sequence[str]) -> set[str]:
    return set(" ".join(lines).casefold().split())


def _jaccard(left: set[str], right: set[str]) -> float:
    if not left or not right:
        return 0.0
    return len(left & right) / len(left | right)
