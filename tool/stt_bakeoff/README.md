# STT bake-off (Intron vs Sunbird vs Whisper)

Two-week eval of **conversational STT** on LingAfriq languages. Isolated-word
WER decides whether a provider can replace the pronunciation sidecar.

## Decision rule

| Scenario | Max WER | If failed |
|---|---|---|
| `isolated_word` | 0.15 | Keep Whisper + MFA for games |
| `short_phrase` | 0.20 | Do not use for lesson dictation |
| `code_switch` | 0.35 | Expected Intron win; others may fail |
| `learner` | 0.20 | Must transcribe the attempt, not "fix" it |

Pick **Intron for live roleplay / Polie** if it wins `code_switch` on Yo/Ha/Ig/Pidgin.
Do **not** move pronunciation scoring unless `isolated_word` also passes.

## Collect audio

Drop **16 kHz mono WAV** files into `tool/stt_bakeoff/audio/` using the filenames
in `eval_set.json`. Two speakers per core language (native + learner). Do not
use TTS as gold audio.

Core languages: Yoruba, Hausa, Igbo, Pidgin, Swahili, Zulu (24 clips).
Stretch: Xhosa, Amharic, Twi, Wolof, Afrikaans.

## Run

```bash
python3 tool/stt_bakeoff/probe.py --self-test
python3 tool/stt_bakeoff/probe.py --dry-run --priority core

export INTRON_API_KEY=...
export SUNBIRD_API_TOKEN=...          # or AUTH_TOKEN
export LINGAFRIQ_AUTH_TOKEN=...       # Bearer for POST /api/v2/asr/score
# optional:
# export LINGAFRIQ_ASR_URL=https://admin.lingafriq.com/api/v2/asr/score
# export BACKEND_URL=https://admin.lingafriq.com

python3 tool/stt_bakeoff/probe.py --priority core --providers intron,sunbird,whisper
```

Intron is called with `use_disable_llm_corrections=TRUE` so we score ASR, not
their post-processor. Results write to `tool/stt_bakeoff/results/` (gitignored).
