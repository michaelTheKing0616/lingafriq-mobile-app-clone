"""P4-114 quarterly language scoring. Missing evidence is never a default number."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.language_scoring import (  # noqa: E402
    CARD_ID,
    CRITERIA,
    LanguageScoringError,
    quarterly_run,
    score_language,
)


def _evidence(**scores: tuple[int, str]) -> dict[str, dict[str, object]]:
    return {name: {"score": score, "note": note} for name, (score, note) in scores.items()}


def _full(language_id: str, base: int) -> dict[str, object]:
    evidence = _evidence(
        **{
            name: (base if name != "mission_value" else min(5, base + 1), f"{name} source")
            for name in CRITERIA
        }
    )
    return {"language_id": language_id, "evidence": evidence}


def _paid(language_id: str) -> dict[str, object]:
    return {
        "language_id": language_id,
        "reviewer_id": f"rev-{language_id}",
        "role": "reviewer",
        "paid": True,
    }


def test_scored_language_uses_one_to_five_and_keeps_the_note() -> None:
    roster = [_paid("yo")]
    result = score_language(
        "yo",
        _evidence(speakers=(5, "Ethnologue L1+L2"), diaspora_demand=(4, "waitlist 1200")),
        roster,
    )
    assert result["criteria"]["speakers"] == {
        "status": "scored",
        "score": 5,
        "note": "Ethnologue L1+L2",
    }
    assert result["criteria"]["diaspora_demand"]["score"] == 4
    assert result["total"] == 9
    assert "ai_coverage" in result["criteria"]
    assert result["criteria"]["ai_coverage"]["status"] == "unscored"


def test_missing_evidence_is_excluded_from_the_total() -> None:
    result = score_language("ig", _evidence(speakers=(3, "census table")), [])
    assert result["criteria"]["partner_support"] == {
        "status": "unscored",
        "reason": "missing_evidence",
    }
    assert result["total"] == 3
    assert "partner_support" not in result["scored_criteria"]


def test_empty_roster_marks_reviewer_availability_unknown() -> None:
    evidence = _evidence(
        reviewer_voice_talent=(5, "this note must not become a score"),
        speakers=(2, "speaker estimate"),
    )
    result = score_language("xh", evidence, [])
    assert result["criteria"]["reviewer_voice_talent"]["status"] == "unknown"
    assert result["criteria"]["reviewer_voice_talent"]["reason"] == "roster_empty"
    assert "score" not in result["criteria"]["reviewer_voice_talent"]
    assert result["total"] == 2


def test_roster_without_this_language_is_unknown_not_a_number() -> None:
    result = score_language("ha", _evidence(speakers=(4, "speaker note")), [_paid("yo")])
    assert result["criteria"]["reviewer_voice_talent"]["status"] == "unknown"
    assert result["criteria"]["reviewer_voice_talent"]["reason"] == "roster_missing"


def test_quarterly_run_ranks_and_records_the_delta() -> None:
    roster = [_paid("yo"), _paid("ig")]
    previous = quarterly_run(
        [_full("yo", 3), _full("ig", 4)],
        roster,
        as_of="2026-08-01",
    )
    current = quarterly_run(
        [_full("ig", 4), _full("yo", 5), {"language_id": "sw", "evidence": {}}],
        roster,
        as_of="2026-11-22",
        previous=previous,
    )
    assert current["card_id"] == CARD_ID
    assert current["date"] == "2026-11-22"
    assert [row["language_id"] for row in current["ranked"]] == ["yo", "ig", "sw"]
    yo = current["ranked"][0]
    ig = current["ranked"][1]
    sw = current["ranked"][2]
    assert yo["delta"] == yo["total"] - previous["ranked"][1]["total"]
    assert yo["delta_reason"] is None
    assert ig["delta"] == 0
    assert sw["total"] is None
    assert sw["delta_reason"] == "no_previous"


def test_changed_criteria_do_not_invent_a_delta() -> None:
    roster = [_paid("yo")]
    previous = quarterly_run([_full("yo", 3)], roster, as_of="2026-08-01")
    current = quarterly_run(
        [
            {
                "language_id": "yo",
                "evidence": _evidence(speakers=(5, "updated speaker note")),
            }
        ],
        roster,
        as_of="2026-11-22",
        previous=previous,
    )
    assert current["ranked"][0]["delta"] is None
    assert current["ranked"][0]["delta_reason"] == "criteria_changed"


def test_score_without_a_note_or_outside_one_to_five_fails() -> None:
    with pytest.raises(LanguageScoringError) as missing:
        score_language("yo", {"speakers": {"score": 3, "note": "  "}}, [_paid("yo")])
    assert missing.value.code == "EVIDENCE_NOTE_MISSING"
    with pytest.raises(LanguageScoringError) as low:
        score_language("yo", {"speakers": {"score": 0, "note": "none"}}, [_paid("yo")])
    assert low.value.code == "SCORE_OUT_OF_RANGE"


def test_bad_date_fails() -> None:
    with pytest.raises(LanguageScoringError) as exc:
        quarterly_run([], [], as_of="22-11-2026")
    assert exc.value.code == "DATE_INVALID"
