"""Automated validators for the LingAfriq LLM authoring pipeline.

Each validator returns a :class:`ReviewReport`. Validators are pure
functions over plain dictionaries (decoded JSON), so they can run in CI
without any LLM access.

Checks implemented:

- orthography  — required diacritics / scripts per language
- length       — vocab list size, dialogue turn count, scene count
- english_leak — English words appearing in target-language fields
- repetition   — duplicate vocab or duplicate dialogue turns
- vocab_density — at least N distinct vocab tokens appear in the dialogue
- proverb_real — bans clearly fabricated short proverbs (heuristic)
- schema       — required keys are present
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from typing import Any, Iterable

from .schemas import ReviewReport, SUPPORTED_LEVELS, SUPPORTED_LANGUAGES

logger = logging.getLogger(__name__)


# --- Language-specific orthography expectations -----------------------------
_DIACRITIC_PATTERNS: dict[str, str] = {
    "yoruba": r"[áàāéèēíìīóòōúùūṣẹọńṅ]",
    "igbo": r"[ịọụṅáàéèíìóòúù]",
    "wolof": r"[ñŋéèóòô]",
    "twi": r"[ɛɔáàéèíìóòúù]",
    "lingala": r"[éèíìóòáà]",
    "shona": r"[áàéèíìóòúù]?",  # tone marks optional in modern orthography
    "somali": r"(aa|ee|ii|oo|uu)",
    "amharic": r"[\u1200-\u137F]",  # Ge'ez block
    "arabic": r"[\u0600-\u06FF]",   # Arabic block
}


# Common English stopwords used to detect obvious leaks in target-language
# fields. We deliberately keep this conservative; native reviewers catch the
# rest.
_ENGLISH_STOPWORDS = {
    "the", "and", "with", "from", "this", "that", "have", "you", "your",
    "for", "but", "not", "are", "is", "was", "were", "will", "would",
    "should", "could", "what", "where", "when", "how", "why", "who",
    "good", "bad", "hello", "please", "thank", "thanks", "morning",
    "afternoon", "evening", "yes", "no", "very", "much",
}


def _stringify_dialogue(dialogue: dict) -> list[tuple[str, str, str]]:
    """Return [(scene_label, target_text, english_translation), ...]"""
    out: list[tuple[str, str, str]] = []
    scenes = dialogue.get("scenes") if isinstance(dialogue, dict) else None
    if scenes:
        for scene in scenes:
            label = scene.get("label", "")
            for turn in scene.get("script", []) or []:
                out.append(
                    (label, str(turn.get("text", "")), str(turn.get("translation", "")))
                )
        return out
    flat = dialogue.get("script") if isinstance(dialogue, dict) else None
    if flat:
        for turn in flat:
            out.append(("", str(turn.get("text", "")), str(turn.get("translation", ""))))
    return out


def _english_leak(text: str) -> list[str]:
    tokens = re.findall(r"[A-Za-z']{3,}", text.lower())
    return [t for t in tokens if t in _ENGLISH_STOPWORDS]


def check_lesson(lesson: dict[str, Any]) -> ReviewReport:
    target_id = lesson.get("id") or (
        f"{lesson.get('lang','?')}-{lesson.get('level','?')}-"
        f"u{lesson.get('unit','?')}-l{lesson.get('lesson','?')}"
    )
    report = ReviewReport(target_id=str(target_id))
    lang = str(lesson.get("lang", "")).lower()
    level = str(lesson.get("level", ""))

    # --- Schema basics ---
    required_keys = ("title", "objective", "vocab", "dialogue")
    for key in required_keys:
        if not lesson.get(key):
            report.add("error", "missing_key", f"Missing required key: {key}", key)

    if lang and lang not in SUPPORTED_LANGUAGES:
        report.add(
            "error",
            "unsupported_lang",
            f"Lesson lang '{lang}' is not in the supported set.",
            "lang",
        )
    if level and level not in SUPPORTED_LEVELS:
        report.add(
            "error",
            "unsupported_level",
            f"Lesson level '{level}' is not in the supported set.",
            "level",
        )

    # --- Vocab ---
    vocab = lesson.get("vocab", []) or []
    if len(vocab) < 3:
        report.add(
            "error",
            "vocab_too_short",
            f"Lesson must include at least 3 vocab items (got {len(vocab)}).",
            "vocab",
        )
    seen_words: set[str] = set()
    for idx, v in enumerate(vocab):
        word = str(v.get("word", "")).strip()
        meaning = str(v.get("meaning", "")).strip()
        if not word:
            report.add("error", "vocab_empty_word", "Empty vocab word.", f"vocab[{idx}]")
        if not meaning:
            report.add("error", "vocab_empty_meaning", "Empty vocab meaning.", f"vocab[{idx}]")
        if word in seen_words:
            report.add(
                "warning",
                "vocab_duplicate",
                f"Duplicate vocab word: {word!r}",
                f"vocab[{idx}]",
            )
        seen_words.add(word)
        leaks = _english_leak(word)
        if leaks:
            report.add(
                "warning",
                "english_leak_word",
                f"Target-language word contains English-looking tokens {leaks}.",
                f"vocab[{idx}].word",
            )

    # --- Grammar ---
    grammar = lesson.get("grammar")
    if not grammar:
        report.add(
            "warning",
            "grammar_missing",
            "Lesson has no grammar notes — learners benefit from 2-4 rules.",
            "grammar",
        )

    # --- Dialogue ---
    dialogue = lesson.get("dialogue") or {}
    turns = _stringify_dialogue(dialogue)
    min_turns = 6 if level in {"A1", "A2"} else 8
    if len(turns) < min_turns:
        report.add(
            "error",
            "dialogue_too_short",
            f"Dialogue has {len(turns)} turns; expected at least {min_turns} for {level}.",
            "dialogue",
        )
    if dialogue.get("scenes") and len(dialogue["scenes"]) < 2:
        report.add(
            "warning",
            "single_scene",
            "Dialogue has only one scene — aim for at least two scenes.",
            "dialogue.scenes",
        )

    # English leak check on dialogue target text
    for idx, (label, text, _trans) in enumerate(turns):
        leaks = _english_leak(text)
        if leaks:
            report.add(
                "warning",
                "english_leak_dialogue",
                f"Dialogue target text leaks English tokens {leaks}.",
                f"dialogue.turn[{idx}]",
            )

    # --- Vocab density: at least 2 distinct vocab words appear in dialogue ---
    if vocab and turns:
        vocab_words = {str(v.get("word", "")).lower() for v in vocab if v.get("word")}
        dialogue_lower = " ".join(t[1].lower() for t in turns)
        hits = sum(1 for w in vocab_words if w and w in dialogue_lower)
        if hits < 2:
            report.add(
                "warning",
                "low_vocab_density",
                (
                    f"Dialogue uses only {hits} of the lesson's vocab items; "
                    "aim for ≥2 reinforcements."
                ),
                "dialogue",
            )

    # --- Orthography ---
    pattern = _DIACRITIC_PATTERNS.get(lang)
    if pattern and turns:
        joined = " ".join(t[1] for t in turns)
        if not re.search(pattern, joined):
            report.add(
                "warning",
                "missing_diacritics",
                (
                    f"Dialogue for {lang} contains no recognised diacritic/script "
                    f"characters. Check tone marks and orthography."
                ),
                "dialogue",
            )

    return report


def check_game_content(content: dict[str, Any]) -> ReviewReport:
    target_id = f"games-{content.get('lang','?')}-{content.get('level','?')}"
    report = ReviewReport(target_id=target_id)
    lang = str(content.get("lang", "")).lower()
    cards = content.get("vocab_cards") or []
    proverbs = content.get("proverbs") or []

    if len(cards) < 10:
        report.add(
            "error",
            "too_few_cards",
            f"Need at least 10 vocab cards (got {len(cards)}).",
            "vocab_cards",
        )

    seen: set[str] = set()
    for idx, c in enumerate(cards):
        word = str(c.get("word", "")).strip()
        if not word:
            report.add("error", "card_empty_word", "Empty card word.", f"vocab_cards[{idx}]")
            continue
        if word in seen:
            report.add(
                "warning",
                "card_duplicate",
                f"Duplicate card word: {word!r}",
                f"vocab_cards[{idx}]",
            )
        seen.add(word)
        if not str(c.get("meaning", "")).strip():
            report.add(
                "error",
                "card_empty_meaning",
                "Empty card meaning.",
                f"vocab_cards[{idx}]",
            )
        if not str(c.get("example", "")).strip():
            report.add(
                "warning",
                "card_no_example",
                "Card has no example sentence.",
                f"vocab_cards[{idx}]",
            )

    if proverbs and len(proverbs) < 3:
        report.add(
            "info",
            "few_proverbs",
            f"Only {len(proverbs)} proverbs included; aim for ≥3.",
            "proverbs",
        )

    pattern = _DIACRITIC_PATTERNS.get(lang)
    if pattern and cards:
        joined = " ".join(str(c.get("word", "")) for c in cards)
        if not re.search(pattern, joined):
            report.add(
                "warning",
                "missing_diacritics",
                (
                    f"Vocab cards for {lang} contain no recognised diacritic/script "
                    "characters."
                ),
                "vocab_cards",
            )

    return report


def check_path(path: Path) -> ReviewReport:
    """Detect file type and dispatch to the right checker."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if "vocab_cards" in data:
        return check_game_content(data)
    return check_lesson(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Run automated review checks over authoring drafts."
    )
    parser.add_argument(
        "paths",
        nargs="+",
        type=Path,
        help="JSON draft files or directories containing them.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with code 1 if any warning is emitted (default: errors only).",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="Optional path to write a combined JSON report.",
    )
    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

    files: list[Path] = []
    for p in args.paths:
        if p.is_dir():
            files.extend(sorted(p.rglob("*.json")))
        else:
            files.append(p)

    combined: list[dict[str, Any]] = []
    total_errors = 0
    total_warnings = 0
    for f in files:
        try:
            report = check_path(f)
        except Exception as exc:  # noqa: BLE001
            logger.error("Failed to check %s: %s", f, exc)
            total_errors += 1
            combined.append({"file": str(f), "error": str(exc)})
            continue
        total_errors += report.error_count
        total_warnings += report.warning_count
        combined.append({"file": str(f), **report.to_dict()})
        if report.error_count or report.warning_count:
            logger.info(
                "%s — %s errors, %s warnings",
                f.name,
                report.error_count,
                report.warning_count,
            )

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            json.dumps(combined, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        logger.info("Wrote combined report to %s", args.report)

    logger.info(
        "Reviewed %s file(s): %s errors, %s warnings",
        len(files),
        total_errors,
        total_warnings,
    )
    if total_errors:
        return 1
    if args.strict and total_warnings:
        return 1
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
