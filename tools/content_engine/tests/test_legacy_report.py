"""Spec tests for legacy rebuild dashboard (P4-088)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.report import (  # noqa: E402
    CARD_ID,
    ReportError,
    build_counts,
    dashboard_payload,
    run_report,
)
from tools.content_engine.legacy.salvage import pipeline_input_dir  # noqa: E402

from tools.content_engine.tests.test_legacy_salvage import (  # noqa: E402
    _mini_curriculum,
    _write_curriculum,
)


def test_P4_088_AC1_dashboard_counts_sum_to_legacy_total(tmp_path: Path) -> None:
    curriculum = _write_curriculum(tmp_path, _mini_curriculum())
    stages = {
        "grammar": {"lessons_affected": 1},
        "dialogues": {"regenerated": 2},
        "structure": {"units_rebuilt": 1},
        "tone": {"derived": 1, "removed": 0},
        "ui": {"strings_total": 3},
    }
    result = run_report(
        tmp_path,
        dry_run=True,
        curriculum_path=curriculum,
        stage_manifests=stages,
    )
    c = result.counts
    assert c.salvaged + c.rebuilt + c.dropped == c.legacy_total
    payload = dashboard_payload(c, result.stages)
    assert payload["card"] == CARD_ID
    assert payload["salvaged"] == c.salvaged
    assert payload["rebuilt"] == 8


def test_P4_088_AC2_count_mismatch_raises() -> None:
    with pytest.raises(ReportError) as exc:
        build_counts(3, 2, 1, legacy_total=10)
    assert exc.value.code == "REPORT_COUNT_MISMATCH"


def test_P4_088_dry_run_lists_changes_without_write(tmp_path: Path) -> None:
    curriculum = _write_curriculum(tmp_path, _mini_curriculum())
    dashboard = pipeline_input_dir(tmp_path) / "legacy_rebuild_dashboard.json"
    result = run_report(
        tmp_path,
        dry_run=True,
        curriculum_path=curriculum,
        stage_manifests={},
    )
    assert not dashboard.is_file()
    assert result.counts.rebuilt == 0


def test_P4_088_rerun_is_idempotent(tmp_path: Path) -> None:
    curriculum = _write_curriculum(tmp_path, _mini_curriculum())
    stages = {"grammar": {}, "dialogues": {}, "structure": {}, "tone": {}, "ui": {}}
    first = run_report(
        tmp_path,
        dry_run=False,
        curriculum_path=curriculum,
        stage_manifests=stages,
    )
    path = first.dashboard_path
    assert path.is_file()
    before = path.read_text(encoding="utf-8")
    second = run_report(
        tmp_path,
        dry_run=False,
        curriculum_path=curriculum,
        stage_manifests=stages,
    )
    assert path.read_text(encoding="utf-8") == before
    assert second.counts == first.counts
