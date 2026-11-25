charter: v2

# ADR-013 — Two-layer living lexicon (P7-901)

Status: **Accepted** (builder default, Tope may override, 2026-10-27). Records EP-§17.7-13 and unblocks P7 lexicon build cards (P7-905–P7-923).

## Context

Elevation §17.7 describes a **living lexicon** that is shared and verified, while the app today stores **per-user** rows in `living_lexemes` (`LivingLexemeModel`) with lemma/translation only—no tone, audio, dialect, or link to the content-engine **Verified Lexicon** (`schemas/v2/content/lexeme.schema.json`, signed packs). Admin CRUD on `/admin/living-dictionary` is a third shape. Learners expect “My Words” plus a trustworthy dictionary; conflating the two stores breaks honesty and FSRS quality (P7-909).

## Decision

### Layer 1 — Verified Lexicon (shared)

- **Source of truth:** content-engine lexemes in signed packs and the backend lexicon index (same v2 `lexeme.schema.json` for all Stage-1 languages and future waves).
- **Every entry includes:** full tone-marked lemma (`orthography.standard`), `tone_pattern` where the language kit requires it, 2–3 native human audio clips (age/gender spread when available), CEFR and frequency metadata, and **label** progression per D1 (AI-drafted → native-verified / expert_reviewed per language tier).
- **Not writable by learners.** Changes flow through Studio, Native Corrections, and the living-loop promotion queue (P7-920).

### Layer 2 — My Words (personal)

- **Keeps current behaviour:** user-owned saves via learning v2 living-dictionary API (`userId`, `lemma`, `translation`, optional media context)—private to the learner.
- **New link field (when built):** `verified_lexeme_id` (nullable) referencing a Verified Lexicon `id` when a match exists; display and SRS use verified tone/audio when linked.
- **Unlinked rows** remain personal notes; they never appear in shared search, Lens tags, or lesson gloss without explicit learner action and review.

### Link rules

| Situation | Rule |
|---|---|
| Learner saves a word from a lesson, Lens, or chat | Create My Words row; set `verified_lexeme_id` when the surface token resolves to exactly one pack lexeme (NFC-normalised, dialect policy P4-115). |
| Learner types a custom lemma | My Words only; `verified_lexeme_id` null until native review promotes or links (P7-920). |
| Verified entry updated | Linked My Words rows inherit display/audio on next sync; FSRS history stays on the personal row. |
| Admin import | Writes **Verified** layer only; never overwrites My Words. |

### Living loop (outline)

Learner suggestion → moderation/review queue → on acceptance, new or updated Verified Lexicon entry with suggester credit (P7-920, P7-921). Corrections from Native Corrections and the Square feed the same queue.

### Single schema across languages

- **Verified:** `schemas/v2/content/lexeme.schema.json` + `common.schema.json` envelope (provenance, label, audio kinds).
- **Personal:** Mongo `LivingLexeme` document plus optional `verified_lexeme_id` string matching lexeme `id` pattern; no parallel proprietary schema for “shared” words.

### Everywhere (long-press)

Long-press on lesson, chat, feed, or game text offers **Save to My Words** and **Look up** (Verified when linked). Implementation cards: P7-923.

## Alternatives considered

| Option | Rejected because |
|---|---|
| One merged store (user rows promoted to global without review) | Violates §17.7-09; unverified learner text would ship as curriculum |
| Retire My Words; only pack lexicon | Loses personal context, media timestamps, and FSRS per-learner state |
| Separate per-language JSON schemas | Breaks pack signing, Studio, and Lens dictionary mapping (P7-946) |
| Wiktionary/Kaikki as live display layer | P4-003/P4-009: share-alike and evidence-only; not proprietary display |

## Consequences

- P7-905–P7-909, P7-916–P7-923 cite this ADR for layer boundaries.
- `docs/build/DECISIONS.md` row **P7-901** must be signed before those build cards leave Draft (card AC2).
- Backend migrations add `verified_lexeme_id` on `LivingLexeme` in the card that implements linking (P7-919), not in this ADR-only card.
