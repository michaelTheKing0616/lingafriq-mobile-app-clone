import json,glob,os,collections
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L=["A1","A2","B1","B2","C1","C2"]; langs=["yo","ig","ha","pcm","sw","zu","xh"]
rows=[];tot=collections.Counter()
for g in langs:
  for lv in L:
    f=f"{R}/packs/{g}/{lv}.json"
    if not os.path.exists(f): continue
    it=json.load(open(f))["items"]; c=collections.Counter(x["type"] for x in it); b=sum(x["status"]=="Beta" for x in it)
    tot[g,"n"]+=len(it); tot[g,"b"]+=b
    rows.append(f"| {g} | {lv} | {len(it)} | {b} | {len(it)-b} | {c['lexeme']} | {c['sentence']} | {c['pattern']} | {c['dialogue']} | {c['culture_note']} |")
summ="\n".join(f"| {g} | {tot[g,'n']} | {tot[g,'b']} | {tot[g,'n']-tot[g,'b']} | {((tot[g,'n']-tot[g,'b'])/tot[g,'n']*100 if tot[g,'n'] else 0):.0f}% |" for g in langs)
rep=json.load(open(f"{R}/validators/reports/report.json"))
open(f"{R}/README.md","w").write(f"""# LingAfriq source-grounded curriculum packs (A1–C2), built 2026-10-21

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
{summ}

## Per language per level
| lang | level | items | Beta | needs-review | lexemes | sentences | patterns | dialogues | culture |
|---|---|---|---|---|---|---|---|---|---|
{chr(10).join(rows)}

Validator errors: {json.dumps(rep['errors'])}; warnings: {json.dumps(rep['warnings'])}

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
""")
print(summ)
