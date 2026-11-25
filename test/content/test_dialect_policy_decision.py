"""P4-115 Stage 1 dialect policy ADR artefact."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.dialect_policy_decision import (  # noqa: E402
    CARD_ID,
    DialectPolicyError,
    load_dialect_policy_decision,
    stage_1_by_language,
    validate_dialect_policy_decision,
)
from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS  # noqa: E402


def test_decision_file_validates() -> None:
    data = load_dialect_policy_decision()
    validate_dialect_policy_decision(data)
    assert data["card_id"] == CARD_ID
    by_lang = stage_1_by_language(data)
    assert set(by_lang) == WAVE_1_LANGUAGE_IDS


def test_igbo_audio_variants_per_elevation() -> None:
    ig = stage_1_by_language(load_dialect_policy_decision())["ig"]
    tags = {v["dialect_tag"] for v in ig["regional_variants"]}
    assert tags == {"ig-onitsha", "ig-owerri"}
    assert ig["standard_taught"] == "Central Igbo"


def test_dialect_preference_hook_has_owner_and_review_date() -> None:
    hook = load_dialect_policy_decision()["dialect_preference_hook"]
    assert hook["mapping_owner"] == "content-pipeline"
    assert hook["review_date"] == "2026-10-26"


def test_unmarked_variant_fails_validation() -> None:
    data = load_dialect_policy_decision()
    bad = dict(data)
    stage = [dict(row) for row in data["stage_1"]]
    yo = dict(stage[0])
    vars_ = [dict(v) for v in yo["regional_variants"]]
    vars_[0] = dict(vars_[0], must_mark_in_content=False)
    yo["regional_variants"] = vars_
    stage[0] = yo
    bad["stage_1"] = stage
    with pytest.raises(DialectPolicyError) as exc:
        validate_dialect_policy_decision(bad)
    assert exc.value.code == "VARIANT_UNMARKED"
