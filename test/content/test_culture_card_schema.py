"""Culture card schema with claims and review gate (P4-104)."""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any, Mapping

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.schema_loader import (  # noqa: E402
    CommonSchemaError,
    validate_content_envelope,
)

_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "content" / "culture_card.schema.json"
_SCHEMA_DIR = _SCHEMA_PATH.parent

_CULTURE_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.culture\.[a-z0-9._-]+$")
_CULTURAL_REVIEW = frozenset({"approved", "pending", "rejected"})


class CultureCardSchemaError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_culture_card_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def _culture_validator() -> Draft202012Validator:
    from referencing import Registry, Resource

    common = json.loads((_SCHEMA_DIR / "common.schema.json").read_text(encoding="utf-8"))
    culture = load_culture_card_schema()
    registry = Registry().with_resources(
        [
            (common["$id"], Resource.from_contents(common)),
            ("common.schema.json", Resource.from_contents(common)),
            (culture["$id"], Resource.from_contents(culture)),
            ("culture_card.schema.json", Resource.from_contents(culture)),
        ]
    )
    return Draft202012Validator(culture, registry=registry)


def _nfc_text(value: object, code: str, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise CultureCardSchemaError(code, f"{label} is required")
    if value != unicodedata.normalize("NFC", value):
        raise CultureCardSchemaError(code, f"{label} must be NFC-normalised")
    return value


def _check_image(image: object) -> None:
    if not isinstance(image, Mapping):
        raise CultureCardSchemaError("IMAGE_INVALID", "image must be a mapping")
    uri = image.get("uri")
    alt_text = image.get("alt_text")
    review = image.get("cultural_review")
    if not isinstance(uri, str) or not uri.strip():
        raise CultureCardSchemaError("IMAGE_INVALID", "image.uri is required")
    _nfc_text(alt_text, "IMAGE_INVALID", "image.alt_text")
    if review not in _CULTURAL_REVIEW:
        raise CultureCardSchemaError("IMAGE_INVALID", "image.cultural_review must be approved, pending, or rejected")


def _check_culture_claims(claims: object) -> None:
    if not isinstance(claims, list) or len(claims) < 1:
        raise CultureCardSchemaError("CLAIM_UNSOURCED", "claims must be a non-empty list")
    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            raise CultureCardSchemaError("CLAIM_UNSOURCED", f"claims[{index}] must be a mapping")
        source_ref = claim.get("source_ref")
        if not isinstance(source_ref, str) or not source_ref.strip():
            raise CultureCardSchemaError("CLAIM_UNSOURCED", f"claims[{index}].source_ref is required")
        _nfc_text(claim.get("text"), "CLAIM_UNSOURCED", f"claims[{index}].text")
        confidence = claim.get("confidence")
        floor = claim.get("confidence_floor")
        if not isinstance(confidence, (int, float)) or confidence < 0 or confidence > 1:
            raise CultureCardSchemaError("CLAIM_UNSOURCED", f"claims[{index}].confidence must be in [0, 1]")
        if not isinstance(floor, (int, float)) or floor < 0 or floor > 1:
            raise CultureCardSchemaError("CLAIM_UNSOURCED", f"claims[{index}].confidence_floor must be in [0, 1]")
        if float(confidence) < float(floor):
            raise CultureCardSchemaError(
                "CLAIM_UNSOURCED",
                f"claims[{index}].confidence is below confidence_floor",
            )


def validate_culture_card(obj: Mapping[str, Any], *, validator: Draft202012Validator | None = None) -> None:
    if not isinstance(obj, Mapping):
        raise CultureCardSchemaError("CULTURE_CARD_INVALID", "culture card must be a mapping")
    card_id = obj.get("id")
    if not isinstance(card_id, str) or not _CULTURE_ID_RE.match(card_id):
        raise CultureCardSchemaError("CULTURE_CARD_INVALID", "id must match <lang>.culture.<slug>")
    if obj.get("label") == "beta":
        raise CultureCardSchemaError("CULTURE_NEVER_BETA", "culture cards cannot carry label beta (C1)")
    _nfc_text(obj.get("title"), "CULTURE_CARD_INVALID", "title")
    _nfc_text(obj.get("body"), "CULTURE_CARD_INVALID", "body")
    _check_image(obj.get("image"))
    _check_culture_claims(obj.get("claims"))
    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise CultureCardSchemaError(exc.code, str(exc)) from exc
    v = validator or _culture_validator()
    errors = sorted(v.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise CultureCardSchemaError("CULTURE_CARD_INVALID", errors[0].message)


def _approved_risk_reviewers(obj: Mapping[str, Any]) -> tuple[set[str], bool]:
    review = obj.get("review")
    if not isinstance(review, Mapping):
        return set(), False
    reviewers = review.get("reviewers")
    if not isinstance(reviewers, list):
        return set(), False
    native_ids: set[str] = set()
    linguist_ok = False
    for row in reviewers:
        if not isinstance(row, Mapping) or row.get("approved") is not True:
            continue
        role = row.get("role")
        reviewer_id = row.get("reviewer_id")
        if not isinstance(reviewer_id, str) or not reviewer_id.strip():
            continue
        if role == "native":
            native_ids.add(reviewer_id.strip())
        elif role == "linguist":
            linguist_ok = True
    return native_ids, linguist_ok


def assert_culture_card_publishable(obj: Mapping[str, Any]) -> None:
    """Publish gate: high-risk tags require two natives and a linguist (never AI-only)."""
    validate_culture_card(obj)
    risk_tags = obj.get("risk_tags")
    if not isinstance(risk_tags, list) or len(risk_tags) < 1:
        return
    native_ids, linguist_ok = _approved_risk_reviewers(obj)
    if len(native_ids) < 2 or not linguist_ok:
        raise CultureCardSchemaError(
            "HIGH_RISK_REVIEW_REQUIRED",
            "risk_tags require two approved native reviewers and one linguist",
        )
    provenance = obj.get("provenance")
    if isinstance(provenance, Mapping) and provenance.get("ai_assisted") is True:
        if len(native_ids) < 2 or not linguist_ok:
            raise CultureCardSchemaError(
                "HIGH_RISK_REVIEW_REQUIRED",
                "ai_assisted culture cards with risk_tags cannot publish without human review",
            )


def _sample_card(**overrides: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": "yo.culture.market_greeting",
        "title": "Market greetings",
        "body": "In many Yoruba markets, buyers greet sellers before asking prices.",
        "image": {
            "uri": "images/yo/a1b2c3d4e5f6.jpg",
            "alt_text": "Busy outdoor market with produce stalls",
            "cultural_review": "approved",
        },
        "label": "expert_reviewed",
        "provenance": {
            "author": "content-studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "FSI Yoruba course",
                    "licence": "public-domain",
                    "uri_or_citation": "curriculum/sources/fsi-yoruba-unit-3",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        "claims": [
            {
                "kind": "cultural",
                "source_ref": "curriculum/sources/fsi-yoruba-unit-3",
                "text": "Greeting precedes price negotiation in market settings.",
                "confidence": 0.92,
                "confidence_floor": 0.85,
            }
        ],
        "confidence": 0.92,
        "risk_tags": [],
        "audio": [],
    }
    body.update(overrides)
    return body


def test_culture_card_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(load_culture_card_schema())


def test_complete_culture_card_passes() -> None:
    validate_culture_card(_sample_card())


def test_culture_never_beta() -> None:
    broken = _sample_card(label="beta")
    with pytest.raises(CultureCardSchemaError) as exc:
        validate_culture_card(broken)
    assert exc.value.code == "CULTURE_NEVER_BETA"


def test_claim_unsourced_missing_citation() -> None:
    broken = _sample_card()
    broken["claims"] = [
        {
            "kind": "cultural",
            "source_ref": "",
            "text": "A fact.",
            "confidence": 0.9,
            "confidence_floor": 0.8,
        }
    ]
    with pytest.raises(CultureCardSchemaError) as exc:
        validate_culture_card(broken)
    assert exc.value.code == "CLAIM_UNSOURCED"


def test_claim_unsourced_below_floor() -> None:
    broken = _sample_card()
    broken["claims"][0]["confidence"] = 0.5
    broken["claims"][0]["confidence_floor"] = 0.85
    with pytest.raises(CultureCardSchemaError) as exc:
        validate_culture_card(broken)
    assert exc.value.code == "CLAIM_UNSOURCED"


def test_risk_tags_require_human_review_to_publish() -> None:
    row = _sample_card(risk_tags=["culture_history_religion"])
    with pytest.raises(CultureCardSchemaError) as exc:
        assert_culture_card_publishable(row)
    assert exc.value.code == "HIGH_RISK_REVIEW_REQUIRED"


def test_risk_tags_publish_with_two_natives_and_linguist() -> None:
    row = _sample_card(
        risk_tags=["culture_history_religion"],
        review={
            "reviewers": [
                {"role": "native", "reviewer_id": "n1", "approved": True},
                {"role": "native", "reviewer_id": "n2", "approved": True},
                {"role": "linguist", "reviewer_id": "l1", "approved": True},
            ]
        },
    )
    assert_culture_card_publishable(row)
