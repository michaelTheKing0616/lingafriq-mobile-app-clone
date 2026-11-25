# AI eval gate

`scripts/ci/ai_eval_gate.py` runs in the LLM Authoring workflow on every pull request.

A change that does not touch a prompt file or a model identifier prints `skipped: no prompt or model identifier change` and exits 0.

A change that does touch one must bring `evals/outputs.json` for those exact file bytes. The gate scores the items itself:

- `diacritic_completeness`: the output matches the reference and both carry a tone mark
- `refusal_correctness`: `refused` matches `expected_refused`
- `persona_fidelity`: `citation` is present inside `output`

A score under `evals/thresholds.yaml` prints `blocked:` and exits 1. A missing file, a hash mismatch, a git failure, or an item that cannot be scored prints `eval infrastructure failure:` and exits 2. That path never prints `skipped`.

This job does not call a live model and does not set `AI_EVALS_PASSED`. The per-language native set of at least 300 items is not in this gate.

Write the hash with `python3 scripts/ci/ai_eval_gate.py --print-sources-hash`, then store it as `sources_sha256` next to the items.
