"""Back-translation MT stage (P4-059, CURRICULUM §3.1 stage 5).

Injectable client only — no live API calls. Model ids from env (EXT-01 companion doc).
"""

from __future__ import annotations

import os
import re
from collections.abc import Mapping
from difflib import SequenceMatcher
from typing import Any, Protocol

CARD_ID = "P4-059"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.7 Machine translation"

_GOOGLE_MT_MODEL_ENV = "CONTENT_ENGINE_GOOGLE_MT_MODEL"
_MADLAD_MT_MODEL_ENV = "CONTENT_ENGINE_MADLAD_MT_MODEL"

GOOGLE_CLOUD_LANGUAGE_CODES = frozenset({"yo", "ig", "ha", "sw", "xh", "zu"})

# Pilot-calibrated disagree threshold (CURRICULUM §3.1: flag only, no auto-reject).
DEFAULT_DISAGREE_THRESHOLD = 0.65

_WHITESPACE = re.compile(r"\s+")


class BacktranslateError(Exception):
    """Back-translation validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class MtClient(Protocol):
    def translate(
        self,
        provider: str,
        model: str,
        payload: Mapping[str, Any],
    ) -> str:
        """Return English back-translation text for the payload."""


def read_backtranslate_routing() -> dict[str, str]:
    google_model = os.environ.get(_GOOGLE_MT_MODEL_ENV, "").strip()
    if not google_model:
        raise BacktranslateError(
            "MODEL_NOT_CONFIGURED",
            f"set {_GOOGLE_MT_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    madlad_model = os.environ.get(_MADLAD_MT_MODEL_ENV, "").strip()
    if not madlad_model:
        raise BacktranslateError(
            "MODEL_NOT_CONFIGURED",
            f"set {_MADLAD_MT_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "google_mt_model": google_model,
        "madlad_mt_model": madlad_model,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def mt_provider_for_language(language: str) -> str:
    """Route stage-1 languages to Google Cloud Translation; long tail to MADLAD-400."""
    code = language.strip().lower()
    if not code:
        raise BacktranslateError("ITEM_INVALID", "language code required")
    if code in ("pcm", "pidgin"):
        return "madlad"
    if code in GOOGLE_CLOUD_LANGUAGE_CODES:
        return "google_cloud"
    return "madlad"


def _normalize_english(text: str) -> str:
    return _WHITESPACE.sub(" ", text.strip().casefold())


def semantic_similarity(intended_meaning: str, back_translated: str) -> float:
    """Score back-translation against intended English meaning (0–1)."""
    left = _normalize_english(intended_meaning)
    right = _normalize_english(back_translated)
    if not left and not right:
        return 1.0
    if not left or not right:
        return 0.0
    return float(SequenceMatcher(None, left, right).ratio())


def build_mt_payload(
    language: str,
    target_text: str,
    *,
    provider: str,
    model: str,
) -> dict[str, Any]:
    if not isinstance(target_text, str) or not target_text.strip():
        raise BacktranslateError("ITEM_INVALID", "target_text required")
    return {
        "card_id": CARD_ID,
        "provider": provider,
        "model": model,
        "source_language": language.strip().lower(),
        "target_language": "en",
        "text": target_text.strip(),
    }


def _item_fields(item: Mapping[str, Any]) -> tuple[str, str, str]:
    language = item.get("language")
    target_text = item.get("target_text")
    intended = item.get("intended_meaning")
    if not isinstance(language, str) or not language.strip():
        raise BacktranslateError("ITEM_INVALID", "language required")
    if not isinstance(target_text, str) or not target_text.strip():
        raise BacktranslateError("ITEM_INVALID", "target_text required")
    if not isinstance(intended, str) or not intended.strip():
        raise BacktranslateError("ITEM_INVALID", "intended_meaning required")
    return language.strip(), target_text.strip(), intended.strip()


def run_backtranslate(
    item: Mapping[str, Any],
    client: MtClient,
    *,
    disagree_threshold: float = DEFAULT_DISAGREE_THRESHOLD,
) -> dict[str, Any]:
    """Back-translate target text; flag low similarity without auto-reject (AC2)."""
    if not 0.0 <= disagree_threshold <= 1.0:
        raise BacktranslateError(
            "THRESHOLD_INVALID",
            "disagree_threshold must be between 0 and 1",
        )
    routing = read_backtranslate_routing()
    language, target_text, intended_meaning = _item_fields(item)
    provider = mt_provider_for_language(language)
    model = (
        routing["google_mt_model"]
        if provider == "google_cloud"
        else routing["madlad_mt_model"]
    )
    payload = build_mt_payload(
        language,
        target_text,
        provider=provider,
        model=model,
    )
    try:
        english = client.translate(provider, model, payload)
    except Exception as exc:
        return {
            "card_id": CARD_ID,
            "status": "BT_UNAVAILABLE",
            "code": "BT_UNAVAILABLE",
            "message": str(exc),
            "can_publish": False,
            "provider": provider,
            "model": model,
            "ext01_citation": routing["ext01_citation"],
        }

    if not isinstance(english, str):
        return {
            "card_id": CARD_ID,
            "status": "BT_UNAVAILABLE",
            "code": "BT_UNAVAILABLE",
            "message": "translator returned non-text",
            "can_publish": False,
            "provider": provider,
            "model": model,
            "ext01_citation": routing["ext01_citation"],
        }

    similarity = semantic_similarity(intended_meaning, english)
    flagged = similarity < disagree_threshold
    bt_status = "flagged" if flagged else "pass"

    return {
        "card_id": CARD_ID,
        "status": "ok",
        "can_publish": True,
        "flagged": flagged,
        "provider": provider,
        "model": model,
        "back_translation": {
            "text": english,
            "similarity": similarity,
            "status": bt_status,
        },
        "features": {"backtranslation_similarity": similarity},
        "ext01_citation": routing["ext01_citation"],
    }
