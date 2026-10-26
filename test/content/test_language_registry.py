"""P4-112 language registry (waves, scripts, readiness, consent)."""

from __future__ import annotations

import sys
from copy import deepcopy
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.language_registry import (  # noqa: E402
    CARD_ID,
    LanguageRegistryError,
    assert_kit_creation_allowed,
    assert_l0_start_allowed,
    assemble_registry_from_sources,
    load_language_registry,
    planning_target_totals,
    set_entry_readiness,
    validate_language_registry,
    wave1_all_at_least_l1,
)
from tools.content_pipeline.wave_roster_decision import WAVE_1_LANGUAGE_IDS  # noqa: E402


def test_registry_loads_and_validates() -> None:
    data = load_language_registry()
    validate_language_registry(data)
    assert data["card_id"] == CARD_ID
    wave1 = {r["language_id"] for r in data["entries"] if r["wave"] == 1}
    assert wave1 == set(WAVE_1_LANGUAGE_IDS)


def test_dual_script_entries_share_language_id() -> None:
    data = load_language_registry()
    ff = [r for r in data["entries"] if r["language_id"] == "ff"]
    scripts = {r["script"] for r in ff}
    assert scripts == {"Latn", "Adlm"}
    assert len({r["entry_id"] for r in ff}) == 2


def test_readiness_updates_are_independent() -> None:
    data = deepcopy(load_language_registry())
    set_entry_readiness(data, "yo", "L1")
    yo = next(r for r in data["entries"] if r["entry_id"] == "yo")
    ig = next(r for r in data["entries"] if r["entry_id"] == "ig")
    assert yo["readiness_level"] == "L1"
    assert ig["readiness_level"] is None


def test_planning_targets_not_shipped_counts() -> None:
    totals = planning_target_totals(load_language_registry())
    assert totals["kind"] == "planning_target"
    assert totals["wave_1"] == 7
    assert totals["wave_4_cumulative"] == "95+"
    assert "not shipped" in totals["disclaimer"].lower()


def test_nuu_kit_without_consent_fails() -> None:
    data = load_language_registry()
    with pytest.raises(LanguageRegistryError) as exc:
        assert_kit_creation_allowed(data, "ngh", None)
    assert exc.value.code == "CONSENT_MISSING"


def test_wave2_l0_blocked_until_wave1_l1() -> None:
    data = deepcopy(load_language_registry())
    assert not wave1_all_at_least_l1(data)
    with pytest.raises(LanguageRegistryError) as exc:
        assert_l0_start_allowed(data, "am")
    assert exc.value.code == "WAVE_GATE_NOT_MET"
    for lang in WAVE_1_LANGUAGE_IDS:
        set_entry_readiness(data, lang, "L1")
    assert_l0_start_allowed(data, "am")


def test_assemble_matches_committed_file() -> None:
    built = assemble_registry_from_sources()
    validate_language_registry(built)
    on_disk = load_language_registry()
    assert len(built["entries"]) == len(on_disk["entries"])
