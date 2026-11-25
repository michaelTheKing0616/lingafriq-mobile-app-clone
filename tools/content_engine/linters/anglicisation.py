"""Pidgin anglicisation check via cross-check naturalness rating (P4-048, CURRICULUM §3.2).

Injectable client only — no live API calls. Model id from env (EXT-01 companion doc).
"""

from __future__ import annotations

import json
import os
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Protocol

from tools.content_engine.linters.types import LintResult, Span

CARD_ID = "P4-048"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.9 Content and curriculum bootstrapping"

_RATING_MODEL_ENV = "CONTENT_ENGINE_CROSSCHECK_MODEL"
_LANGUAGE = "pcm"
_RULE_PASS = "PCM_ANGLICISATION"
_RULE_ANGLICISED = "PCM_ANGLICISED"
_RULE_MISSING = "PCM_ANGLICISATION_MISSING"
_NATURALNESS_MIN_PASS = 3


class AnglicisationError(Exception):
    """Anglicisation validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class AnglicisationClient(Protocol):
    def complete(self, model: str, payload: Mapping[str, Any]) -> str:
        """Return model output text (JSON object) for the naturalness request."""


@dataclass(frozen=True)
class AnglicisationLintResult(LintResult):
    naturalness: int = 0
    anglicised: bool = False


def read_anglicisation_routing() -> dict[str, str]:
    model = os.environ.get(_RATING_MODEL_ENV, "").strip()
    if not model:
        raise AnglicisationError(
            "MODEL_NOT_CONFIGURED",
            f"set {_RATING_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "rating_model": model,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def build_anglicisation_payload(item: Mapping[str, Any]) -> dict[str, Any]:
    if item.get("language") != _LANGUAGE:
        raise AnglicisationError(
            "LANGUAGE_INVALID",
            f"anglicisation check applies only to {_LANGUAGE!r}",
        )
    text = item.get("text")
    if not isinstance(text, str) or not text.strip():
        raise AnglicisationError("ITEM_INVALID", "text is required")
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise AnglicisationError("ITEM_INVALID", "id is required")
    routing = read_anglicisation_routing()
    return {
        "card_id": CARD_ID,
        "item_id": item_id.strip(),
        "language": _LANGUAGE,
        "text": text.strip(),
        "rating_model": routing["rating_model"],
    }


def parse_rating_response(raw: str | Mapping[str, Any]) -> dict[str, Any]:
    if isinstance(raw, Mapping):
        data: Mapping[str, Any] = raw
    elif isinstance(raw, str):
        try:
            loaded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise AnglicisationError(
                "RATING_RESPONSE_INVALID",
                f"response is not valid JSON: {exc}",
            ) from exc
        if not isinstance(loaded, Mapping):
            raise AnglicisationError(
                "RATING_RESPONSE_INVALID",
                "response root must be a JSON object",
            )
        data = loaded
    else:
        raise AnglicisationError(
            "RATING_RESPONSE_INVALID",
            "response must be JSON text or a mapping",
        )

    naturalness = data.get("naturalness")
    anglicised = data.get("anglicised")
    if not isinstance(naturalness, int) or isinstance(naturalness, bool):
        raise AnglicisationError(
            "RATING_RESPONSE_INVALID",
            "naturalness must be an integer 1–5",
        )
    if naturalness < 1 or naturalness > 5:
        raise AnglicisationError(
            "RATING_RESPONSE_INVALID",
            "naturalness must be between 1 and 5",
        )
    if not isinstance(anglicised, bool):
        raise AnglicisationError(
            "RATING_RESPONSE_INVALID",
            "anglicised must be a boolean",
        )
    return {"naturalness": naturalness, "anglicised": anglicised}


def naturalness_to_feature_score(naturalness: int) -> float:
    if naturalness < 1 or naturalness > 5:
        raise ValueError("naturalness must be 1–5")
    return (naturalness - 1) / 4.0


def is_low_naturalness(naturalness: int, anglicised: bool) -> bool:
    return anglicised or naturalness < _NATURALNESS_MIN_PASS


def routing_from_rating(naturalness: int, anglicised: bool) -> dict[str, Any]:
    low = is_low_naturalness(naturalness, anglicised)
    return {
        "can_auto_publish": not low,
        "route": "review" if low else "pass",
        "high_risk_tag": "anglicised_pidgin" if low else None,
    }


def run_anglicisation_rating(
    item: Mapping[str, Any],
    client: AnglicisationClient,
) -> dict[str, Any]:
    """Call the cross-check model for naturalness; return rating fields (AC1)."""
    routing = read_anglicisation_routing()
    payload = build_anglicisation_payload(item)
    model = routing["rating_model"]
    try:
        raw = client.complete(model, payload)
    except Exception as exc:
        return {
            "card_id": CARD_ID,
            "status": "error",
            "code": "ANGLICISATION_ERROR",
            "message": str(exc),
            "can_auto_publish": False,
            "route": "review",
        }
    rating = parse_rating_response(raw)
    route_info = routing_from_rating(rating["naturalness"], rating["anglicised"])
    return {
        "card_id": CARD_ID,
        "status": "ok",
        "model": model,
        "naturalness": rating["naturalness"],
        "anglicised": rating["anglicised"],
        "ext01_citation": routing["ext01_citation"],
        **route_info,
    }


def merge_verification_report(
    report: Mapping[str, Any],
    rating_result: Mapping[str, Any],
) -> dict[str, Any]:
    """Store naturalness and anglicised flag on the verification report (AC1)."""
    if not isinstance(report, Mapping):
        raise TypeError("report must be a mapping")
    merged = dict(report)
    features = merged.get("features")
    feature_map: dict[str, Any] = (
        dict(features) if isinstance(features, Mapping) else {}
    )
    naturalness = rating_result.get("naturalness")
    if isinstance(naturalness, int) and not isinstance(naturalness, bool):
        feature_map["cross_model_naturalness"] = naturalness_to_feature_score(
            naturalness,
        )
    merged["features"] = feature_map
    merged["anglicisation"] = {
        "card_id": CARD_ID,
        "naturalness": rating_result.get("naturalness"),
        "anglicised": rating_result.get("anglicised"),
        "anglicised_flag": bool(rating_result.get("anglicised")),
        "model": rating_result.get("model"),
        "route": rating_result.get("route"),
        "can_auto_publish": rating_result.get("can_auto_publish"),
        "high_risk_tag": rating_result.get("high_risk_tag"),
    }
    return merged


_learner_flags: dict[str, list[dict[str, Any]]] = {}


def reset_learner_flag_store() -> None:
    _learner_flags.clear()


def record_learner_flag(
    item_id: str,
    *,
    learner_id: str,
    note: str,
    published: bool = True,
) -> dict[str, Any]:
    """Persist a learner flag for native validators (AC3)."""
    if not item_id.strip():
        raise ValueError("item_id is required")
    if not learner_id.strip():
        raise ValueError("learner_id is required")
    entry = {
        "item_id": item_id.strip(),
        "learner_id": learner_id.strip(),
        "note": note.strip(),
        "published": published,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "queue": "native_validators",
    }
    _learner_flags.setdefault(item_id.strip(), []).append(entry)
    return entry


def list_learner_flags(item_id: str) -> list[dict[str, Any]]:
    return list(_learner_flags.get(item_id.strip(), []))


def _rating_from_item(item: Mapping[str, Any]) -> dict[str, Any] | None:
    verification = item.get("verification")
    if not isinstance(verification, Mapping):
        return None
    block = verification.get("anglicisation")
    if not isinstance(block, Mapping):
        return None
    naturalness = block.get("naturalness")
    anglicised = block.get("anglicised")
    if not isinstance(naturalness, int) or isinstance(naturalness, bool):
        return None
    if not isinstance(anglicised, bool):
        return None
    return {"naturalness": naturalness, "anglicised": anglicised}


def lint_anglicisation(item: Mapping, kit: Mapping) -> AnglicisationLintResult:
    """Deterministic lint: uses stored verification anglicisation block on pcm items."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")
    item_id = item["id"]
    language = item.get("language")
    if language != _LANGUAGE:
        return AnglicisationLintResult(
            item_id=item_id,
            rule_id=_RULE_PASS,
            span=Span(0, 0),
            status="pass",
            naturalness=0,
            anglicised=False,
        )

    rating = _rating_from_item(item)
    text = item.get("text")
    text_len = len(text) if isinstance(text, str) else 0
    if rating is None:
        return AnglicisationLintResult(
            item_id=item_id,
            rule_id=_RULE_MISSING,
            span=Span(0, text_len),
            status="fail",
            naturalness=0,
            anglicised=False,
        )

    naturalness = rating["naturalness"]
    anglicised = rating["anglicised"]
    if is_low_naturalness(naturalness, anglicised):
        return AnglicisationLintResult(
            item_id=item_id,
            rule_id=_RULE_ANGLICISED,
            span=Span(0, text_len),
            status="fail",
            naturalness=naturalness,
            anglicised=anglicised,
        )

    return AnglicisationLintResult(
        item_id=item_id,
        rule_id=_RULE_PASS,
        span=Span(0, 0),
        status="pass",
        naturalness=naturalness,
        anglicised=anglicised,
    )


def make_fixture_client(
    responses: Mapping[str, str | Mapping[str, Any]],
) -> AnglicisationClient:
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
