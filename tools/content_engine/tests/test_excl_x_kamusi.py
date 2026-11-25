"""Kamusi exclusion pending commercial licence on request (P4-016)."""

from __future__ import annotations

import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.exclusion_enforce import (  # noqa: E402
    enforce_row,
    load_exclusions,
)

_KAMUSI_LICENCE = "CC BY-NC-SA"
_PENDING_ACTION = "commercial licence on request"
_SWAHILI_GAP_DECISION = "optional"


def test_kamusi_excluded_pending_commercial_licence_on_request() -> None:
    table = load_exclusions()
    row = table["sources"]["kamusi"]
    assert row["status"] == "excluded"
    assert row["licence"] == _KAMUSI_LICENCE
    assert row["pending_action"] == _PENDING_ACTION
    assert row["swahili_gap_decision"] == _SWAHILI_GAP_DECISION
    assert row["request_sent"] is False
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "kamusi"})
