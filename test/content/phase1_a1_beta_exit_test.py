"""P5-077 Phase 1 A1 Beta exit gate (CURRICULUM §9.2)."""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.phase1_a1_beta_exit import (  # noqa: E402
    CARD_ID,
    Phase1ExitError,
    append_verification_ledger_row,
    verify_phase1_a1_beta_exit,
)


def test_measured_checklist_fails_until_ledger_and_anchors_close() -> None:
    out = verify_phase1_a1_beta_exit(as_of=date(2026, 10, 27))
    assert out["card_id"] == CARD_ID
    assert out["measurement_status"] == "measured_checklist"
    assert out["gate_passed"] is False
    assert out["failure_code"] == "PHASE1_CONTENT_NOT_ANCHORED"
    assert out["ac1"]["ac1_passed"] is False
    assert "yo" in out["ac1"]["lexicon_unanchored"]
    assert out["ac2"]["ac2_passed"] is False
    assert "yo" in out["ac2"]["tts_pending_languages"]
    assert out["ac3"]["ac3_passed"] is False
    assert out["ac3"]["blind_sampling_weekly_active"] is False


def test_ac1_has_a1_units_for_stage1_languages() -> None:
    out = verify_phase1_a1_beta_exit(as_of=date(2026, 10, 27))
    units = out["ac1"]["a1_units_by_lang"]
    for lang in ("yo", "ig", "ha", "pcm", "sw", "zu", "xh"):
        assert units[lang] >= 6


def test_append_verification_ledger_row() -> None:
    store: dict = {}
    row = append_verification_ledger_row(
        store,
        {
            "card_id": CARD_ID,
            "gate": "G5",
            "measured_on": "2026-10-27",
            "gate_passed": False,
            "failure_code": "PHASE1_CONTENT_NOT_ANCHORED",
            "measurement_status": "measured_checklist",
        },
    )
    assert store["phase1_a1_beta_verifications"] == [row]


def test_ledger_must_exist() -> None:
    ledger = _REPO_ROOT / "assets/content/phase1_a1_beta_ledger.json"
    assert ledger.is_file()
    data = json.loads(ledger.read_text(encoding="utf-8"))
    assert data["card_id"] == CARD_ID


def test_bad_store_raises() -> None:
    with pytest.raises(Phase1ExitError):
        append_verification_ledger_row({"phase1_a1_beta_verifications": "nope"}, {"card_id": CARD_ID})
