"""Cited culture cards: CU-001..003 and stage-1 libraries (P5-034)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.culture_linter import (  # noqa: E402
    RULE_CU001,
    RULE_CU002,
    RULE_CU003,
    cu_findings,
    lint_all_culture_files,
    lint_culture_library,
)

_CULTURE_DIR = _REPO_ROOT / "assets" / "data" / "culture"
_STAGE1 = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
_THEMES = ("greetings", "kinship", "food", "festivals")


def _load(lang: str) -> dict:
    return json.loads((_CULTURE_DIR / f"{lang}.json").read_text(encoding="utf-8"))


def test_P5_034_all_stage1_libraries_lint_clean() -> None:
    findings = lint_all_culture_files(root=_REPO_ROOT)
    assert findings == []


def test_P5_034_each_language_has_four_theme_cards() -> None:
    for lang in _STAGE1:
        document = _load(lang)
        assert document["language"] == lang
        by_id = {row["id"]: row for row in document["cards"]}
        for theme in _THEMES:
            card_id = f"{lang}.culture.{theme}"
            assert card_id in by_id
            card = by_id[card_id]
            assert card["label"] == "expert_reviewed"
            assert card["label"] != "beta"
            assert card["claims"][0]["source_ref"].strip()
            assert card["provenance"]["sources"][0]["uri_or_citation"].strip()


def test_cu001_fails_when_claim_lacks_linked_citation() -> None:
    document = _load("yo")
    broken = dict(document["cards"][0])
    broken["claims"] = [
        {
            "kind": "cultural",
            "source_ref": "invented:missing-register",
            "text": "Unsupported claim.",
            "confidence": 0.9,
            "confidence_floor": 0.85,
        }
    ]
    findings = cu_findings(broken)
    assert any(f.rule_id == RULE_CU001 for f in findings)


def test_cu002_fails_on_beta_label() -> None:
    document = _load("yo")
    broken = dict(document["cards"][0])
    broken["label"] = "beta"
    findings = cu_findings(broken)
    assert any(f.rule_id == RULE_CU002 for f in findings)


def test_cu003_requires_cultural_reviewer() -> None:
    document = _load("yo")
    broken = dict(document["cards"][0])
    broken.pop("review", None)
    findings = cu_findings(broken)
    assert any(f.rule_id == RULE_CU003 for f in findings)


def test_missing_theme_card_reported() -> None:
    document = _load("yo")
    document = dict(document)
    document["cards"] = [c for c in document["cards"] if c["id"] != "yo.culture.festivals"]
    findings = lint_culture_library(document, root=_REPO_ROOT)
    assert any(f.card_id == "yo.culture.festivals" for f in findings)
