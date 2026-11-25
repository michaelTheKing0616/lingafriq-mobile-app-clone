"""Typed linter results. Deterministic; no network or AI."""

from __future__ import annotations

from dataclasses import dataclass

_STATUSES = frozenset({"pass", "fail", "LINT_ERROR"})


@dataclass(frozen=True)
class Span:
    start: int
    end: int


@dataclass(frozen=True)
class LintResult:
    item_id: str
    rule_id: str
    span: Span
    status: str

    def __post_init__(self) -> None:
        if self.status not in _STATUSES:
            raise ValueError(
                f"status must be one of {sorted(_STATUSES)}, got {self.status!r}"
            )
