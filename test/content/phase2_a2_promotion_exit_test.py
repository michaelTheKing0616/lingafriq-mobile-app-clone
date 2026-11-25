"""P5-078 Phase 2 A2 + promotion exit gate (CURRICULUM §9.2)."""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.phase2_a2_promotion_exit import (  # noqa: E402
    CARD_ID,
    Phase2ExitError,
    append_verification_ledger_row,
    verify_phase2_a2_promotion_exit,
)


def test_measured_checklist_fails_until_ledger_and_content_close() -> None:
    out = verify_phase2_a2_promotion_exit(as_of=date(2026, 10, 27))
    assert out["card_id"] == CARD_ID
    assert out["gate"] == "G6"
    assert out["measurement_status"] == "measured_checklist"
    assert out["gate_passed"] is False
    assert out["failure_code"] == "PHASE2_A2_NOT_PUBLISHED"
    assert out["ac1"]["ac1_passed"] is False
    assert "ha" in out["ac1"]["a2_lexicon"]["missing_manifest"]
    assert "yo" in out["ac1"]["a2_unpublished_languages"]
    assert out["ac2"]["ac2_passed"] is False
    assert out["ac2"]["ext13_gated"] is True


def test_ac1_has_a2_units_mapped_for_stage1_languages() -> None:
    out = verify_phase2_a2_promotion_exit(as_of=date(2026, 10, 27))
    counts = out["ac1"]["a2_units_in_cando_by_lang"]
    for lang in ("yo", "ig", "ha", "pcm", "sw", "zu", "xh"):
        assert counts[lang] >= 6


def test_append_verification_ledger_row() -> None:
    store: dict = {}
    row = append_verification_ledger_row(
        store,
        {
            "card_id": CARD_ID,
            "gate": "G6",
            "measured_on": "2026-10-27",
            "gate_passed": False,
            "failure_code": "PHASE2_A2_NOT_PUBLISHED",
            "measurement_status": "measured_checklist",
        },
    )
    assert store["phase2_a2_promotion_verifications"] == [row]


def test_ledger_must_exist() -> None:
    ledger = _REPO_ROOT / "assets/content/phase2_a2_promotion_ledger.json"
    assert ledger.is_file()
    data = json.loads(ledger.read_text(encoding="utf-8"))
    assert data["card_id"] == CARD_ID


def test_bad_store_raises() -> None:
    with pytest.raises(Phase2ExitError):
        append_verification_ledger_row(
            {"phase2_a2_promotion_verifications": "nope"},
            {"card_id": CARD_ID},
        )
