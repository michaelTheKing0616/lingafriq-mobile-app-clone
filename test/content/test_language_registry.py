"""P4-112 language registry waves, scripts, readiness and consent gates."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.language_registry import (  # noqa: E402
    CARD_ID,
    LanguageRegistryError,
    assert_kit_creation_allowed,
    assert_wave2_l0_allowed,
    load_language_registry,
    planning_target_totals,
    registry_entry_counts,
    set_readiness,
    validate_language_registry,
    with_updated_readiness,
)
from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS  # noqa: E402


def test_registry_validates_and_matches_schema() -> None:
    data = load_language_registry()
    validate_language_registry(data)
    assert data["card_id"] == CARD_ID
    schema = json.loads(
        (_REPO_ROOT / "schemas/v2/language_registry.schema.json").read_text(encoding="utf-8")
    )
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema).validate(data)


def test_wave1_and_multi_script_entries() -> None:
    data = load_language_registry()
    w1 = {e["language_id"] for e in data["entries"] if e["wave"] == 1}
    assert w1 == WAVE_1_LANGUAGE_IDS
    ff = [e for e in data["entries"] if e["language_id"] == "ff"]
    assert len(ff) == 2
    assert {e["script"] for e in ff} == {"Latn", "Adlm"}
    assert {e["entry_id"] for e in ff} == {"ff-Latn", "ff-Adlm"}


def test_readiness_updates_independently() -> None:
    data = load_language_registry()
    yo_before = next(e for e in data["entries"] if e["entry_id"] == "yo")["readiness_level"]
    ig_before = next(e for e in data["entries"] if e["entry_id"] == "ig")["readiness_level"]
    mutated = with_updated_readiness(data, "yo", "L1")
    assert next(e for e in mutated["entries"] if e["entry_id"] == "yo")["readiness_level"] == "L1"
    assert next(e for e in data["entries"] if e["entry_id"] == "yo")["readiness_level"] == yo_before
    assert next(e for e in mutated["entries"] if e["entry_id"] == "ig")["readiness_level"] == ig_before


def test_planning_targets_not_shipped_counts() -> None:
    targets = planning_target_totals()
    assert targets["kind"] == "planning_target"
    assert targets["wave_1"] == 7
    assert targets["wave_4_cumulative"] == "95+"
    data = load_language_registry()
    counts = registry_entry_counts(data)
    assert counts[1] == 7
    assert counts[2] == 14
    assert sum(counts.values()) != targets["wave_1"]


def test_consent_missing_blocks_nuu_kit() -> None:
    data = load_language_registry()
    nuu = next(e for e in data["entries"] if e["language_id"] == "ngh")
    assert nuu["community_consent_required"] is True
    with pytest.raises(LanguageRegistryError) as exc:
        assert_kit_creation_allowed(nuu, consent_recorded=False, benefit_sharing_terms=None)
    assert exc.value.code == "CONSENT_MISSING"
    with pytest.raises(LanguageRegistryError) as exc2:
        assert_kit_creation_allowed(nuu, consent_recorded=True, benefit_sharing_terms="  ")
    assert exc2.value.code == "CONSENT_MISSING"
    assert_kit_creation_allowed(
        nuu,
        consent_recorded=True,
        benefit_sharing_terms="Community MOU 2026-10-01",
    )


def test_wave2_l0_blocked_until_wave1_l1() -> None:
    data = load_language_registry()
    am = next(e for e in data["entries"] if e["entry_id"] == "am")
    partial = {lid: "L0" for lid in WAVE_1_LANGUAGE_IDS}
    partial["yo"] = "L1"
    with pytest.raises(LanguageRegistryError) as exc:
        assert_wave2_l0_allowed(am, partial, target_level="L0")
    assert exc.value.code == "WAVE_GATE_NOT_MET"
    all_l1 = {lid: "L1" for lid in WAVE_1_LANGUAGE_IDS}
    assert_wave2_l0_allowed(am, all_l1, target_level="L0")


def test_set_readiness_on_copy() -> None:
    data = load_language_registry()
    copy = dict(data)
    copy["entries"] = [dict(e) for e in data["entries"]]
    set_readiness(copy, "ha", "L2")
    assert next(e for e in copy["entries"] if e["entry_id"] == "ha")["readiness_level"] == "L2"
