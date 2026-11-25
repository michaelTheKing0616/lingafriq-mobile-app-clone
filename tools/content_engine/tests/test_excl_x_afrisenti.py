"""AfriSenti exclusion declaration (P4-012)."""

from __future__ import annotations

import copy
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.exclusion_enforce import (  # noqa: E402
    ExclusionEnforceError,
    enforce_row,
    load_exclusions,
)

_AFRISENTI_HF_CARD = "CC BY 4.0"
_AFRISENTI_CONFLICT = (
    "HF card says CC BY 4.0; the paper restricts commercial use without creator approval"
)
_AFRISENTI_ACTION = "ask-the-creators"


def test_afrisenti_excluded_with_hf_conflict_and_creator_action() -> None:
    table = load_exclusions()
    row = table["sources"]["afrisenti"]
    assert row["status"] == "excluded"
    assert row["licence"] == "non-commercial"
    assert row["licence"] != _AFRISENTI_HF_CARD
    assert row["hf_card_licence"] == _AFRISENTI_HF_CARD
    assert row["conflict"] == _AFRISENTI_CONFLICT
    assert row["action"] == _AFRISENTI_ACTION
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "afrisenti"})


def test_afrisenti_display_true_with_empty_document_fails_nc_excluded() -> None:
    table = load_exclusions()
    row = copy.deepcopy(table["sources"]["afrisenti"])
    row["uses"] = {"display": True, "evidence": False, "training": False}
    with pytest.raises(ExclusionEnforceError) as exc_info:
        enforce_row({**row, "source_id": "afrisenti"})
    assert exc_info.value.code == "NC_EXCLUDED"
