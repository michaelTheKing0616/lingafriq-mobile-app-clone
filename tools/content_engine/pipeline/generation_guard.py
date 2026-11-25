"""Reject out-of-lexicon tokens and uncited culture or grammar claims (P4-056, CURRICULUM §3.1)."""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping, Sequence
from typing import Any

CARD_ID = "P4-056"
MAX_REGENERATION_ATTEMPTS = 2

_SECTIONS_NEED_CITATION = frozenset({"culture_note", "grammar_note"})
_TARGET_LANGUAGE_SECTIONS = frozenset({"dialogue_line"})
_PUNCT_STRIP = ".,!?;:\"'()[]"


class GenerationGuardError(Exception):
    """Guard validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def allowed_form_set(allowed_lexicon: Sequence[Mapping[str, Any]]) -> frozenset[str]:
    forms: set[str] = set()
    for lexeme in allowed_lexicon:
        if not isinstance(lexeme, Mapping):
            raise GenerationGuardError("LEXICON_INVALID", "lexeme entry must be a mapping")
        form = lexeme.get("form")
        if not isinstance(form, str) or not form.strip():
            raise GenerationGuardError("LEXICON_INVALID", "lexeme form required")
        forms.add(nfc(form.strip()))
    return frozenset(forms)


def iter_target_tokens(text: str) -> list[str]:
    normalized = nfc(text)
    tokens: list[str] = []
    for piece in normalized.split():
        token = piece.strip(_PUNCT_STRIP)
        if token:
            tokens.append(token)
    return tokens


def first_out_of_lexicon_token(
    text: str,
    allowed_forms: frozenset[str],
) -> str | None:
    for token in iter_target_tokens(text):
        if token not in allowed_forms:
            return token
    return None


def _citation_present(citation: object) -> bool:
    if not isinstance(citation, Mapping):
        return False
    source_id = citation.get("source_id")
    locator = citation.get("locator")
    return (
        isinstance(source_id, str)
        and source_id.strip()
        and isinstance(locator, str)
        and locator.strip()
    )


def validate_claims_lexicon_and_citations(
    claims: Sequence[object],
    allowed_forms: frozenset[str],
) -> None:
    if isinstance(claims, (str, bytes)) or not isinstance(claims, Sequence):
        raise GenerationGuardError(
            "ITEM_INVALID",
            "claims must be a list",
        )
    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise GenerationGuardError(
                "ITEM_INVALID",
                f"claim {index}: must be a mapping",
            )
        section = claim.get("section")
        text = claim.get("text")
        if not isinstance(section, str):
            raise GenerationGuardError(
                "ITEM_INVALID",
                f"claim {index}: section required",
            )
        if not isinstance(text, str):
            raise GenerationGuardError(
                "ITEM_INVALID",
                f"claim {index}: text required",
            )
        if section in _TARGET_LANGUAGE_SECTIONS and text.strip():
            offender = first_out_of_lexicon_token(text, allowed_forms)
            if offender is not None:
                raise GenerationGuardError(
                    "OUT_OF_LEXICON",
                    f"token not in allowed lexicon: {offender}",
                )
        if section in _SECTIONS_NEED_CITATION and text.strip():
            if not _citation_present(claim.get("citation")):
                raise GenerationGuardError(
                    "CLAIM_UNCITED",
                    f"claim {index}: culture or grammar claim requires citation",
                )


def next_regeneration_count(current: int) -> int:
    """Increment rejection count toward MAX_REGENERATION_ATTEMPTS (AC3)."""
    if current < 0:
        raise GenerationGuardError(
            "REGENERATION_INVALID",
            "regeneration count cannot be negative",
        )
    return current + 1


def may_regenerate(regeneration_count: int) -> bool:
    return regeneration_count < MAX_REGENERATION_ATTEMPTS


def run_generation_guard(
    item: Mapping[str, Any],
    allowed_lexicon: Sequence[Mapping[str, Any]],
    *,
    regeneration_count: int = 0,
) -> dict[str, Any]:
    """Validate a generated item; on failure return rejection metadata with bumped count."""
    if not isinstance(item, Mapping):
        raise GenerationGuardError("ITEM_INVALID", "item must be a mapping")
    allowed = allowed_form_set(allowed_lexicon)
    claims = item.get("claims")
    try:
        validate_claims_lexicon_and_citations(claims or (), allowed)
    except GenerationGuardError as exc:
        new_count = next_regeneration_count(regeneration_count)
        return {
            "card_id": CARD_ID,
            "status": "rejected",
            "code": exc.code,
            "message": str(exc),
            "regeneration_count": new_count,
            "may_regenerate": may_regenerate(new_count),
        }
    return {
        "card_id": CARD_ID,
        "status": "accepted",
        "regeneration_count": regeneration_count,
        "may_regenerate": may_regenerate(regeneration_count),
    }
