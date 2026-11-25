"""P5-030 dialogue libraries: DL-001, i+1, content-graph surfaces."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.dialogue_linter import (  # noqa: E402
    RULE_DL001,
    RULE_DL003,
    dl001_findings,
    lint_all_stage1_libraries,
    lint_dialogue_library,
    lint_legacy_bundle,
    load_dialogue_library,
)

_LEGACY_A1 = _REPO_ROOT / "assets/data/lingafriq_authentic_curriculum_a1.json"


def test_P5_030_stage1_libraries_lint_clean() -> None:
    findings = lint_all_stage1_libraries(root=_REPO_ROOT)
    assert findings == []


def test_P5_030_content_graph_surfaces_on_yo_pilot() -> None:
    doc = load_dialogue_library("yo", root=_REPO_ROOT)
    findings = lint_dialogue_library(doc, root=_REPO_ROOT)
    assert findings == []
    first = doc["dialogues"][0]
    surfaces = first["content_graph"]["surfaces"]
    assert "lessons" in surfaces
    assert "scenario_theatre" in surfaces
    assert "market_haggle" in surfaces
    assert "greeting_gauntlet" in surfaces


def test_P5_030_DL001_legacy_bundle_has_repeat_findings() -> None:
    assert _LEGACY_A1.is_file()
    findings = lint_legacy_bundle(_LEGACY_A1)
    dl001 = [f for f in findings if f.rule_id == RULE_DL001]
    assert len(dl001) >= 100


def test_P5_030_DL001_within_dialogue_repeat() -> None:
    findings = dl001_findings(
        "test.dlg.x",
        ["Ẹ káàbọ̀", "Ẹ káàbọ̀"],
    )
    assert len(findings) == 1
    assert findings[0].rule_id == RULE_DL001


def test_P5_030_unit_binding_resolves_dialogue() -> None:
    doc = load_dialogue_library("sw", root=_REPO_ROOT)
    bound = {b["dialogue_id"] for b in doc["unit_bindings"]}
    ids = {d["id"] for d in doc["dialogues"]}
    assert bound == ids
    for dialogue in doc["dialogues"]:
        assert dialogue["turns"][0]["audio"]["kind"] in ("human", "tts_synthetic")
