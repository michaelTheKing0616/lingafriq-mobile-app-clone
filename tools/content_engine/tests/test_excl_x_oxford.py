"""Oxford Languages commercial licence-required (P4-018)."""

from __future__ import annotations

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
    scan_manifest,
)

_OXFORD_LICENCE = "Commercial licence not held"
_PENDING_ACTION = "request a quote"
_QUOTE_COVERS = "tone-marked headwords, examples, and the right to display"
_DATASETS = "Hausa, isiXhosa, Igbo, Yoruba"
_API_LANGUAGES = "Swahili"


def test_oxford_languages_licence_required_pending_quote() -> None:
    table = load_exclusions()
    row = table["sources"]["oxford-languages"]
    assert row["status"] == "licence-required"
    assert row["licence"] == _OXFORD_LICENCE
    assert row["pending_action"] == _PENDING_ACTION
    assert row["quote_covers"] == _QUOTE_COVERS
    assert row["request_sent"] is False
    assert row["datasets"] == _DATASETS
    assert row["api_languages"] == _API_LANGUAGES
    assert row["commercial_licence_document"] == ""
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False
    enforce_row({**row, "source_id": "oxford-languages"})


def test_manifest_oxford_languages_lexicon_fails_excluded_source_used() -> None:
    table = load_exclusions()
    with pytest.raises(ExclusionEnforceError) as exc_info:
        scan_manifest(
            [{"source_id": "oxford-languages", "layer": "lexicon"}],
            table,
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "EXCLUDED_SOURCE_USED"
    assert "oxford-languages" in message
