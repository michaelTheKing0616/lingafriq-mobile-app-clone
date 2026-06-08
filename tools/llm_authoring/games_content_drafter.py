"""Draft game vocab cards and proverbs with Claude; validate locally.

CLI::

    python -m tools.llm_authoring.games_content_drafter \\
        --lang yoruba --level A2 \\
        --count-vocab 50 --count-proverbs 8 \\
        --out tools/llm_authoring/drafts/games

Requires ``CLAUDE_API_KEY`` (or ``ANTHROPIC_API_KEY``). This drafter does
**not** emit placeholder cards — if the LLM is unavailable the command exits
with a non-zero status and writes nothing.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path
from typing import Any

from . import review_checks
from ._llm_clients import ClaudeClient
from .prompts import build_games_content_prompt
from .schemas import (
    GameContentDraft,
    GameProverbCard,
    GameVocabCard,
    SUPPORTED_LANGUAGES,
    SUPPORTED_LEVELS,
    json_dump,
    validate_supported,
)

logger = logging.getLogger(__name__)


def _cards_from_dict(data: dict[str, Any], lang: str, level: str) -> GameContentDraft:
    vocab_raw = data.get("vocab_cards") or []
    proverb_raw = data.get("proverbs") or []
    vocab: list[GameVocabCard] = []
    for item in vocab_raw:
        if not isinstance(item, dict):
            continue
        word = str(item.get("word", "")).strip()
        meaning = str(item.get("meaning", "")).strip()
        if not word or not meaning:
            continue
        vocab.append(
            GameVocabCard(
                word=word,
                meaning=meaning,
                category=str(item.get("category", "general")).strip().lower()
                or "general",
                difficulty=str(item.get("difficulty", level)).strip() or level,
                example=str(item.get("example", "")).strip(),
                pronunciation=str(item.get("pronunciation", "")).strip(),
            )
        )
    proverbs: list[GameProverbCard] = []
    for item in proverb_raw:
        if not isinstance(item, dict):
            continue
        original = str(item.get("original", "")).strip()
        translation = str(item.get("translation", "")).strip()
        meaning = str(item.get("meaning", "")).strip()
        if not original or not translation:
            continue
        proverbs.append(
            GameProverbCard(
                original=original,
                translation=translation,
                meaning=meaning or translation,
                region=str(item.get("region", "")).strip(),
            )
        )
    return GameContentDraft(
        lang=lang,
        level=level,
        vocab_cards=vocab,
        proverbs=proverbs,
        drafted_by=data.get("drafted_by", "claude-sonnet-4.5"),
        review_status="drafted",
        review_notes=list(data.get("review_notes", []) or []),
    )


def draft_game_content(
    *,
    lang: str,
    level: str,
    count_vocab: int = 40,
    count_proverbs: int = 6,
    claude: ClaudeClient | None = None,
) -> GameContentDraft:
    validate_supported(lang, level)
    claude = claude or ClaudeClient()
    if not claude.is_configured:
        raise RuntimeError(
            "CLAUDE_API_KEY (or ANTHROPIC_API_KEY) is required. "
            "This drafter does not write placeholder game content."
        )

    system, user = build_games_content_prompt(
        lang=lang,
        level=level,
        count_vocab=count_vocab,
        count_proverbs=count_proverbs,
    )
    logger.info(
        "Drafting game content %s %s (%s cards, %s proverbs)",
        lang,
        level,
        count_vocab,
        count_proverbs,
    )
    response = claude.call(system, user, max_tokens=16_000)
    if response is None:
        raise RuntimeError("Claude returned no response for game content draft.")

    data = response.parse_json()
    if not isinstance(data, dict):
        raise ValueError("Drafter response must be a JSON object.")

    draft = _cards_from_dict(data, lang, level)
    report = review_checks.check_game_content(draft.to_dict())
    if report.issues:
        draft.review_notes.extend(
            f"[local:{i.severity}] {i.code} — {i.message} @{i.where}"
            for i in report.issues
        )
    if report.error_count:
        draft.review_status = "needs_native"
    else:
        draft.review_status = "pending_review"

    if len(draft.vocab_cards) < max(10, count_vocab // 2):
        draft.review_notes.append(
            f"Low vocab yield: expected ~{count_vocab}, got {len(draft.vocab_cards)}"
        )
        draft.review_status = "needs_native"

    return draft


def write_draft(draft: GameContentDraft, out_dir: Path) -> Path:
    target_dir = out_dir / draft.lang
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{draft.lang}-{draft.level}-games.json"
    target.write_text(json_dump(draft.to_dict()), encoding="utf-8")
    return target


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    parser = argparse.ArgumentParser(
        description="Draft LingAfriq game vocab + proverbs via Claude."
    )
    parser.add_argument("--lang", required=True, choices=SUPPORTED_LANGUAGES)
    parser.add_argument("--level", required=True, choices=SUPPORTED_LEVELS)
    parser.add_argument("--count-vocab", type=int, default=40)
    parser.add_argument("--count-proverbs", type=int, default=6)
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("tools/llm_authoring/drafts/games"),
        help="Output directory for JSON drafts",
    )
    args = parser.parse_args(argv)

    try:
        draft = draft_game_content(
            lang=args.lang,
            level=args.level,
            count_vocab=args.count_vocab,
            count_proverbs=args.count_proverbs,
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("%s", exc)
        return 1

    path = write_draft(draft, args.out)
    logger.info(
        "Wrote %s (%s cards, %s proverbs, status=%s)",
        path,
        len(draft.vocab_cards),
        len(draft.proverbs),
        draft.review_status,
    )
    return 0 if draft.review_status != "needs_native" else 2


if __name__ == "__main__":
    sys.exit(main())
