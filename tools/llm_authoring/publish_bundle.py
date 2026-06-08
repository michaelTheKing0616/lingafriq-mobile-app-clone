#!/usr/bin/env python3
"""Promote native-reviewed authoring drafts into shipped app bundles.

Reads approved JSON from:
  - ``tools/llm_authoring/drafts/<lang>/<level>/*.json`` (curriculum lessons)
  - ``tools/llm_authoring/drafts/games/<lang>/*-games.json`` (game batches)

Writes:
  - ``assets/data/game_content.json`` (merged words + proverbs)
  - ``assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json`` (merged lessons)
  - ``LingAfriq Content Writing/native_review_log.json`` (audit trail append)

Only drafts with ``review_status`` in ``approved`` or ``native_approved`` are
promoted. Everything else is skipped with a log line.

Usage::

    python tools/llm_authoring/publish_bundle.py \\
        --drafts tools/llm_authoring/drafts \\
        --dry-run

    python tools/llm_authoring/publish_bundle.py --bump-game-version 2.1.0
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "data"
GAME_CONTENT_PATH = ASSETS / "game_content.json"
CURRICULUM_PATH = ASSETS / "lingafriq_authentic_curriculum_a1_a2_b1.json"
REVIEW_LOG_PATH = ROOT / "tools" / "content_data" / "native_review_log.json"

APPROVED_STATUSES = frozenset({"approved", "native_approved"})


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def _next_word_id(words: list[dict]) -> int:
    ids = [int(w.get("id", 0)) for w in words if isinstance(w.get("id"), int)]
    return (max(ids) if ids else 0) + 1


def _game_word_from_card(card: dict, lang: str, level: str, word_id: int) -> dict:
    word = str(card.get("word", "")).strip()
    meaning = str(card.get("meaning", "")).strip()
    category = str(card.get("category", "general")).strip()
    example = str(card.get("example", "")).strip()
    return {
        "id": word_id,
        "language": lang,
        "word": word,
        "english_meaning": meaning,
        "phonetic_guide": card.get("pronunciation") or None,
        "part_of_speech": category,
        "cefr": level,
        "topic": category.replace("_", " ").title(),
        "tonal_note": None,
        "cultural_note": example or None,
        "game_tags": [
            "WordMatch",
            "SpeedRound",
            "PronunciationDuel",
            "FlashcardSafari",
            "ProverbUnlocker",
        ],
        "_authoring_hash": hashlib.sha256(f"{lang}:{word}".encode()).hexdigest()[:16],
    }


def _game_proverb_from_card(card: dict, lang: str) -> dict:
    return {
        "language": lang,
        "original": str(card.get("original", "")).strip(),
        "translation": str(card.get("translation", "")).strip(),
        "meaning": str(card.get("meaning", "")).strip(),
        "region": str(card.get("region", "")).strip() or None,
    }


def _merge_game_draft(bundle: dict, draft: dict, path: Path) -> tuple[int, int]:
    lang = str(draft.get("lang", "")).lower()
    level = str(draft.get("level", "A1"))
    words: list[dict] = bundle.setdefault("words", [])
    proverbs: list[dict] = bundle.setdefault("proverbs", [])

    existing_words = {
        (w.get("language", "").lower(), w.get("word", "").strip())
        for w in words
        if isinstance(w, dict)
    }
    existing_proverbs = {
        (p.get("language", "").lower(), p.get("original", "").strip())
        for p in proverbs
        if isinstance(p, dict)
    }

    next_id = _next_word_id(words)
    added_w = 0
    added_p = 0

    for card in draft.get("vocab_cards") or []:
        if not isinstance(card, dict):
            continue
        key = (lang, str(card.get("word", "")).strip())
        if not key[1] or key in existing_words:
            continue
        words.append(_game_word_from_card(card, lang, level, next_id))
        existing_words.add(key)
        next_id += 1
        added_w += 1

    for card in draft.get("proverbs") or []:
        if not isinstance(card, dict):
            continue
        key = (lang, str(card.get("original", "")).strip())
        if not key[1] or key in existing_proverbs:
            continue
        proverbs.append(_game_proverb_from_card(card, lang))
        existing_proverbs.add(key)
        added_p += 1

    logger.info("Merged game draft %s (+%s words, +%s proverbs)", path.name, added_w, added_p)
    return added_w, added_p


def _merge_lesson_into_curriculum(curriculum: dict, lesson: dict) -> bool:
    lang = str(lesson.get("lang", "")).lower()
    level = str(lesson.get("level", ""))
    lesson_no = int(lesson.get("lesson", 0))
    langs = curriculum.setdefault("languages", {})
    lang_block = langs.setdefault(lang, {"levels": {}})
    levels = lang_block.setdefault("levels", {})
    level_block = levels.setdefault(level, {"units": []})
    units: list = level_block.setdefault("units", [])
    unit_no = int(lesson.get("unit", 1))
    while len(units) < unit_no:
        units.append({"title": f"Unit {len(units) + 1}", "lessons": []})
    unit = units[unit_no - 1]
    lessons: list = unit.setdefault("lessons", [])
    lesson_id = lesson.get("id") or f"{lang}-{level}-u{unit_no}-l{lesson_no}"
    for existing in lessons:
        if existing.get("id") == lesson_id:
            existing.clear()
            existing.update(lesson)
            return False
    lessons.append(lesson)
    lessons.sort(key=lambda x: int(x.get("lesson", 0)))
    return True


def _append_review_log(entries: list[dict], dry_run: bool) -> None:
    log: dict
    if REVIEW_LOG_PATH.exists():
        log = _load_json(REVIEW_LOG_PATH)
    else:
        log = {"promotions": []}
    promotions: list = log.setdefault("promotions", [])
    promotions.extend(entries)
    if dry_run:
        logger.info("Dry-run: would append %s promotion records", len(entries))
        return
    REVIEW_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    _write_json(REVIEW_LOG_PATH, log)


def publish(
    *,
    drafts_dir: Path,
    dry_run: bool,
    bump_game_version: str | None,
    bump_curriculum_version: str | None,
) -> int:
    if not GAME_CONTENT_PATH.exists():
        logger.error("Missing %s", GAME_CONTENT_PATH)
        return 1
    if not CURRICULUM_PATH.exists():
        logger.error("Missing %s", CURRICULUM_PATH)
        return 1

    game_bundle = _load_json(GAME_CONTENT_PATH)
    curriculum = _load_json(CURRICULUM_PATH)
    promotions: list[dict] = []
    total_words = 0
    total_proverbs = 0
    total_lessons = 0

    # Game drafts: drafts/games/<lang>/<lang>-<level>-games.json
    games_root = drafts_dir / "games"
    if games_root.is_dir():
        for path in sorted(games_root.glob("*/*-games.json")):
            draft = _load_json(path)
            status = str(draft.get("review_status", ""))
            if status not in APPROVED_STATUSES:
                logger.info("Skip game draft %s (status=%s)", path, status)
                continue
            w, p = _merge_game_draft(game_bundle, draft, path)
            total_words += w
            total_proverbs += p
            promotions.append(
                {
                    "type": "game_content",
                    "path": str(path.relative_to(ROOT)),
                    "lang": draft.get("lang"),
                    "level": draft.get("level"),
                    "words_added": w,
                    "proverbs_added": p,
                    "promoted_at": datetime.now(timezone.utc).isoformat(),
                }
            )

    # Curriculum drafts: drafts/<lang>/<level>/<id>.json
    for path in sorted(drafts_dir.glob("*/*/*.json")):
        if "games" in path.parts:
            continue
        draft = _load_json(path)
        if "vocab_cards" in draft:
            continue
        status = str(draft.get("review_status", ""))
        if status not in APPROVED_STATUSES:
            logger.info("Skip lesson draft %s (status=%s)", path, status)
            continue
        if _merge_lesson_into_curriculum(curriculum, draft):
            total_lessons += 1
        promotions.append(
            {
                "type": "curriculum_lesson",
                "path": str(path.relative_to(ROOT)),
                "lesson_id": draft.get("id"),
                "promoted_at": datetime.now(timezone.utc).isoformat(),
            }
        )

    meta = game_bundle.setdefault("meta", {})
    if bump_game_version:
        meta["version"] = bump_game_version
    meta["last_publish"] = datetime.now(timezone.utc).isoformat()

    if bump_curriculum_version:
        curriculum.setdefault("meta", {})["version"] = bump_curriculum_version

    logger.info(
        "Promotion summary: +%s words, +%s proverbs, +%s lessons",
        total_words,
        total_proverbs,
        total_lessons,
    )

    if dry_run:
        logger.info("Dry-run complete — no files written")
        return 0

    _write_json(GAME_CONTENT_PATH, game_bundle)
    _write_json(CURRICULUM_PATH, curriculum)
    _append_review_log(promotions, dry_run=False)
    return 0


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    parser = argparse.ArgumentParser(description="Promote approved authoring drafts.")
    parser.add_argument(
        "--drafts",
        type=Path,
        default=Path("tools/llm_authoring/drafts"),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--bump-game-version", default=None)
    parser.add_argument("--bump-curriculum-version", default=None)
    args = parser.parse_args(argv)
    drafts_dir = args.drafts if args.drafts.is_absolute() else ROOT / args.drafts
    return publish(
        drafts_dir=drafts_dir,
        dry_run=args.dry_run,
        bump_game_version=args.bump_game_version,
        bump_curriculum_version=args.bump_curriculum_version,
    )


if __name__ == "__main__":
    sys.exit(main())
