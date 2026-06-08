"""Prompt templates for the LingAfriq LLM authoring pipeline.

Each template returns a tuple of (system_prompt, user_prompt). Templates
embed per-language and per-level guidance plus a curated few-shot example
so the drafter produces JSON the validators will accept on the first try.

Templates are pure-Python (no Jinja) to keep the dependency surface tiny
and to make CI debugging easy.
"""

from .curriculum import build_curriculum_lesson_prompt, build_curriculum_verify_prompt
from .games import build_games_content_prompt
from .language_briefs import LANGUAGE_BRIEFS, LEVEL_BRIEFS

__all__ = [
    "build_curriculum_lesson_prompt",
    "build_curriculum_verify_prompt",
    "build_games_content_prompt",
    "LANGUAGE_BRIEFS",
    "LEVEL_BRIEFS",
]
