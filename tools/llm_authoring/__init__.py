"""LingAfriq LLM authoring pipeline.

This package coordinates:

- ``curriculum_drafter``: drafts an authentic curriculum lesson using
  Anthropic Claude (primary) and verifies with OpenAI GPT (cross-check).
- ``games_content_drafter``: drafts vocab cards, proverbs, and game
  scenarios for the games engine.
- ``review_checks``: automated validators (orthography, tone marks,
  dialogue length, vocab density, real-word membership).
- ``publish_bundle``: promotes approved drafts into ``assets/data/*``
  with versioning + SHA256 manifest.

All modules are designed to fail safely if API keys are missing — they
will skip API calls and emit a structured "needs_review" payload rather
than crash. This makes the pipeline runnable on contributor machines
without secrets, while still producing useful artifacts.
"""

from .schemas import (
    LessonDraft,
    GameContentDraft,
    ReviewIssue,
    ReviewReport,
    SUPPORTED_LANGUAGES,
    SUPPORTED_LEVELS,
)

__all__ = [
    "LessonDraft",
    "GameContentDraft",
    "ReviewIssue",
    "ReviewReport",
    "SUPPORTED_LANGUAGES",
    "SUPPORTED_LEVELS",
]
