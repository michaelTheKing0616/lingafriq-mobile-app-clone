"""Assign two independent native reviewers per item (P4-132, ELEVATION §6.6)."""

from __future__ import annotations

from typing import Any, Mapping, Sequence

from tools.content_pipeline.dialect_policy_decision import load_dialect_policy_decision

CARD_ID = "P4-132"


class ReviewAssignmentError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def dialect_regions_required(language_id: str, policy: Mapping[str, Any] | None = None) -> bool:
    """True when Stage 1 dialect policy lists ≥2 regional variants (AC1)."""
    data = policy if policy is not None else load_dialect_policy_decision()
    lang = language_id.strip().lower()
    stage = data.get("stage_1")
    if not isinstance(stage, Sequence):
        return False
    for entry in stage:
        if not isinstance(entry, Mapping):
            continue
        if str(entry.get("language_id", "")).lower() != lang:
            continue
        variants = entry.get("regional_variants")
        return isinstance(variants, Sequence) and len(variants) >= 2
    return False


def _qualified_natives(
    roster: Sequence[Mapping[str, Any]],
    *,
    exclude: frozenset[str],
) -> list[Mapping[str, Any]]:
    rows: list[Mapping[str, Any]] = []
    for row in roster:
        if not isinstance(row, Mapping):
            continue
        rid = row.get("reviewer_id")
        if not isinstance(rid, str) or not rid.strip() or rid.strip() in exclude:
            continue
        if row.get("role") == "linguist":
            continue
        for flag in ("paid_native", "consent_signed", "licence_terms_signed"):
            if row.get(flag) is not True:
                break
        else:
            rows.append(row)
    return rows


def assign_independent_reviewers(
    *,
    object_id: str,
    language_id: str,
    roster: Sequence[Mapping[str, Any]],
    exclude_reviewer_ids: frozenset[str] | None = None,
    policy: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Pick two distinct native reviewers. When dialect regions differ for the language,
    the pair must have different region_tag values (AC1).
    """
    if not isinstance(object_id, str) or not object_id.strip():
        raise ReviewAssignmentError("OBJECT_INVALID", "object_id is required")
    exclude = exclude_reviewer_ids or frozenset()
    candidates = _qualified_natives(roster, exclude=exclude)
    if len(candidates) < 2:
        raise ReviewAssignmentError(
            "ASSIGNMENT_INSUFFICIENT",
            "need at least two qualified native reviewers on the roster",
        )
    need_regions = dialect_regions_required(language_id, policy)

    def region_tag(row: Mapping[str, Any]) -> str:
        tag = row.get("region_tag")
        if isinstance(tag, str) and tag.strip():
            return tag.strip().lower()
        return "unspecified"

    chosen: list[Mapping[str, Any]] = []
    if need_regions:
        by_region: dict[str, list[Mapping[str, Any]]] = {}
        for row in candidates:
            by_region.setdefault(region_tag(row), []).append(row)
        distinct_regions = [r for r in by_region if r != "unspecified"]
        if len(distinct_regions) < 2:
            raise ReviewAssignmentError(
                "ASSIGNMENT_REGION_CONFLICT",
                "dialect policy requires reviewers from different regions; roster lacks region_tag diversity",
            )
        first_region = distinct_regions[0]
        second_region = distinct_regions[1]
        chosen = [by_region[first_region][0], by_region[second_region][0]]
    else:
        chosen = [candidates[0], candidates[1]]

    a_id = str(chosen[0]["reviewer_id"]).strip()
    b_id = str(chosen[1]["reviewer_id"]).strip()
    if a_id == b_id:
        raise ReviewAssignmentError("ASSIGNMENT_INVALID", "reviewers must be distinct")

    return {
        "card_id": CARD_ID,
        "object_id": object_id.strip(),
        "language_id": language_id.strip().lower(),
        "reviewer_a_id": a_id,
        "reviewer_b_id": b_id,
        "region_a": region_tag(chosen[0]),
        "region_b": region_tag(chosen[1]),
        "dialect_regions_required": need_regions,
    }
