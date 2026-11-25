"""P4-132 two-reviewer native review and agreement tracking."""

from __future__ import annotations

import sys
from copy import deepcopy
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.review_agreement import (  # noqa: E402
    CHECK_FIELDS,
    ReviewAgreementError,
    aggregate_language_kappa,
    build_native_review_row,
    cohens_kappa_binary,
    kappa_for_review_pair,
    resolve_disagreement_with_dialect_note,
    store_language_kappa,
)
from tools.content_pipeline.review_assignment import (  # noqa: E402
    ReviewAssignmentError,
    assign_independent_reviewers,
    dialect_regions_required,
)


def _roster_yo() -> list[dict]:
    base = {
        "paid_native": True,
        "consent_signed": True,
        "licence_terms_signed": True,
        "role": "native",
    }
    return [
        {**base, "reviewer_id": "yo-native-lagos", "region_tag": "yo-lagos"},
        {**base, "reviewer_id": "yo-native-ibadan", "region_tag": "yo-ibadan"},
        {**base, "reviewer_id": "yo-native-extra", "region_tag": "yo-lagos"},
    ]


def test_dialect_regions_required_for_yoruba() -> None:
    assert dialect_regions_required("yo") is True
    assert dialect_regions_required("pcm") is False


def test_assign_requires_distinct_regions_for_yo() -> None:
    out = assign_independent_reviewers(
        object_id="yo.item.1",
        language_id="yo",
        roster=_roster_yo(),
    )
    assert out["reviewer_a_id"] != out["reviewer_b_id"]
    assert out["region_a"] != out["region_b"]
    assert out["dialect_regions_required"] is True


def test_assign_pcm_without_region_tags() -> None:
    roster = [
        {
            "reviewer_id": "pcm-1",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
        },
        {
            "reviewer_id": "pcm-2",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
        },
    ]
    out = assign_independent_reviewers(
        object_id="pcm.item.1",
        language_id="pcm",
        roster=roster,
    )
    assert out["dialect_regions_required"] is False


def test_assign_fails_when_regions_missing_for_yo() -> None:
    roster = [
        {
            "reviewer_id": "yo-1",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
            "region_tag": "yo-lagos",
        },
        {
            "reviewer_id": "yo-2",
            "paid_native": True,
            "consent_signed": True,
            "licence_terms_signed": True,
            "region_tag": "yo-lagos",
        },
    ]
    with pytest.raises(ReviewAssignmentError) as exc:
        assign_independent_reviewers(object_id="x", language_id="yo", roster=roster)
    assert exc.value.code == "ASSIGNMENT_REGION_CONFLICT"


def test_build_native_review_records_checks() -> None:
    row = build_native_review_row(
        reviewer_id="n1",
        checks={f: True for f in CHECK_FIELDS},
        approved=True,
        region_tag="yo-lagos",
    )
    assert set(row["checks"]) == set(CHECK_FIELDS)
    assert row["provenance"] == "human"


def test_cohens_kappa_perfect_agreement() -> None:
    assert cohens_kappa_binary([True, False, True], [True, False, True]) == 1.0


def test_aggregate_and_store_kappa() -> None:
    a = build_native_review_row(
        reviewer_id="a",
        checks={"orthography_tone": True, "naturalness": True, "register_cultural": True},
        approved=True,
    )
    b = build_native_review_row(
        reviewer_id="b",
        checks={"orthography_tone": True, "naturalness": False, "register_cultural": True},
        approved=False,
    )
    pair_stats = kappa_for_review_pair(a, b)
    assert pair_stats["naturalness"] == 0.0
    stats = aggregate_language_kappa("yo", [(a, b)])
    assert stats["sample_size"] == 1
    store: dict = {}
    store_language_kappa(store, stats)
    assert "yo" in store["by_language"]


def test_resolve_disagreement_does_not_edit_content() -> None:
    content = {"id": "yo.item.2", "text": "Ẹ kú àárọ̀"}
    before = deepcopy(content)
    record = {
        "object_id": "yo.item.2",
        "reviewers": [
            {
                "role": "native",
                "reviewer_id": "a",
                "approved": True,
                "variant_note": "Lagos form",
            },
            {
                "role": "native",
                "reviewer_id": "b",
                "approved": True,
                "variant_note": "Ibadan form",
            },
        ],
    }
    out = resolve_disagreement_with_dialect_note(
        content,
        record,
        linguist_id="ling-1",
        decision="both_valid_dialect",
        summary="Document both greetings as regional variants.",
    )
    assert content == before
    assert out["content_unchanged"] is True
    assert record["status"] == "disagreement_recorded"
