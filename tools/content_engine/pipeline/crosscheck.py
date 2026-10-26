"""Independent cross-check with a second model family (P4-057, CURRICULUM §3.1 stage 4).

Injectable client only — no live API calls. Model ids from env (EXT-01 companion doc).
"""

from __future__ import annotations

import json
import os
from collections.abc import Mapping, Sequence
from typing import Any, Protocol

CARD_ID = "P4-057"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.9 Content and curriculum bootstrapping"

_CROSSCHECK_MODEL_ENV = "CONTENT_ENGINE_CROSSCHECK_MODEL"
_TIEBREAK_MODEL_ENV = "CONTENT_ENGINE_TIEBREAK_MODEL"

class CrosscheckError(Exception):
    """Cross-check validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class CrosscheckClient(Protocol):
    def complete(self, model: str, payload: Mapping[str, Any]) -> str:
        """Return model output text (JSON object) for the cross-check request."""


def model_family(model_id: str) -> str:
    lower = model_id.lower()
    if "gemini" in lower or "palm" in lower:
        return "google"
    if "gpt" in lower or lower.startswith("o1") or lower.startswith("o3"):
        return "openai"
    if "claude" in lower or "sonnet" in lower:
        return "anthropic"
    return "other"


def read_crosscheck_routing() -> dict[str, str]:
    crosscheck = os.environ.get(_CROSSCHECK_MODEL_ENV, "").strip()
    if not crosscheck:
        raise CrosscheckError(
            "MODEL_NOT_CONFIGURED",
            f"set {_CROSSCHECK_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    tiebreak = os.environ.get(_TIEBREAK_MODEL_ENV, "").strip()
    if not tiebreak:
        raise CrosscheckError(
            "MODEL_NOT_CONFIGURED",
            f"set {_TIEBREAK_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "crosscheck_model": crosscheck,
        "tiebreak_model": tiebreak,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def _generator_model(generated: Mapping[str, Any]) -> str:
    models = generated.get("models")
    if not isinstance(models, Mapping):
        raise CrosscheckError("ITEM_INVALID", "generated bundle missing models mapping")
    generator = models.get("generator")
    if not isinstance(generator, str) or not generator.strip():
        raise CrosscheckError("ITEM_INVALID", "generator model id required")
    return generator.strip()


def _item_claims(generated: Mapping[str, Any]) -> list[dict[str, Any]]:
    item = generated.get("item")
    if not isinstance(item, Mapping):
        raise CrosscheckError("ITEM_INVALID", "generated bundle missing item mapping")
    claims = item.get("claims")
    if not isinstance(claims, Sequence) or isinstance(claims, (str, bytes)):
        raise CrosscheckError("ITEM_INVALID", "item claims must be a list")
    parsed: list[dict[str, Any]] = []
    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise CrosscheckError("ITEM_INVALID", f"claim {index}: must be a mapping")
        parsed.append(dict(claim))
    if not parsed:
        raise CrosscheckError("ITEM_INVALID", "item claims must be non-empty")
    return parsed


def build_crosscheck_payload(
    generated: Mapping[str, Any],
    *,
    evidence_passages: Sequence[Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Item for the verifier: claims and evidence only — no generator reasoning (AC1)."""
    can_do = generated.get("can_do")
    if not isinstance(can_do, str) or not can_do.strip():
        raise CrosscheckError("ITEM_INVALID", "can_do is required")
    routing = read_crosscheck_routing()
    generator_model = _generator_model(generated)
    crosscheck_model = routing["crosscheck_model"]
    if model_family(generator_model) == model_family(crosscheck_model):
        raise CrosscheckError(
            "MODEL_FAMILY",
            "cross-check model must be a different family than the generator",
        )
    payload: dict[str, Any] = {
        "card_id": CARD_ID,
        "can_do": can_do.strip(),
        "claims": _item_claims(generated),
        "evidence_passages": list(evidence_passages or ()),
        "crosscheck_model": crosscheck_model,
    }
    return payload


def parse_opinion_response(raw: str | Mapping[str, Any], role: str) -> dict[str, Any]:
    if isinstance(raw, Mapping):
        data: Mapping[str, Any] = raw
    elif isinstance(raw, str):
        try:
            loaded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise CrosscheckError(
                "OPINION_RESPONSE_INVALID",
                f"{role}: response is not valid JSON: {exc}",
            ) from exc
        if not isinstance(loaded, Mapping):
            raise CrosscheckError(
                "OPINION_RESPONSE_INVALID",
                f"{role}: response root must be a JSON object",
            )
        data = loaded
    else:
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: response must be JSON text or a mapping",
        )

    approves = data.get("approves")
    naturalness = data.get("naturalness")
    if not isinstance(approves, bool):
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: approves must be a boolean",
        )
    if not isinstance(naturalness, int) or isinstance(naturalness, bool):
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: naturalness must be an integer 1–5",
        )
    if naturalness < 1 or naturalness > 5:
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: naturalness must be between 1 and 5",
        )
    english = data.get("english_translation")
    if not isinstance(english, str):
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: english_translation must be a string",
        )
    errors = data.get("errors")
    if errors is None:
        errors_list: list[Any] = []
    elif isinstance(errors, Sequence) and not isinstance(errors, (str, bytes)):
        errors_list = list(errors)
    else:
        raise CrosscheckError(
            "OPINION_RESPONSE_INVALID",
            f"{role}: errors must be a list when present",
        )
    return {
        "role": role,
        "approves": approves,
        "naturalness": naturalness,
        "english_translation": english,
        "errors": errors_list,
    }


def _generator_opinion(generator_model: str) -> dict[str, Any]:
    return {
        "role": "generator",
        "model": generator_model,
        "approves": True,
    }


def _opinions_disagree(
    generator: Mapping[str, Any],
    crosscheck: Mapping[str, Any],
) -> bool:
    return bool(generator.get("approves")) != bool(crosscheck.get("approves"))


def run_independent_crosscheck(
    generated: Mapping[str, Any],
    client: CrosscheckClient,
    *,
    evidence_passages: Sequence[Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Cross-check the generated item; tie-break on disagreement; store all opinions (AC2)."""
    routing = read_crosscheck_routing()
    generator_model = _generator_model(generated)
    generator_opinion = _generator_opinion(generator_model)
    payload = build_crosscheck_payload(
        generated,
        evidence_passages=evidence_passages,
    )
    crosscheck_model = routing["crosscheck_model"]
    tiebreak_model = routing["tiebreak_model"]

    try:
        raw_cross = client.complete(crosscheck_model, payload)
    except Exception as exc:
        return {
            "card_id": CARD_ID,
            "status": "XCHECK_ERROR",
            "code": "XCHECK_ERROR",
            "message": str(exc),
            "can_publish": False,
            "model_opinions": [generator_opinion],
        }

    cross_opinion = parse_opinion_response(raw_cross, "crosscheck")
    cross_opinion["model"] = crosscheck_model
    opinions: list[dict[str, Any]] = [generator_opinion, cross_opinion]

    final_approves = bool(cross_opinion["approves"])
    if _opinions_disagree(generator_opinion, cross_opinion):
        tie_payload = {
            **payload,
            "prior_opinions": [
                {"role": "generator", "approves": generator_opinion["approves"]},
                {
                    "role": "crosscheck",
                    "approves": cross_opinion["approves"],
                    "naturalness": cross_opinion["naturalness"],
                },
            ],
        }
        try:
            raw_tie = client.complete(tiebreak_model, tie_payload)
        except Exception as exc:
            return {
                "card_id": CARD_ID,
                "status": "XCHECK_ERROR",
                "code": "XCHECK_ERROR",
                "message": str(exc),
                "can_publish": False,
                "model_opinions": opinions,
            }
        tie_opinion = parse_opinion_response(raw_tie, "tiebreak")
        tie_opinion["model"] = tiebreak_model
        opinions.append(tie_opinion)
        final_approves = bool(tie_opinion["approves"])

    return {
        "card_id": CARD_ID,
        "status": "ok",
        "can_publish": final_approves,
        "crosscheck": crosscheck_model,
        "crosscheck_score": cross_opinion["naturalness"],
        "crosscheck_ok": final_approves,
        "model_opinions": opinions,
        "ext01_citation": routing["ext01_citation"],
    }


def make_fixture_client(
    responses: Mapping[str, str | Mapping[str, Any]],
) -> CrosscheckClient:
    """Test helper: map model id -> fixed JSON payload."""

    class _Fixture:
        def complete(self, model: str, _payload: Mapping[str, Any]) -> str:
            if model not in responses:
                raise RuntimeError(f"no fixture response for model {model}")
            response = responses[model]
            if isinstance(response, Mapping):
                return json.dumps(response)
            return response

    return _Fixture()
