"""PanLex exclusion pending written permission (P4-013)."""

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

_PANLEX_LICENCE = "CC BY-NC-SA 4.0"
_PANLEX_EMAIL = "info@panlex.org"
_PANLEX_DRAFT = (
    "LingAfriq is a paid language-learning app and needs written permission "
    "before any use of PanLex, including training and evidence."
)


def test_panlex_excluded_pending_written_permission() -> None:
    table = load_exclusions()
    row = table["sources"]["panlex"]
    assert row["status"] == "excluded"
    assert row["licence"] == _PANLEX_LICENCE
    assert row["permission_email"] == _PANLEX_EMAIL
    assert row["permission_status"] == "pending"
    assert row["reply"] == ""
    assert row["permission_draft"].strip() == _PANLEX_DRAFT
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "panlex"})
