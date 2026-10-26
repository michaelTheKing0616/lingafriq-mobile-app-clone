"""Regenerate legacy lesson dialogues from can-do targets (P4-085, CURRICULUM §8.5).

Live Gemini generation is gated on P4-055 / EXT-01 (see LINGAFRIQ_AI_MODEL_STACK.md).
Callers pass a generator callable; the CLI refuses write mode when generation is disabled.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from tools.content_engine.kits.kit_schema import KitError, validate_kit
from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import pipeline_input_dir, resolve_curriculum_path
from tools.content_engine.linters.duplicates import lint_duplicates

CARD_ID = "P4-085"
MAX_GENERATION_ATTEMPTS = 2
MANIFEST_BASENAME = "legacy_dialogues_manifest.json"
PARK_INPUT_BASENAME = "legacy_dialogue_park.jsonl"
EXT01_CITATION = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md#EXT-01"

_KIT_LANG: dict[str, str] = {
    "yoruba": "yo",
    "hausa": "ha",
    "igbo": "ig",
    "swahili": "sw",
    "zulu": "zu",
    "xhosa": "xh",
    "nigerian_pidgin": "pcm",
    "pidgin": "pcm",
}

DialogueGenerator = Callable[[str, Mapping[str, Any], Mapping[str, Any]], list[dict[str, Any]]]


@dataclass(frozen=True)
class DialogueChange:
    lesson_id: str
    can_do: str
    action: str
    attempts: int
    reason: str | None


@dataclass(frozen=True)
class DialogueRegenStats:
    lessons_with_dialogue: int
    regenerated: int
    parked: int
    skipped_clean: int
    skipped_no_lint_kit: int


@dataclass(frozen=True)
class DialogueRegenResult:
    changes: tuple[DialogueChange, ...]
    park_records: tuple[dict[str, Any], ...]
    stats: DialogueRegenStats
    curriculum_path: Path
    manifest_path: Path
    park_path: Path
    changed: bool


def generation_enabled() -> bool:
    """True when server-side Gemini routing is explicitly enabled (P4-055 / EXT-01)."""
    return os.environ.get("AI_GEMINI_ENABLED", "").strip().lower() in (
        "1",
        "true",
        "yes",
    )


def build_can_do_target(cefr: str, objective: str) -> str:
    obj = objective.strip() if isinstance(objective, str) else ""
    if not obj:
        obj = "practice dialogue"
    level = cefr.strip() if isinstance(cefr, str) and cefr.strip() else "A1"
    return f"{level}.SPEAK: {obj}"


def load_lint_kit(kit_lang: str, kits_root: Path) -> dict[str, Any]:
    path = kits_root / kit_lang / "kit.yaml"
    if not path.is_file():
        raise KitError(
            "KIT_NOT_FOUND",
            f"Language kit not found for {kit_lang!r}: {path}",
        )
    with path.open(encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)
    if not isinstance(raw, Mapping):
        raise KitError(
            "DUPLICATE_CONFIG_MISSING",
            f"kit {kit_lang!r} is not a mapping",
        )
    duplicate_config = raw.get("duplicate_config")
    if not isinstance(duplicate_config, Mapping):
        raise KitError(
            "DUPLICATE_CONFIG_MISSING",
            f"kit {kit_lang!r} missing duplicate_config (P4-051)",
        )
    validated = validate_kit(raw)
    return {**dict(validated), "duplicate_config": dict(duplicate_config)}


def script_turns(dialogue: object) -> list[dict[str, Any]]:
    if not isinstance(dialogue, Mapping):
        return []
    script = dialogue.get("script")
    if not isinstance(script, list):
        return []
    turns: list[dict[str, Any]] = []
    for turn in script:
        if isinstance(turn, Mapping):
            turns.append(dict(turn))
    return turns


def lines_from_script(script: Sequence[Mapping[str, Any]]) -> list[str]:
    lines: list[str] = []
    for turn in script:
        text = turn.get("text")
        if isinstance(text, str) and text.strip():
            lines.append(text)
    return lines


def apply_dialogue_script(lesson: dict[str, Any], script: list[dict[str, Any]]) -> None:
    dialogue = lesson.get("dialogue")
    if not isinstance(dialogue, dict):
        dialogue = {}
        lesson["dialogue"] = dialogue
    dialogue["script"] = script
    scenes = dialogue.get("scenes")
    if isinstance(scenes, list) and scenes and isinstance(scenes[0], dict):
        scenes[0]["script"] = [dict(turn) for turn in script]


def build_unit_lint_bundle(
    unit_key: str,
    lessons: Sequence[tuple[str, Mapping[str, Any]]],
) -> dict[str, Any]:
    dialogues: list[dict[str, Any]] = []
    all_lines: list[str] = []
    for lesson_id, lesson in lessons:
        dialogue = lesson.get("dialogue")
        if not isinstance(dialogue, Mapping):
            continue
        lines = lines_from_script(script_turns(dialogue))
        if not lines:
            continue
        dialogues.append({"id": f"{lesson_id}-dialogue", "lines": lines})
        all_lines.extend(lines)
    return {
        "id": unit_key,
        "dialogues": dialogues,
        "units": [{"id": f"{unit_key}-lines", "lines": all_lines}],
    }


def unit_lint_status(bundle: Mapping[str, Any], lint_kit: Mapping[str, Any]) -> str:
    result = lint_duplicates(bundle, lint_kit)
    return result.status


def vocab_turn_script(lesson: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Deterministic non-repeating turns from lesson vocab (tests / fixtures only)."""
    vocab = lesson.get("vocab")
    if not isinstance(vocab, list):
        return []
    turns: list[dict[str, Any]] = []
    speaker = "A"
    seen: set[str] = set()
    for entry in vocab:
        if not isinstance(entry, Mapping):
            continue
        word = entry.get("word")
        if not isinstance(word, str) or not word.strip():
            continue
        text = word.strip()
        if text in seen:
            continue
        seen.add(text)
        meaning = entry.get("meaning")
        translation = meaning if isinstance(meaning, str) else ""
        turns.append({"speaker": speaker, "text": text, "translation": translation})
        speaker = "B" if speaker == "A" else "A"
    return turns


def iter_unit_lessons(
    curriculum: Mapping[str, Any],
) -> list[tuple[str, str, str, str, list[tuple[str, dict[str, Any]]]]]:
    """Yield (lang_key, kit_lang, cefr, unit_key, lessons) for supported languages."""
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return []

    found: list[tuple[str, str, str, str, list[tuple[str, dict[str, Any]]]]] = []
    for lang_key, levels in languages.items():
        if not isinstance(lang_key, str) or not isinstance(levels, Mapping):
            continue
        kit_lang = _KIT_LANG.get(lang_key)
        if kit_lang is None:
            continue
        for cefr, units in levels.items():
            if not isinstance(cefr, str) or not isinstance(units, list):
                continue
            for unit in units:
                if not isinstance(unit, Mapping):
                    continue
                unit_num = unit.get("unit", 0)
                unit_key = f"{lang_key}-{cefr}-u{unit_num}"
                lessons: list[tuple[str, dict[str, Any]]] = []
                for lesson in unit.get("lessons", []):
                    if not isinstance(lesson, Mapping):
                        continue
                    lesson_id = lesson.get("id")
                    if not isinstance(lesson_id, str) or not lesson_id.strip():
                        continue
                    lessons.append((lesson_id, dict(lesson)))
                if lessons:
                    found.append((lang_key, kit_lang, cefr, unit_key, lessons))
    return found


def build_park_record(
    lesson_id: str,
    can_do: str,
    attempts: int,
    rule_id: str,
) -> dict[str, Any]:
    return {
        "card": CARD_ID,
        "lesson_id": lesson_id,
        "can_do": can_do,
        "attempts": attempts,
        "last_lint_rule": rule_id,
        "queue": "human",
        "route": "human",
        "publish": False,
        "ext01": EXT01_CITATION,
    }


def regenerate_lesson_dialogue(
    lesson: dict[str, Any],
    can_do: str,
    generator: DialogueGenerator,
    lint_kit: Mapping[str, Any],
    unit_key: str,
    unit_lessons: Sequence[tuple[str, Mapping[str, Any]]],
) -> tuple[str, int, str | None]:
    """Try up to MAX_GENERATION_ATTEMPTS; return action, attempts, lint rule if parked."""
    last_rule = "DUPLICATE_DIALOGUE"
    for attempt in range(1, MAX_GENERATION_ATTEMPTS + 1):
        script = generator(can_do, lesson, lint_kit)
        if not script:
            last_rule = "GENERATION_EMPTY"
            continue
        apply_dialogue_script(lesson, script)
        bundle = build_unit_lint_bundle(unit_key, unit_lessons)
        if unit_lint_status(bundle, lint_kit) == "pass":
            return "regenerated", attempt, None
        result = lint_duplicates(bundle, lint_kit)
        if result.status == "fail":
            last_rule = result.rule_id

    return "parked", MAX_GENERATION_ATTEMPTS, last_rule


def run_dialogue_regeneration(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    curriculum_path: Path | None = None,
    generator: DialogueGenerator | None = None,
    lint_kit_by_lang: Mapping[str, Mapping[str, Any]] | None = None,
    kits_root: Path | None = None,
) -> DialogueRegenResult:
    base = repo_root(root)
    src = (
        curriculum_path
        if curriculum_path is not None
        else resolve_curriculum_path(base)
    )
    curriculum = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(curriculum, dict):
        raise TypeError("curriculum root must be an object")

    if not dry_run and generator is None and not generation_enabled():
        raise RuntimeError(
            f"dialogue write requires P4-055 generator or AI_GEMINI_ENABLED ({EXT01_CITATION})",
        )

    kits = kits_root or (base / "tools" / "content_engine" / "kits")
    lint_overrides = lint_kit_by_lang or {}

    changes: list[DialogueChange] = []
    park_records: list[dict[str, Any]] = []
    lessons_with_dialogue = 0
    regenerated = 0
    parked = 0
    skipped_clean = 0
    skipped_no_lint_kit = 0

    gen = generator or _missing_generator

    for _lang_key, kit_lang, cefr, unit_key, unit_lessons in iter_unit_lessons(curriculum):
        try:
            lint_kit = lint_overrides.get(kit_lang) or load_lint_kit(kit_lang, kits)
        except KitError:
            skipped_no_lint_kit += sum(
                1
                for _lid, lesson in unit_lessons
                if isinstance(lesson.get("dialogue"), Mapping)
            )
            continue

        bundle = build_unit_lint_bundle(unit_key, unit_lessons)
        if not bundle["dialogues"]:
            continue
        lessons_with_dialogue += len(bundle["dialogues"])

        if unit_lint_status(bundle, lint_kit) == "pass":
            skipped_clean += len(bundle["dialogues"])
            continue

        if dry_run:
            for lesson_id, lesson in unit_lessons:
                if not isinstance(lesson.get("dialogue"), Mapping) or not script_turns(
                    lesson.get("dialogue"),
                ):
                    continue
                obj = lesson.get("objective")
                can_do = build_can_do_target(
                    cefr,
                    obj if isinstance(obj, str) else "",
                )
                changes.append(
                    DialogueChange(lesson_id, can_do, "would_regenerate", 0, None),
                )
            continue

        for lesson_id, lesson in unit_lessons:
            if unit_lint_status(
                build_unit_lint_bundle(unit_key, unit_lessons),
                lint_kit,
            ) == "pass":
                break
            dialogue = lesson.get("dialogue")
            if not isinstance(dialogue, Mapping) or not script_turns(dialogue):
                continue
            objective = lesson.get("objective")
            can_do = build_can_do_target(
                cefr,
                objective if isinstance(objective, str) else "",
            )
            action, attempts, rule = regenerate_lesson_dialogue(
                lesson,
                can_do,
                gen,
                lint_kit,
                unit_key,
                unit_lessons,
            )
            changes.append(DialogueChange(lesson_id, can_do, action, attempts, rule))
            if action == "regenerated":
                regenerated += 1
            elif action == "parked":
                parked += 1
                park_records.append(
                    build_park_record(
                        lesson_id,
                        can_do,
                        attempts,
                        rule or "DUPLICATE_DIALOGUE",
                    ),
                )

    changed = (
        any(c.action in {"regenerated", "parked"} for c in changes)
        and not dry_run
    )
    manifest_path = src.parent / MANIFEST_BASENAME
    park_path = pipeline_input_dir(base) / PARK_INPUT_BASENAME

    if not dry_run and changed:
        if regenerated > 0:
            src.write_text(
                json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        out_dir = park_path.parent
        out_dir.mkdir(parents=True, exist_ok=True)
        if park_records:
            lines = [
                json.dumps(rec, ensure_ascii=False, sort_keys=True) for rec in park_records
            ]
            park_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        manifest = {
            "card": CARD_ID,
            "curriculum": str(src.relative_to(base)) if src.is_relative_to(base) else str(src),
            "lessons_with_dialogue": lessons_with_dialogue,
            "regenerated": regenerated,
            "parked": parked,
            "park_file": PARK_INPUT_BASENAME if park_records else None,
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = DialogueRegenStats(
        lessons_with_dialogue=lessons_with_dialogue,
        regenerated=regenerated,
        parked=parked,
        skipped_clean=skipped_clean,
        skipped_no_lint_kit=skipped_no_lint_kit,
    )
    return DialogueRegenResult(
        tuple(changes),
        tuple(park_records),
        stats,
        src,
        manifest_path,
        park_path,
        changed,
    )


def _missing_generator(
    _can_do: str,
    _lesson: Mapping[str, Any],
    _lint_kit: Mapping[str, Any],
) -> list[dict[str, Any]]:
    raise RuntimeError(
        f"dialogue generator not configured; enable P4-055 / {EXT01_CITATION}",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Regenerate legacy lesson dialogues from can-do targets.",
    )
    parser.add_argument("--dry-run", action="store_true", help="List work without writing.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument(
        "--curriculum",
        type=Path,
        default=None,
        help="Override curriculum JSON path (for tests).",
    )
    args = parser.parse_args(argv)

    try:
        result = run_dialogue_regeneration(
            args.repo_root,
            dry_run=args.dry_run,
            curriculum_path=args.curriculum,
        )
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    s = result.stats
    print(
        f"lessons_with_dialogue={s.lessons_with_dialogue}\t"
        f"regenerated={s.regenerated}\t"
        f"parked={s.parked}\t"
        f"skipped_clean={s.skipped_clean}\t"
        f"skipped_no_lint_kit={s.skipped_no_lint_kit}"
    )
    for change in result.changes:
        print(
            f"change\t{change.lesson_id}\t{change.action}\t"
            f"attempts={change.attempts}\treason={change.reason or ''}\t"
            f"can_do={change.can_do[:60]}"
        )
    if not args.dry_run and result.changed:
        print(f"curriculum\t{result.curriculum_path}")
        print(f"manifest\t{result.manifest_path}")
        if result.park_records:
            print(f"park\t{result.park_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
