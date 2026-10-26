"""Tone-mark suggestions for AI bootstrap (P4-121, EXT-01 §3.9).

Yoruba uses Spitch diacritics restoration; other tonal kits use an injectable LLM
suggestion only when language linters pass. No live vendor calls.
"""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping
from typing import Any, Protocol

from tools.content_engine.pipeline.stage_lint import run_lint_stage

CARD_ID = "P4-121"
_YORUBA = "yo"
_SPITCH_VENDOR = "spitch"
_LLM_VENDOR = "llm"


class ToneSuggestError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class SpitchDiacriticsClient(Protocol):
    def restore(self, language: str, text: str) -> str:
        """Return tone-marked surface for the given language and plain text."""


class LlmToneClient(Protocol):
    def suggest(self, language: str, text: str, *, model: str) -> str:
        """Return tone-marked surface from an LLM draft."""


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def tone_suggester_for_language(language_id: str) -> str:
    """AC2: Spitch for Yoruba; LLM elsewhere."""
    code = language_id.strip().lower()
    if not code:
        raise ToneSuggestError("LANGUAGE_INVALID", "language_id required")
    if code == _YORUBA:
        return _SPITCH_VENDOR
    return _LLM_VENDOR


def lexicon_anchored(marked: str, seed_forms: frozenset[str]) -> bool:
    return nfc(marked.strip()) in seed_forms


def _lint_item_passes(language: str, marked: str, kit: Mapping[str, Any]) -> bool:
    stage = {
        "language": language,
        "items": [
            {
                "id": "tone-bootstrap-probe",
                "learner_facing": True,
                "tokens": [
                    {
                        "surface": marked,
                        "lexicon": marked,
                        "syllabic": False,
                    }
                ],
            }
        ],
    }
    report = run_lint_stage(stage, kit)
    return report.get("route") != "Reject"


def suggest_yoruba_via_spitch(
    plain: str,
    client: SpitchDiacriticsClient,
) -> dict[str, Any]:
    if not isinstance(plain, str) or not plain.strip():
        raise ToneSuggestError("TEXT_INVALID", "plain text required")
    marked = client.restore(_YORUBA, plain.strip())
    return {
        "vendor": _SPITCH_VENDOR,
        "plain": plain.strip(),
        "marked": nfc(marked),
    }


def suggest_via_llm(
    language: str,
    plain: str,
    kit: Mapping[str, Any],
    client: LlmToneClient,
    *,
    model: str,
) -> dict[str, Any]:
    if not isinstance(plain, str) or not plain.strip():
        raise ToneSuggestError("TEXT_INVALID", "plain text required")
    marked = client.suggest(language.strip().lower(), plain.strip(), model=model)
    marked_nfc = nfc(marked)
    if not _lint_item_passes(language, marked_nfc, kit):
        raise ToneSuggestError("TONE_VALIDATION_FAILED", "LLM tone suggestion failed linters")
    return {
        "vendor": _LLM_VENDOR,
        "model": model,
        "plain": plain.strip(),
        "marked": marked_nfc,
    }


def finalize_tone_suggestion(
    suggestion: Mapping[str, Any],
    seed_forms: frozenset[str],
) -> dict[str, Any]:
    """AC3: unanchored marks are flagged for linguist review, never auto-accepted."""
    marked = suggestion.get("marked")
    if not isinstance(marked, str) or not marked.strip():
        raise ToneSuggestError("SUGGESTION_INVALID", "marked surface required")
    anchored = lexicon_anchored(marked, seed_forms)
    out = dict(suggestion)
    out["lexicon_anchored"] = anchored
    if anchored:
        out["acceptance"] = "draft"
    else:
        out["acceptance"] = "linguist_review"
        out["auto_accepted"] = False
    return out
