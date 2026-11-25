"""P5-055 Waves 2–4 label rules and Expert L0 gates (CURRICULUM §6)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.wave_label_rules import (  # noqa: E402
    CARD_ID,
    WAVES_2_4_EXPERT_ERROR_CEILING,
    WaveExpertVerificationError,
    WaveLabelRuleViolation,
    append_verification_ledger_row,
    has_lexicon_source,
    lint_wave_item,
    verify_waves_2_4_expert_gate,
)


def _item(**overrides: object) -> dict:
    body: dict = {
        "id": "am.item.fixture",
        "label": "beta",
        "provenance": {
            "author": "test",
            "created_at": "2026-01-01",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "fixture",
                    "licence": "CC-BY-4.0",
                    "uri_or_citation": "https://example.test",
                    "retrieved_at": "2026-01-01",
                }
            ],
        },
    }
    body.update(overrides)
    return body


def test_wave2_beta_below_l0_without_lexicon_fails() -> None:
    item = _item(label="beta")
    with pytest.raises(WaveLabelRuleViolation) as exc:
        lint_wave_item(item, language_wave=2, language_readiness_level=None)
    assert exc.value.rule == "WAVE_BETA_NO_LEXICON"


def test_wave2_beta_below_l0_with_lexicon_source_passes() -> None:
    item = _item(label="beta", lexicon_source="amharic-lexicon-register")
    lint_wave_item(item, language_wave=2, language_readiness_level=None)


def test_wave2_beta_at_l0_without_lexicon_allowed() -> None:
    item = _item(label="beta")
    lint_wave_item(item, language_wave=2, language_readiness_level="L0")


def test_wave1_beta_below_l0_not_subject_to_wave_rule() -> None:
    item = _item(id="yo.item.fixture", label="beta")
    lint_wave_item(item, language_wave=1, language_readiness_level=None)


def test_l0_taste_publish_requires_expert() -> None:
    item = _item(label="beta", content_track="l0_taste", lexicon_source="amharic-lexicon-register")
    with pytest.raises(WaveLabelRuleViolation) as exc:
        lint_wave_item(item, language_wave=2, for_publish=True)
    assert exc.value.rule == "L0_TASTE_NOT_EXPERT"


def test_l0_taste_publish_accepts_expert() -> None:
    item = _item(label="expert", content_track="l0_taste")
    lint_wave_item(item, language_wave=2, for_publish=True)


def test_has_lexicon_source_detects_provenance_kind() -> None:
    item = _item(
        provenance={
            "author": "test",
            "created_at": "2026-01-01",
            "ai_assisted": False,
            "sources": [
                {
                    "kind": "lexicon",
                    "name": "Amharic seed",
                    "licence": "CC-BY-4.0",
                    "uri_or_citation": "https://example.test",
                    "retrieved_at": "2026-01-01",
                }
            ],
        }
    )
    assert has_lexicon_source(item) is True


def _expert_review(language_id: str, has_error: bool) -> dict:
    return {
        "language_id": language_id,
        "stratum": "expert_reviewed",
        "has_error": has_error,
    }


def test_waves_2_4_expert_gate_passes_at_two_percent() -> None:
    reviews = [_expert_review("am", False)] * 98 + [_expert_review("am", True)] * 2
    out = verify_waves_2_4_expert_gate(reviews, as_of=date(2026, 10, 26))
    assert out["card_id"] == CARD_ID
    assert out["gate_passed"] is True
    assert out["languages"][0]["error_rate"] == 0.02
    assert out["languages"][0]["expert_error_ceiling"] == WAVES_2_4_EXPERT_ERROR_CEILING


def test_waves_2_4_expert_gate_fails_above_ceiling() -> None:
    reviews = [_expert_review("tw", False)] * 97 + [_expert_review("tw", True)] * 3
    out = verify_waves_2_4_expert_gate(reviews, as_of=date(2026, 10, 26))
    assert out["gate_passed"] is False
    assert out["failure_code"] == "WAVES_2_4_EXPERT_ERROR_EXCEEDED"


def test_waves_2_4_expert_gate_ignores_wave1_language() -> None:
    reviews = [_expert_review("yo", False)] * 10
    with pytest.raises(WaveExpertVerificationError) as exc:
        verify_waves_2_4_expert_gate(reviews)
    assert exc.value.code == "NO_WAVE_SAMPLE"


def test_ledger_appends_per_language() -> None:
    reviews = [_expert_review("am", False)] * 50
    result = verify_waves_2_4_expert_gate(reviews, as_of=date(2026, 1, 1))
    store: dict = {}
    rows = append_verification_ledger_row(store, result)
    assert len(rows) == 1
    assert store["waves_2_4_expert_verifications"][0]["language_id"] == "am"
