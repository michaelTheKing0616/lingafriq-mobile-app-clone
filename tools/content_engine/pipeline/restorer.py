"""Run NaijaML restorer for Yoruba tone check (P4-062, CURRICULUM §3.1 stage 7).

Injectable client only — no live model calls. Model id from env (EXT-01 companion doc).
"""

from __future__ import annotations

import os
from collections.abc import Mapping, Sequence
from typing import Any, Protocol

from tools.content_engine.pipeline.tone_agreement import (
    evaluate_tone_agreement,
    resolve_restorer,
)

CARD_ID = "P4-062"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.4 Content and curriculum bootstrapping"

_NAIJAML_MODEL_ENV = "CONTENT_ENGINE_NAIJAML_MODEL"
_YORUBA_CODE = "yo"
_NAIJAML_TOOL_ID = "naijaml"


class RestorerError(Exception):
    """Restorer validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class RestorerClient(Protocol):
    def restore(
        self,
        provider: str,
        model: str,
        payload: Mapping[str, Any],
    ) -> str:
        """Return diacritic-restored surface for the payload text."""


def read_restorer_routing() -> dict[str, str]:
    model = os.environ.get(_NAIJAML_MODEL_ENV, "").strip()
    if not model:
        raise RestorerError(
            "MODEL_NOT_CONFIGURED",
            f"set {_NAIJAML_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "naijaml_model": model,
        "provider": _NAIJAML_TOOL_ID,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def yoruba_restorer_enabled(kit: Mapping[str, Any], language: str) -> bool:
    if language.strip().lower() != _YORUBA_CODE:
        return False
    return resolve_restorer(kit) == _NAIJAML_TOOL_ID


def build_restorer_payload(
    language: str,
    surface: str,
    *,
    model: str,
) -> dict[str, Any]:
    if language.strip().lower() != _YORUBA_CODE:
        raise RestorerError("LANGUAGE_UNSUPPORTED", "NaijaML restorer applies to Yoruba only")
    if not isinstance(surface, str) or not surface.strip():
        raise RestorerError("TOKEN_INVALID", "surface text required for restoration")
    return {
        "card_id": CARD_ID,
        "provider": _NAIJAML_TOOL_ID,
        "model": model,
        "language": _YORUBA_CODE,
        "text": surface.strip(),
    }


def _item_language(item: Mapping[str, Any]) -> str:
    language = item.get("language")
    if not isinstance(language, str) or not language.strip():
        raise RestorerError("ITEM_INVALID", "item.language required")
    return language.strip().lower()


def _item_tokens(item: Mapping[str, Any]) -> list[dict[str, Any]]:
    tokens = item.get("tokens")
    if not isinstance(tokens, Sequence) or isinstance(tokens, (str, bytes)):
        raise RestorerError("ITEM_INVALID", "item.tokens must be a list")
    if not tokens:
        raise RestorerError("ITEM_INVALID", "item.tokens must be non-empty")
    out: list[dict[str, Any]] = []
    for index, token in enumerate(tokens):
        if not isinstance(token, Mapping):
            raise RestorerError("TOKEN_INVALID", f"token {index}: must be a mapping")
        out.append(dict(token))
    return out


def apply_naijaml_restorer(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
    client: RestorerClient,
) -> dict[str, Any]:
    """Run NaijaML on each token surface; attach restorer forms for three-way agreement (AC1)."""
    if not isinstance(item, Mapping):
        raise RestorerError("ITEM_INVALID", "item must be a mapping")
    if not isinstance(kit, Mapping):
        raise RestorerError("KIT_INVALID", "kit must be a mapping")

    language = _item_language(item)
    if not yoruba_restorer_enabled(kit, language):
        raise RestorerError(
            "RESTORER_NOT_CONFIGURED",
            "Yoruba kit must set tone_restorer to naijaml for this stage",
        )

    routing = read_restorer_routing()
    model = routing["naijaml_model"]
    enriched_tokens = _item_tokens(item)

    for index, token in enumerate(enriched_tokens):
        generator = token.get("generator", token.get("surface"))
        if not isinstance(generator, str):
            raise RestorerError("TOKEN_INVALID", f"token {index}: generator surface required")
        payload = build_restorer_payload(language, generator, model=model)
        try:
            restored = client.restore(_NAIJAML_TOOL_ID, model, payload)
        except Exception as exc:
            return {
                "card_id": CARD_ID,
                "status": "RESTORER_UNAVAILABLE",
                "code": "RESTORER_UNAVAILABLE",
                "message": str(exc),
                "can_publish": False,
                "route": "linguist",
                "provider": _NAIJAML_TOOL_ID,
                "model": model,
                "ext01_citation": routing["ext01_citation"],
            }
        if not isinstance(restored, str):
            return {
                "card_id": CARD_ID,
                "status": "RESTORER_UNAVAILABLE",
                "code": "RESTORER_UNAVAILABLE",
                "message": "restorer returned non-text",
                "can_publish": False,
                "route": "linguist",
                "provider": _NAIJAML_TOOL_ID,
                "model": model,
                "ext01_citation": routing["ext01_citation"],
            }
        token["restorer"] = restored

    enriched_item = {**dict(item), "tokens": enriched_tokens}
    agreement = evaluate_tone_agreement(enriched_item, kit)
    return {
        "card_id": CARD_ID,
        "status": "ok",
        "can_publish": agreement.get("can_publish", False),
        "route": agreement.get("route"),
        "provider": _NAIJAML_TOOL_ID,
        "model": model,
        "restored_item": enriched_item,
        "tone_agreement": agreement,
        "ext01_citation": routing["ext01_citation"],
    }


def run_restorer_stage(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
    client: RestorerClient,
) -> dict[str, Any]:
    """Stage contract: restore then evaluate three-way tone agreement."""
    return apply_naijaml_restorer(item, kit, client)
