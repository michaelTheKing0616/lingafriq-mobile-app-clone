"""P4-111 Wave 2–4 roster ADR artefact."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.wave_roster_decision import (  # noqa: E402
    CARD_ID,
    WaveRosterError,
    load_wave_roster_decision,
    scored_total,
    validate_wave_roster_decision,
    wave_language_ids,
)


def test_decision_file_validates() -> None:
    data = load_wave_roster_decision()
    validate_wave_roster_decision(data)
    assert data["card_id"] == CARD_ID
    assert len(wave_language_ids(data, 2)) == 14
    assert len(wave_language_ids(data, 3)) == 25


def test_arabic_darija_wave_four_per_d15() -> None:
    block = load_wave_roster_decision()["egyptian_arabic_moroccan_darija"]
    assert block["included"] is True
    assert block["wave"] == 4
    assert block["egyptian_arabic_id"] == "ar-eg"
    assert block["moroccan_darija_id"] == "ary"


def test_reviewer_scores_unscored_not_in_total() -> None:
    data = load_wave_roster_decision()
    row = data["wave_2"][0]
    assert row["scores"]["reviewer_voice_availability"] is None
    total = scored_total(row)
    assert total is not None
    assert total < 30


def test_duplicate_language_fails_validation() -> None:
    data = load_wave_roster_decision()
    bad = dict(data)
    w3 = [dict(row) for row in data["wave_3"]]
    w3[1] = dict(w3[1], language_id=w3[0]["language_id"])
    bad["wave_3"] = w3
    with pytest.raises(WaveRosterError) as exc:
        validate_wave_roster_decision(bad)
    assert exc.value.code == "DUPLICATE_LANGUAGE"
