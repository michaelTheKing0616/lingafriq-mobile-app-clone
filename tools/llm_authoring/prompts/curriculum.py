"""Prompt templates for curriculum lesson drafting + verification."""

from __future__ import annotations

import json

from .language_briefs import LANGUAGE_BRIEFS, LEVEL_BRIEFS

_CURRICULUM_FEWSHOT_YORUBA_A1 = {
    "lang": "yoruba",
    "level": "A1",
    "unit": 1,
    "lesson": 2,
    "title": "Morning greetings",
    "objective": "Greet someone by time of day and reply naturally.",
    "cultural_notes": (
        "Greetings open every Yoruba interaction. Skipping them is read as "
        "rudeness, even with peers."
    ),
    "duration_min": 12,
    "vocab": [
        {"word": "Ẹ kú àárọ̀", "meaning": "Good morning (respectful)", "pos": "phrase", "example": "Ẹ kú àárọ̀, ìyá."},
        {"word": "Báwo ni", "meaning": "How are you? (informal)", "pos": "phrase", "example": "Báwo ni, ọ̀rẹ́?"},
        {"word": "Mo ń ṣe dáadáa", "meaning": "I am fine", "pos": "phrase", "example": "Mo ń ṣe dáadáa, ẹ ṣé."},
    ],
    "grammar": [
        "Pattern: greeting → reply → follow-up question.",
        "Use the plural respectful form (Ẹ) for elders and groups, even one elder.",
    ],
    "dialogue": {
        "scene": "Morning greeting on a Lagos street",
        "scenes": [
            {
                "label": "Meeting at the gate",
                "script": [
                    {"speaker": "A", "text": "Ẹ kú àárọ̀, ìyá.", "translation": "Good morning, mother."},
                    {"speaker": "B", "text": "Báwo ni?", "translation": "How are you?"},
                    {"speaker": "A", "text": "Mo ń ṣe dáadáa, ẹ ṣé.", "translation": "I am fine, thank you."},
                    {"speaker": "B", "text": "Ẹ ṣé. Ẹ jọ̀wọ́, jókòó.", "translation": "Thank you. Please, sit down."},
                ],
            },
            {
                "label": "Continuing the chat",
                "script": [
                    {"speaker": "A", "text": "Báwo ni ẹ̀bí?", "translation": "How is the family?"},
                    {"speaker": "B", "text": "Wọ́n ń ṣe dáadáa.", "translation": "They are well."},
                    {"speaker": "A", "text": "Ẹ ṣé pupọ̀.", "translation": "Thank you very much."},
                ],
            },
        ],
    },
    "polie_roleplay": {
        "persona": "Encouraging Mentor",
        "prompt": (
            "You are Polie, a Yoruba mentor. Greet the learner in Yoruba, ask "
            "Báwo ni, and gently correct if they reply in English. Use tone "
            "marks when writing."
        ),
        "correction_level": "gentle",
    },
    "tags": {
        "difficulty": "A1",
        "vocab_theme": "greetings",
        "cultural_topic": "respect",
        "pronunciation_difficulty": "tone_aware",
        "ai_readiness": "beginner_slow",
    },
}


def build_curriculum_lesson_prompt(
    *,
    lang: str,
    level: str,
    unit: int,
    lesson: int,
    title: str,
    objective: str | None = None,
) -> tuple[str, str]:
    """Return ``(system_prompt, user_prompt)`` for a curriculum lesson draft."""
    language_brief = LANGUAGE_BRIEFS.get(lang, "")
    level_brief = LEVEL_BRIEFS.get(level, "")
    objective_line = (
        f"The objective of this lesson is: {objective}."
        if objective
        else "Choose a clear, learner-centric objective."
    )

    system = (
        "You are a senior African languages curriculum author for LingAfriq. "
        "You write authentic, culturally grounded lessons that pass native "
        "speaker review. Every output MUST be valid JSON conforming to the "
        "supplied schema. Never include commentary outside the JSON.\n\n"
        f"Language brief — {lang}:\n{language_brief}\n\n"
        f"Level brief — {level}:\n{level_brief}\n\n"
        "Hard rules:\n"
        "- All target-language text must be authentic (no machine-translation "
        "  artifacts, no made-up words).\n"
        "- Include proper orthography and tone/diacritic marks where the "
        "  language uses them.\n"
        "- Dialogue must contain at least 6 turns across 2 scenes for A1/A2 "
        "  and 8+ turns across 2-3 scenes for B1+.\n"
        "- Grammar field must contain 2-4 short, learner-readable rules.\n"
        "- Vocab examples must be full sentences in the target language.\n"
        "- Output JSON ONLY, no markdown fences."
    )

    schema_hint = {
        "lang": lang,
        "level": level,
        "unit": unit,
        "lesson": lesson,
        "title": title,
        "objective": "<learner-centric objective>",
        "cultural_notes": "<2-3 sentence cultural anchor>",
        "duration_min": 14,
        "vocab": [
            {
                "word": "<target language>",
                "meaning": "<english>",
                "pos": "phrase|noun|verb|adjective|adverb",
                "example": "<full target-language sentence>",
                "pronunciation": "<optional ipa or syllable hint>",
            }
        ],
        "grammar": ["<short rule>", "<short rule>"],
        "dialogue": {
            "scenes": [
                {
                    "label": "<short setting>",
                    "script": [
                        {"speaker": "A", "text": "<target>", "translation": "<english>"},
                        {"speaker": "B", "text": "<target>", "translation": "<english>"},
                    ],
                }
            ]
        },
        "polie_roleplay": {
            "persona": "Encouraging Mentor",
            "prompt": "<system prompt for Polie>",
            "correction_level": "gentle",
        },
        "tags": {
            "difficulty": level,
            "vocab_theme": "<short_snake_case>",
            "cultural_topic": "<short_snake_case>",
            "pronunciation_difficulty": "tone_aware|standard",
            "ai_readiness": "beginner_slow|intermediate|advanced",
        },
    }

    user = (
        "Draft a lesson for the LingAfriq Authentic Path with the following "
        "parameters:\n\n"
        f"- Language: {lang}\n"
        f"- CEFR level: {level}\n"
        f"- Unit: {unit}\n"
        f"- Lesson number within unit: {lesson}\n"
        f"- Lesson title: {title}\n"
        f"- {objective_line}\n\n"
        "Return JSON matching this schema (keys, types, and nesting):\n"
        f"{json.dumps(schema_hint, indent=2, ensure_ascii=False)}\n\n"
        "Reference few-shot example (Yoruba A1, do NOT copy verbatim):\n"
        f"{json.dumps(_CURRICULUM_FEWSHOT_YORUBA_A1, indent=2, ensure_ascii=False)}"
    )

    return system, user


def build_curriculum_verify_prompt(lesson_json: dict) -> tuple[str, str]:
    """Return ``(system_prompt, user_prompt)`` for a verifier cross-check."""
    system = (
        "You are a quality reviewer for African languages curriculum at "
        "LingAfriq. You verify draft lessons produced by another model. You "
        "are strict and concise. Output JSON only with the following shape:\n"
        "{\n"
        '  "is_passing": true|false,\n'
        '  "issues": [\n'
        '    {"severity": "error|warning|info", "code": "<short>", '
        '"message": "<one sentence>", "where": "<jsonpath-ish>"}\n'
        "  ]\n"
        "}\n"
        "Look for: bad orthography or missing tone marks, English in "
        "target-language fields, hallucinated words, fewer than 6 dialogue "
        "turns, dialogue that doesn't match the lesson topic, vocab list "
        "shorter than 3 items, missing grammar field, mismatched level "
        "difficulty, and cultural inaccuracy."
    )
    user = (
        "Review the following draft lesson JSON and report issues. Be "
        "specific. If everything is high quality, return is_passing=true with "
        "an empty issues array.\n\n"
        f"{json.dumps(lesson_json, indent=2, ensure_ascii=False)}"
    )
    return system, user
