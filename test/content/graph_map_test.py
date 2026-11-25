"""P5-032 content graph → feature surface map."""

from __future__ import annotations

import copy
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.graph_map_check import (  # noqa: E402
    RULE_GM002,
    RULE_GM003,
    check_feature_binding,
    exercise_item_irt_eligible,
    lint_all,
    lint_exercise_pool,
    load_content_graph_map,
    validate_map_structure,
)


def test_P5_032_map_loader_and_structure_clean() -> None:
    doc = load_content_graph_map(root=_REPO_ROOT)
    assert doc["card"] == "P5-032"
    findings = validate_map_structure(doc)
    assert findings == []


def test_P5_032_lexeme_feeds_word_card_and_games() -> None:
    doc = load_content_graph_map(root=_REPO_ROOT)
    feeds = set(doc["graph_nodes"]["lexeme"]["feeds"])
    assert "word_card" in feeds
    assert "games_word_pool" in feeds
    assert "flashcards" in feeds


def test_P5_032_siloed_binding_fails_gm002() -> None:
    doc = load_content_graph_map(root=_REPO_ROOT)
    good = doc["feature_bindings"][0]
    assert check_feature_binding(good, doc) == []
    siloed = copy.deepcopy(good)
    siloed["read_mode"] = "embedded_lexicon_copy"
    findings = check_feature_binding(siloed, doc)
    assert any(f.rule_id == RULE_GM002 for f in findings)


def test_P5_032_checkpoint_requires_calibrated_irt() -> None:
    calibrated = {
        "id": "yo.item.test",
        "irt": {"irt_status": "calibrated", "a": 1.0, "b": 0.0},
    }
    uncalibrated = {"id": "yo.item.bad", "irt": {"irt_status": "uncalibrated"}}
    assert exercise_item_irt_eligible(calibrated, surface="checkpoints")
    assert not exercise_item_irt_eligible(uncalibrated, surface="checkpoints")
    assert exercise_item_irt_eligible(uncalibrated, surface="lesson_recap")
    pool_findings = lint_exercise_pool(
        [calibrated, uncalibrated],
        surface="placement_test",
    )
    assert len(pool_findings) == 1
    assert pool_findings[0].rule_id == RULE_GM003


def test_P5_032_repo_lint_clean() -> None:
    assert lint_all(root=_REPO_ROOT) == []
