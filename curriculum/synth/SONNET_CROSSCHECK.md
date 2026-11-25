# Proposed independent cross-check (different model family, e.g. Claude Sonnet via API)
Status: not run. There is no Anthropic API key on the box. Run it once a key is added as ANTHROPIC_API_KEY; this would be a small script, synth/crosscheck.py (not written yet).

## Where it adds value
1. Grammar and concord for synthesized B2–C2 items (all langs), especially Bantu concords and Swahili TAM.
2. Tone consistency in context for yo/ig: is each attested toned token the right homograph for this meaning?
3. Naturalness and register (calques, formality).
4. Blind back-translation: translate to English without seeing our gloss, then compare.
5. Proverb gloss accuracy. Also Hausa orthography restoration (ƙ/ɗ/ɓ).
It does NOT replace a native reviewer. Disagreements route to the linguist queue; agreement alone never promotes to Beta.

## Prompt (system)
You are a senior descriptive linguist for {LANGUAGE}. Judge only; do not rewrite unless asked. Use the standard orthography ({ORTHO_NOTE}). If unsure, say "uncertain". Never guess tones.

## Prompt (user, per item, JSON in/out)
Item: {"text": "...", "level": "C1", "category": "relative_clause", "our_gloss": null}
Tasks:
1. back_translation: translate the text into English yourself (do not look for our gloss).
2. Score 1–5 with one-line reasons for: grammaticality, concord_or_tone (Bantu concord / Yoruba-Igbo tone-in-context / Hausa hooked letters), naturalness, register_fit (for the level and category), and level_fit (does it exercise the category at the level?).
3. List suspect_tokens: tokens likely to be the wrong form, homograph or spelling.
4. Give a minimal_fix only if grammaticality ≤ 3; reuse only words already in the text where possible.
Return JSON: {"back_translation":"","scores":{...},"suspect_tokens":[],"minimal_fix":null,"confidence":0-1}

## Rubric and routing
- Every score ≥ 4, back-translation semantically equals our gloss (checked by embedding plus a string judge), and no suspect tokens: confidence +0.1. The item stays needs-review but is prioritised for a quick human check.
- Any score ≤ 2, or a suspect token in yo/ig: risk_tag "crosscheck_fail", and the item goes to the top of the linguist queue.
- Any minimal_fix: re-run synth/package.py attestation on the fix before it can replace the text.
- Log agreement rates per language and category, and sample 10% for human audit to calibrate the judge.
