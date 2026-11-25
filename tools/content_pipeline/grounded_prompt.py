"""Lexicon-grounded LLM prompt assembly for human-first drafting (P4-131, ELEVATION §6.6)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from tools.content_engine.pipeline.generate import EXT01_CITATION, read_model_routing
from tools.content_engine.pipeline.generation_guard import (
    allowed_form_set,
    first_out_of_lexicon_token,
    iter_target_tokens,
)

CARD_ID = "P4-131"
_PROMPT_ID = "human-draft-llm-variant-v1"
_STACK_SECTION = "§6.6 Drafting (variants and distractors only)"


class GroundedPromptError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def approved_lexicon_forms(approved_lexicon: Sequence[Mapping[str, Any]]) -> frozenset[str]:
    """Normalize approved lexicon rows to an allowed surface-form set."""
    if not approved_lexicon:
        raise GroundedPromptError(
            "LEXICON_EMPTY",
            "approved lexicon must be non-empty for grounded prompts",
        )
    return allowed_form_set(approved_lexicon)


def flag_out_of_lexicon_tokens(
    text: str,
    approved_lexicon: Sequence[Mapping[str, Any]],
) -> list[str]:
    """Return unique out-of-lexicon tokens in order of appearance (AC2)."""
    allowed = approved_lexicon_forms(approved_lexicon)
    seen: set[str] = set()
    flagged: list[str] = []
    for token in iter_target_tokens(text):
        if token in allowed:
            continue
        if token not in seen:
            seen.add(token)
            flagged.append(token)
    return flagged


def build_grounded_prompt(
    *,
    language_id: str,
    draft_role: str,
    human_core_text: str,
    approved_lexicon: Sequence[Mapping[str, Any]],
    task_hint: str = "",
) -> dict[str, Any]:
    """Build a grounded LLM request payload on the approved lexicon only (AC2)."""
    lang = language_id.strip().lower()
    if not lang:
        raise GroundedPromptError("LANGUAGE_MISSING", "language_id is required")
    role = draft_role.strip().lower()
    if role not in {"variant", "distractor"}:
        raise GroundedPromptError(
            "PROMPT_ROLE_INVALID",
            "grounded prompts are only built for variant or distractor roles",
        )
    core = human_core_text.strip()
    if not core:
        raise GroundedPromptError("CORE_TEXT_MISSING", "human_core_text is required")
    allowed = approved_lexicon_forms(approved_lexicon)
    core_flags = flag_out_of_lexicon_tokens(core, approved_lexicon)
    routing = read_model_routing()
    lexicon_payload = [
        {"form": row.get("form"), "gloss": row.get("gloss")}
        for row in approved_lexicon
        if isinstance(row, Mapping) and isinstance(row.get("form"), str)
    ]
    return {
        "card_id": CARD_ID,
        "prompt_id": _PROMPT_ID,
        "language_id": lang,
        "draft_role": role,
        "human_core_text": core,
        "task_hint": task_hint.strip(),
        "allowed_lexicon": lexicon_payload,
        "allowed_forms": sorted(allowed),
        "core_out_of_lexicon": core_flags,
        "routing": routing,
        "ext01_citation": EXT01_CITATION,
        "stack_section": _STACK_SECTION,
        "instructions": (
            "Generate only an alternate surface form (variant) or a plausible wrong option "
            "(distractor). Use tokens from allowed_lexicon only. Do not rewrite the core item."
        ),
    }


def assert_prompt_text_grounded(
    candidate_text: str,
    approved_lexicon: Sequence[Mapping[str, Any]],
) -> None:
    """Hard-fail when candidate text uses tokens outside the approved lexicon."""
    offender = first_out_of_lexicon_token(candidate_text, approved_lexicon_forms(approved_lexicon))
    if offender is not None:
        raise GroundedPromptError(
            "OUT_OF_LEXICON",
            f"token not in approved lexicon: {offender}",
        )
