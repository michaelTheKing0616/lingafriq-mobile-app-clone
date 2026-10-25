"""Spec tests for legacy bundle quarantine (P4-081)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.quarantine import (  # noqa: E402
    CANONICAL_SALVAGE_SOURCE,
    DUPLICATE_EXPANDED_BUNDLE,
    PLACEHOLDER_AUTHENTIC_BUNDLES,
    QUARANTINE_SOURCES,
    build_excluded_relpaths,
    load_manifest,
    manifest_path,
    path_is_build_excluded,
    quarantine_dir,
    run_quarantine,
    salvage_source_path,
)


def _mini_repo(tmp_path: Path) -> None:
    for rel in QUARANTINE_SOURCES:
        path = tmp_path / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if rel.endswith(".json"):
            path.write_text('{"placeholder": true}\n', encoding="utf-8")
        else:
            path.mkdir(parents=True, exist_ok=True)
            (path / "stub.json").write_text('{"word": "word1a"}\n', encoding="utf-8")


def test_P4_081_sources_match_curriculum_eight_one() -> None:
    assert len(PLACEHOLDER_AUTHENTIC_BUNDLES) == 3
    assert CANONICAL_SALVAGE_SOURCE in PLACEHOLDER_AUTHENTIC_BUNDLES
    assert DUPLICATE_EXPANDED_BUNDLE in QUARANTINE_SOURCES
    assert len(QUARANTINE_SOURCES) == 4


def test_P4_081_AC1_dry_run_lists_moves(tmp_path: Path) -> None:
    _mini_repo(tmp_path)
    result = run_quarantine(tmp_path, dry_run=True)
    moves = [a for a in result.actions if a.action == "move"]
    assert len(moves) == len(QUARANTINE_SOURCES)
    assert not manifest_path(tmp_path).exists()


def test_P4_081_AC1_moves_out_of_build_paths(tmp_path: Path) -> None:
    _mini_repo(tmp_path)
    run_quarantine(tmp_path, dry_run=False)
    for rel in QUARANTINE_SOURCES:
        assert not (tmp_path / rel).exists()
        assert (tmp_path / "quarantine/legacy" / rel).exists()
    assert path_is_build_excluded(quarantine_dir(tmp_path), tmp_path)
    assert path_is_build_excluded(salvage_source_path(tmp_path), tmp_path)


def test_P4_081_AC2_rerun_is_idempotent_and_writes_manifest(tmp_path: Path) -> None:
    _mini_repo(tmp_path)
    run_quarantine(tmp_path, dry_run=False)
    first = load_manifest(tmp_path)
    assert first is not None
    assert len(first["quarantined"]) == len(QUARANTINE_SOURCES)

    second_result = run_quarantine(tmp_path, dry_run=False)
    assert all(a.action == "skip" for a in second_result.actions)
    second = load_manifest(tmp_path)
    assert second["quarantined"] == first["quarantined"]
    assert salvage_source_path(tmp_path).is_file()
    excluded = build_excluded_relpaths(tmp_path)
    assert QUARANTINE_SOURCES[0] not in excluded
    assert any(p.startswith("quarantine/legacy/") for p in excluded)


def test_P4_081_manifest_invalid_json_raises(tmp_path: Path) -> None:
    qdir = quarantine_dir(tmp_path)
    qdir.mkdir(parents=True)
    manifest_path(tmp_path).write_text("{", encoding="utf-8")
    with pytest.raises(json.JSONDecodeError):
        load_manifest(tmp_path)
