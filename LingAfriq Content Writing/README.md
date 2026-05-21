# LingAfriq Content Operating System

Production-grade content for lessons, games, AI (Polie), culture magazine, and historical personas — aligned with the [Master Blueprint](./african_language_learning_content_design_partner_blueprint%20(2).md).

## Generated assets (run `tools/generate_lingafriq_content.py`)

| Asset | Path | Purpose |
|-------|------|---------|
| Game content DB | `assets/data/game_content.json` | Words, proverbs, scenarios for 37+ games |
| Authentic A1 curriculum | `assets/data/lingafriq_authentic_curriculum_a1.json` | Polie + placement + curriculum service |
| Word repo merge | `assets/data/word_repo_game_seed.json` | Offline game phrase cards (+ pidgin) |

## Authoring guides

- [Master lesson template](./01_master_lesson_template.md) — 10-stage pedagogical flow mapped to app sections
- [UX brand voice](./02_ux_brand_voice_guide.md) — warm corrections, streak copy (wired in `lib/content/lingafriq_ux_voice.dart`)
- [AI tutor personality bible](./03_ai_tutor_personality_bible.md) — Polie personas + correction hierarchy
- [Games content guide](./04_games_content_operating_guide.md) — all game types, tags, scenario IDs
- [Content tagging schema](./05_content_tagging_schema.json) — metadata for adaptive learning
- [Persona missions](./persona_missions.json) — historical narrative arcs
- [Magazine seed](./magazine_articles_seed.json) — culture magazine editorial starter set
- [Polie prompt snippets](./polie_prompt_snippets.json) — mode-specific system prompts

## Launch languages

Yoruba, Hausa, Igbo, Swahili, isiZulu, Xhosa, Wolof, Nigerian Pidgin.

## Workflow

1. Edit `tools/content_data/packs.py` (source of truth for generated JSON).
2. Run `python tools/generate_lingafriq_content.py`.
3. Native speaker review for tone, dialect, and cultural accuracy.
4. Sync backend lesson CMS from generated curriculum where applicable.
5. Record slow + native audio per vocabulary item.

## Quality bar

- No placeholder tokens (`Yor_word1a`, `word1a`, etc.).
- Optimize for **how real humans communicate**, not textbook-only correctness.
- Encourage before correcting; distinguish critical vs non-critical errors.
