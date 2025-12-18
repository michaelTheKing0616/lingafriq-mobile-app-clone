Pronunciation Duel - Montreal Forced Aligner Orchestration (guide)
----------------------------------------------------------------
This document explains how to orchestrate phoneme-level scoring using Montreal Forced Aligner (MFA).

Prereqs:
- MFA installed (https://montreal-forced-aligner.readthedocs.io/)
- Acoustic model and pronunciation dictionary for the target language (for low-resource languages, train or adapt models)
- Python + textgrid parsing utilities (praatio/textgrid)

Steps:
1) Receive user audio (wav, 16kHz, mono) and reference text.
2) Create temp corpus: a folder with <uttid>.wav and transcripts.txt (format: uttid\ttext).
3) Run: `mfa align /tmp/corpus /path/to/dict /path/to/model /tmp/output --clean`
4) MFA outputs TextGrid files per utterance. Parse TextGrid to extract phoneme intervals and durations.
5) Compute Phoneme Error Rate (PER) by aligning predicted phoneme sequence to canonical sequence (levenshtein) and dividing by canonical length.
6) Compute timing deviations: for each phoneme compute expected vs actual duration ratios.
7) Aggregate metrics to a 0..100 score (e.g., 100 - 100*PER - timing_penalty*10).
8) Return JSON: {score, per, phoneme_errors:[{expected,heard,start,end,advice}], duration_ms}

Considerations:
- For languages without dictionaries, either generate a grapheme-to-phoneme mapping or use ASR-based phoneme decoding.
- MFA can be CPU-intensive; use batching and pre-warm models.
- Provide clear feedback to users and map scores to SRS quality bins.
