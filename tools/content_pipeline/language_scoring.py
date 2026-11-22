"""Quarterly next-language scoring (P4-114, ELEVATION §6.4).

Each language is scored 1-5 on six criteria. A criterion with no evidence note
is unscored and left out of the total. It is never filled with a default.
Reviewer and voice-talent availability is read from the paid roster. An empty
roster, which is the state while EXT-13 is open, marks that criterion unknown.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Mapping, Sequence
from datetime import date
from pathlib import Path
from typing import Any

CARD_ID = "P4-114"

CRITERIA = (
    "speakers",
    "diaspora_demand",
    "reviewer_voice_talent",
    "ai_coverage",
    "partner_support",
    "mission_value",
)

REVIEWER_CRITERION = "reviewer_voice_talent"
PAID_ROLES = frozenset({"reviewer", "voice"})


class LanguageScoringError(Exception):
    """Scoring input that cannot be ranked. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _require_language_id(value: object) -> str:
    if not isinstance(value, str) or not value.strip():
        raise LanguageScoringError("LANGUAGE_ID", "language_id is required")
    return value.strip()


def _parse_date(value: str) -> str:
    try:
        parsed = date.fromisoformat(value)
    except ValueError as exc:
        raise LanguageScoringError("DATE_INVALID", "date must be YYYY-MM-DD") from exc
    return parsed.isoformat()


def roster_availability(language_id: str, roster: Sequence[Mapping[str, Any]]) -> str:
    """Return known or unknown for paid reviewers and voice talent."""
    if len(roster) == 0:
        return "unknown"
    for row in roster:
        if not isinstance(row, Mapping):
            raise LanguageScoringError("ROSTER_INVALID", "each roster row must be an object")
        if row.get("language_id") != language_id:
            continue
        if row.get("paid") is True and row.get("role") in PAID_ROLES:
            reviewer_id = row.get("reviewer_id")
            if isinstance(reviewer_id, str) and reviewer_id.strip():
                return "known"
    return "unknown"


def _score_criterion(
    name: str,
    raw: object,
    *,
    availability: str | None,
) -> dict[str, Any]:
    if name == REVIEWER_CRITERION and availability == "unknown":
        return {"status": "unknown"}
    if raw is None:
        return {"status": "unscored", "reason": "missing_evidence"}
    if not isinstance(raw, Mapping):
        raise LanguageScoringError("EVIDENCE_INVALID", f"{name} evidence must be an object")
    score = raw.get("score")
    note = raw.get("note")
    if score is None and (note is None or note == ""):
        return {"status": "unscored", "reason": "missing_evidence"}
    if not isinstance(score, int) or isinstance(score, bool) or score < 1 or score > 5:
        raise LanguageScoringError("SCORE_OUT_OF_RANGE", f"{name} score must be an integer 1-5")
    if not isinstance(note, str) or not note.strip():
        raise LanguageScoringError("EVIDENCE_NOTE_MISSING", f"{name} needs an evidence note")
    return {"status": "scored", "score": score, "note": note.strip()}


def score_language(
    language_id: str,
    evidence: Mapping[str, Any] | None,
    roster: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    """Score one language. Missing criteria stay out of the total."""
    language = _require_language_id(language_id)
    provided = evidence or {}
    if not isinstance(provided, Mapping):
        raise LanguageScoringError("EVIDENCE_INVALID", "evidence must be an object")
    unknown_keys = [key for key in provided if key not in CRITERIA]
    if unknown_keys:
        raise LanguageScoringError("CRITERION_UNKNOWN", f"unknown criteria: {', '.join(unknown_keys)}")
    availability = roster_availability(language, roster)
    criteria: dict[str, Any] = {}
    total = 0
    scored_names: list[str] = []
    for name in CRITERIA:
        result = _score_criterion(
            name,
            provided.get(name),
            availability=availability if name == REVIEWER_CRITERION else None,
        )
        if name == REVIEWER_CRITERION and availability == "unknown":
            result["reason"] = "roster_empty" if len(roster) == 0 else "roster_missing"
        criteria[name] = result
        if result["status"] == "scored":
            total += int(result["score"])
            scored_names.append(name)
    return {
        "language_id": language,
        "criteria": criteria,
        "total": total if scored_names else None,
        "scored_criteria": scored_names,
    }


def _previous_index(previous: Mapping[str, Any] | None) -> dict[str, Mapping[str, Any]]:
    if previous is None:
        return {}
    rows = previous.get("ranked")
    if not isinstance(rows, list):
        raise LanguageScoringError("PREVIOUS_INVALID", "previous quarter ranked must be a list")
    index: dict[str, Mapping[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            raise LanguageScoringError("PREVIOUS_INVALID", "previous quarter row must be an object")
        language_id = _require_language_id(row.get("language_id"))
        index[language_id] = row
    return index


def _delta(current: Mapping[str, Any], prior: Mapping[str, Any] | None) -> tuple[int | None, str | None]:
    if prior is None:
        return None, "no_previous"
    prior_names = prior.get("scored_criteria")
    current_names = current.get("scored_criteria")
    if prior_names != current_names:
        return None, "criteria_changed"
    prior_total = prior.get("total")
    current_total = current.get("total")
    if not isinstance(prior_total, int) or not isinstance(current_total, int):
        return None, "criteria_changed"
    return current_total - prior_total, None


def quarterly_run(
    languages: Sequence[Mapping[str, Any]],
    roster: Sequence[Mapping[str, Any]],
    *,
    as_of: str,
    previous: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Rank languages for one quarter and attach the delta from the previous run."""
    run_date = _parse_date(as_of)
    if not isinstance(languages, Sequence) or isinstance(languages, (str, bytes)):
        raise LanguageScoringError("LANGUAGES_INVALID", "languages must be a list")
    prior = _previous_index(previous)
    scored: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in languages:
        if not isinstance(row, Mapping):
            raise LanguageScoringError("LANGUAGES_INVALID", "each language must be an object")
        language_id = _require_language_id(row.get("language_id"))
        if language_id in seen:
            raise LanguageScoringError("LANGUAGE_DUPLICATE", f"duplicate language_id {language_id}")
        seen.add(language_id)
        evidence = row.get("evidence")
        result = score_language(language_id, evidence if isinstance(evidence, Mapping) else evidence, roster)
        delta, reason = _delta(result, prior.get(language_id))
        result["delta"] = delta
        result["delta_reason"] = reason
        scored.append(result)
    scored.sort(key=lambda row: (row["total"] is None, -(row["total"] or 0), row["language_id"]))
    return {
        "card_id": CARD_ID,
        "date": run_date,
        "roster_state": "empty" if len(roster) == 0 else "present",
        "ranked": scored,
    }


def _load_json(path: Path) -> Any:
    if not path.is_file():
        raise LanguageScoringError("INPUT_MISSING", f"file not found: {path}")
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, required=True, help="JSON list of language evidence")
    parser.add_argument("--roster", type=Path, required=True, help="JSON list of paid reviewers and voice talent")
    parser.add_argument("--date", required=True, help="Quarter run date, YYYY-MM-DD")
    parser.add_argument("--previous", type=Path, help="Previous quarter JSON from this tool")
    args = parser.parse_args(argv)
    languages = _load_json(args.evidence)
    roster = _load_json(args.roster)
    previous = _load_json(args.previous) if args.previous else None
    if not isinstance(roster, list):
        raise LanguageScoringError("ROSTER_INVALID", "roster must be a list")
    report = quarterly_run(languages, roster, as_of=args.date, previous=previous)
    json.dump(report, fp=sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
