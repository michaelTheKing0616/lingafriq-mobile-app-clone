# LingAfriq source-grounded curriculum packs (A1–C2), built 2026-10-21

Built by `build/build.py` + `build/postfix.py` (rerun to regenerate; one file per level per language is the checkpoint) following LINGAFRIQ_CURRICULUM_PLAN.md.
Every target-language string is copied verbatim (NFC) from a **shippable** source: Leipzig CC BY corpora (Wikipedia/Bible/spam domains excluded), Mozilla Common Voice CC0 sentence-collector text, African Storybook CC BY stories, SADiLaR CC BY 4.0 corpora, or FSI (public domain).
Kaikki/Wiktionary (CC BY-SA) is used **only** as an anchor/cross-check for exact spelling, tone marks, short factual glosses (≤3 words) and noun classes. No words, tones or translations were invented; items without evidence are absent, not padded.
Licences: `sources/licence_register.md` (all re-verified 2026-10-21). Schema: `schema/item.schema.json`. Validators: `validators/validate.py` → `validators/reports/report.md`.

## Status rules
Beta = confidence ≥ 0.90, lexicon-anchored exact form, short gloss, no high-risk tag. Everything else is needs-review. Grammar, culture, dialogue, idiom, tone homographs, Igbo tone, and items with no gloss source are always needs-review.
Levels: lexemes come from frequency bands among anchored lemmas (A1 1–800, A2 –1,600, B1 –3,200, B2 –5,200, C1 –8,200, C2 –12,000); sentences come from length and known-word bands; FSI grammar notes are mapped to A1–B1 by their position in the course.

## Totals
| lang | items | Beta | needs-review | needs-review share |
|---|---|---|---|---|
| yo | 10709 | 4597 | 6112 | 57% |
| ig | 11270 | 0 | 11270 | 100% |
| ha | 4540 | 820 | 3720 | 82% |
| pcm | 8775 | 0 | 8775 | 100% |
| sw | 18377 | 6107 | 12270 | 67% |
| zu | 8118 | 1075 | 7043 | 87% |
| xh | 5709 | 1535 | 4174 | 73% |

## Per language per level
| lang | level | items | Beta | needs-review | lexemes | sentences | patterns | dialogues | culture |
|---|---|---|---|---|---|---|---|---|---|
| yo | A1 | 1034 | 411 | 623 | 800 | 201 | 6 | 3 | 24 |
| yo | A2 | 1713 | 799 | 914 | 800 | 900 | 3 | 3 | 7 |
| yo | B1 | 3114 | 1435 | 1679 | 1600 | 1500 | 10 | 0 | 4 |
| yo | B2 | 1849 | 1474 | 375 | 349 | 1500 | 0 | 0 | 0 |
| yo | C1 | 1500 | 458 | 1042 | 0 | 1500 | 0 | 0 | 0 |
| yo | C2 | 1499 | 20 | 1479 | 0 | 1499 | 0 | 0 | 0 |
| ig | A1 | 1436 | 0 | 1436 | 800 | 599 | 18 | 0 | 19 |
| ig | A2 | 1729 | 0 | 1729 | 798 | 900 | 29 | 0 | 2 |
| ig | B1 | 3121 | 0 | 3121 | 1588 | 1500 | 31 | 0 | 2 |
| ig | B2 | 1985 | 0 | 1985 | 485 | 1500 | 0 | 0 | 0 |
| ig | C1 | 1499 | 0 | 1499 | 0 | 1499 | 0 | 0 | 0 |
| ig | C2 | 1500 | 0 | 1500 | 0 | 1500 | 0 | 0 | 0 |
| ha | A1 | 962 | 683 | 279 | 800 | 136 | 23 | 1 | 2 |
| ha | A2 | 316 | 124 | 192 | 230 | 59 | 25 | 0 | 2 |
| ha | B1 | 1519 | 8 | 1511 | 0 | 1500 | 16 | 0 | 3 |
| ha | B2 | 1500 | 5 | 1495 | 0 | 1500 | 0 | 0 | 0 |
| ha | C1 | 186 | 0 | 186 | 0 | 186 | 0 | 0 | 0 |
| ha | C2 | 57 | 0 | 57 | 0 | 57 | 0 | 0 | 0 |
| pcm | A1 | 1181 | 0 | 1181 | 800 | 381 | 0 | 0 | 0 |
| pcm | A2 | 1600 | 0 | 1600 | 700 | 900 | 0 | 0 | 0 |
| pcm | B1 | 1500 | 0 | 1500 | 0 | 1500 | 0 | 0 | 0 |
| pcm | B2 | 1498 | 0 | 1498 | 0 | 1498 | 0 | 0 | 0 |
| pcm | C1 | 1498 | 0 | 1498 | 0 | 1498 | 0 | 0 | 0 |
| pcm | C2 | 1498 | 0 | 1498 | 0 | 1498 | 0 | 0 | 0 |
| sw | A1 | 1483 | 856 | 627 | 800 | 600 | 46 | 25 | 12 |
| sw | A2 | 1756 | 810 | 946 | 800 | 900 | 30 | 24 | 2 |
| sw | B1 | 3121 | 1023 | 2098 | 1600 | 1498 | 12 | 5 | 6 |
| sw | B2 | 3499 | 1090 | 2409 | 2000 | 1499 | 0 | 0 | 0 |
| sw | C1 | 4496 | 1461 | 3035 | 2996 | 1500 | 0 | 0 | 0 |
| sw | C2 | 4022 | 867 | 3155 | 2522 | 1500 | 0 | 0 | 0 |
| zu | A1 | 1437 | 523 | 914 | 800 | 600 | 16 | 21 | 0 |
| zu | A2 | 922 | 489 | 433 | 800 | 102 | 0 | 20 | 0 |
| zu | B1 | 2194 | 63 | 2131 | 693 | 1500 | 0 | 1 | 0 |
| zu | B2 | 1499 | 0 | 1499 | 0 | 1499 | 0 | 0 | 0 |
| zu | C1 | 1500 | 0 | 1500 | 0 | 1500 | 0 | 0 | 0 |
| zu | C2 | 566 | 0 | 566 | 0 | 566 | 0 | 0 | 0 |
| xh | A1 | 1222 | 643 | 579 | 800 | 381 | 17 | 24 | 0 |
| xh | A2 | 862 | 687 | 175 | 800 | 48 | 0 | 14 | 0 |
| xh | B1 | 2345 | 205 | 2140 | 845 | 1500 | 0 | 0 | 0 |
| xh | B2 | 1201 | 0 | 1201 | 0 | 1201 | 0 | 0 | 0 |
| xh | C1 | 69 | 0 | 69 | 0 | 69 | 0 | 0 | 0 |
| xh | C2 | 10 | 0 | 10 | 0 | 10 | 0 | 0 | 0 |

Validator errors: {}; warnings: {"noun_class_prefix": 357, "yo_tone_not_in_lexicon": 2308, "orthography_beta_sentence": 1}

## Synthesized B2–C2 layer (packs/<lang>/<LEVEL>.synth.json)
These items were drafted by AI within the attested evidence. Every token must exist verbatim (exact toned form for yo/ig) in an attested source index (`synth/attest.py`); drafts that fail are rejected (`synth/package_log.json`). All are source_type=synthesized, status=needs-review, with per-token evidence IDs. Attested proverbs are type=proverb, cited to the corpus sentence. Self-review: `synth/SELF_REVIEW.md`. Proposed second-model cross-check: `synth/SONNET_CROSSCHECK.md` (not run; no API key).
Added (B2/C1/C2): sw 13/10/8, yo 8/3/2, ha 5/5/1, ig 5/3/1, zu 7/4/2, xh 6/4/1, pcm 0.

## Gaps (honest)
- **Nigerian Pidgin: 0 items (blocked, not padded).** Leipzig pcm is spam or English. The Common Voice GitHub repo has no pcm sentence file; the 987 CC0 pcm sentences and 12.5 h of audio are only in the Mozilla Data Collective download, which needs an account. African Voices (CC BY) needs registration. Naija-TTS (NOODL) is excluded. HF asr-nigerian-pidgin has text of unknown provenance, so it is not shipped. Naija Langwej Akademi has no licensed text. Unblock: register on MDC/African Voices, then rerun `build/build.py`.
- **Igbo:** words and sentences come from CC0 Common Voice + Leipzig, but there is no lexicon. Everything has no gloss and is needs-review with tones unverified. A licensed dictionary (IgboAPI/Oxford) is needed for Beta.
- **Yoruba/Hausa:** the glossed (Kaikki-anchored) lexicon runs out at about 950 lemmas. Further Yoruba lemmas are toned forms attested in CC0/CC BY text, with no gloss (needs-review). Hausa ships standard orthography; tones are withheld.
- **Upper levels (B2–C2):** authentic news sentences only, all needs-review. There are no CC BY idiom, proverb or literature sources yet, and no culture notes beyond FSI-located ones (1960s-era, needs-review). Only Swahili reaches 5k–12k anchored lemmas.
- **Translations:** the English for ASP sentences is page-aligned only (needs-review). Leipzig sentences have no translation.
- **Grammar:** FSI notes are located by OCR (English model). Descriptions are left null for a linguist to write from the cited pages. Bantu noun-class patterns are data-derived.
- **Audio: none shipped.** No downloaded CC0/CC BY clips. FLEURS and SLR32 are cross-check only; ViXSD needs a signed agreement.
