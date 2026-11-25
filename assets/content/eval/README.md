# Speech evaluation bundles (P4-124)

Store per-language JSON bundles alongside native-recorded 300-utterance ASR sets. Each bundle may include:

- `asr`: `{ backend, set_id, eval_date, utterance_count, wer }` — backend is `omnilingual` or `intron` (Intron only when `AI_INTRON_ENABLED` and `INTRON_API_KEY` are set server-side).
- `tts`: `{ native_mos, tone_error_rate, tone_accuracy_gate_passed }` — required for yo/ig/ha TTS enablement.
- `tone_scoring_calibration`: output of `tone_scoring_calibration_report` with `calibration_passed`.

Enablement never invents scores; missing fields keep the feature off with a visible reason code.
