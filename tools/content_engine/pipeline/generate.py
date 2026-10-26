"""Grounded curriculum generation with configurable Gemini routing (P4-055, CURRICULUM §3.1).

No live API calls in this module: callers inject a client. Model ids come from env
(see EXT-01 companion doc). No invented language data.
"""

from __future__ import annotations

import json
import os
from collections.abc import Mapping, Sequence
from typing import Any, Protocol

from tools.content_engine.pipeline.anchoring import compute_lexeme_status

CARD_ID = "P4-055"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.9 Content and curriculum bootstrapping"
_GENERATION_MODEL_ENV = "CONTENT_ENGINE_GENERATION_MODEL"

_CLAIM_SECTIONS = frozenset(
    {"explanation", "culture_note", "grammar_note", "dialogue_line"},
)


class GenerateError(Exception):
    """Generation validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class GenerationClient(Protocol):
    def complete(self, model: str, payload: Mapping[str, Any]) -> str:
        """Return model output text (JSON object) for the grounded generation request."""


def read_model_routing() -> dict[str, str]:
    """Read generator model id from env; cite EXT-01 companion doc (AC3)."""
    model = os.environ.get(_GENERATION_MODEL_ENV, "").strip()
    if not model:
        raise GenerateError(
            "MODEL_NOT_CONFIGURED",
            f"set {_GENERATION_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "model": model,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def allowed_lexemes_for_generation(
    lexemes: Sequence[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    """Keep anchored lexemes only (CURRICULUM §3.1 stage 3)."""
    allowed: list[dict[str, Any]] = []
    for lexeme in lexemes:
        if not isinstance(lexeme, Mapping):
            raise GenerateError("LEXICON_INVALID", "lexeme entry must be a mapping")
        status = compute_lexeme_status(lexeme)
        if status["status"] == "anchored" and status["available_to_generation"]:
            allowed.append(dict(lexeme))
    return allowed


def build_generation_request(
    can_do: str,
    lexemes: Sequence[Mapping[str, Any]],
    *,
    pattern_library: Sequence[Mapping[str, Any]] | None = None,
    evidence_passages: Sequence[Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Assemble the grounded generation payload (AC1)."""
    target = can_do.strip() if isinstance(can_do, str) else ""
    if not target:
        raise GenerateError("CAN_DO_MISSING", "can-do target is required")
    allowed = allowed_lexemes_for_generation(lexemes)
    if not allowed:
        raise GenerateError(
            "LEXICON_EMPTY",
            "no anchored lexemes available for generation",
        )
    routing = read_model_routing()
    return {
        "card_id": CARD_ID,
        "can_do": target,
        "allowed_lexicon": allowed,
        "pattern_library": list(pattern_library or ()),
        "evidence_passages": list(evidence_passages or ()),
        "routing": routing,
        "response_schema": {
            "claims": [
                {
                    "section": "explanation",
                    "text": "string",
                    "citation": {"source_id": "string", "locator": "string"},
                },
            ],
        },
    }


def _require_citation(citation: object, claim_index: int) -> dict[str, str]:
    if not isinstance(citation, Mapping):
        raise GenerateError(
            "CITATION_MISSING",
            f"claim {claim_index}: citation must be a mapping",
        )
    source_id = citation.get("source_id")
    locator = citation.get("locator")
    if not isinstance(source_id, str) or not source_id.strip():
        raise GenerateError(
            "CITATION_MISSING",
            f"claim {claim_index}: source_id required",
        )
    if not isinstance(locator, str) or not locator.strip():
        raise GenerateError(
            "CITATION_MISSING",
            f"claim {claim_index}: locator required",
        )
    return {"source_id": source_id.strip(), "locator": locator.strip()}


def parse_generation_response(raw: str | Mapping[str, Any]) -> dict[str, Any]:
    """Parse structured JSON and require a citation per claim (AC2)."""
    if isinstance(raw, Mapping):
        data: Mapping[str, Any] = raw
    elif isinstance(raw, str):
        try:
            loaded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise GenerateError(
                "GENERATION_RESPONSE_INVALID",
                f"response is not valid JSON: {exc}",
            ) from exc
        if not isinstance(loaded, Mapping):
            raise GenerateError(
                "GENERATION_RESPONSE_INVALID",
                "response root must be a JSON object",
            )
        data = loaded
    else:
        raise GenerateError(
            "GENERATION_RESPONSE_INVALID",
            "response must be JSON text or a mapping",
        )

    claims = data.get("claims")
    if not isinstance(claims, Sequence) or isinstance(claims, (str, bytes)):
        raise GenerateError(
            "GENERATION_RESPONSE_INVALID",
            "claims must be a non-empty list",
        )
    if len(claims) == 0:
        raise GenerateError(
            "GENERATION_RESPONSE_INVALID",
            "claims must be a non-empty list",
        )

    parsed_claims: list[dict[str, Any]] = []
    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise GenerateError(
                "GENERATION_RESPONSE_INVALID",
                f"claim {index}: must be a mapping",
            )
        section = claim.get("section")
        text = claim.get("text")
        if not isinstance(section, str) or section not in _CLAIM_SECTIONS:
            raise GenerateError(
                "GENERATION_RESPONSE_INVALID",
                f"claim {index}: unsupported section",
            )
        if not isinstance(text, str) or not text.strip():
            raise GenerateError(
                "GENERATION_RESPONSE_INVALID",
                f"claim {index}: text required",
            )
        citation = _require_citation(claim.get("citation"), index)
        parsed_claims.append(
            {
                "section": section,
                "text": text.strip(),
                "citation": citation,
            },
        )

    return {"claims": parsed_claims}


def generate_grounded_item(
    can_do: str,
    lexemes: Sequence[Mapping[str, Any]],
    client: GenerationClient,
    *,
    pattern_library: Sequence[Mapping[str, Any]] | None = None,
    evidence_passages: Sequence[Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Call the injected client with only the allowed lexicon, then parse output."""
    request = build_generation_request(
        can_do,
        lexemes,
        pattern_library=pattern_library,
        evidence_passages=evidence_passages,
    )
    routing = request["routing"]
    model = routing["model"]
    raw = client.complete(model, request)
    item = parse_generation_response(raw)
    return {
        "can_do": request["can_do"],
        "models": {"generator": model},
        "ext01_citation": routing["ext01_citation"],
        "item": item,
    }


def make_fixture_client(
    response: str | Mapping[str, Any],
) -> GenerationClient:
    """Test helper: return a fixed JSON payload."""

    class _Fixture:
        def complete(self, _model: str, _payload: Mapping[str, Any]) -> str:
            if isinstance(response, Mapping):
                return json.dumps(response)
            return response

    return _Fixture()

