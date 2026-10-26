"""P5-076 Phase 0 foundations exit gate (CURRICULUM §9.2)."""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.phase0_foundations_exit import (  # noqa: E402
    CARD_ID,
    Phase0ExitError,
    append_verification_ledger_row,
    verify_phase0_foundations_exit,
)


def test_measured_checklist_fails_while_ext_blockers_open() -> None:
    out = verify_phase0_foundations_exit(as_of=date(2026, 10, 27))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_checklist"
    assert out["gate_passed"] is False
    assert out["failure_code"] == "PHASE0_LICENCE_OR_COUNSEL"
    assert out["ac1"]["ac1_passed"] is False
    assert "EXT-03" in out["ac1"]["failure_codes"]


def test_ac3_reports_missing_yo_ig_ha_kits() -> None:
    out = verify_phase0_foundations_exit(as_of=date(2026, 10, 27))
    missing = set(out["ac3"]["language_kits_missing"])
    assert {"yo", "ig", "ha"}.issubset(missing)
    assert out["ac3"]["legacy_quarantine_ok"] is True
    assert out["ac3"]["publishable_lessons"] == 0


def test_append_verification_ledger_row() -> None:
    store: dict = {}
    row = append_verification_ledger_row(
        store,
        {
            "card_id": CARD_ID,
            "gate": "G5",
            "measured_on": "2026-10-27",
            "gate_passed": False,
            "failure_code": "PHASE0_LICENCE_OR_COUNSEL",
            "measurement_status": "measured_checklist",
        },
    )
    assert store["phase0_foundations_verifications"] == [row]


def test_ledger_must_exist() -> None:
    ledger = _REPO_ROOT / "assets/content/phase0_foundations_ledger.json"
    assert ledger.is_file()
    data = json.loads(ledger.read_text(encoding="utf-8"))
    assert data["card_id"] == CARD_ID


def test_bad_store_raises() -> None:
    with pytest.raises(Phase0ExitError):
        append_verification_ledger_row({"phase0_foundations_verifications": "nope"}, {"card_id": CARD_ID})
