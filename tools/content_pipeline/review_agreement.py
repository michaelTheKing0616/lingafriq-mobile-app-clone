"""Inter-reviewer agreement and native review capture (P4-132, ELEVATION §6.6)."""

from __future__ import annotations

from copy import deepcopy
from datetime import UTC, datetime
from typing import Any, Mapping, MutableMapping, Sequence

from tools.content_pipeline.native_validation import adjudicate_native_disagreement

CARD_ID = "P4-132"

CHECK_FIELDS: tuple[str, ...] = (
    "orthography_tone",
    "naturalness",
    "register_cultural",
)


class ReviewAgreementError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _bool_check(value: object) -> bool:
    if value is True:
        return True
    if value is False:
        return False
    raise ReviewAgreementError("CHECK_INVALID", "review checks must be boolean")


def build_native_review_row(
    *,
    reviewer_id: str,
    checks: Mapping[str, Any],
    approved: bool,
    region_tag: str | None = None,
    variant_note: str | None = None,
) -> dict[str, Any]:
    """Persist a native review with §6.6 check dimensions (AC2)."""
    if not isinstance(reviewer_id, str) or not reviewer_id.strip():
        raise ReviewAgreementError("REVIEWER_INVALID", "reviewer_id is required")
    missing = [f for f in CHECK_FIELDS if f not in checks]
    if missing:
        raise ReviewAgreementError("CHECKS_INCOMPLETE", f"missing checks: {', '.join(missing)}")
    normalized_checks = {field: _bool_check(checks[field]) for field in CHECK_FIELDS}
    row: dict[str, Any] = {
        "role": "native",
        "reviewer_id": reviewer_id.strip(),
        "approved": approved,
        "provenance": "human",
        "checks": normalized_checks,
        "reviewed_at": datetime.now(UTC).isoformat(),
    }
    if region_tag:
        row["region_tag"] = region_tag.strip()
    if variant_note:
        row["variant_note"] = variant_note.strip()
    return row


def cohens_kappa_binary(ratings_a: Sequence[bool], ratings_b: Sequence[bool]) -> float | None:
    """Cohen's κ for two raters on paired binary judgments."""
    if len(ratings_a) != len(ratings_b):
        raise ReviewAgreementError("KAPPA_LENGTH", "rating sequences must have equal length")
    n = len(ratings_a)
    if n == 0:
        return None
    n11 = n10 = n01 = n00 = 0
    for a, b in zip(ratings_a, ratings_b, strict=True):
        if a and b:
            n11 += 1
        elif a and not b:
            n10 += 1
        elif not a and b:
            n01 += 1
        else:
            n00 += 1
    po = (n11 + n00) / n
    pa = (n11 + n10) / n
    pb = (n11 + n01) / n
    pe = pa * pb + (1 - pa) * (1 - pb)
    if pe >= 1.0:
        return 1.0 if po >= 1.0 else 0.0
    return (po - pe) / (1 - pe)


def kappa_for_review_pair(
    review_a: Mapping[str, Any],
    review_b: Mapping[str, Any],
) -> dict[str, float | None]:
    """κ per check dimension for one item's two native reviews."""
    checks_a = review_a.get("checks")
    checks_b = review_b.get("checks")
    if not isinstance(checks_a, Mapping) or not isinstance(checks_b, Mapping):
        raise ReviewAgreementError("CHECKS_MISSING", "both reviews need checks maps")
    out: dict[str, float | None] = {}
    for field in CHECK_FIELDS:
        if field not in checks_a or field not in checks_b:
            raise ReviewAgreementError("CHECKS_INCOMPLETE", f"missing {field}")
        ka = cohens_kappa_binary([_bool_check(checks_a[field])], [_bool_check(checks_b[field])])
        out[field] = ka
    overall = cohens_kappa_binary(
        [_bool_check(checks_a[f]) for f in CHECK_FIELDS],
        [_bool_check(checks_b[f]) for f in CHECK_FIELDS],
    )
    out["overall"] = overall
    return out


def aggregate_language_kappa(
    language_id: str,
    pairs: Sequence[tuple[Mapping[str, Any], Mapping[str, Any]]],
) -> dict[str, Any]:
    """Aggregate κ per dimension across completed review pairs for a language (AC3)."""
    if not pairs:
        return {
            "card_id": CARD_ID,
            "language_id": language_id.strip().lower(),
            "sample_size": 0,
            "kappa_by_dimension": {field: None for field in CHECK_FIELDS},
            "kappa_overall": None,
        }
    per_field: dict[str, list[bool]] = {f: [] for f in CHECK_FIELDS}
    per_field_b: dict[str, list[bool]] = {f: [] for f in CHECK_FIELDS}
    for review_a, review_b in pairs:
        for field in CHECK_FIELDS:
            ca = review_a.get("checks", {})
            cb = review_b.get("checks", {})
            if not isinstance(ca, Mapping) or not isinstance(cb, Mapping):
                raise ReviewAgreementError("CHECKS_MISSING", "review pair missing checks")
            per_field[field].append(_bool_check(ca[field]))
            per_field_b[field].append(_bool_check(cb[field]))
    kappa_by_dimension: dict[str, float | None] = {}
    for field in CHECK_FIELDS:
        kappa_by_dimension[field] = cohens_kappa_binary(per_field[field], per_field_b[field])
    flat_a = [v for field in CHECK_FIELDS for v in per_field[field]]
    flat_b = [v for field in CHECK_FIELDS for v in per_field_b[field]]
    return {
        "card_id": CARD_ID,
        "language_id": language_id.strip().lower(),
        "sample_size": len(pairs),
        "kappa_by_dimension": kappa_by_dimension,
        "kappa_overall": cohens_kappa_binary(flat_a, flat_b),
        "recorded_at": datetime.now(UTC).isoformat(),
    }


def store_language_kappa(
    store: MutableMapping[str, Any],
    stats: Mapping[str, Any],
) -> None:
    """Persist latest κ snapshot under store['by_language'][language_id] (AC3)."""
    lang = stats.get("language_id")
    if not isinstance(lang, str) or not lang.strip():
        raise ReviewAgreementError("LANGUAGE_INVALID", "language_id required in stats")
    by_lang = store.get("by_language")
    if by_lang is None:
        store["by_language"] = {}
        by_lang = store["by_language"]
    if not isinstance(by_lang, MutableMapping):
        raise ReviewAgreementError("STORE_INVALID", "store.by_language must be a mapping")
    by_lang[lang.strip().lower()] = dict(stats)


def resolve_disagreement_with_dialect_note(
    content: Mapping[str, Any],
    review_record: MutableMapping[str, Any],
    *,
    linguist_id: str,
    decision: str,
    summary: str,
) -> dict[str, Any]:
    """Route disagreement to dialect notes; never mutate learner content (AC4)."""
    before = deepcopy(dict(content))
    result = adjudicate_native_disagreement(
        content,
        review_record,
        linguist_id=linguist_id,
        decision=decision,
        summary=summary,
    )
    after = deepcopy(dict(content))
    if before != after:
        raise ReviewAgreementError("CONTENT_MUTATED", "silent content edit forbidden")
    return {"card_id": CARD_ID, **result}
