"""Re-derive legacy tonal_note from lexicon tone_pattern (P4-084, CURRICULUM §8.4)."""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from tools.content_engine.legacy.grammar_cleanup import iter_lessons
from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import pipeline_input_dir

CARD_ID = "P4-084"
REASON_NO_LEXICON_TONE = "NO_LEXICON_TONE"
HIGH_RISK_TAG_TONE = "tone"
INPUT_BASENAME = "legacy_tone_claims.jsonl"
MANIFEST_BASENAME = "legacy_tone_claims_manifest.json"
DEFAULT_GAME_CONTENT = "assets/data/game_content.json"

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
class TonalTarget:
    locator: str
    lang_key: str
    kit_lang: str
    surface: str
    container: dict[str, Any]
    field: str


@dataclass(frozen=True)
class ToneClaimChange:
    locator: str
    kit_lang: str
    surface: str
    action: str
    previous: str
    next_note: str | None
    reason: str | None


@dataclass(frozen=True)
class ToneClaimsStats:
    targets_with_note: int
    derived: int
    removed: int
    unchanged: int
    skipped_unsupported_lang: int


@dataclass(frozen=True)
class ToneClaimsResult:
    changes: tuple[ToneClaimChange, ...]
    review_records: tuple[dict[str, Any], ...]
    stats: ToneClaimsStats
    game_path: Path
    input_path: Path
    manifest_path: Path
    changed: bool


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def format_lexicon_tone_note(tone_pattern: str) -> str:
    pattern = tone_pattern.strip()
    if not pattern:
        raise ValueError("empty tone_pattern")
    return f"tone_pattern: {pattern}"


def is_legacy_tonal_note(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def lexicon_tone_pattern(lookup: LexiconLookup | None, kit_lang: str, surface: str) -> str | None:
    if lookup is None:
        return None
    lexeme = lookup(kit_lang, nfc(surface))
    if lexeme is None:
        return None
    raw = lexeme.get("tone_pattern")
    if not isinstance(raw, str) or not raw.strip():
        return None
    return raw.strip()


def plan_tone_claim_change(
    target: TonalTarget,
    lookup: LexiconLookup | None,
) -> ToneClaimChange | None:
    previous = target.container.get(target.field)
    if not is_legacy_tonal_note(previous):
        return None
    prev = nfc(str(previous))
    pattern = lexicon_tone_pattern(lookup, target.kit_lang, target.surface)
    if pattern is None:
        if target.container.get(target.field) is None and prev == "":
            return None
        return ToneClaimChange(
            target.locator,
            target.kit_lang,
            nfc(target.surface),
            "removed",
            prev,
            None,
            REASON_NO_LEXICON_TONE,
        )
    next_note = format_lexicon_tone_note(pattern)
    if prev == next_note:
        return None
    return ToneClaimChange(
        target.locator,
        target.kit_lang,
        nfc(target.surface),
        "derived",
        prev,
        next_note,
        None,
    )


def apply_change(target: TonalTarget, change: ToneClaimChange) -> None:
    if change.action == "removed":
        target.container[target.field] = None
    elif change.action == "derived" and change.next_note is not None:
        target.container[target.field] = change.next_note


def build_review_record(change: ToneClaimChange) -> dict[str, Any]:
    if change.action != "derived" or change.next_note is None:
        raise ValueError("review record requires a derived tone claim")
    return {
        "card": CARD_ID,
        "locator": change.locator,
        "lang": change.kit_lang,
        "surface": change.surface,
        "tonal_note": change.next_note,
        "high_risk_tags": [HIGH_RISK_TAG_TONE],
        "queue": "high_risk",
        "route": "human",
        "ai_only": False,
    }


def _game_words(data: Mapping[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    words = data.get("words")
    if not isinstance(words, list):
        return []
    out: list[tuple[str, dict[str, Any]]] = []
    for idx, row in enumerate(words):
        if isinstance(row, dict):
            wid = row.get("id", idx)
            out.append((f"game_content#words[{wid}]", row))
    return out


def iter_tonal_targets(
    game_content: Mapping[str, Any],
    curriculum: Mapping[str, Any] | None = None,
) -> list[TonalTarget]:
    found: list[TonalTarget] = []
    for locator, row in _game_words(game_content):
        lang_key = row.get("language")
        if not isinstance(lang_key, str):
            continue
        kit_lang = _KIT_LANG.get(lang_key)
        if kit_lang is None:
            continue
        word = row.get("word")
        if not isinstance(word, str) or not word.strip():
            continue
        found.append(
            TonalTarget(locator, lang_key, kit_lang, word, row, "tonal_note"),
        )

    if curriculum is not None:
        for lang_key, lesson in iter_lessons(curriculum):
            kit_lang = _KIT_LANG.get(lang_key)
            if kit_lang is None:
                continue
            lesson_id = lesson.get("id")
            lid = lesson_id if isinstance(lesson_id, str) else "unknown"
            for v_idx, vocab in enumerate(lesson.get("vocab", [])):
                if not isinstance(vocab, dict):
                    continue
                word = vocab.get("word")
                if not isinstance(word, str) or not word.strip():
                    continue
                if "tonal_note" not in vocab:
                    continue
                found.append(
                    TonalTarget(
                        f"{lid}#vocab[{v_idx}].tonal_note",
                        lang_key,
                        kit_lang,
                        word,
                        vocab,
                        "tonal_note",
                    ),
                )
    return found


def _stable_records(records: Sequence[Mapping[str, Any]]) -> tuple[dict[str, Any], ...]:
    ordered = sorted(records, key=lambda r: (r.get("locator", ""), r.get("surface", "")))
    return tuple(dict(r) for r in ordered)


def run_tone_claims(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    lexicon_lookup: LexiconLookup | None = None,
    game_path: Path | None = None,
    curriculum: Mapping[str, Any] | None = None,
) -> ToneClaimsResult:
    base = repo_root(root)
    game_file = game_path if game_path is not None else base / DEFAULT_GAME_CONTENT
    game_data = json.loads(game_file.read_text(encoding="utf-8"))
    if not isinstance(game_data, dict):
        raise TypeError("game content root must be an object")

    targets = iter_tonal_targets(game_data, curriculum)
    changes: list[ToneClaimChange] = []
    derived = 0
    removed = 0
    unchanged = 0
    with_note = 0
    skipped_lang = 0

    words = game_data.get("words")
    if isinstance(words, list):
        for row in words:
            if not isinstance(row, dict):
                continue
            lang_key = row.get("language")
            if isinstance(lang_key, str) and lang_key not in _KIT_LANG:
                if is_legacy_tonal_note(row.get("tonal_note")):
                    skipped_lang += 1

    for target in targets:
        if is_legacy_tonal_note(target.container.get(target.field)):
            with_note += 1
        change = plan_tone_claim_change(target, lexicon_lookup)
        if change is None:
            unchanged += 1
            continue
        changes.append(change)
        if not dry_run:
            apply_change(target, change)
        if change.action == "derived":
            derived += 1
        elif change.action == "removed":
            removed += 1

    review_records = _stable_records(
        [build_review_record(c) for c in changes if c.action == "derived"],
    )
    out_dir = pipeline_input_dir(base)
    input_path = out_dir / INPUT_BASENAME
    manifest_path = out_dir / MANIFEST_BASENAME
    changed = bool(changes)

    if not dry_run and changed:
        game_file.write_text(
            json.dumps(game_data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        out_dir.mkdir(parents=True, exist_ok=True)
        lines = [json.dumps(rec, ensure_ascii=False, sort_keys=True) for rec in review_records]
        payload = "\n".join(lines)
        if payload:
            payload += "\n"
        input_path.write_text(payload, encoding="utf-8")
        manifest = {
            "card": CARD_ID,
            "game_content": str(
                game_file.relative_to(base) if game_file.is_relative_to(base) else game_file,
            ),
            "targets_with_note": with_note,
            "derived": derived,
            "removed": removed,
            "review_queue_items": len(review_records),
            "input_file": INPUT_BASENAME,
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = ToneClaimsStats(
        targets_with_note=with_note,
        derived=derived,
        removed=removed,
        unchanged=unchanged,
        skipped_unsupported_lang=skipped_lang,
    )
    return ToneClaimsResult(
        tuple(changes),
        review_records,
        stats,
        game_file,
        input_path,
        manifest_path,
        changed,
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Re-derive legacy tonal_note fields from lexicon tone_pattern.",
    )
    parser.add_argument("--dry-run", action="store_true", help="List changes without writing.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument(
        "--game-content",
        type=Path,
        default=None,
        help="Override game_content.json path (for tests).",
    )
    args = parser.parse_args(argv)

    result = run_tone_claims(
        args.repo_root,
        dry_run=args.dry_run,
        game_path=args.game_content,
    )
    s = result.stats
    print(
        f"targets_with_note={s.targets_with_note}\t"
        f"derived={s.derived}\t"
        f"removed={s.removed}\t"
        f"unchanged={s.unchanged}\t"
        f"skipped_unsupported_lang={s.skipped_unsupported_lang}"
    )
    for change in result.changes:
        print(
            f"change\t{change.locator}\t{change.action}\t"
            f"reason={change.reason or ''}\tprev={change.previous[:40]}"
        )
    if not args.dry_run and result.changed:
        print(f"game_content\t{result.game_path}")
        print(f"input\t{result.input_path}")
        print(f"manifest\t{result.manifest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
