# Moderation toxicity eval (P9-923)

Evaluates hosted moderation category mapping on Stage-1 languages and code-switch slices. **Text in fixtures is case ids only** (no slur lexicon in-repo). Production labels require native moderators (EXT-26).

## Threshold (AC3)

Severe-category **recall ≥ 0.80** on any slice with ≥500 native-labelled examples. Matches `node-backend/src/services/moderation/baseline.json` recall **4/5** and `SEVERE_RECALL_THRESHOLD` in `evalSets.ts`.

## Run

```bash
cd node-backend && yarn
cd ../lingafriq-mobile-app-clone
python3 scripts/moderation/eval_harness.py --self-test
python3 scripts/moderation/eval_harness.py --gate --json
```

Slices with **<500** examples report `insufficient_evidence`; pipeline treats them as **unsure** (no published score).

## Licence

Fixture annotator: `fixture-native-moderator-panel` / `lingafriq:moderation-eval-fixture:v1`. Replace with EXT-26 panel ids before launch gate.
