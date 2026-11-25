"""Tests for CC evidence sources in the licence register (P4-004)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
    ingest_story,
    leipzig_use,
    load_register_csv,
    validate_rows,
)

_REGISTER_CSV = (
    Path(__file__).resolve().parents[1] / "licences" / "register.csv"
)

_CC_SOURCE_IDS = frozenset(
    {
        "leipzig-corpora",
        "fleurs",
        "waxal-ghana",
        "waxal-other",
        "african-storybook",
    }
)


def _row_by_id(source_id: str) -> dict[str, str]:
    rows = load_register_csv(_REGISTER_CSV)
    return next(r for r in rows if r["source_id"] == source_id)


def test_seeded_cc_rows_validate_in_full_register() -> None:
    rows = load_register_csv(_REGISTER_CSV)
    seeded = [r for r in rows if r["source_id"] in _CC_SOURCE_IDS]
    assert len(seeded) == 5
    validate_rows(rows)


def test_leipzig_excluded_uses_and_leipzig_use() -> None:
    row = _row_by_id("leipzig-corpora")
    assert row["excluded_uses"] == "web services and applications (CC BY-NC)"
    with pytest.raises(LicenceRegisterError) as exc_info:
        leipzig_use("application")
    assert exc_info.value.code == "LICENCE_NC_EXCLUDED"
    assert leipzig_use("download") is None


def test_fleurs_languages_and_licence() -> None:
    row = _row_by_id("fleurs")
    assert row["licence"] == "CC BY 4.0"
    assert row["languages"] == "yo,ig,ha,sw,xh,zu"


def test_waxal_other_share_alike_and_display() -> None:
    row = _row_by_id("waxal-other")
    assert row["share_alike"] == "true"
    assert row["display"] == "false"
    assert row["training"] == "false"


def test_waxal_ghana_licence() -> None:
    row = _row_by_id("waxal-ghana")
    assert row["licence"] == "CC BY 4.0"
    assert row["share_alike"] == "false"


def test_ingest_story_rejects_by_nc() -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        ingest_story({"licence": "CC BY-NC", "author": "Ada"})
    assert exc_info.value.code == "LICENCE_NC_EXCLUDED"


def test_ingest_story_accepts_cc_by_with_author() -> None:
    story = ingest_story({"licence": "CC BY", "author": "Ada"})
    assert story["author"] == "Ada"


def test_ingest_story_requires_author() -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        ingest_story({"licence": "CC BY", "author": "   "})
    assert exc_info.value.code == "STORY_AUTHOR_MISSING"


def test_african_storybook_igbo_evidence_note() -> None:
    row = _row_by_id("african-storybook")
    igbo = row.get("igbo_cc_by_titles", "").strip()
    assert igbo in ("none", "unverified") or igbo.isdigit()
    note = (
        Path(__file__).resolve().parents[1]
        / "licences"
        / "storybook_igbo_2026-10-23.md"
    )
    assert note.is_file()
    text = note.read_text(encoding="utf-8")
    assert text.splitlines()[0] == "charter: v2"
    assert "2026-10-23" in text
