"""Yoruba A1 aspect patterns ń, ti, máa (P5-021)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.pattern_linter import lint_pattern_library  # noqa: E402

_YO_PATTERNS = _REPO_ROOT / "assets" / "data" / "patterns" / "yo.json"
_EXPECTED_IDS = ("yo.pat.progressive", "yo.pat.perfect", "yo.pat.future")
_MARKER_IN_FORM = ("ń", "ti", "máa")


def _load_library() -> dict:
    return json.loads(_YO_PATTERNS.read_text(encoding="utf-8"))


def test_P5_021_library_lints_clean() -> None:
    document = _load_library()
    findings, gaps = lint_pattern_library(document, root=_REPO_ROOT)
    assert findings == []
    assert gaps == []


def test_P5_021_three_aspect_entries_with_citations() -> None:
    document = _load_library()
    assert document["language"] == "yo"
    patterns = document["patterns"]
    assert len(patterns) == 3
    by_id = {row["id"]: row for row in patterns}
    assert tuple(by_id) == _EXPECTED_IDS
    for pattern_id, marker in zip(_EXPECTED_IDS, _MARKER_IN_FORM, strict=True):
        entry = by_id[pattern_id]
        assert entry["label"] == "expert_reviewed"
        assert entry["label"] != "beta"
        assert entry["cefr"] == "A1"
        assert marker in entry["form"] or any(marker in ex for ex in entry["examples"])
        assert entry["contrasts"]
        assert entry["common_errors"]
        sources = entry["provenance"]["sources"]
        assert sources and sources[0]["uri_or_citation"].strip()
        assert entry["claims"][0]["source_ref"].strip()
