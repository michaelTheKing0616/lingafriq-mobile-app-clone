# Gateway model bakeoff (P6-072)

Generated: 2026-10-27T02:35:00.205Z
Scoring: fixture (fixture scores in CI; re-run with live when keys are set).
Task: generation
EXT-01: docs/plan/LINGAFRIQ_AI_MODEL_STACK.md

## Excluded by licence

- (none)

## Per-language score table (mean fixture score)

| language | model | mean | items |
| --- | --- | ---: | ---: |
| ha | gemini-3-flash | 0.6094 | 300 |
| ha | gemini-3-flash-lite | 0.5019 | 300 |
| ha | gpt-5-mini | 0.5447 | 300 |
| ha | claude-sonnet-4 | 0.5311 | 300 |
| ha | gemma-3-12b | 0.5064 | 300 |
| ha | afriquegemma-12b | 0.4923 | 300 |
| ha | qwen3-8b | 0.4788 | 300 |
| ig | gemini-3-flash | 0.6305 | 300 |
| ig | gemini-3-flash-lite | 0.5347 | 300 |
| ig | gpt-5-mini | 0.5064 | 300 |
| ig | claude-sonnet-4 | 0.5407 | 300 |
| ig | gemma-3-12b | 0.4623 | 300 |
| ig | afriquegemma-12b | 0.4569 | 300 |
| ig | qwen3-8b | 0.5112 | 300 |
| pcm | gemini-3-flash | 0.6008 | 300 |
| pcm | gemini-3-flash-lite | 0.5025 | 300 |
| pcm | gpt-5-mini | 0.5628 | 300 |
| pcm | claude-sonnet-4 | 0.5386 | 300 |
| pcm | gemma-3-12b | 0.4642 | 300 |
| pcm | afriquegemma-12b | 0.5067 | 300 |
| pcm | qwen3-8b | 0.4661 | 300 |
| sw | gemini-3-flash | 0.6273 | 300 |
| sw | gemini-3-flash-lite | 0.5033 | 300 |
| sw | gpt-5-mini | 0.5162 | 300 |
| sw | claude-sonnet-4 | 0.5225 | 300 |
| sw | gemma-3-12b | 0.4689 | 300 |
| sw | afriquegemma-12b | 0.5050 | 300 |
| sw | qwen3-8b | 0.4938 | 300 |
| xh | gemini-3-flash | 0.5911 | 300 |
| xh | gemini-3-flash-lite | 0.5177 | 300 |
| xh | gpt-5-mini | 0.5198 | 300 |
| xh | claude-sonnet-4 | 0.5356 | 300 |
| xh | gemma-3-12b | 0.4826 | 300 |
| xh | afriquegemma-12b | 0.4633 | 300 |
| xh | qwen3-8b | 0.4890 | 300 |
| yo | gemini-3-flash | 0.6303 | 300 |
| yo | gemini-3-flash-lite | 0.4944 | 300 |
| yo | gpt-5-mini | 0.5150 | 300 |
| yo | claude-sonnet-4 | 0.5051 | 300 |
| yo | gemma-3-12b | 0.4839 | 300 |
| yo | afriquegemma-12b | 0.4584 | 300 |
| yo | qwen3-8b | 0.4889 | 300 |
| zu | gemini-3-flash | 0.6157 | 300 |
| zu | gemini-3-flash-lite | 0.5248 | 300 |
| zu | gpt-5-mini | 0.5229 | 300 |
| zu | claude-sonnet-4 | 0.5467 | 300 |
| zu | gemma-3-12b | 0.4480 | 300 |
| zu | afriquegemma-12b | 0.4585 | 300 |
| zu | qwen3-8b | 0.4725 | 300 |

## Accepted generation winners (router patch)

| language | provider | model | mean |
| --- | --- | --- | ---: |
| ha | gemini | gemini-3-flash | 0.6094 |
| ig | gemini | gemini-3-flash | 0.6305 |
| pcm | gemini | gemini-3-flash | 0.6008 |
| sw | gemini | gemini-3-flash | 0.6273 |
| xh | gemini | gemini-3-flash | 0.5911 |
| yo | gemini | gemini-3-flash | 0.6303 |
| zu | gemini | gemini-3-flash | 0.6157 |

Routing: `routes.config.ts` imports `evals/bakeoff/generation_winners.json` (regenerate via `npx tsx evals/bakeoff/run.ts`).
