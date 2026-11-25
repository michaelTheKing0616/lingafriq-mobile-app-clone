"""P4-122 two-native plus linguist validation stage."""

from __future__ import annotations

import sys
from copy import deepcopy
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.native_validation import (  # noqa: E402
    BETA_EXCLUDED_CONTEXTS,
    NativeValidationError,
    adjudicate_native_disagreement,
    assert_not_ai_only_approval,
    beta_delivery_policy,
    distinct_approved_native_ids,
    load_review_record_schema,
    missing_native_verified_approvals,
    request_promotion_to_native_verified,
    run_native_validation_stage,
    validate_review_record,
)


def _content(**overrides: object) -> dict:
    body: dict = {
        "id": "yo.item.sample",
        "label": "expert_reviewed",
        "provenance": {
            "author": "studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "fixture",
                    "licence": "CC0",
                    "uri_or_citation": "fixture://1",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        "claims": [{"kind": "linguistic", "source_ref": "lexicon:yo:sample"}],
        "confidence": 0.9,
        "risk_tags": [],
        "audio": [],
        "review": {"reviewers": []},
    }
    body.update(overrides)
    return body


def _reviewers(
    *,
    n1: str = "native-a",
    n2: str = "native-b",
    linguist: str = "ling-1",
    duplicate_native: bool = False,
) -> dict:
    second = n1 if duplicate_native else n2
    return {
        "reviewers": [
            {"role": "native", "reviewer_id": n1, "approved": True, "provenance": "human"},
            {"role": "native", "reviewer_id": second, "approved": True, "provenance": "human"},
            {"role": "linguist", "reviewer_id": linguist, "approved": True, "provenance": "human"},
        ]
    }


def test_review_record_schema_valid() -> None:
    Draft202012Validator.check_schema(load_review_record_schema())


def test_promotion_rejected_lists_missing_approvals() -> None:
    row = _content(review={"reviewers": [{"role": "native", "reviewer_id": "n1", "approved": True}]})
    result = request_promotion_to_native_verified(row)
    assert result["promoted"] is False
    assert result["code"] == "PROMOTION_REJECTED"
    assert "native_reviewer_2" in result["missing_approvals"]
    assert "linguist_adjudication" in result["missing_approvals"]


def test_same_reviewer_twice_fails_two_native_check() -> None:
    reviewers = _reviewers(duplicate_native=True)["reviewers"]
    assert len(distinct_approved_native_ids(reviewers)) == 1
    assert "native_reviewer_2" in missing_native_verified_approvals(reviewers)


def test_promotion_succeeds_with_two_natives_and_linguist() -> None:
    row = _content(review=_reviewers())
    result = request_promotion_to_native_verified(row)
    assert result["promoted"] is True
    assert result["content"]["label"] == "native_verified"


def test_ai_only_forbidden_on_tone_content() -> None:
    row = _content(
        provenance={
            "author": "studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": True,
            "model_id": "gemini-fixture",
            "prompt_id": "p1",
            "sources": [
                {
                    "name": "fixture",
                    "licence": "CC0",
                    "uri_or_citation": "fixture://1",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        claims=[{"kind": "tone", "source_ref": "lexicon:yo:aaro"}],
        review={"reviewers": []},
    )
    with pytest.raises(NativeValidationError) as exc:
        assert_not_ai_only_approval(row, row["review"])
    assert exc.value.code == "AI_ONLY_FORBIDDEN"


def test_adjudication_records_dialect_note_without_editing_content() -> None:
    content = _content(learner_facing_text="àárọ̀")
    record = {
        "object_id": "yo.item.sample",
        "reviewers": [
            {
                "role": "native",
                "reviewer_id": "n1",
                "approved": True,
                "variant_note": "Lagos",
            },
            {
                "role": "native",
                "reviewer_id": "n2",
                "approved": True,
                "variant_note": "Ibadan",
            },
        ],
        "status": "pending",
    }
    before = deepcopy(content)
    out = adjudicate_native_disagreement(
        content,
        record,
        linguist_id="ling-1",
        decision="both_valid_dialect",
        summary="Both regional greetings are acceptable; teach as variants.",
    )
    assert out["content_unchanged"] is True
    assert content == before
    assert record["status"] == "disagreement_recorded"
    assert len(record["dialect_notes"]) == 1


def test_beta_policy_excludes_d1_contexts() -> None:
    row = _content(label="beta")
    policy = beta_delivery_policy(row)
    assert policy["label"] == "beta"
    assert set(policy["excluded_from"]) == BETA_EXCLUDED_CONTEXTS


def test_run_stage_blocked_ai_only() -> None:
    row = _content(
        label="expert_reviewed",
        provenance={
            "author": "studio",
            "created_at": "2026-10-21T12:00:00Z",
            "ai_assisted": True,
            "model_id": "gemini-fixture",
            "prompt_id": "p1",
            "sources": [
                {
                    "name": "fixture",
                    "licence": "CC0",
                    "uri_or_citation": "fixture://1",
                    "retrieved_at": "2026-10-21T12:00:00Z",
                }
            ],
        },
        claims=[{"kind": "cultural", "source_ref": "curriculum/culture/1"}],
        review={
            "reviewers": [
                {"role": "native", "reviewer_id": "n1", "approved": True, "provenance": "ai"},
                {"role": "native", "reviewer_id": "n2", "approved": True, "provenance": "ai"},
                {"role": "linguist", "reviewer_id": "l1", "approved": True, "provenance": "ai"},
            ]
        },
    )
    result = run_native_validation_stage(row, action="promote")
    assert result["status"] == "blocked"
    assert result["code"] == "AI_ONLY_FORBIDDEN"


def test_validate_review_record_accepts_complete_row() -> None:
    validate_review_record(
        {
            "object_id": "yo.item.sample",
            "reviewers": _reviewers()["reviewers"],
            "status": "approved",
        }
    )
