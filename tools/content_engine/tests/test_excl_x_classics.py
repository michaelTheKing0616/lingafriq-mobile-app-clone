"""Classic dictionaries excluded until copyright confirmed (P4-019)."""

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

_CLASSIC_IDS = ("abraham-yoruba-1958", "bargery-hausa-1934")
_LICENCE = "Copyright unconfirmed"
_EVIDENCE_NOTE = "tools/content_engine/licences/classic_dictionaries_2026-10-23.md"
_NOTE_PATH = _REPO_ROOT / _EVIDENCE_NOTE


def test_classic_dictionaries_excluded_unconfirmed_copyright() -> None:
    table = load_exclusions()
    for source_id in _CLASSIC_IDS:
        row = table["sources"][source_id]
        assert row["status"] == "excluded"
        assert row["licence"] == _LICENCE
        assert row["copyright_status"] == "unconfirmed"
        assert row["pd_confirmed"] is False
        assert row["evidence_note"] == _EVIDENCE_NOTE
        assert row["commercial_licence_document"] == ""
        assert row["uses"]["display"] is False
        assert row["uses"]["evidence"] is False
        assert row["uses"]["training"] is False
        enforce_row({**row, "source_id": source_id})


def test_classic_dictionaries_evidence_note_content() -> None:
    text = _NOTE_PATH.read_text(encoding="utf-8")
    assert "2026-10-23" in text
    assert "unconfirmed" in text.lower()
    assert "excluded" in text.lower()
    assert "abraham-yoruba-1958" in text
    assert "bargery-hausa-1934" in text
