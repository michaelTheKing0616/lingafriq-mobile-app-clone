"""Pattern Library schema and PL-001 linter (P5-020)."""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.pattern_linter import (  # noqa: E402
    CARD_ID,
    PatternLintError,
    PatternMissing,
    coverage_for_language,
    lint_pattern_entry,
    lint_pattern_library,
    load_pattern_schema,
    pattern_validator,
    pl001_findings,
)

_FIXTURE = _REPO_ROOT / "test" / "content" / "fixtures" / "pattern_yo_copula.json"


def _load_fixture() -> dict:
    return json.loads(_FIXTURE.read_text(encoding="utf-8"))


def test_pattern_schema_is_valid_json_schema() -> None:
    schema = load_pattern_schema(_REPO_ROOT)
    Draft202012Validator.check_schema(schema)


def test_fixture_passes_linter() -> None:
    entry = _load_fixture()
    assert lint_pattern_entry(entry, root=_REPO_ROOT) == []


def test_pl001_missing_example() -> None:
    entry = _load_fixture()
    entry = copy.deepcopy(entry)
    entry["examples"] = []
    findings = pl001_findings(entry)
    assert any(f.rule_id == "PL-001" for f in findings)


def test_pl001_missing_citation() -> None:
    entry = _load_fixture()
    entry = copy.deepcopy(entry)
    entry["provenance"] = {
        "author": "content-studio",
        "created_at": "2026-10-26T10:00:00Z",
        "ai_assisted": False,
        "sources": [],
    }
    entry["claims"] = []
    findings = pl001_findings(entry)
    assert any("citation" in f.detail for f in findings)
    with pytest.raises(PatternLintError):
        lint_pattern_entry(entry, root=_REPO_ROOT)


def test_library_coverage_pattern_missing() -> None:
    document = {
        "language": "yo",
        "kit_pattern_ids": ["yo.pat.copulapresent", "yo.pat.progressive"],
        "patterns": [_load_fixture()],
        "gaps": [
            {
                "pattern_id": "yo.pat.progressive",
                "language": "yo",
                "status": "PatternMissing",
            }
        ],
    }
    findings, gaps = lint_pattern_library(document, root=_REPO_ROOT)
    assert findings == []
    assert gaps == []


def test_library_coverage_undeclared_gap_fails() -> None:
    document = {
        "language": "sw",
        "kit_pattern_ids": ["sw.pat.present"],
        "patterns": [],
    }
    findings, gaps = lint_pattern_library(document, root=_REPO_ROOT)
    assert findings == []
    assert gaps == [PatternMissing(pattern_id="sw.pat.present", language="sw")]


def test_coverage_helper() -> None:
    gaps = coverage_for_language(
        "ha",
        [],
        kit_pattern_ids=["ha.pat.copula"],
    )
    assert gaps[0].status == "PatternMissing"


def test_stage1_language_constant_count() -> None:
    from tools.content.pattern_linter import STAGE1_LANGUAGES

    assert len(STAGE1_LANGUAGES) == 7
    assert CARD_ID == "P5-020"
