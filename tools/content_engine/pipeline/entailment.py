"""Claim-level citation entailment against retrieved passages (P4-058, CURRICULUM §3.1).

Injectable client only — no live API calls. Model id from env (EXT-01 companion doc).
"""

from __future__ import annotations

import json
import os
from collections.abc import Mapping, Sequence
from typing import Any, Protocol

CARD_ID = "P4-058"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"
STACK_SECTION = "§3.9 Content and curriculum bootstrapping"

_ENTAILMENT_MODEL_ENV = "CONTENT_ENGINE_ENTAILMENT_MODEL"

_SECTION_REVIEWER: dict[str, str] = {
    "grammar_note": "linguist",
    "culture_note": "cultural_reviewer",
}


class EntailmentError(Exception):
    """Entailment validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class EntailmentClient(Protocol):
    def complete(self, model: str, payload: Mapping[str, Any]) -> str:
        """Return model output text (JSON object) for the entailment request."""


def read_entailment_routing() -> dict[str, str]:
    model = os.environ.get(_ENTAILMENT_MODEL_ENV, "").strip()
    if not model:
        raise EntailmentError(
            "MODEL_NOT_CONFIGURED",
            f"set {_ENTAILMENT_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return {
        "entailment_model": model,
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
    }


def reviewer_route_for_section(section: str) -> str | None:
    return _SECTION_REVIEWER.get(section)


def _citation_key(citation: Mapping[str, Any]) -> tuple[str, str]:
    source_id = citation.get("source_id")
    locator = citation.get("locator")
    if not isinstance(source_id, str) or not source_id.strip():
        raise EntailmentError("ITEM_INVALID", "citation source_id required")
    if not isinstance(locator, str) or not locator.strip():
        raise EntailmentError("ITEM_INVALID", "citation locator required")
    return source_id.strip(), locator.strip()


def lookup_passage(
    citation: Mapping[str, Any],
    evidence_passages: Sequence[Mapping[str, Any]],
) -> str | None:
    """Resolve passage text for a citation; None when no matching passage (AC3)."""
    key = _citation_key(citation)
    for entry in evidence_passages:
        if not isinstance(entry, Mapping):
            continue
        entry_key = (
            entry.get("source_id"),
            entry.get("locator"),
        )
        if (
            isinstance(entry_key[0], str)
            and isinstance(entry_key[1], str)
            and entry_key[0].strip() == key[0]
            and entry_key[1].strip() == key[1]
        ):
            passage = entry.get("passage")
            if isinstance(passage, str) and passage.strip():
                return passage.strip()
            return None
    return None


def build_entailment_payload(
    claim: Mapping[str, Any],
    passage: str,
) -> dict[str, Any]:
    routing = read_entailment_routing()
    text = claim.get("text")
    if not isinstance(text, str) or not text.strip():
        raise EntailmentError("ITEM_INVALID", "claim text required")
    section = claim.get("section")
    if not isinstance(section, str) or not section.strip():
        raise EntailmentError("ITEM_INVALID", "claim section required")
    citation = claim.get("citation")
    if not isinstance(citation, Mapping):
        raise EntailmentError("ITEM_INVALID", "claim citation required")
    return {
        "card_id": CARD_ID,
        "claim_text": text.strip(),
        "section": section.strip(),
        "citation": dict(citation),
        "passage": passage,
        "entailment_model": routing["entailment_model"],
    }


def parse_entailment_response(raw: str | Mapping[str, Any]) -> bool:
    if isinstance(raw, Mapping):
        data: Mapping[str, Any] = raw
    elif isinstance(raw, str):
        try:
            loaded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise EntailmentError(
                "ENTAILMENT_RESPONSE_INVALID",
                f"response is not valid JSON: {exc}",
            ) from exc
        if not isinstance(loaded, Mapping):
            raise EntailmentError(
                "ENTAILMENT_RESPONSE_INVALID",
                "response root must be a JSON object",
            )
        data = loaded
    else:
        raise EntailmentError(
            "ENTAILMENT_RESPONSE_INVALID",
            "response must be JSON text or a mapping",
        )
    entailed = data.get("entailed")
    if not isinstance(entailed, bool):
        raise EntailmentError(
            "ENTAILMENT_RESPONSE_INVALID",
            "entailed must be a boolean",
        )
    return entailed


def check_claim_entailment(
    claim: Mapping[str, Any],
    evidence_passages: Sequence[Mapping[str, Any]],
    client: EntailmentClient,
    *,
    claim_index: int = 0,
) -> dict[str, Any]:
    """Check one claim; grammar/culture always include reviewer routing (AC2)."""
    section = claim.get("section")
    if not isinstance(section, str):
        raise EntailmentError("ITEM_INVALID", f"claim {claim_index}: section required")
    reviewer = reviewer_route_for_section(section)
    citation = claim.get("citation")
    if not isinstance(citation, Mapping):
        result: dict[str, Any] = {
            "claim_index": claim_index,
            "section": section,
            "status": "skipped",
            "entailed": None,
        }
        if reviewer is not None:
            result["reviewer_route"] = reviewer
        return result

    passage = lookup_passage(citation, evidence_passages)
    if passage is None:
        result = {
            "claim_index": claim_index,
            "section": section,
            "status": "fail",
            "code": "PASSAGE_NOT_FOUND",
            "entailed": False,
            "can_publish": False,
        }
        if reviewer is not None:
            result["reviewer_route"] = reviewer
        return result

    routing = read_entailment_routing()
    payload = build_entailment_payload(claim, passage)
    try:
        raw = client.complete(routing["entailment_model"], payload)
    except Exception as exc:
        raise EntailmentError(
            "ENTAILMENT_ERROR",
            str(exc),
        ) from exc
    entailed = parse_entailment_response(raw)
    if not entailed:
        result = {
            "claim_index": claim_index,
            "section": section,
            "status": "fail",
            "code": "CLAIM_NOT_ENTAILED",
            "entailed": False,
            "can_publish": False,
            "passage_excerpt": passage[:120],
        }
        if reviewer is not None:
            result["reviewer_route"] = reviewer
        return result

    result = {
        "claim_index": claim_index,
        "section": section,
        "status": "ok",
        "entailed": True,
        "can_publish": True,
        "passage_excerpt": passage[:120],
    }
    if reviewer is not None:
        result["reviewer_route"] = reviewer
    return result


def run_claim_entailment(
    claims: Sequence[Mapping[str, Any]],
    evidence_passages: Sequence[Mapping[str, Any]],
    client: EntailmentClient,
) -> dict[str, Any]:
    """Stage contract: check all cited claims; block publish on first failure."""
    if isinstance(claims, (str, bytes)) or not isinstance(claims, Sequence):
        raise EntailmentError("ITEM_INVALID", "claims must be a list")
    routing = read_entailment_routing()
    results: list[dict[str, Any]] = []
    can_publish = True
    failure_code: str | None = None

    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise EntailmentError("ITEM_INVALID", f"claim {index}: must be a mapping")
        row = check_claim_entailment(
            claim,
            evidence_passages,
            client,
            claim_index=index,
        )
        results.append(row)
        if row.get("status") == "fail":
            can_publish = False
            failure_code = str(row.get("code", "CLAIM_NOT_ENTAILED"))

    grammar_culture = [
        r for r in results if r.get("reviewer_route") in _SECTION_REVIEWER.values()
    ]
    if grammar_culture and not all("reviewer_route" in r for r in grammar_culture):
        raise EntailmentError(
            "REVIEWER_ROUTE_MISSING",
            "grammar and culture claims must route to a reviewer",
        )

    return {
        "card_id": CARD_ID,
        "status": "ok" if can_publish else "fail",
        "code": failure_code,
        "can_publish": can_publish,
        "claim_results": results,
        "ext01_citation": routing["ext01_citation"],
    }


def make_fixture_client(
    responses: Mapping[str, str | Mapping[str, Any]],
) -> EntailmentClient:
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
