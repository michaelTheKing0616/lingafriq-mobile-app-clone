"""NaijaVoices exclusion with unverified waiver quotes (P4-014)."""

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

_NAIJA_LICENCE = "CC BY-NC-SA 4.0"
_WAIVER_TIER = "$5,000+"
_WAIVER_TERM = "12 months"


def test_naijavoices_excluded_with_unverified_waiver_quotes() -> None:
    table = load_exclusions()
    row = table["sources"]["naijavoices"]
    assert row["status"] == "excluded"
    assert row["licence"] == _NAIJA_LICENCE
    assert row["waiver_recorded"] is False
    assert row["waiver_tier_quote"] == _WAIVER_TIER
    assert row["waiver_term_quote"] == _WAIVER_TERM
    assert row["waiver_quote_status"] == "unverified"
    assert row["waiver_revocable"] is True
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "naijavoices"})
