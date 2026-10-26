"""P5-065 Swahili TTS blind-test decision artefact."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.sw_tts_decision import (  # noqa: E402
    CARD_ID,
    LANGUAGE_ID,
    SwTtsDecisionError,
    load_sw_tts_decision,
    primary_sw_tts_provider,
    sw_tts_fallback_order,
    validate_sw_tts_decision,
)


def test_decision_file_validates() -> None:
    data = load_sw_tts_decision()
    validate_sw_tts_decision(data)
    assert data["card_id"] == CARD_ID
    assert data["language_id"] == LANGUAGE_ID


def test_chirp3_hd_wins_blind_fixture() -> None:
    assert primary_sw_tts_provider() == "google_chirp3_hd_sw_ke"
    assert sw_tts_fallback_order() == ["intron", "azure_sw_ke"]


def test_three_vendors_scored_by_all_reviewers() -> None:
    blind = load_sw_tts_decision()["blind_test"]
    reviewers = set(blind["reviewers"])
    for row in blind["candidates"]:
        assert reviewers == set(row["mos_by_reviewer"])


def test_winner_mismatch_fails() -> None:
    data = load_sw_tts_decision()
    bad = dict(data)
    blind = dict(data["blind_test"])
    blind["winner_id"] = "intron"
    bad["blind_test"] = blind
    with pytest.raises(SwTtsDecisionError) as exc:
        validate_sw_tts_decision(bad)
    assert exc.value.code == "WINNER_MISMATCH"


def test_fallback_documented_for_tie_or_poor() -> None:
    blind = load_sw_tts_decision()["blind_test"]
    fb = blind["fallback_if_tie_or_poor"]
    assert fb["provider_order"][0] == "intron"
    assert blind["poor_mos_threshold"] == 3.5
