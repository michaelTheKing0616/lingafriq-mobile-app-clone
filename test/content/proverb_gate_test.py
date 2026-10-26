"""Proverb publish gate: cited collection + linguist approval (P5-035)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.proverb_gate import (  # noqa: E402
    CODE_PROVERB_UNCITED,
    CODE_PROVERB_UNREVIEWED,
    ProverbGateError,
    RULE_PV001,
    RULE_PV002,
    RULE_PV003,
    lint_all_proverb_files,
    lint_proverb_entry,
    lint_proverb_library,
    main,
    pv_findings,
)


def _valid_proverb() -> dict:
    return {
        "id": "zu.proverb.izandla",
        "text": "Izandla ziyagezana",
        "translation_en": "Hands wash each other.",
        "label": "expert_reviewed",
        "provenance": {
            "author": "content-studio",
            "created_at": "2026-10-26T22:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "Peace Corps isiZulu Language Manual",
                    "licence": "public-domain",
                    "uri_or_citation": "register:peace-corps-zu; CURRICULUM.md#§4:L568-L569",
                    "retrieved_at": "2026-10-26T22:00:00Z",
                }
            ],
        },
        "claims": [
            {
                "kind": "cultural",
                "source_ref": "register:peace-corps-zu",
                "text": "Proverb attested in Peace Corps isiZulu materials.",
                "confidence": 0.9,
                "confidence_floor": 0.85,
            }
        ],
        "confidence": 0.9,
        "risk_tags": ["proverb"],
        "audio": [],
        "review": {
            "reviewers": [
                {
                    "role": "linguist",
                    "reviewer_id": "zu-linguist-1",
                    "approved": True,
                }
            ]
        },
    }


def test_P5_035_no_published_proverb_dir_is_clean() -> None:
    assert lint_all_proverb_files(root=_REPO_ROOT) == []


def test_valid_proverb_passes() -> None:
    assert lint_proverb_entry(_valid_proverb()) == []


def test_proverb_unreviewed_without_linguist() -> None:
    broken = dict(_valid_proverb())
    broken["review"] = {"reviewers": [{"role": "native", "reviewer_id": "n1", "approved": True}]}
    findings = pv_findings(broken)
    assert any(f.code == CODE_PROVERB_UNREVIEWED and f.rule_id == RULE_PV003 for f in findings)


def test_proverb_unreviewed_on_beta_label() -> None:
    broken = dict(_valid_proverb())
    broken["label"] = "beta"
    findings = pv_findings(broken)
    assert any(f.code == CODE_PROVERB_UNREVIEWED and f.rule_id == RULE_PV002 for f in findings)


def test_native_verified_label_passes() -> None:
    row = dict(_valid_proverb())
    row["label"] = "native_verified"
    assert lint_proverb_entry(row) == []


def test_uncited_proverb_fails_pv001() -> None:
    broken = dict(_valid_proverb())
    broken["claims"] = [
        {
            "kind": "cultural",
            "source_ref": "invented:missing",
            "text": "No link.",
            "confidence": 0.9,
            "confidence_floor": 0.85,
        }
    ]
    findings = pv_findings(broken)
    assert any(f.code == CODE_PROVERB_UNCITED and f.rule_id == RULE_PV001 for f in findings)


def test_non_proverb_entry_skipped() -> None:
    row = {"id": "zu.lexeme.demo", "label": "beta", "risk_tags": ["tone"]}
    assert pv_findings(row) == []


def test_lint_proverb_library_and_cli(tmp_path: Path) -> None:
    doc = {"language": "zu", "proverbs": [_valid_proverb()]}
    assert lint_proverb_library(doc) == []
    lib_path = tmp_path / "zu.json"
    lib_path.write_text(json.dumps(doc), encoding="utf-8")
    assert main([str(lib_path)]) == 0
    broken = dict(doc)
    broken["proverbs"] = [dict(_valid_proverb(), review={})]
    bad_path = tmp_path / "bad.json"
    bad_path.write_text(json.dumps(broken), encoding="utf-8")
    assert main([str(bad_path)]) == 1


def test_lint_proverb_library_invalid_document() -> None:
    with pytest.raises(ProverbGateError):
        lint_proverb_library({})
    with pytest.raises(ProverbGateError):
        lint_proverb_entry("not-a-map")  # type: ignore[arg-type]


def test_idiom_risk_tag_triggers_gate() -> None:
    row = dict(_valid_proverb())
    row["id"] = "ha.idiom.sample"
    row["risk_tags"] = ["idiom"]
    assert lint_proverb_entry(row) == []


def test_main_default_clean() -> None:
    assert main([]) == 0


def test_missing_provenance_sources_fails() -> None:
    broken = dict(_valid_proverb())
    broken["provenance"] = {
        "author": "x",
        "created_at": "2026-10-26T22:00:00Z",
        "ai_assisted": False,
        "sources": [],
    }
    findings = pv_findings(broken)
    assert any(f.code == CODE_PROVERB_UNCITED for f in findings)
