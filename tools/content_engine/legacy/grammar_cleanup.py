"""Delete banned generic grammar sentences from legacy curriculum lessons (P4-083)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import resolve_curriculum_path
from tools.content_engine.linters.claims import _GENERIC_PATTERNS, lint_claims

CARD_ID = "P4-083"
EXPECTED_LESSON_COUNT = 1546
MANIFEST_BASENAME = "legacy_grammar_cleanup_manifest.json"

_KIT: dict[str, object] = {}


@dataclass(frozen=True)
class GrammarCleanupStats:
    lessons_total: int
    lessons_affected: int
    sentences_removed: int


@dataclass(frozen=True)
class GrammarCleanupResult:
    stats: GrammarCleanupStats
    curriculum_path: Path
    manifest_path: Path
    changed: bool


def is_generic_grammar_sentence(text: str) -> bool:
    if not isinstance(text, str) or not text.strip():
        return False
    for pattern in _GENERIC_PATTERNS:
        if pattern.search(text):
            return True
    return False


def iter_lessons(curriculum: Mapping[str, Any]) -> list[tuple[str, Mapping[str, Any]]]:
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return []
    found: list[tuple[str, Mapping[str, Any]]] = []
    for lang_key, levels in languages.items():
        if not isinstance(lang_key, str) or not isinstance(levels, Mapping):
            continue
        for _cefr, units in levels.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                if not isinstance(unit, Mapping):
                    continue
                lessons = unit.get("lessons")
                if not isinstance(lessons, list):
                    continue
                for lesson in lessons:
                    if isinstance(lesson, Mapping):
                        found.append((lang_key, lesson))
    return found


def _clean_grammar_list(grammar: object) -> tuple[list[str], int]:
    if not isinstance(grammar, list):
        return [], 0
    kept: list[str] = []
    removed = 0
    for entry in grammar:
        if not isinstance(entry, str):
            if entry is not None:
                kept.append(str(entry))
            continue
        if is_generic_grammar_sentence(entry):
            removed += 1
        else:
            kept.append(entry)
    return kept, removed


def grammar_lint_failures(lesson: Mapping[str, Any]) -> list[str]:
    lesson_id = lesson.get("id")
    lid = lesson_id if isinstance(lesson_id, str) else "unknown"
    grammar = lesson.get("grammar")
    if not isinstance(grammar, list):
        return []
    failures: list[str] = []
    for idx, entry in enumerate(grammar):
        if not isinstance(entry, str):
            continue
        item = {"id": f"{lid}#grammar[{idx}]", "section": "lesson", "text": entry}
        result = lint_claims(item, _KIT)
        if result.status == "fail" and result.rule_id == "GENERIC_TEMPLATE":
            failures.append(item["id"])
    return failures


def run_grammar_cleanup(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    curriculum_path: Path | None = None,
) -> GrammarCleanupResult:
    base = repo_root(root)
    src = (
        curriculum_path
        if curriculum_path is not None
        else resolve_curriculum_path(base)
    )
    curriculum = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(curriculum, dict):
        raise TypeError("curriculum root must be an object")

    lessons = iter_lessons(curriculum)
    sentences_removed = 0
    lessons_affected = 0

    for _lang, lesson in lessons:
        grammar = lesson.get("grammar")
        kept, removed = _clean_grammar_list(grammar)
        if removed:
            lessons_affected += 1
            sentences_removed += removed
            if not dry_run:
                lesson["grammar"] = kept

    changed = sentences_removed > 0
    manifest_path = src.parent / MANIFEST_BASENAME

    if not dry_run and changed:
        src.write_text(
            json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest = {
            "card": CARD_ID,
            "curriculum": str(src.relative_to(base)) if src.is_relative_to(base) else str(src),
            "lessons_total": len(lessons),
            "lessons_affected": lessons_affected,
            "sentences_removed": sentences_removed,
            "expected_lessons": EXPECTED_LESSON_COUNT,
        }
        if len(lessons) != EXPECTED_LESSON_COUNT:
            manifest["lesson_count_note"] = (
                f"lesson total {len(lessons)} differs from spec {EXPECTED_LESSON_COUNT}"
            )
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = GrammarCleanupStats(
        lessons_total=len(lessons),
        lessons_affected=lessons_affected,
        sentences_removed=sentences_removed,
    )
    return GrammarCleanupResult(stats, src, manifest_path, changed)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Remove generic grammar template sentences from authentic curriculum JSON.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Report removals without writing.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument(
        "--curriculum",
        type=Path,
        default=None,
        help="Override curriculum JSON path (for tests).",
    )
    args = parser.parse_args(argv)

    result = run_grammar_cleanup(
        args.repo_root,
        dry_run=args.dry_run,
        curriculum_path=args.curriculum,
    )
    s = result.stats
    print(
        f"lessons_total={s.lessons_total}\t"
        f"lessons_affected={s.lessons_affected}\t"
        f"sentences_removed={s.sentences_removed}\t"
        f"expected_lessons={EXPECTED_LESSON_COUNT}"
    )
    if s.lessons_total != EXPECTED_LESSON_COUNT:
        print(
            f"note\tlesson_count_delta={s.lessons_total - EXPECTED_LESSON_COUNT}",
            file=sys.stderr,
        )
    if not args.dry_run and result.changed:
        print(f"curriculum\t{result.curriculum_path}")
        print(f"manifest\t{result.manifest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
