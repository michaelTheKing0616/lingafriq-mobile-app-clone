"""Draft authentic curriculum lessons with Claude + verify with GPT.

CLI entry point::

    python -m tools.llm_authoring.curriculum_drafter \
        --lang yoruba --level B1 --unit 2 --lessons 3 \
        --out tools/llm_authoring/drafts

Authoring flow:

1. For each ``(lang, level, unit, lesson_no)`` target:
   a. Build a curriculum drafting prompt (system + user) including the
      per-language brief and few-shot example.
   b. Send to Claude (drafter). Parse JSON.
   c. Send the drafted JSON to GPT (verifier). Parse review issues.
   d. Run the local ``review_checks.check_lesson`` validators.
   e. Merge all issues into the draft's ``review_notes`` and write
      the JSON to ``<out>/<lang>/<level>/<id>.json``.

If LLM API keys are missing the drafter still writes a structured
"skeleton" draft (using titles + objectives provided on the CLI) and
flags it ``review_status="needs_llm"``. This lets CI run end-to-end
without secrets.
"""

from __future__ import annotations

import argparse
import dataclasses
import json
import logging
import os
import sys
from pathlib import Path
from typing import Any

from . import review_checks
from ._llm_clients import ClaudeClient, OpenAIClient
from .prompts import build_curriculum_lesson_prompt, build_curriculum_verify_prompt
from .schemas import (
    DialogueScene,
    DialogueTurn,
    LessonDraft,
    SUPPORTED_LANGUAGES,
    SUPPORTED_LEVELS,
    VocabEntry,
    json_dump,
    validate_supported,
)

logger = logging.getLogger(__name__)


# --- Lesson title catalog ---------------------------------------------------
# A high-level catalog of unit/lesson titles per CEFR level. When the CLI
# does not pass explicit titles, we pull from this list. Titles are level-
# appropriate and culturally generic so the drafter picks the right register.
_LESSON_TITLES: dict[str, list[str]] = {
    "A1": [
        "First greetings",
        "Introducing yourself",
        "Family basics",
        "Numbers 1 to 10",
        "Food and drink",
        "At the market",
        "Asking directions",
        "Time of day",
        "Colours and clothes",
        "Saying goodbye",
    ],
    "A2": [
        "Past day recap",
        "Future plans",
        "Asking for help",
        "Describing people",
        "Travel and transport",
        "Eating out",
        "Shopping for clothes",
        "Health and the body",
        "Weather and seasons",
        "Hobbies and interests",
    ],
    "B1": [
        "Telling a personal story",
        "Workplace conversations",
        "Negotiating a price",
        "Giving opinions",
        "Hospitality customs",
        "Community values",
        "Resolving misunderstandings",
        "Talking about news",
        "Festivals and holidays",
        "Travel mishaps",
    ],
    "B2": [
        "Job interviews",
        "Discussing current events",
        "Cultural debates",
        "Professional emails",
        "Leadership and teamwork",
        "Education systems",
        "Migration stories",
        "Technology in daily life",
        "Health and wellness",
        "Climate and environment",
    ],
    "C1": [
        "Public speaking and rhetoric",
        "Media analysis",
        "Storytelling traditions",
        "Negotiating contracts",
        "Civic engagement",
        "Cross-cultural diplomacy",
        "Persuasion and counter-argument",
        "Heritage and identity",
        "Business strategy talk",
        "Mentoring younger speakers",
    ],
    "C2": [
        "Mastery rhetoric",
        "Cultural literacy",
        "Idioms and wordplay",
        "Literary register",
        "Advanced negotiation",
        "Code-switching with elegance",
        "Public ceremony language",
        "Crisis communication",
        "Heritage preservation",
        "Cross-regional variation",
    ],
}


def _objective_for(title: str, level: str) -> str:
    """Generate a learner-centric objective from the title + level."""
    return (
        f"By the end of this lesson the learner can confidently use {title.lower()} "
        f"vocabulary and the surrounding social register at CEFR {level}."
    )


def _skeleton_draft(
    lang: str,
    level: str,
    unit: int,
    lesson_no: int,
    title: str,
    objective: str,
) -> LessonDraft:
    """Skeleton draft used when LLM clients are not configured.

    This is intentionally minimal but schema-valid so downstream
    validators and publishing can still execute in CI without secrets.
    """
    vocab = [
        VocabEntry(word=f"[{lang}-{level}-vocab-1]", meaning="placeholder one"),
        VocabEntry(word=f"[{lang}-{level}-vocab-2]", meaning="placeholder two"),
        VocabEntry(word=f"[{lang}-{level}-vocab-3]", meaning="placeholder three"),
    ]
    scenes = [
        DialogueScene(
            label="Opening exchange",
            script=[
                DialogueTurn(speaker="A", text="[needs-llm]", translation="[needs-llm]"),
                DialogueTurn(speaker="B", text="[needs-llm]", translation="[needs-llm]"),
                DialogueTurn(speaker="A", text="[needs-llm]", translation="[needs-llm]"),
            ],
        ),
        DialogueScene(
            label="Continuing the conversation",
            script=[
                DialogueTurn(speaker="A", text="[needs-llm]", translation="[needs-llm]"),
                DialogueTurn(speaker="B", text="[needs-llm]", translation="[needs-llm]"),
                DialogueTurn(speaker="A", text="[needs-llm]", translation="[needs-llm]"),
            ],
        ),
    ]
    return LessonDraft(
        lang=lang,
        level=level,
        unit=unit,
        lesson=lesson_no,
        title=title,
        objective=objective,
        cultural_notes="(needs LLM draft)",
        vocab=vocab,
        grammar=["(needs LLM draft)"],
        dialogue_scenes=scenes,
        polie_roleplay_prompt=f"You are Polie, a {lang} mentor. Practice {title}.",
        polie_roleplay_persona="Encouraging Mentor",
        cefr_tags={
            "difficulty": level,
            "vocab_theme": title.lower().replace(" ", "_"),
            "cultural_topic": "daily_life",
            "pronunciation_difficulty": "tone_aware" if lang == "yoruba" else "standard",
            "ai_readiness": "beginner_slow" if level == "A1" else "intermediate",
        },
        duration_min=12 if level == "A1" else 14 if level == "A2" else 16,
        drafted_by="skeleton",
        verified_by="skeleton",
        review_status="needs_llm",
        review_notes=[
            "LLM API key not configured during drafting. "
            "Re-run with CLAUDE_API_KEY + OPENAI_API_KEY for a full draft."
        ],
    )


def _draft_from_dict(data: dict[str, Any], lang: str, level: str, unit: int, lesson_no: int) -> LessonDraft:
    data = dict(data)
    data.setdefault("lang", lang)
    data.setdefault("level", level)
    data.setdefault("unit", unit)
    data.setdefault("lesson", lesson_no)
    return LessonDraft.from_dict(data)


def draft_lesson(
    *,
    lang: str,
    level: str,
    unit: int,
    lesson_no: int,
    title: str | None = None,
    objective: str | None = None,
    claude: ClaudeClient | None = None,
    openai: OpenAIClient | None = None,
) -> LessonDraft:
    validate_supported(lang, level)
    titles = _LESSON_TITLES.get(level, [])
    lesson_title = title or (
        titles[(lesson_no - 1) % len(titles)] if titles else f"Lesson {lesson_no}"
    )
    lesson_objective = objective or _objective_for(lesson_title, level)

    claude = claude or ClaudeClient()
    openai = openai or OpenAIClient()

    if not claude.is_configured:
        draft = _skeleton_draft(lang, level, unit, lesson_no, lesson_title, lesson_objective)
        return draft

    system, user = build_curriculum_lesson_prompt(
        lang=lang,
        level=level,
        unit=unit,
        lesson=lesson_no,
        title=lesson_title,
        objective=lesson_objective,
    )
    logger.info(
        "Drafting %s %s u%s l%s: %s", lang, level, unit, lesson_no, lesson_title
    )
    response = claude.call(system, user)
    if response is None:
        return _skeleton_draft(lang, level, unit, lesson_no, lesson_title, lesson_objective)
    try:
        data = response.parse_json()
    except ValueError as exc:
        logger.warning("Claude returned non-JSON; falling back to skeleton: %s", exc)
        draft = _skeleton_draft(lang, level, unit, lesson_no, lesson_title, lesson_objective)
        draft.review_notes.append(f"Drafter parse failure: {exc}")
        return draft

    draft = _draft_from_dict(data, lang, level, unit, lesson_no)
    draft.review_status = "drafted"

    # Verifier (cross-check)
    if openai.is_configured:
        v_system, v_user = build_curriculum_verify_prompt(draft.to_dict())
        try:
            verify_resp = openai.call(v_system, v_user, max_tokens=2000)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Verifier call failed: %s", exc)
            verify_resp = None
        if verify_resp is not None:
            try:
                verify_data = verify_resp.parse_json()
            except ValueError as exc:
                logger.warning("Verifier returned non-JSON: %s", exc)
                verify_data = None
            if isinstance(verify_data, dict):
                issues = verify_data.get("issues") or []
                draft.review_notes.extend(
                    f"[verifier:{i.get('severity','info')}] "
                    f"{i.get('code','')} — {i.get('message','')} @{i.get('where','')}"
                    for i in issues
                )
                if not verify_data.get("is_passing", True):
                    draft.review_status = "needs_native"

    # Local validators
    report = review_checks.check_lesson(draft.to_dict())
    if report.error_count or report.warning_count:
        draft.review_notes.extend(
            f"[local:{i.severity}] {i.code} — {i.message} @{i.where}"
            for i in report.issues
        )
    if report.error_count:
        draft.review_status = "needs_native"

    return draft


def write_draft(draft: LessonDraft, out_dir: Path) -> Path:
    target_dir = out_dir / draft.lang / draft.level
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{draft.lesson_id()}.json"
    target.write_text(json_dump(draft.to_dict()), encoding="utf-8")
    return target


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Draft LingAfriq curriculum lessons via Claude + GPT."
    )
    parser.add_argument("--lang", required=True, choices=SUPPORTED_LANGUAGES)
    parser.add_argument("--level", required=True, choices=SUPPORTED_LEVELS)
    parser.add_argument("--unit", type=int, default=1)
    parser.add_argument(
        "--lessons",
        type=int,
        default=1,
        help="Number of lessons to draft inside the unit (1-10).",
    )
    parser.add_argument(
        "--start-lesson",
        type=int,
        default=1,
        help="Lesson number to start from (default 1).",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("tools/llm_authoring/drafts"),
        help="Output directory for drafts (default: tools/llm_authoring/drafts).",
    )
    parser.add_argument(
        "--title",
        action="append",
        default=None,
        help=(
            "Optional explicit lesson title. Pass --title repeatedly to "
            "override titles for each lesson in order."
        ),
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

    claude = ClaudeClient()
    openai = OpenAIClient()
    logger.info(
        "Drafter ready — Claude configured: %s, OpenAI configured: %s",
        claude.is_configured,
        openai.is_configured,
    )

    titles = args.title or []
    written: list[Path] = []
    for offset in range(args.lessons):
        lesson_no = args.start_lesson + offset
        explicit_title = titles[offset] if offset < len(titles) else None
        draft = draft_lesson(
            lang=args.lang,
            level=args.level,
            unit=args.unit,
            lesson_no=lesson_no,
            title=explicit_title,
            claude=claude,
            openai=openai,
        )
        path = write_draft(draft, args.out)
        written.append(path)
        logger.info(
            "Wrote %s (status=%s, notes=%s)",
            path.relative_to(Path.cwd()) if path.is_absolute() else path,
            draft.review_status,
            len(draft.review_notes),
        )

    logger.info(
        "Drafted %s lesson(s). Claude usage: %s req, OpenAI usage: %s req.",
        len(written),
        claude.usage.requests_made,
        openai.usage.requests_made,
    )
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
