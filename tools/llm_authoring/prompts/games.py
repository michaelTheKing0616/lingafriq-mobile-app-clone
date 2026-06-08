"""Prompt template for game content drafting (vocab cards + proverbs)."""

from __future__ import annotations

import json

from .language_briefs import LANGUAGE_BRIEFS, LEVEL_BRIEFS

_GAMES_FEWSHOT_SWAHILI_A2 = {
    "lang": "swahili",
    "level": "A2",
    "vocab_cards": [
        {
            "word": "Kiti",
            "meaning": "Chair",
            "category": "home",
            "difficulty": "A2",
            "example": "Ninakaa kwenye kiti.",
            "pronunciation": "kee-tee",
        },
        {
            "word": "Soko",
            "meaning": "Market",
            "category": "places",
            "difficulty": "A2",
            "example": "Tunaenda sokoni.",
            "pronunciation": "soh-koh",
        },
    ],
    "proverbs": [
        {
            "original": "Haraka haraka haina baraka",
            "translation": "Hurry hurry has no blessing",
            "meaning": "Do things carefully — speed without care brings no reward.",
            "region": "East Africa",
        }
    ],
}


def build_games_content_prompt(
    *,
    lang: str,
    level: str,
    count_vocab: int = 40,
    count_proverbs: int = 6,
) -> tuple[str, str]:
    """Return ``(system_prompt, user_prompt)`` for a game content draft.

    The drafter is asked to produce ``count_vocab`` vocab cards and
    ``count_proverbs`` proverbs in a single response. Counts can be
    tuned per-language to respect token budgets.
    """
    language_brief = LANGUAGE_BRIEFS.get(lang, "")
    level_brief = LEVEL_BRIEFS.get(level, "")

    system = (
        "You are a senior African languages content author for LingAfriq's "
        "games engine. You produce authentic vocab cards and traditional "
        "proverbs that pass native speaker review. Output is JSON only.\n\n"
        f"Language brief — {lang}:\n{language_brief}\n\n"
        f"Level brief — {level}:\n{level_brief}\n\n"
        "Hard rules:\n"
        "- Words must be real, current usage (no archaic forms unless flagged).\n"
        "- Examples must be full target-language sentences using the word.\n"
        "- Categories must be short snake_case strings (home, market, body, "
        "  family, etc).\n"
        "- Proverbs must be genuine cultural sayings, never invented.\n"
        "- Diversify across themes — avoid 30 food words in one batch.\n"
        "- Output JSON ONLY, no markdown fences."
    )

    schema_hint = {
        "lang": lang,
        "level": level,
        "vocab_cards": [
            {
                "word": "<target language>",
                "meaning": "<english>",
                "category": "<snake_case>",
                "difficulty": level,
                "example": "<full target sentence>",
                "pronunciation": "<optional>",
            }
        ],
        "proverbs": [
            {
                "original": "<target language>",
                "translation": "<english literal translation>",
                "meaning": "<one sentence explanation>",
                "region": "<region/community>",
            }
        ],
    }

    user = (
        f"Draft {count_vocab} vocab cards and {count_proverbs} proverbs for "
        f"the LingAfriq games engine in {lang} at CEFR level {level}.\n\n"
        "Return JSON matching this schema:\n"
        f"{json.dumps(schema_hint, indent=2, ensure_ascii=False)}\n\n"
        "Reference few-shot example (Swahili A2, do NOT copy verbatim):\n"
        f"{json.dumps(_GAMES_FEWSHOT_SWAHILI_A2, indent=2, ensure_ascii=False)}"
    )
    return system, user
