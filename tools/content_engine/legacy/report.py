"""Before/after legacy rebuild dashboard (P4-088, CURRICULUM §8.8)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import (
    is_real_phrase,
    iter_candidates,
    pipeline_input_dir,
    resolve_curriculum_path,
)

CARD_ID = "P4-088"
DASHBOARD_BASENAME = "legacy_rebuild_dashboard.json"

_SALVAGE_MANIFEST = "legacy_salvage_manifest.json"
_GRAMMAR_MANIFEST = "legacy_grammar_cleanup_manifest.json"
_DIALOGUES_MANIFEST = "legacy_dialogues_manifest.json"
_STRUCTURE_MANIFEST = "legacy_structure_manifest.json"
_TONE_MANIFEST = "legacy_tone_claims_manifest.json"
_UI_MANIFEST = "legacy_ui_strings_manifest.json"


class ReportError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class RebuildCounts:
    salvaged: int
    rebuilt: int
    dropped: int
    legacy_total: int


@dataclass(frozen=True)
class StageDetail:
    grammar_lessons_affected: int
    dialogues_regenerated: int
    structure_units_rebuilt: int
    tone_claims_changed: int
    ui_strings_processed: int


@dataclass(frozen=True)
class DashboardResult:
    counts: RebuildCounts
    stages: StageDetail
    dashboard_path: Path
    written: bool


def _read_manifest(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def _int_field(manifest: Mapping[str, Any], key: str) -> int:
    value = manifest.get(key)
    if value is None:
        return 0
    if isinstance(value, bool) or not isinstance(value, int):
        raise ReportError(
            "REPORT_MANIFEST_INVALID",
            f"manifest field {key} must be an integer",
        )
    return value


def phrase_buckets_from_curriculum(curriculum: Mapping[str, Any]) -> tuple[int, int]:
    salvaged = 0
    dropped = 0
    for candidate in iter_candidates(curriculum):
        if is_real_phrase(candidate.text):
            salvaged += 1
        else:
            dropped += 1
    return salvaged, dropped


def rebuilt_from_stage_manifests(
    *,
    grammar: Mapping[str, Any],
    dialogues: Mapping[str, Any],
    structure: Mapping[str, Any],
    tone: Mapping[str, Any],
    ui: Mapping[str, Any],
) -> tuple[int, StageDetail]:
    grammar_lessons = _int_field(grammar, "lessons_affected")
    dialogues_regen = _int_field(dialogues, "regenerated")
    units_rebuilt = _int_field(structure, "units_rebuilt")
    tone_changed = _int_field(tone, "derived") + _int_field(tone, "removed")
    ui_total = _int_field(ui, "strings_total")
    detail = StageDetail(
        grammar_lessons_affected=grammar_lessons,
        dialogues_regenerated=dialogues_regen,
        structure_units_rebuilt=units_rebuilt,
        tone_claims_changed=tone_changed,
        ui_strings_processed=ui_total,
    )
    rebuilt = (
        grammar_lessons
        + dialogues_regen
        + units_rebuilt
        + tone_changed
        + ui_total
    )
    return rebuilt, detail


def build_counts(
    salvaged: int,
    rebuilt: int,
    dropped: int,
    *,
    legacy_total: int | None = None,
) -> RebuildCounts:
    total = legacy_total if legacy_total is not None else salvaged + rebuilt + dropped
    counts = RebuildCounts(
        salvaged=salvaged,
        rebuilt=rebuilt,
        dropped=dropped,
        legacy_total=total,
    )
    if counts.salvaged + counts.rebuilt + counts.dropped != counts.legacy_total:
        raise ReportError(
            "REPORT_COUNT_MISMATCH",
            "salvaged + rebuilt + dropped must equal legacy_total",
        )
    return counts


def load_stage_manifests(base: Path, curriculum_parent: Path) -> dict[str, dict[str, Any]]:
    pipeline = pipeline_input_dir(base)
    return {
        "salvage": _read_manifest(pipeline / _SALVAGE_MANIFEST),
        "grammar": _read_manifest(curriculum_parent / _GRAMMAR_MANIFEST),
        "dialogues": _read_manifest(curriculum_parent / _DIALOGUES_MANIFEST),
        "structure": _read_manifest(curriculum_parent / _STRUCTURE_MANIFEST),
        "tone": _read_manifest(pipeline / _TONE_MANIFEST),
        "ui": _read_manifest(pipeline / _UI_MANIFEST),
    }


def dashboard_payload(counts: RebuildCounts, stages: StageDetail) -> dict[str, Any]:
    return {
        "card": CARD_ID,
        "legacy_total": counts.legacy_total,
        "salvaged": counts.salvaged,
        "rebuilt": counts.rebuilt,
        "dropped": counts.dropped,
        "stages": {
            "grammar_lessons_affected": stages.grammar_lessons_affected,
            "dialogues_regenerated": stages.dialogues_regenerated,
            "structure_units_rebuilt": stages.structure_units_rebuilt,
            "tone_claims_changed": stages.tone_claims_changed,
            "ui_strings_processed": stages.ui_strings_processed,
        },
    }


def run_report(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    curriculum_path: Path | None = None,
    stage_manifests: Mapping[str, Mapping[str, Any]] | None = None,
) -> DashboardResult:
    base = repo_root(root)
    src = curriculum_path if curriculum_path is not None else resolve_curriculum_path(base)
    curriculum = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(curriculum, dict):
        raise TypeError("curriculum root must be an object")

    salvaged, dropped = phrase_buckets_from_curriculum(curriculum)

    if stage_manifests is not None:
        grammar = stage_manifests.get("grammar", {})
        dialogues = stage_manifests.get("dialogues", {})
        structure = stage_manifests.get("structure", {})
        tone = stage_manifests.get("tone", {})
        ui = stage_manifests.get("ui", {})
    else:
        loaded = load_stage_manifests(base, src.parent)
        salvage_manifest = loaded["salvage"]
        if salvage_manifest:
            salvaged = _int_field(salvage_manifest, "extracted")
            dropped = _int_field(salvage_manifest, "dropped_non_real")
        grammar = loaded["grammar"]
        dialogues = loaded["dialogues"]
        structure = loaded["structure"]
        tone = loaded["tone"]
        ui = loaded["ui"]

    rebuilt, stages = rebuilt_from_stage_manifests(
        grammar=grammar,
        dialogues=dialogues,
        structure=structure,
        tone=tone,
        ui=ui,
    )
    counts = build_counts(salvaged, rebuilt, dropped)
    out_path = pipeline_input_dir(base) / DASHBOARD_BASENAME
    written = False

    if not dry_run:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        body = json.dumps(dashboard_payload(counts, stages), indent=2, sort_keys=True) + "\n"
        if not (out_path.is_file() and out_path.read_text(encoding="utf-8") == body):
            out_path.write_text(body, encoding="utf-8")
        written = True

    return DashboardResult(counts, stages, out_path, written)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Produce before/after legacy rebuild dashboard counts.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Compute counts without writing.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument(
        "--curriculum",
        type=Path,
        default=None,
        help="Override curriculum JSON path (for tests).",
    )
    args = parser.parse_args(argv)

    try:
        result = run_report(
            args.repo_root,
            dry_run=args.dry_run,
            curriculum_path=args.curriculum,
        )
    except ReportError as exc:
        print(f"error\t{exc.code}\t{exc}", file=sys.stderr)
        return 1

    c = result.counts
    print(
        f"legacy_total={c.legacy_total}\t"
        f"salvaged={c.salvaged}\t"
        f"rebuilt={c.rebuilt}\t"
        f"dropped={c.dropped}"
    )
    if not args.dry_run:
        print(f"dashboard\t{result.dashboard_path}")
    return 0
