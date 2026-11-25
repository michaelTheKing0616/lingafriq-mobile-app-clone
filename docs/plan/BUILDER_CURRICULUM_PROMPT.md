# LingAfriq curriculum: handoff for the app build

You're building LingAfriq's Flutter app, Node backend and admin panel. A full CEFR A1–C2 curriculum for 7 languages is ready to power them. Use it as the single source of learning content, and render it in beautiful, modern ways.

## What exists
- Location: `curriculum/` at the repo root.
  - `packs/<lang>/<A1..C2>.json` are the main items.
  - `packs/<lang>/<B2..C2>.synth.json` are expert-written advanced items.
  - `schema/item.schema.json` is the contract. Validate against it.
  - `sources/licence_register.md` gives the licence and attribution for every source.
  - `README.md` describes the build pipeline (`build/build.py`, `validators/validate.py`).
- Languages: `yo` Yoruba, `ig` Igbo, `ha` Hausa, `pcm` Nigerian Pidgin, `sw` Swahili, `zu` isiZulu, `xh` isiXhosa.
- Size: about 67,900 items (sw 18.4k, ig 11.3k, yo 10.8k, pcm 8.8k, zu 8.1k, xh 5.7k, ha 4.8k).
- Audio: about 33,800 items link to human recordings, CC0 or CC BY 4.0, from Common Voice and African Voices.
- Item types (`type`): `lexeme`, `sentence`, `pattern`, `dialogue`, `culture_note`, `proverb`.
- Key fields:
  - `id`: stable hash.
  - `cefr`, `can_do[]`, `text`.
  - `orthography.ascii_fallback` and `orthography.tone_marked`.
  - `senses[].gloss_en` and `senses[].gloss_status`.
  - `pos`, `noun_class{sg,pl}`, `frequency_rank`.
  - `examples`, `audio[]{uri, licence, kind, source_id}`.
  - `confidence` (0–1) and `risk_tags[]`.
  - `status` (`Beta` | `needs-review`) and `label` (`beta` | `expert` | `native`).
  - `feature_hooks{lessons, games, point_and_say, living_dictionary, personas}`.
  - `provenance` and `claims`.
  - `crosscheck` and `score` on the advanced items.

## Hard rules
1. **Trust labelling.** Show a small, elegant badge on every item: Beta, Expert-reviewed or Native-verified. Never present `needs-review` items as authoritative. Put them in practice and exposure modes, keep them out of graded tests, and add a gentle "Report / suggest a fix" action. That feedback goes to an admin review queue.
2. **Never alter text.** Render `text` exactly as stored, in NFC, keeping the tone marks and the Hausa letters ƙ ɗ ɓ ƴ. Use fonts with full Yoruba, Igbo and Hausa diacritic coverage (for example Noto Sans), and test that marks stack correctly.
3. **Attribution.** Build an About → Sources & licences screen generated from `licence_register.md`. Each audio clip needs its credit available, either on long-press or in an info sheet.
4. **Audio.** Stream from the `uri` references, cache them, and never re-host them without checking the licence register. Prefer `kind: human`, and when there's none, fall back to the approved TTS described in the model-stack doc.
5. **Don't cut features.** The curriculum must feed every existing feature, including Point & Say, the Living Dictionary, games, lessons, quizzes, Historical Personas (curated and free chat) and community. Fix and elevate them; never remove one.
6. **Backend import.** Ingest the packs through an idempotent importer that upserts by `id`. The admin panel should be able to filter by language, level, type, status, `risk_tags` and `confidence`, and approve items to change their `label`/`status`. When native speakers sign off later, update the label only; ids never change.

## Creative ways to use it (aim for best-in-class 2026 UX)
- **Adaptive path:** use `cefr` + `can_do` + `frequency_rank` for a skill map. Each "can-do" is a unit, and mastery is tracked per item with spaced repetition (FSRS).
- **Hear it first:** human audio on every card that has it, with a waveform scrubber, slow playback, shadowing (record and compare), and a tone contour for Yoruba and Igbo.
- **Living Dictionary:** lexemes with `noun_class` show singular/plural pairs and concord chips (zu, xh, sw), along with example sentences, frequency, and "heard in" clips from real speakers.
- **Point & Say:** use lexemes flagged `point_and_say` with camera detection. Speak the word, show its tone-marked spelling, and save it to the user's deck.
- **Games:** tone-matching, audio-to-text sprint, sentence builder from shuffled tokens, noun-class sorting, a proverb completion duel, and listening bingo with real clips.
- **Proverbs and culture:** a daily proverb card with meaning, usage and a voice clip, plus `culture_note` stories as swipeable illustrated cards.
- **Dialogues to roleplay:** turn `dialogue` items into AI roleplay scenes. The AI tutor and the personas should draw vocabulary and patterns at or slightly above the learner's level.
- **Accent-aware ASCII search:** search through `ascii_fallback`, so typing "ojo" finds "òjò", but always display the marked form.
- **Progress honesty:** show the learner's coverage per level, and make the trust badges feel premium rather than like warnings.

## Deliverables
1. A curriculum loader and importer (backend, admin) with schema validation in CI.
2. Flutter data models generated from the schema, plus an offline-first local store.
3. The features above wired to real items, with no placeholder content left.
4. The Sources & licences screen.
5. An admin review queue.

Report back the screens you changed and any schema gaps you find.
