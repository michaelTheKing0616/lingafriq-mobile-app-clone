"""Helsinki Swahili-2 exclusion with unverified ELRA quotes (P4-017)."""

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

_HCS_LICENCE = "academic-only CLARIN ACA"
_ELRA_MEMBER_QUOTE = "EUR 7,500 (member)"
_ELRA_QUOTE = "EUR 15,000"


def test_helsinki_swahili_2_excluded_with_unverified_elra_quotes() -> None:
    table = load_exclusions()
    row = table["sources"]["helsinki-swahili-2"]
    assert row["status"] == "excluded"
    assert row["licence"] == _HCS_LICENCE
    assert row["elra_member_quote"] == _ELRA_MEMBER_QUOTE
    assert row["elra_quote"] == _ELRA_QUOTE
    assert row["quote_status"] == "unverified"
    assert row["purchase_recorded"] is False
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "helsinki-swahili-2"})
