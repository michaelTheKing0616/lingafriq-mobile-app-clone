"""Salvage real phrases from authentic curriculum JSON (P4-082, CURRICULUM §8.2)."""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from scripts.ci.placeholder_linter import find_placeholder_patterns
from tools.content_engine.legacy.quarantine import (
    CANONICAL_SALVAGE_SOURCE,
    repo_root,
    salvage_source_path,
)
from tools.content_engine.linters.claims import _GENERIC_PATTERNS
from tools.content_engine.pipeline.anchoring import compute_lexeme_status

CARD_ID = "P4-082"
INPUT_BASENAME = "legacy_salvage.jsonl"
MANIFEST_BASENAME = "legacy_salvage_manifest.json"

# Curriculum bundle language keys → pipeline kit codes (seven kits only).
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

LexiconLookup = Callable[[str, str], Mapping[str, Any] | None]


@dataclass(frozen=True)
class SalvageCandidate:
    source_id: str
    lang: str
    kit_lang: str
    cefr: str
    field: str
    text: str


@dataclass(frozen=True)
class SalvageStats:
    extracted: int
    dropped_non_real: int
    skipped_unsupported_lang: int


@dataclass(frozen=True)
class SalvageResult:
    records: tuple[dict[str, Any], ...]
    stats: SalvageStats
    input_path: Path
    manifest_path: Path


def pipeline_input_dir(root: Path) -> Path:
    return repo_root(root).parent / "curriculum" / "pipeline" / "input"


def resolve_curriculum_path(root: Path) -> Path:
    base = repo_root(root)
    quarantined = salvage_source_path(base)
    if quarantined.is_file():
        return quarantined
    in_tree = base / CANONICAL_SALVAGE_SOURCE
    if in_tree.is_file():
        return in_tree
    raise FileNotFoundError(
        f"authentic curriculum JSON not found at {quarantined} or {in_tree}"
    )


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def is_real_phrase(text: str) -> bool:
    """True when text is non-empty and not placeholder or generic-template filler."""
    normalized = nfc(text)
    if not normalized:
        return False
    if find_placeholder_patterns(normalized):
        return False
    for pattern in _GENERIC_PATTERNS:
        if pattern.search(normalized):
            return False
    return True


def _dialogue_lines(dialogue: object) -> list[str]:
    lines: list[str] = []
    if not isinstance(dialogue, Mapping):
        return lines
    script = dialogue.get("script")
    if isinstance(script, list):
        for turn in script:
            if isinstance(turn, Mapping):
                text = turn.get("text")
                if isinstance(text, str):
                    lines.append(text)
    scenes = dialogue.get("scenes")
    if isinstance(scenes, list):
        for scene in scenes:
            if not isinstance(scene, Mapping):
                continue
            nested = scene.get("script")
            if isinstance(nested, list):
                for turn in nested:
                    if isinstance(turn, Mapping):
                        text = turn.get("text")
                        if isinstance(text, str):
                            lines.append(text)
    return lines


def _flashcard_phrases(items: object) -> list[str]:
    if not isinstance(items, list):
        return []
    out: list[str] = []
    for raw in items:
        if not isinstance(raw, str):
            continue
        part = raw.split("—", 1)[0].split(" - ", 1)[0]
        out.append(part.strip())
    return out


def iter_candidates(curriculum: Mapping[str, Any]) -> list[SalvageCandidate]:
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return []

    found: list[SalvageCandidate] = []
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
                for lesson in unit.get("lessons", []):
                    if not isinstance(lesson, Mapping):
                        continue
                    lesson_id = lesson.get("id")
                    if not isinstance(lesson_id, str) or not lesson_id.strip():
                        continue
                    for idx, vocab in enumerate(lesson.get("vocab", [])):
                        if not isinstance(vocab, Mapping):
                            continue
                        word = vocab.get("word")
                        if isinstance(word, str):
                            found.append(
                                SalvageCandidate(
                                    lesson_id,
                                    lang_key,
                                    kit_lang,
                                    cefr,
                                    f"vocab[{idx}].word",
                                    word,
                                )
                            )
                    for line in _dialogue_lines(lesson.get("dialogue")):
                        found.append(
                            SalvageCandidate(
                                lesson_id,
                                lang_key,
                                kit_lang,
                                cefr,
                                "dialogue.text",
                                line,
                            )
                        )
                    for ex_idx, exercise in enumerate(lesson.get("exercises", [])):
                        if not isinstance(exercise, Mapping):
                            continue
                        if exercise.get("type") != "flashcards":
                            continue
                        for p_idx, phrase in enumerate(
                            _flashcard_phrases(exercise.get("items"))
                        ):
                            found.append(
                                SalvageCandidate(
                                    lesson_id,
                                    lang_key,
                                    kit_lang,
                                    cefr,
                                    f"exercises[{ex_idx}].items[{p_idx}]",
                                    phrase,
                                )
                            )
    return found


def lexicon_anchor_status(
    kit_lang: str,
    phrase: str,
    lookup: LexiconLookup | None,
) -> str:
    if lookup is None:
        return "missing"
    lexeme = lookup(kit_lang, nfc(phrase))
    if lexeme is None:
        return "missing"
    return compute_lexeme_status(lexeme)["status"]


def build_pipeline_record(
    candidate: SalvageCandidate,
    lookup: LexiconLookup | None = None,
) -> dict[str, Any]:
    text = nfc(candidate.text)
    anchor = lexicon_anchor_status(candidate.kit_lang, text, lookup)
    anchored = anchor == "anchored"
    return {
        "card": CARD_ID,
        "source_id": candidate.source_id,
        "legacy_locator": f"{candidate.source_id}#{candidate.field}",
        "lang": candidate.kit_lang,
        "cefr": candidate.cefr,
        "text": text,
        "provenance": {"source": "legacy"},
        "lexicon_anchor": anchor,
        "queue_status": "unverified" if not anchored else "needs-review",
        "published": False,
    }


def _stable_records(records: Sequence[Mapping[str, Any]]) -> tuple[dict[str, Any], ...]:
    ordered = sorted(records, key=lambda r: (r["legacy_locator"], r["text"]))
    return tuple(dict(r) for r in ordered)


def run_salvage(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    lexicon_lookup: LexiconLookup | None = None,
    curriculum_path: Path | None = None,
) -> SalvageResult:
    base = repo_root(root)
    src = curriculum_path if curriculum_path is not None else resolve_curriculum_path(base)
    curriculum = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(curriculum, dict):
        raise TypeError("curriculum root must be an object")

    extracted: list[dict[str, Any]] = []
    dropped = 0
    skipped_lang = 0

    languages = curriculum.get("languages")
    if isinstance(languages, Mapping):
        for lang_key in languages:
            if isinstance(lang_key, str) and lang_key not in _KIT_LANG:
                skipped_lang += 1

    for candidate in iter_candidates(curriculum):
        if not is_real_phrase(candidate.text):
            dropped += 1
            continue
        extracted.append(build_pipeline_record(candidate, lexicon_lookup))

    records = _stable_records(extracted)
    out_dir = pipeline_input_dir(base)
    input_path = out_dir / INPUT_BASENAME
    manifest_path = out_dir / MANIFEST_BASENAME

    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
        lines = [json.dumps(rec, ensure_ascii=False, sort_keys=True) for rec in records]
        payload = "\n".join(lines)
        if payload:
            payload += "\n"
        input_path.write_text(payload, encoding="utf-8")
        manifest = {
            "card": CARD_ID,
            "source_json": str(src.relative_to(base)) if src.is_relative_to(base) else str(src),
            "extracted": len(records),
            "dropped_non_real": dropped,
            "skipped_unsupported_lang_keys": skipped_lang,
            "input_file": INPUT_BASENAME,
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = SalvageStats(
        extracted=len(records),
        dropped_non_real=dropped,
        skipped_unsupported_lang=skipped_lang,
    )
    return SalvageResult(records, stats, input_path, manifest_path)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Salvage real phrases from lingafriq_authentic_curriculum_a1_c2.json.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Compute records without writing files.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument(
        "--curriculum",
        type=Path,
        default=None,
        help="Override curriculum JSON path (for tests).",
    )
    args = parser.parse_args(argv)

    result = run_salvage(
        args.repo_root,
        dry_run=args.dry_run,
        curriculum_path=args.curriculum,
    )
    print(
        f"extracted={result.stats.extracted}\t"
        f"dropped_non_real={result.stats.dropped_non_real}\t"
        f"skipped_lang={result.stats.skipped_unsupported_lang}"
    )
    if not args.dry_run:
        print(f"input\t{result.input_path}")
        print(f"manifest\t{result.manifest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
