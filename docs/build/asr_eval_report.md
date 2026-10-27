# ASR evaluation (P6-074)

Generated: 2026-10-27T02:43:15.424Z
Scoring: fixture (fixture hypotheses in CI; re-run live when Intron/Omnilingual keys are set).
EXT-01: docs/plan/LINGAFRIQ_AI_MODEL_STACK.md

## Per-language WER and tone diacritic accuracy

| language | n | WER Intron | WER Omni | WER Whisper | tone Intron | tone Omni | tone Whisper | whisper diacritic drop |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ha | 300 | 0.0244 | 0.0317 | 0.0000 | 0.9756 | 0.9683 | 1.0000 | 0.0000 |
| ig | 300 | 0.0333 | 0.0467 | 0.0000 | 0.9667 | 0.9533 | 1.0000 | 0.0000 |
| pcm | 300 | 0.0167 | 0.0350 | 0.0000 | 0.9833 | 0.9650 | 1.0000 | 0.0000 |
| sw | 300 | 0.0333 | 0.0417 | 0.0000 | 0.9667 | 0.9583 | 1.0000 | 0.0000 |
| xh | 300 | 0.0267 | 0.0433 | 0.0000 | 0.9733 | 0.9567 | 1.0000 | 0.0000 |
| yo | 300 | 0.0194 | 0.0311 | 0.5000 | 0.9806 | 0.9689 | 0.5000 | 0.4806 |
| zu | 300 | 0.0217 | 0.0500 | 0.0000 | 0.9783 | 0.9500 | 1.0000 | 0.0000 |

## Accepted STT routing (gateway)

| language | primary | fallback | WER primary | WER fallback |
| --- | --- | --- | ---: | ---: |
| ha | intron | omnilingual-asr | 0.0244 | 0.0317 |
| ig | intron | omnilingual-asr | 0.0333 | 0.0467 |
| pcm | intron | omnilingual-asr | 0.0167 | 0.0350 |
| sw | intron | omnilingual-asr | 0.0333 | 0.0417 |
| xh | intron | omnilingual-asr | 0.0267 | 0.0433 |
| yo | intron | omnilingual-asr | 0.0194 | 0.0311 |
| zu | intron | omnilingual-asr | 0.0217 | 0.0500 |

Omnilingual-first languages (STT_OMNILINGUAL_PRIMARY_LANGS default): `(none)`.

Routing: `sttPrimaryPolicy.ts` reads `evals/asr/sets/stt_routing.json` (regenerate via `npx tsx evals/asr/run.ts`).
