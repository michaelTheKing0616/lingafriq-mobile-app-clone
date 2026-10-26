"""Human-first drafting policy: LLM may only supply variants and distractors (P4-131)."""

from __future__ import annotations

from collections.abc import Mapping, MutableMapping
from copy import deepcopy
from typing import Any

from tools.content_pipeline.grounded_prompt import (
    assert_prompt_text_grounded,
    build_grounded_prompt,
    flag_out_of_lexicon_tokens,
)

CARD_ID = "P4-131"

_LLM_ALLOWED_ROLES = frozenset({"variant", "distractor"})
_CORE_ROLES = frozenset(
    {
        "core",
        "stimulus",
        "correct",
        "dialogue",
        "dialogue_line",
        "grammar_note",
        "culture_note",
        "explanation",
    },
)


class DraftingPolicyError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def normalize_draft_source(raw: object) -> str:
    if not isinstance(raw, str) or not raw.strip():
        raise DraftingPolicyError("DRAFT_SOURCE_INVALID", "draft_source must be human or llm")
    source = raw.strip().lower()
    if source not in {"human", "llm"}:
        raise DraftingPolicyError("DRAFT_SOURCE_INVALID", "draft_source must be human or llm")
    return source


def normalize_draft_role(raw: object) -> str:
    if not isinstance(raw, str) or not raw.strip():
        raise DraftingPolicyError("DRAFT_ROLE_INVALID", "draft_role is required")
    return raw.strip().lower()


def validate_draft_source_policy(draft_source: str, draft_role: str) -> None:
    """Reject LLM-authored core content (AC1)."""
    source = normalize_draft_source(draft_source)
    role = normalize_draft_role(draft_role)
    if source == "llm" and role in _CORE_ROLES:
        raise DraftingPolicyError(
            "DRAFT_SOURCE_FORBIDDEN",
            "LLM may not author core item fields; use human drafting",
        )
    if source == "llm" and role not in _LLM_ALLOWED_ROLES:
        raise DraftingPolicyError(
            "DRAFT_SOURCE_FORBIDDEN",
            f"LLM drafting is limited to {_LLM_ALLOWED_ROLES}; got {role}",
        )


def _provenance_mapping(record: Mapping[str, Any]) -> Mapping[str, Any]:
    prov = record.get("provenance")
    if not isinstance(prov, Mapping):
        raise DraftingPolicyError("PROVENANCE_INVALID", "provenance must be a mapping")
    return prov


def validate_ai_assisted_immutable(
    before: Mapping[str, Any],
    after: Mapping[str, Any],
    *,
    draft_source: str,
) -> None:
    """Reject stripping ai_assisted on AI-drafted saves (AC3)."""
    source = normalize_draft_source(draft_source)
    if source != "llm":
        return
    before_prov = _provenance_mapping(before)
    after_prov = _provenance_mapping(after)
    if before_prov.get("ai_assisted") is True and after_prov.get("ai_assisted") is not True:
        raise DraftingPolicyError(
            "AI_FLAG_STRIP_FORBIDDEN",
            "ai_assisted cannot be removed from AI-drafted content",
        )


def apply_ai_assisted_for_save(
    record: MutableMapping[str, Any],
    *,
    draft_source: str,
) -> MutableMapping[str, Any]:
    """Ensure AI-drafted strings are saved with ai_assisted true (AC3)."""
    source = normalize_draft_source(draft_source)
    out = deepcopy(record)
    prov = out.get("provenance")
    if not isinstance(prov, MutableMapping):
        prov = {}
        out["provenance"] = prov
    if source == "llm":
        prov["ai_assisted"] = True
    return out


def save_drafted_string(
    record: MutableMapping[str, Any],
    *,
    draft_source: str,
    draft_role: str,
    text: str,
    approved_lexicon: list[Mapping[str, Any]],
    language_id: str,
    human_core_text: str = "",
) -> dict[str, Any]:
    """Validate policy, grounding, and provenance; return saved envelope metadata."""
    source = normalize_draft_source(draft_source)
    role = normalize_draft_role(draft_role)
    validate_draft_source_policy(source, role)
    candidate = text.strip()
    if not candidate:
        raise DraftingPolicyError("TEXT_EMPTY", "draft text is required")

    grounded_flags: list[str] = []
    prompt: dict[str, Any] | None = None
    if source == "llm":
        prompt = build_grounded_prompt(
            language_id=language_id,
            draft_role=role,
            human_core_text=human_core_text or candidate,
            approved_lexicon=approved_lexicon,
        )
        grounded_flags = flag_out_of_lexicon_tokens(candidate, approved_lexicon)
        if grounded_flags:
            raise DraftingPolicyError(
                "OUT_OF_LEXICON",
                f"tokens outside approved lexicon: {', '.join(grounded_flags)}",
            )
        assert_prompt_text_grounded(candidate, approved_lexicon)

    before = deepcopy(record)
    saved = apply_ai_assisted_for_save(record, draft_source=source)
    validate_ai_assisted_immutable(before, saved, draft_source=source)
    saved["draft_text"] = candidate
    saved["draft_role"] = role
    saved["draft_source"] = source
    return {
        "card_id": CARD_ID,
        "status": "saved",
        "draft_source": source,
        "draft_role": role,
        "ai_assisted": _provenance_mapping(saved).get("ai_assisted"),
        "out_of_lexicon": grounded_flags,
        "grounded_prompt": prompt,
        "record": saved,
    }


def review_llm_draft_submission(
    draft_source: str,
    draft_role: str,
) -> dict[str, Any]:
    """Gate an LLM draft before generation or save."""
    try:
        validate_draft_source_policy(draft_source, draft_role)
    except DraftingPolicyError as exc:
        return {
            "card_id": CARD_ID,
            "status": "rejected",
            "code": exc.code,
            "message": str(exc),
        }
    return {
        "card_id": CARD_ID,
        "status": "accepted",
        "draft_source": normalize_draft_source(draft_source),
        "draft_role": normalize_draft_role(draft_role),
    }
