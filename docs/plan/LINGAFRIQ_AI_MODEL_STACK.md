# LingAfriq AI Model Stack: what you can use commercially (October 2026)

**Prepared for:** Tope (Fabian Umole) · **Date:** 17 October 2026 (Africa/Lagos) · **Companion to:** `LINGAFRIQ_ELEVATION_PLAN.md`

**Scope.** Every AI-powered part of LingAfriq: the LLM tutor and AI modes, Historical Personas, realtime voice conversation, speech recognition (ASR), text-to-speech (TTS), pronunciation and tone scoring, machine translation (MT), avatar lip-sync and visemes, content and curriculum bootstrapping, lesson images, moderation and child safety, embeddings and retrieval for persona grounding, and OCR. The target is the seven **Stage-1 languages** (Yoruba, Igbo, Hausa, Nigerian Pidgin, Swahili, isiXhosa, isiZulu). **Breadth is a first-class goal:** LingAfriq wants as many African languages as possible, as fast as possible. For every option this document therefore reports both Stage-1 coverage and **how many African languages it unlocks commercially**.

**How to read the evidence.** Licences, prices and language lists were checked live on 17 October 2026 against vendor documentation, model cards and licence files (links in §12). **[verify]** marks anything I could not confirm from a primary source, including any pricing that requires a sales quote. Language counts are taken from the vendor's own published list. Where a count is my own tally of that list, it says "≈". Benchmarks are cited only where they exist. For most African languages, public benchmarks are thin or old, which is why §8 makes **your own native-speaker evals** the deciding test.

---

## 0. Executive summary

1. **The four non-commercial components must go.** `utils/ttsRouting.ts:94,107,119` routes African-language TTS to **MMS-TTS first and XTTS-v2 second**. MMS-TTS weights are CC-BY-NC 4.0 and XTTS-v2 is under the Coqui Public Model Licence, which is non-commercial. NLLB (`facebook/nllb-200-distilled-600M` and the NLLB-derived `AfriNLP/AfriNLLB…`, `services/aiServiceFallback.ts:37-40,584`) is CC-BY-NC 4.0, and so are derivatives fine-tuned from it **[verify AfriNLLB card]**. `freeGoogleTranslate.service.ts:7` scrapes Google Translate's consumer site through `@vitalets/google-translate-api`. Each one has a commercial replacement below.
2. **African speech coverage is fragmented, so use a router per language and task, not one vendor.** No single vendor covers all seven Stage-1 languages for both ASR and TTS. **Intron (Sahara v2.5)** comes closest. Its ASR covers all seven, with code-switching for six of them. Its TTS covers five (Yoruba, Igbo, Hausa, Pidgin, Swahili), and Zulu and Xhosa exist there only as accents of English.
3. **isiXhosa TTS has no commercial vendor voice.** I found none at Intron, Spitch, Azure, Google, ElevenLabs or Gemini TTS. Lelapa lists TTS as "coming soon". The answer is to **commission a native isiXhosa voice and train your own model on a permissively licensed architecture** (§3.4). isiZulu has Azure's `zu-ZA` neural voices.
4. **Pronunciation and tone scoring has no off-the-shelf vendor for African languages.** Azure Pronunciation Assessment covers 33 locales and none of them is African. LingAfriq must **build** its signature scorer from Apache-2.0 **Omnilingual ASR** (forced alignment plus goodness-of-pronunciation) and open pitch tracking (pYIN/torchcrepe), calibrated against native reference recordings. That is also your moat.
5. **Gemini is the strongest commercial default for LLM and realtime work in African languages.** The 2025 AfroBench paper found frontier closed models 12–13 points ahead of the best open model across 64 African languages. A third-party leaderboard updated in October 2026 ranks Gemini Flash models first **[verify; not peer-reviewed]**. Gemini Live's native-audio model lists **13 African languages**, including Swahili, Yoruba, Hausa and Zulu, but **not Igbo, isiXhosa or Pidgin**. Those three need a cascaded pipeline (ASR → LLM → TTS).
6. **Long-tail languages are unlocked by open weights:** Omnilingual ASR (1,600+ languages, Apache-2.0), MADLAD-400 MT (400+ languages, Apache-2.0), and Gemini/frontier LLMs for drafting. Whatever they produce in a long-tail language **must be native-validated before learners see it**. §7 sets out what can be AI-bootstrapped and what cannot.
7. **The existing Intron integration is well built but barely used.** It is server-side, keeps its key off the client, maps all seven languages and gates TTS to the languages Intron actually supports (`intron.service.ts`, `intronLanguageMap.ts:52`). But the mobile app never calls it: `pronunciation_service.dart:18` posts to `/api/voice/stt/transcribe`, which proxies to the Whisper-large-v3 voice service (`voice.route.ts:95-120`, `lingafriq-voice-service/main.py:16`). Whisper's language list has **no Igbo, isiZulu, isiXhosa or Pidgin**.
8. **Rough monthly AI spend:** about **$3.5k–5k at 10k MAU** and **$25k–40k at 100k MAU**, before the native-review content budget, under the usage assumptions in §10. The biggest levers are caching curriculum audio (record once, never synthesise per user), self-hosting ASR for scoring, and per-tier quotas.

### Recommended primary per app function (plain English)

| App function | Primary (licence) | Fallback | Why |
|---|---|---|---|
| LLM tutor, AI modes, explanations | **Gemini 3 Flash** via Vertex AI (commercial API; paid tier not used for training) | GPT-5 mini (commercial API); open-weight Gemma 3 / AfriqueGemma self-hosted | Best published African-language results among affordable models; $0.50 / $3 per M tokens; the same vendor also covers realtime, TTS (Swahili), OCR and embeddings |
| Historical Personas (grounded, long answers) | **Gemini 3.1 Pro** for authoring and offline dossier work; **Gemini 3 Flash** at runtime with retrieval (RAG) | Claude or GPT frontier model **[verify current African-language evals]** | Grounded answers need retrieval and citations more than raw model size; Pro only where depth matters |
| Realtime voice conversation | **Gemini Live native audio** (sw, yo, ha, zu) + **cascaded Intron STT → Gemini Flash → Intron/Spitch TTS** (ig, pcm, xh) | OpenAI gpt-realtime (cascade-only for African languages **[verify language quality]**) | Native audio where it covers the language; a cascade where it does not, so all seven work |
| Speech recognition (ASR) | **Intron Sahara v2.5** (commercial API; covers all 7, code-switching in 6) | **Omnilingual ASR** self-hosted (Apache-2.0); Google Chirp 3 (yo, ha, sw, xh, zu); Lelapa (zu) | Only vendor covering all seven, built for African accents and code-switching; open fallback avoids lock-in and unlocks the long tail |
| Text-to-speech (dynamic AI turns) | **Intron TTS** for yo, ig, ha, pcm, sw; **Azure `zu-ZA`** for isiZulu; **custom-trained voice** for isiXhosa | **Spitch** (yo, ig, ha, pcm, am); ElevenLabs v3 (ha, sw); Google Chirp 3 HD (sw) | Native-designed voices; Spitch restores Yoruba tone marks before synthesis. Curriculum audio should be **human-recorded**, not synthesised |
| Pronunciation and tone scoring | **Build in-house:** Omnilingual ASR CTC alignment + GOP (Apache-2.0) + pYIN/torchcrepe F0 (ISC/MIT) + native reference contours | Vendor ASR transcript match as a coarse "was it understood?" check | No vendor supports African-language pronunciation assessment; this is the product's signature and moat |
| Machine translation | **Google Cloud Translation** (commercial API) for yo, ig, ha, sw, xh, zu; **Gemini** for Pidgin and style | **Azure Translator** (same 6); **MADLAD-400** self-hosted (Apache-2.0) for long tail; Spitch/Lelapa for local pairs | Broad African coverage, paid terms, no scraping. Gemini handles Pidgin, which the MT APIs do not list |
| Lip-sync and visemes (avatars) | **Phoneme timings from forced alignment** of the TTS or recorded audio (Omnilingual CTC, Apache-2.0) → per-language viseme table | Rhubarb Lip Sync (MIT) phonetic mode; RMS-driven jaw | Works for every language you have audio for; no vendor covers African visemes |
| Content and curriculum bootstrapping | **Gemini 3.1 Pro** (drafts, distractors, variants) + **Spitch diacritics restoration** for tone-mark QA | GPT-5 / Claude for second-opinion drafts; MADLAD-400 for long-tail glosses | Drafts only; every learner-facing string is native-validated (§7) |
| Lesson images | **Imagen 4** via Vertex AI ($0.02–0.06/image, Google IP indemnity) | FLUX.1 [schnell] self-hosted (Apache-2.0) | Commercial terms with indemnity; open fallback. Not FLUX.2 [dev] (non-commercial) |
| Moderation (text, image) | **OpenAI omni-moderation** (free) + **Gemini Flash-Lite classifier** with native-curated lexicons for African languages | **Qwen3Guard** self-hosted (Apache-2.0, 119 languages **[verify African coverage]**) | Free baseline, plus an LLM classifier that you evaluate per language. Don't build on Perspective API, which shuts down 31 Dec 2026 |
| Child safety (CSAM) | **Microsoft PhotoDNA Cloud** (free for vetted organisations) | **Thorn Safer Match** (paid; ~$30.7k/yr for 1M queries/month on AWS Marketplace) | Industry-standard known-CSAM hash matching; required before any media sharing |
| Voice-message moderation | **ASR (Intron) → text moderation pipeline**; no recording of minors' calls | Gemini audio understanding for flagged clips | No vendor moderates African-language audio directly |
| Embeddings and RAG (persona grounding) | **Gemini embedding-001** ($0.15/M tokens, 100+ languages) | **BGE-M3** (MIT) or **Qwen3-Embedding** (Apache-2.0) self-hosted | Persona sources are mostly English and French archival text; a multilingual embedder suffices; evaluate retrieval on target-language queries |
| OCR (archival sources, learner photos) | **Google Cloud Vision** (supports yo, ha, sw, zu) | Gemini vision for diacritic-heavy pages; Tesseract (Apache-2.0; yor, swa) | Vendor OCR with African Latin-script support; LLM vision as a diacritic-aware second pass |

---

## 1. Ground rules for choosing a model

1. **Commercial test.** A model is eligible only if (a) it is a paid API whose terms allow use in a commercial consumer app, or (b) its weights carry a licence that permits commercial use (Apache-2.0, MIT, BSD, CC-BY-4.0) or a "community" licence whose conditions LingAfriq meets (Gemma Terms of Use; Llama 4 Community Licence, which needs a separate licence only above 700M MAU). **Excluded:** CC-BY-NC, Coqui CPML, FLUX [dev] non-commercial terms, Awarri's N-ATLaS licence above 1,000 active end-users, and any scraping of consumer websites.
2. **Datasets count too.** A model fine-tuned on NC data (for example the MMS or NLLB training sets) inherits risk. Keep a licence register for every model **and** dataset (§9).
3. **Server-side keys only.** Every model call goes through the node-backend gateway (§9). No vendor key ever ships in the app, which fixes P0-3 in the elevation plan.
4. **Kids and voice data.** Use paid tiers where vendors commit not to train on your data. Get a DPA from every speech vendor. Default to **no storage of raw audio** unless the learner opts in (NDPA 2023, GDPR, COPPA; see elevation plan §13.2).
5. **Native validation decides.** Vendor claims and leaderboards only produce a shortlist. A model goes live in a language only after passing **your** per-language eval with native reviewers (§8).

### 1.1 Replacements for the non-commercial components

| Current component (evidence) | Licence problem | Replace with |
|---|---|---|
| **MMS-TTS** (`node-backend/mms-tts-service/main.py:46`; first in `utils/ttsRouting.ts:94,119`) | CC-BY-NC 4.0 (non-commercial) | Intron TTS (yo, ig, ha, pcm, sw) · Spitch (yo, ig, ha, pcm) · Azure `zu-ZA` · custom isiXhosa voice (§3.4) |
| **XTTS-v2** (`node-backend/coqui-xtts-service/app.py:64`; second in `ttsRouting.ts:94`, first at `:107`) | Coqui Public Model Licence (non-commercial; Coqui closed in 2024, so no commercial licence can be bought) | Same as above. For voice cloning of persona actors, use a vendor custom-voice feature with signed consent (Spitch custom voices, ElevenLabs Professional Voice Clone) or train your own on licensed recordings |
| **NLLB / AfriNLLB** (`node-backend/src/services/aiServiceFallback.ts:37-40,584`; client `NLLB_API_URL` in `lib/services/secrets_manager.dart:85`) | CC-BY-NC 4.0 | Google Cloud Translation / Azure Translator (API); MADLAD-400 (Apache-2.0) self-hosted; Gemini for Pidgin |
| **Unofficial Google Translate scraper** (`services/freeGoogleTranslate.service.ts:7`, `@vitalets/google-translate-api`) | Violates Google's terms; unreliable; no data-processing terms | Google Cloud Translation API (paid, contractual) |
| **Whisper-large-v3 STT** (`lingafriq-voice-service/main.py:16` via `voice.route.ts:95-120`) | Licence is fine (MIT), but Whisper's language list has **no Igbo, isiZulu, isiXhosa or Pidgin** | Intron (primary), Omnilingual ASR (self-hosted fallback) |
| **Groq `llama-3.1-70b-versatile`** (`services/telemetryIngest.service.ts`, `controllers/telemetry.controller.ts`) | Decommissioned by Groq on 24 Jan 2025, so calls fail. `llama-3.3-70b-versatile` (used in `polieConversation.controller.ts` and many client screens) was deprecated for Free/Developer tiers on 16 Aug 2026 | Gemini 3 Flash through the gateway (§9) |

### 1.2 The existing Intron integration (checked in code)

- **Good:** server-side client with the key read from env and never exposed (`services/intron.service.ts:2-3,61`). Routes are mounted at `/api/stt` and `/api/voice/intron` with `requireSignin` and `uploadLimiter` (`routes/intron.route.ts:104-108,163-166`, `routes/index.route.ts:225-226`). Uploads are capped at 10 MB (`intron.route.ts:30`). The language map covers all seven Stage-1 languages (`utils/intronLanguageMap.ts:6-47`). TTS is restricted to `yo, ha, ig, pcm, sw, en` (`:52`), which matches Intron's published TTS list (Zulu and Xhosa are English accents only). `use_disable_llm_corrections` defaults to TRUE (`intron.service.ts:94-98`). That is the right choice for pronunciation, because you want what the learner actually said, not an LLM-"corrected" version.
- **Gaps:**
  1. **Nothing in the app calls it.** The app's STT path is `/api/voice/stt/transcribe` → Whisper voice service (`lib/services/hybrid_polie/pronunciation_service.dart:18`; `routes/voice.route.ts:95-120`).
  2. It uses the **synchronous** upload endpoint with a 90 s timeout (`intron.service.ts:24,102`). Sahara v2.5 has **streaming** STT and TTS endpoints, which is what realtime voice needs.
  3. TTS calls `/tts/v1/generate` (`intron.service.ts:186`), but the current docs show `/tts/v1/enqueue`. **[verify]** whether `generate` is still supported.
  4. Intron publishes **no price list** (demo or quote only), so its cost cannot be modelled precisely **[verify]**. Its data-retention and training terms need a DPA.
- **Action:** make Intron the default ASR in the gateway for all seven languages, switch realtime turns to the streaming endpoints, and negotiate a contract that includes a DPA, a no-training clause, data residency options, and volume pricing.

---

## 2. Coverage breadth matrix (Stage 1 + how many African languages each option unlocks)

✓ = listed by the vendor for that capability · ◐ = partial (preview, English-accent only, a different model tier, or quality listed as "moderate") · ✗ = not listed · ? = could not verify.

### 2.1 ASR (speech-to-text)

| Option | Licence / access | Yoruba | Igbo | Hausa | Pidgin | Swahili | Xhosa | Zulu | African languages covered (commercially) |
|---|---|---|---|---|---|---|---|---|---|
| **Intron Sahara v2.5** | Commercial API (quote) | ✓ (code-switch) | ✓ (cs) | ✓ (cs) | ✓ (cs) | ✓ (cs) | ✓ | ✓ (cs) | ≈28 distinct African languages in the docs list (35 entries, counting 8 Fulani variants), plus Arabic. Intron advertises 63 total languages in v2.5 |
| **Omnilingual ASR** (Meta) | **Apache-2.0** weights; corpus CC-BY-4.0; self-host | ? [verify code] | ? | ? | ? | ? | ? | ? | 1,600+ languages total, including hundreds of low-resource ones. **The broadest long-tail unlock**; the per-language CER table is published in the repo CSV. Stage-1 codes not individually checked **[verify]** |
| **Google Chirp 3** (Cloud STT v2) | Commercial API | ◐ preview | ◐ Chirp 2 only | ◐ preview | ✗ | ◐ preview | ◐ preview | ◐ preview | ≈10 Sub-Saharan (af, am, ha, sw, xh, yo, zu, wo, Twi, Sotho) + Egyptian and Moroccan Arabic |
| **ElevenLabs Scribe v2** | Commercial API | ◐ "moderate" (25–50% WER) | ◐ moderate | ✓ "good" (10–20%) | ✗ | ✓ "high" (5–10%) | ◐ moderate | ◐ moderate | ≈13 (sw, af, ha, am, lug, ig, nso, sn, so, wo, xh, yo, zu) |
| **Spitch** | Commercial API | ✓ | ✓ | ✓ | ? | ? | ✗ | ✗ | yo, ig, ha, am, en documented; Swahili mentioned on overview **[verify]** |
| **Lelapa Vulavula** | Commercial API | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ (translation only) | ✓ (incl. code-switched) | isiZulu ASR; Xhosa and Zulu translation; TTS "coming soon" |
| **N-ATLaS ASR** (Awarri/NCAIR) | **Not commercial** above 1,000 active users/30 days without a separate licence | ✓ | ✓ | ✓ | ◐ (Nigerian English) | ✗ | ✗ | ✗ | 3; **excluded** unless a commercial licence is negotiated |
| **Whisper large-v3** (current) | MIT | ◐ | ✗ | ◐ | ✗ | ◐ | ✗ | ✗ | Several (yo, ha, sw, sn, so, ln, af, am…), all weak per published Nigerian benchmarks |

### 2.2 TTS (text-to-speech)

| Option | Licence / access | Yoruba | Igbo | Hausa | Pidgin | Swahili | Xhosa | Zulu | African languages (native voices) |
|---|---|---|---|---|---|---|---|---|---|
| **Intron TTS** | Commercial API | ✓ m/f | ✓ m/f | ✓ m/f | ✓ m/f | ✓ m/f | ◐ English-accent only | ◐ English-accent only | 12 (af, am, ha, ig, rw, lg, om, pcm, sn, sw, wo, yo) |
| **Spitch TTS** | Commercial API ($0.0014/s) | ✓ (auto-diacritises Yoruba) | ✓ | ✓ | ✓ | ? | ✗ | ✗ | yo, ig, ha, pcm, am (+ custom voices from a short reference) |
| **Azure Neural TTS** | Commercial API ($16/M chars) | ✗ | ✗ | ✗ | ✗ | ✓ (sw-KE) | ✗ | ✓ (zu-ZA, 2 voices) | sw, zu, plus af, am, so **[verify last three]** |
| **Google Cloud TTS (Chirp 3 HD)** | Commercial API | ✗ | ✗ | ✗ | ✗ | ✓ (sw-KE) | ✗ | ✗ | sw (+ other tiers for af, am **[verify]**) |
| **ElevenLabs Eleven v3** | Commercial API ($0.08/1k chars) | ✗ | ✗ | ✓ | ✗ | ✓ | ✗ | ✗ | ha, sw (+ af **[verify]**) |
| **Gemini TTS** | Commercial API | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | sw |
| **9jaLingo TTS-2** | Package code Apache-2.0; **weights licence [verify]** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | 4 + Nigerian English |
| **YarnGPT** | **CC-BY-NC-SA 4.0**: excluded | – | – | – | – | – | – | – | – |
| **MMS-TTS / XTTS-v2** (current) | **Non-commercial**: excluded | – | – | – | – | – | – | – | – |
| **Train your own** (VITS/Piper-class, MIT/Apache architectures) | Your weights, your licence | possible | possible | possible | possible | possible | **required** | possible | Unlimited, given licensed recordings (≈2–10 h per voice; §3.4) |

### 2.3 Machine translation

| Option | Licence / access | yo | ig | ha | pcm | sw | xh | zu | African breadth |
|---|---|---|---|---|---|---|---|---|---|
| **Google Cloud Translation** | Commercial API | ✓ | ✓ | ✓ | ✗ [verify] | ✓ | ✓ | ✓ | Broadest API. About a quarter of the 110 languages added in June 2024 are African (Fon, Kikongo, Luo, Ga, Swati, Venda, Wolof, Ndebele…), on top of existing ones (Fulani, Kanuri, Tiv, Amharic, Somali, Shona, Kinyarwanda…). ≈40+ African **[verify exact count in the Cloud API, which can differ from the consumer app]** |
| **Azure Translator** | Commercial API | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ≈15–20 African **[verify]**; containers available for ha, ig, xh, yo (on-prem option) |
| **MADLAD-400** (Google Research) | **Apache-2.0**; self-host (3B/7B/10B) | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 400+ languages; ≈30+ African in the model card (am, so, rw, ny, sn, st, om, lg, ti, ts, tn, nso, ee, ak, ln, mg, sg, lu…). Model card says "research model", so evaluate before production |
| **TranslateGemma** (Jan 2026) | Gemma Terms (commercial allowed with use policy) | ✓ | ✓ | ✓ | ? | ✓ | ? | ? | 55 evaluated languages, incl. ak, am, bm, ee, ha, ig, sw, yo; ~500 extra pairs trained but unevaluated |
| **Gemini / frontier LLM translation** | Commercial API | ✓ | ✓ | ✓ | ✓ (strong) | ✓ | ✓ | ✓ | Any language the model knows; quality varies widely, so evaluate per language |
| **Spitch translation** | Commercial API ($1/10k words) | ✓ | ✓ | ✓ | ? | ? | ✗ | ✗ | Nigerian languages |
| **Lelapa Vulavula** | Commercial API | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | Zulu, Xhosa (+ other South African languages **[verify]**) |
| **NLLB / scraper** (current) | Excluded | – | – | – | – | – | – | – | – |

### 2.4 LLMs and realtime voice

| Option | Licence | Stage-1 text quality evidence | Realtime voice languages |
|---|---|---|---|
| **Gemini 3 Flash / 3.1 Pro / 3.1 Flash-Lite** | Commercial API | AfroBench (ACL Findings 2025): Gemini 1.5 Pro 58.5 vs Gemma 2 27B 47.9 (older generation). DataLens Africa leaderboard (Oct 2026, 4 benchmarks): Gemini Flash models ranked #1–2 **[verify; third-party]** | **Gemini Live native audio: 13 African languages** (af, ak, am, ha, om, rw, so, st, sw, tn, wo, yo, zu). **Not** ig, xh, pcm |
| **OpenAI GPT-5 mini / frontier** | Commercial API | AfroBench: GPT-4o 59.6 (top); DataLens ranks recent GPT models #3–4 **[verify]** | gpt-realtime-2 ($32/$64 per M audio tokens) and realtime-2.1 mini ($10/$20). African-language list not published **[verify]** |
| **Anthropic Claude** | Commercial API | DataLens ranks Claude below Gemini/GPT on African benchmarks **[verify]** | No native realtime voice API; cascade only |
| **Gemma 3 / AfriqueGemma-12B** | Gemma Terms (commercial OK). AfriqueGemma states CC-BY-4.0 but is a Gemma derivative, so Gemma terms also apply | AfriqueGemma: continued pre-training on 20 African languages, including yo, ig, ha, sw, xh, zu (not pcm) | Self-hosted cascade only |
| **Qwen3** | **Apache-2.0** | 119 languages incl. Swahili; Yoruba not listed | Cascade only |
| **Llama 4** | Llama 4 Community Licence (commercial < 700M MAU) | No African-specific evidence found **[verify]** | Cascade only |
| **Aya (Cohere For AI)** | **CC-BY-NC**: excluded for self-hosting | – | – |
| **N-ATLaS LLM** | 1,000-user cap: excluded without a licence | yo, ig, ha, Nigerian English | – |

---

## 3. Function-by-function recommendations

Each subsection gives options, licence in plain words, coverage, quality evidence, cost, latency, privacy notes, and a recommended **primary** and **fallback**.

### 3.1 LLM tutor and AI modes (explain, converse, grade free text, generate drills)

- **Options:**
  - **Gemini 3 Flash.** $0.50 input / $3.00 output per M tokens, thinking tokens included.
  - **Gemini 3.1 Flash-Lite.** $0.25 / $1.50; for classification, grading and short replies.
  - **Gemini 3.1 Pro.** $2 / $12 up to 200k-token prompts.
  - **GPT-5 mini.** $0.25 / $2, with $0.025 cached input.
  - **Open weights, self-hosted:** Gemma 3 / AfriqueGemma, Qwen3.
- **Licence in plain words:** paid APIs let you use outputs commercially. Gemini's paid tier (a Cloud project with billing) does not use prompts to train Google's models, but the **free tier and AI Studio do, and humans may review them, so never send user data through the free tier.** Vertex AI offers zero data retention when optional logging, session resumption and grounding retention are disabled.
- **Quality:**
  - Frontier closed models lead open models by about 12–13 points on AfroBench, and the gap is widest on reasoning and knowledge tasks.
  - Every model is weakest at **diacritics and tone marks**. AfroBench added AfriADR, a diacritic-restoration task, for exactly this reason.
  - Mitigations:
    - Constrain generation to the approved lexicon.
    - Run a diacritic validator.
    - Run Spitch tone-marking as a check for Yoruba.
    - Have natives review all reusable outputs.
- **Latency:** Flash-class models stream a first token in a few hundred ms **[verify on your region]**. Target under 400 ms to first token.
- **Privacy:** paid tier only, a DPA, a region choice in Vertex AI, and PII scrubbing before prompts (names, phone numbers, school names for minors).
- **Primary:** Gemini 3 Flash, with Flash-Lite for classification and grading. **Fallback:** GPT-5 mini. **Long-term hedge:** a self-hosted AfriqueGemma/Gemma 3 fine-tune for high-volume, low-risk tasks once your eval sets exist.

### 3.2 Historical Personas

- **Runtime:** Gemini 3 Flash with **retrieval over a curated persona dossier** (primary sources, historian notes, claims list with citations). Answers must cite dossier passages, and the system refuses or hedges when retrieval confidence is low. Gemini 3.1 Pro handles **offline** dossier summarisation, timeline extraction and eval generation.
- **Disclosure:** every persona is labelled as AI (EU AI Act Art. 50 transparency duties apply from 2 Aug 2026), and the system prompt must not say "never mention being an AI" (elevation plan P0-15).
- **Voice:** the persona speaks in the target language through the TTS router. A cloned actor voice is allowed only with a signed consent and licence, and labelled as synthetic.
- **Primary:** Gemini 3 Flash + RAG. **Fallback:** GPT-5 mini + RAG. Evals follow §8 (persona fidelity, factuality, refusal correctness, sensitivity).

### 3.3 Realtime voice conversation

- **Option A, native audio (lowest latency):** Gemini Live native audio. Pricing is $3 per M audio-input tokens and $12 per M audio-output tokens (text $0.50/$2). Sessions are limited to **15 minutes** audio-only (extendable with session management), and clients connect with **ephemeral tokens**, so no long-lived key reaches the app. It covers **yo, ha, sw, zu** of Stage 1, plus am, so, af, rw, wo, ak, om, st, tn for later waves.
- **Option B, cascade (covers all seven, plus code-switching):**
  1. VAD.
  2. **Intron streaming STT** (v2.5).
  3. Gemini 3 Flash, streaming.
  4. Streaming TTS: Intron (yo, ig, ha, pcm, sw), Azure (zu), custom (xh).
  5. Client playback with barge-in.
  Run it on LiveKit Agents (Apache-2.0) or Pipecat (BSD-2) **[verify current licences]**.
- **Option C:** OpenAI gpt-realtime-2 / 2.1 mini. African-language voice quality is unpublished, so treat it as a backup for English explanations.
- **Latency targets:** under 800 ms from the user stopping speaking to the first audio. The cascade typically needs streaming at every stage to hit this **[measure]**.
- **Primary:** Gemini Live for sw, yo, ha, zu; the cascade for ig, pcm, xh and for any session that needs scoring or code-switching. **Fallback:** the cascade everywhere.

### 3.4 Speech recognition (ASR) per language

| Language | Primary | Fallback(s) | Notes |
|---|---|---|---|
| Yoruba | Intron (Yoruba-English code-switch) | Omnilingual ASR (self-host); Google Chirp 3 (preview) | Disable LLM corrections for scoring; ask for diacritised output, or restore diacritics with Spitch |
| Igbo | Intron (Igbo-English) | Omnilingual; Google Chirp 2 | Scribe rates Igbo "moderate" (25–50% WER) |
| Hausa | Intron (Hausa-English) | Omnilingual; Scribe ("good", 10–20% WER); Chirp 3 | Check ɓ/ɗ/ƙ/ƴ handling in transcripts |
| Nigerian Pidgin | Intron (Pidgin-English) | Omnilingual **[verify pcm]** | No other major vendor lists Pidgin |
| Swahili | Intron (Swahili-English) | Scribe ("high", 5–10% WER); Google Chirp 3 | Most competitive language; benchmark vendors head-to-head |
| isiXhosa | Intron | Omnilingual; Chirp 3 (preview) | Clicks c/q/x need careful eval; few vendors |
| isiZulu | Intron (Zulu-English) | Lelapa Vulavula (incl. code-switched); Chirp 3 | Lelapa is South African and Zulu-first; good second opinion |

- **Cost:** Intron by quote **[verify]**. Google STT v2 costs $0.016/min for the first 500k min/month, falling to $0.004/min at volume, and dynamic batch is $0.003/min. Spitch costs $0.00042/s (≈$0.025/min). Scribe v2 costs $0.22/hour (≈$0.0037/min). Self-hosted Omnilingual costs GPU time (§10).
- **Privacy:** send audio server-side only, delete after processing unless the learner opts in, put a vendor DPA in place, and choose an EU or African region where offered **[verify Intron hosting region]**.

### 3.5 Text-to-speech per language (natural, tone-correct)

**Principle:** **curriculum audio is human-recorded** (≥4 native voices per Tier-1 language, elevation plan §6.6). TTS is for *dynamic* content only: AI tutor turns, personas, and user-generated phrases. Even then, cache every synthesised phrase by `(text NFC, voice, speed)` hash.

| Language | Primary | Fallback | Tone-correctness notes |
|---|---|---|---|
| Yoruba | Intron TTS | Spitch (diacritises Yoruba input before synthesis) | **Always send fully tone-marked text.** Unmarked Yoruba is ambiguous, so TTS will guess. Run text through the diacritic validator first |
| Igbo | Intron TTS | Spitch | Same; dotted vowels and tone marks |
| Hausa | Intron TTS | Spitch; ElevenLabs v3 | Hausa tone and vowel length are rarely written; use a lexicon of marked forms for teaching items |
| Nigerian Pidgin | Intron TTS | Spitch | Lower tone risk; naturalness and register matter more |
| Swahili | Intron TTS | Google Chirp 3 HD `sw-KE`; Azure `sw-KE`; ElevenLabs v3; Gemini TTS | Several good options; pick by blind native listening test |
| isiZulu | **Azure `zu-ZA`** (ThandoNeural, ThembaNeural) | **Custom voice** (below) | Only two prebuilt voices; consider a custom voice for the cast |
| isiXhosa | **Custom-trained voice** | None found commercially (Lelapa "coming soon"; Intron English-accent only) | Commission 2 voice actors (f/m) for ≈5–10 h each of studio recordings under a buy-out licence. Train a VITS/Piper-class model (MIT/Apache architectures) or a vendor custom voice where the vendor supports Xhosa **[verify Spitch/ElevenLabs custom-voice support for Xhosa]** |

**Cost:** Azure $16 per M characters (500k free per month). ElevenLabs $0.08 per 1k characters (v3/Multilingual) or $0.04 (Flash). Spitch $0.0014/s (≈$0.084/min). Intron by quote **[verify]**. Custom voices cost a one-off recording fee plus GPU training and hosting **[get quotes]**.

### 3.6 Pronunciation and tone scoring (the signature capability)

- **Vendor check:** **Azure Pronunciation Assessment supports 33 locales and none is African.** I found no commercial vendor offering phone- or tone-level assessment for any Stage-1 language **[verify Speechace/SpeechSuper; not checked in depth]**.
- **Build pipeline:**
  1. Run **Omnilingual ASR CTC** (Apache-2.0) to force-align the learner audio to the expected phone sequence. Omnilingual CTC models accept up to 40 s of audio, which suits short items.
  2. Compute **goodness of pronunciation (GOP)** per phone from CTC posteriors.
  3. Extract **F0** with pYIN (librosa, ISC licence) or **torchcrepe** (MIT). Normalise per speaker (semitones relative to the speaker's median) and compare the syllable-level contour with **native reference recordings** of the same item using DTW. Classify each syllable as H/M/L for Yoruba, or H/L/downstep for Igbo and Hausa.
  4. Return per-syllable feedback with a **confidence** score. Below the confidence threshold, show "I'm not sure, try again" instead of a fake score.
  5. Calibrate thresholds per language on a native and learner dataset rated by 3+ native judges. Report agreement (Cohen's κ) before launch.
- **Languages:** tone is central for yo, ig, ha. isiZulu and isiXhosa are tonal too, though tone is unwritten and less critical for learners, so prioritise clicks and vowels there. Swahili is non-tonal, so focus on stress and vowel purity. Pidgin needs intelligibility feedback only.
- **Licences:** Praat/Parselmouth is GPL-3. That is fine on a server you don't distribute, but **avoid bundling it in the app**.
- **Cost:** a GPU inference service, roughly one L4-class GPU at 10k MAU and 3–4 at 100k (§10).
- **Primary:** in-house scorer. **Fallback:** a coarse "understood / not understood" check using vendor ASR.

### 3.7 Machine translation

- **Use MT for:** glosses, UI drafts, learner free-text help, and community chat translation. **Never** use it for curriculum text without native review.
- **Primary:** Google Cloud Translation for yo, ig, ha, sw, xh, zu, and Gemini 3 Flash for Pidgin and register-controlled output. **Fallback:** Azure Translator. **Long tail:** MADLAD-400 (Apache-2.0) self-hosted, and TranslateGemma for its 55 evaluated languages. **Local specialists:** Spitch (Nigerian languages, $1/10k words) and Lelapa (Zulu, Xhosa).
- **Cost:** Google and Azure translation run at a few dollars to about $20 per M characters, varying by model tier **[verify current SKU prices]**. Self-hosted MADLAD-10B needs one GPU.

### 3.8 Lip-sync and visemes for avatars (forward-looking: avatars are not built yet)

- **Pipeline:**
  1. For every audio clip the avatar speaks (human-recorded or TTS), run forced alignment with Omnilingual CTC for phone timings.
  2. Map phones to the per-language viseme enum in the avatar brief (elevation plan §4): lab-velar KP/GB, clicks C/Q/X, nasal vowels.
  3. Ship timings alongside the audio as a small JSON sidecar.
  4. At runtime, drive the Rive View Model `viseme` enum from those timings, and drive `jawOpen` from RMS.
- **Fallbacks:** Rhubarb Lip Sync (MIT) in phonetic mode, or RMS-only jaw. Azure TTS emits viseme events, but only for Azure-supported voices (sw, zu) **[verify viseme support for those locales]**.
- **Do not** map letters to visemes (the current `lip_sync_engine.dart` approach).

### 3.9 Content and curriculum bootstrapping

- **Allowed AI work:**
  - First-draft dialogues and stories, constrained to the approved lexicon.
  - Distractors with rationales.
  - Paraphrase variants.
  - Example sentences for an approved lexeme.
  - Item difficulty guesses.
  - Cultural-note drafts, which require citations.
  - Eval-set generation.
- **Tools:** Gemini 3.1 Pro for drafts, plus a second model (GPT-5 or Claude) as a cross-check that flags disagreements. Spitch diacritics restoration ($1/10k words) handles tone-mark QA in Yoruba. A diacritic validator in CI completes the set.
- Every AI-assisted string is tagged `ai_assisted: true` and **cannot publish without two native approvals** (elevation plan §6.6). See §7 for the full matrix of what AI may bootstrap and what must be native-validated.

### 3.10 Lesson images

- **Primary:** Imagen 4 on Vertex AI: $0.04/image standard, $0.02 Fast, $0.06 Ultra. Google's generative-AI indemnity covers Imagen through the Vertex/Agent Platform API.
- **Fallback:** FLUX.1 [schnell] (Apache-2.0) self-hosted.
- **Excluded:** FLUX.1/FLUX.2 [dev] weights (non-commercial). FLUX.2 through BFL's paid API includes commercial rights.
- **Rules:** generate offline, review every image for cultural accuracy (dress, setting, skin tones, no stereotypes), and store alt text. Never generate images of real historical people without a historian's review and a "depiction" label.

### 3.11 Moderation and child safety (text, image, voice)

- **Text and images:**
  1. Layer 1: **OpenAI omni-moderation**, free. It handles text and images, was tested across 40 languages, and posted big gains on low-resource languages such as Swati. African coverage beyond that is unpublished, so evaluate it.
  2. Layer 2: a **Gemini Flash-Lite classifier** prompted with your policy, plus native-curated, word-boundary-aware lexicons per language. This fixes the `ode`/"code" substring problem.
  3. Layer 3, an open option: **Qwen3Guard** (Apache-2.0, 119 languages) self-hosted **[verify African-language coverage]**.
  4. **Do not adopt Perspective API.** It shuts down on 31 Dec 2026 and stopped accepting new usage in Feb 2026.
  5. Llama Guard 4 supports only 8 languages (English plus 7 European and Asian languages), so it is not useful for African-language text.
- **CSAM:** **PhotoDNA Cloud** (free for vetted organisations; apply now). **Thorn Safer Match** is the paid alternative (AWS Marketplace lists $30,720/yr for 1M queries per month). Google CSAI Match covers video for qualifying partners. Hash-match **every** image and video upload before delivery, and report to NCMEC or the relevant national authority as the law requires **[verify Nigerian reporting obligations with counsel]**.
- **Voice:** voice notes go through ASR (Intron), then the text pipeline. Under-18s get no recorded calls, no voice DMs outside approved circles, and no stored audio by default.
- **Primary:** omni-moderation + Gemini classifier + lexicons + PhotoDNA. **Fallback:** Qwen3Guard + Safer.

### 3.12 Embeddings and RAG (persona grounding, search, dictionary)

- **Options:**
  - Gemini embedding-001: 100+ languages, $0.15/M tokens.
  - Cohere embed-v4: 100+ languages, $0.12/M, text and images.
  - BGE-M3: MIT, self-host, 8k context.
  - Qwen3-Embedding: Apache-2.0, 32k context.
- **Primary:** Gemini embedding-001, which keeps one vendor and one DPA. **Fallback:** BGE-M3 self-hosted.
- Evaluate retrieval with target-language queries against English sources. Add a **lexical (BM25) leg** for names and diacritic variants, and normalise NFC on both sides.

### 3.13 OCR

- **Use for:** digitising archival sources for personas, community-contributed texts and printed primers (with permission), and "snap a sign" learner features.
- **Primary:** Google Cloud Vision (lists yo, ha, sw, zu). **Second pass:** Gemini vision, prompted to preserve diacritics. **Open fallback:** Tesseract (Apache-2.0; `yor`, `swa`; no Hausa model listed).
- Validate diacritic accuracy on a sample per language before relying on it.

---

## 4. Long-tail strategy: which options unlock "as many languages as possible"

| Capability | Breadth leader (commercial) | Rough African reach | How LingAfriq uses it |
|---|---|---|---|
| ASR | **Omnilingual ASR** (Apache-2.0) | Hundreds of African languages within 1,600+ **[count unverified]** | Default ASR and aligner for any language beyond Intron's list; fine-tune with a few hours of your own data per language (the paper reports adaptation from few examples) |
| ASR (managed) | **Intron** | ≈28 in docs, 63 total advertised | Default for every language Intron covers |
| MT | **MADLAD-400** (Apache-2.0), **Google Cloud Translation** | ≈30+ (MADLAD), ≈40+ (Google) **[verify]** | Glosses and drafts; native review required |
| LLM | **Gemini / frontier APIs** | Any language with web text, quality highly variable | Drafting and tutoring after per-language evals; lexicon-constrained |
| TTS | **None broad enough commercially** (Intron 12, Spitch ~5, Azure ~5) | Small | **Train your own voices** from commissioned recordings (§3.5). This is the bottleneck for scaling, so budget for it |
| Realtime | **Gemini Live** | 13 | Native audio where listed, cascade elsewhere |
| Tone scoring | **In-house** (Omnilingual + pitch) | Any language with native reference audio | Scales with your recorded reference library |

**Implication:** text-side breadth (LLM, MT) is cheap and fast to unlock, and ASR breadth is now unlocked by Omnilingual ASR. The constraints on reaching dozens of languages are **(1) native reviewers, (2) recorded reference audio and (3) TTS voices**. The elevation plan's scaling pipeline (§6.4–6.6) is built around exactly these three.

---

## 5. Data privacy and NDPA/GDPR notes per vendor class

- **Contracts:** sign a DPA and standard contractual clauses (or NDPA-compliant transfer terms) with every vendor that receives user data, including Google, OpenAI, Intron, Spitch, Microsoft and Lelapa. Record each in the data map (elevation plan §13.2). Under NDPA 2023, cross-border transfers need an adequacy basis or appropriate safeguards **[verify current NDPC guidance with counsel]**.
- **Voice:** treat recordings as sensitive. Process transiently, store only on opt-in, and give voice contributions for model training a **separate** consent, with payment or benefit-sharing.
- **Minors:** route minors' AI traffic through stricter policies, keep no persistent personal memory, and never use their data for training or for vendor improvement programmes.
- **Free tiers:** never send user data through a free tier that permits training (for example, the Gemini API free tier or AI Studio).
- **Residency:** prefer EU regions for EU users. Ask Intron, Spitch and Lelapa where they process and store data **[verify]**.

---

## 6. Licence register (start here; keep it in the repo)

| Component | Licence | Commercial? | Conditions |
|---|---|---|---|
| Omnilingual ASR models and code | Apache-2.0 | Yes | Keep the NOTICE file; corpus CC-BY-4.0 needs attribution |
| MADLAD-400 MT | Apache-2.0 | Yes | "Research model" disclaimer; evaluate first |
| Gemma 3 / TranslateGemma / AfriqueGemma | Gemma Terms of Use (+ CC-BY-4.0 for AfriqueGemma) | Yes | Prohibited-use policy; pass terms downstream; NOTICE file |
| Qwen3 / Qwen3Guard / Qwen3-Embedding | Apache-2.0 | Yes | – |
| Llama 4 | Llama 4 Community Licence | Yes (< 700M MAU) | Attribution, acceptable-use policy |
| BGE-M3 | MIT | Yes | – |
| FLUX.1 [schnell] | Apache-2.0 | Yes | – |
| Rhubarb Lip Sync, Montreal Forced Aligner | MIT | Yes | MFA's out-of-the-box models are mostly non-African |
| librosa (pYIN) / torchcrepe | ISC / MIT | Yes | – |
| Praat / Parselmouth | GPL-3 | Server-side only | Don't distribute in the app |
| 9jaLingo TTS-2 | Package code Apache-2.0; weights **[verify]** | Unknown | Check the model card before use |
| **MMS-TTS, NLLB** | CC-BY-NC 4.0 | **No** | Remove |
| **XTTS-v2** | Coqui Public Model Licence | **No** | Remove |
| **YarnGPT** | CC-BY-NC-SA 4.0 | **No** | Don't adopt |
| **N-ATLaS** (LLM + ASR) | Awarri ORIL | **No** above 1,000 active users/30 days | Commercial licence from Awarri/NCAIR needed |
| **Aya models** | CC-BY-NC | **No** (self-host) | – |
| **FLUX [dev]** weights | Non-commercial | **No** | Use the paid API or schnell |

---

## 7. Fast-scaling to many languages: what AI can bootstrap vs what natives must validate

| Asset | AI may bootstrap | Native validation required before learners see it | Notes |
|---|---|---|---|
| Frequency word list | Yes (from licensed corpora, MADLAD text, web) | **Yes**: one native + linguist | Remove loans and offensive senses; mark dialect |
| Lexeme glosses and example sentences | Yes (LLM + MT) | **Yes**: two natives | Tone marks checked by natives, not by a model |
| Tone marks and diacritics | Yes as a *suggestion* (Spitch for yo; LLM elsewhere) | **Always** | The highest-risk asset; a wrong mark teaches the wrong word |
| Grammar explanations (in English or French) | Yes (LLM grounded on linguist notes) | **Yes**: linguist | |
| Dialogues and stories | Yes (lexicon-constrained LLM) | **Yes**: two natives, naturalness and register | |
| Distractors and item variants | Yes | Spot-check 20% + item statistics after pilot | Bad distractors surface quickly in data |
| Cultural notes | Draft only, with citations | **Yes**: cultural reviewer | Never publish uncited claims |
| Curriculum audio | **No** (human recordings) | Recorded by natives; QA listen-through | TTS only for dynamic content |
| Dynamic TTS voice | Vendor or custom model | Blind listening test per voice (MOS ≥ 4 target) | |
| ASR for scoring | Omnilingual / vendor | Calibration set rated by natives | |
| Tone-scoring thresholds | No | **Yes**: native judges, κ reported | |
| Persona dossiers | AI summarisation of sources | **Yes**: historian | |
| UI translation | MT/LLM draft | **Yes**: native, in context | |

**Language readiness levels** (used by the elevation plan's waves):
- **L0 "Taste":** greetings, numbers, 50 words. Native-recorded audio and AI-drafted, native-approved text. Can ship within weeks per language.
- **L1 "Starter":** A1 with real audio and ASR feedback.
- **L2 "Core":** A1–A2 with tone scoring and TTS.
- **L3 "Full":** A1–B1, realtime voice and personas.

---

## 8. Evals per language (the deciding test)

- **Per language × task test sets:**
  - ASR: 300+ utterances across ages, genders, dialects and noise.
  - TTS: 50 sentences for blind MOS and tone-error rate.
  - MT: 300 sentence pairs.
  - LLM tutor: 300 prompts covering explanations, corrections and refusals.
  - Moderation: 500 labelled messages including code-switching.
  - Tone scoring: 200 learner clips with native judgements.
- **Metrics:**
  - ASR: WER and CER, plus *diacritic error rate*.
  - TTS: MOS and tone-error rate (native rated).
  - MT: chrF++/COMET plus native adequacy and fluency.
  - LLM: native-rated correctness, diacritic completeness, out-of-level vocabulary rate, factuality, refusal correctness.
  - Moderation: precision and recall per category.
  - Scoring: κ with native judges.
- **Process:**
  - Run on every model or prompt change in CI (gateway eval harness).
  - Block deploys on regression.
  - Re-run quarterly against new vendor releases.
  - Publish an internal scorecard per language.
- **Reviewers:** a paid panel of ≥3 natives per language, rotated, with inter-rater agreement tracked.

---

## 9. Integration plan

### 9.1 Architecture (in `node-backend`)

```text
Flutter app ──HTTPS/WSS (user JWT only)──► AI Gateway (node-backend module, later its own service)
                                             ├─ AuthN/Z, age tier, plan tier, per-user & per-feature quotas
                                             ├─ Router: (task, language, tier, latency budget) → provider/model
                                             │     config in DB/flags, hot-swappable, A/B-able
                                             ├─ Providers (server-side keys in a secrets manager):
                                             │     gemini (Vertex), openai, intron, spitch, azure-speech,
                                             │     google-stt/tts/translate/vision, lelapa, elevenlabs,
                                             │     self-hosted GPU pool (Omnilingual ASR+aligner, scorer,
                                             │     MADLAD, custom TTS voices, BGE-M3)
                                             ├─ Prompt registry (versioned, server-owned system prompts)
                                             ├─ Safety: input/output moderation, PII scrub, minors policy
                                             ├─ Cache: Redis + object storage
                                             │     • TTS by hash(NFC text, voice, speed) → Opus file on CDN
                                             │     • MT/gloss by hash(text, pair, model version)
                                             │     • embeddings by content hash
                                             ├─ Streaming: SSE for text, WebSocket/WebRTC for voice
                                             │     (Gemini Live via ephemeral tokens minted here)
                                             ├─ Fallbacks: per-provider circuit breakers, timeouts, retry budget;
                                             │     honest error to client when all fail (no fake output)
                                             ├─ Cost control: token/second metering per user, daily caps per tier,
                                             │     model downgrade under budget pressure, batch API for offline jobs
                                             ├─ Observability: OpenTelemetry spans, cost per feature, fallback rate,
                                             │     latency p50/p95 per provider × language
                                             └─ Eval harness: CI job runs §8 suites against router config
```

- **Replace:**
  - every client-side Groq, HF, Stability, Replicate and Leonardo call (elevation plan P0-3);
  - `aiCompletion.controller.ts`'s open proxy (P0-9);
  - `utils/ttsRouting.ts` priorities (MMS and XTTS out);
  - `freeGoogleTranslate.service.ts`;
  - the Whisper default in `voice.route.ts`.
- **Consolidate:** `aiServiceFallback.ts`, `hybrid_polie_orchestrator.dart` and the per-screen model strings into the router config.
- **Key handling:** keys live in a secrets manager (GCP Secret Manager or Doppler) and are injected at runtime. Rotate them quarterly, and run gitleaks in CI.
- **Client contract:** one typed endpoint per task (`/ai/tutor`, `/ai/translate`, `/speech/transcribe`, `/speech/synthesize`, `/speech/score`, `/ai/realtime/session`), generated into Dart from OpenAPI.

### 9.2 Phased rollout

| Phase | Weeks | Deliverables |
|---|---|---|
| **0. Stop the bleeding** | 1–2 | Revoke leaked keys. Gateway skeleton with Gemini Flash. Remove client keys. Disable MMS/XTTS/NLLB/scraper (fall back to Intron/Spitch/Google). Wire the app's STT to Intron |
| **1. Stage-1 speech** | 3–8 | Intron contract and DPA. TTS router (Intron, Spitch, Azure zu). TTS cache plus CDN. Omnilingual ASR GPU service plus aligner. ASR and TTS eval sets for all 7. Commission isiXhosa (and optionally isiZulu) voice recordings |
| **2. Scoring and avatars** | 6–14 | Tone and pronunciation scorer v1 for yo, ig, ha (then the others). Calibration with native judges. Viseme sidecar generation for the avatar pipeline. Custom isiXhosa voice v1 |
| **3. Realtime and personas** | 10–18 | Gemini Live for sw, yo, ha, zu. Cascade for ig, pcm, xh. Persona RAG with Gemini embeddings. Persona eval suite. Moderation layers 1–2 and PhotoDNA |
| **4. Breadth** | 16+ | Wave-2 languages through Omnilingual ASR + MADLAD + LLM drafting + native review. Train custom TTS voices for each new language. Monthly vendor re-benchmarks |

---

## 10. Rough monthly AI cost (illustrative; assumptions labelled)

**Assumptions per monthly active user (MAU):** 8 sessions/month; 60 AI text turns (≈600 input tokens with caching, 200 output); 80 scored speech attempts × 4 s (≈5.3 min ASR); 40 dynamic TTS utterances × 80 characters (3,200 characters, ≈3.5 min audio), with **50% cache hits**; 20% of users do 10 min/month of realtime voice. Curriculum audio is pre-recorded (no per-user TTS). Images are generated offline. Moderation uses the free OpenAI endpoint. Vendor prices are the public list prices above. **Intron is unpriced, so ASR is modelled at Google/Spitch list rates [verify].** Prices are list rates, not negotiated, and exclude tax.

| Line item | Per-MAU estimate | 10k MAU | 100k MAU | Basis |
|---|---|---|---|---|
| LLM (Gemini 3 Flash + Flash-Lite mix) | ≈$0.04–0.06 | $400–600 | $4k–6k | 36k in × $0.50/M + 12k out × $3/M ≈ $0.054; Lite routing lowers it |
| ASR (scoring + chat) | ≈$0.09–0.13 | $900–1.3k | $5k–9k | 5.3 min × $0.016 (Google) to $0.025 (Spitch); at 100k, self-hosting Omnilingual for scoring cuts this |
| TTS (dynamic, after cache) | ≈$0.05–0.15 | $500–1.5k | $4k–12k | 1,600 billable characters at Azure $16/M = $0.026, up to Spitch ≈$0.15 for 105 s |
| Realtime voice (20% of users × 10 min) | ≈$0.05 | ≈$500 | ≈$5k | Gemini Live ≈$0.25 per 10-min session including context re-billing **[estimate]** |
| GPU pool (Omnilingual ASR/aligner, scorer, MADLAD, custom TTS) | fixed | ≈$600–1k (1–2 L4-class GPUs) | ≈$3k–5k (4–6 GPUs) | Cloud GPU list prices **[verify provider]** |
| Embeddings, moderation, images, OCR | small | ≈$100–200 | ≈$500–1k | Embeddings $0.15/M; omni-moderation free; Imagen as content is produced |
| Gateway infra (Redis, CDN egress, logs) | fixed | ≈$200–400 | ≈$1.5k–3k | |
| **Total AI and infra** | | **≈$3.2k–5.5k / month** | **≈$23k–41k / month** | |

**Not included (budget separately):**
- Native reviewers and voice talent, the real cost of quality. As an illustration, 3 reviewers × 7 languages × part-time is a material monthly line; get local quotes.
- Thorn Safer, if used instead of PhotoDNA.
- Intron contract minimums.
- Custom-voice production (studio, actor buy-out).

**Controls that keep spend inside these ranges:**
- Hard daily caps per user by plan tier.
- Free tier limited to Flash-Lite and cached TTS.
- Realtime minutes as a premium feature.
- Batch APIs (50% off) for offline generation.
- Prompt caching.
- An alert when spend per DAU exceeds a threshold.

---

## 11. Unverified items to close before contracts

1. Intron pricing, DPA, data residency, the `/tts/v1/generate` vs `/enqueue` endpoint, and streaming endpoint docs.
2. Omnilingual ASR per-language CER for the seven Stage-1 languages (repo CSV) and the exact codes for Pidgin and Xhosa.
3. Spitch support for Swahili TTS and ASR and for Pidgin ASR; custom voice support for isiXhosa or isiZulu.
4. The 9jaLingo TTS-2 weights licence.
5. Whether Google Cloud Translation lists Nigerian Pidgin, and the exact count of African languages in the Cloud API.
6. African-language coverage of Qwen3Guard and of OpenAI omni-moderation beyond the published 40.
7. OpenAI realtime language quality for African languages.
8. The DataLens Africa leaderboard methodology (third-party; not peer-reviewed).
9. Azure viseme support for `sw-KE` and `zu-ZA`; Azure TTS coverage for af, am, so.
10. NDPC cross-border transfer requirements and data-controller registration thresholds (counsel).
11. Cloud GPU prices for your chosen provider and region.

---

## 12. Sources (checked 17 Oct 2026)

- Intron: [Sahara v2.5 site](https://www.intron.io/) · [STT supported languages](https://docs.voice.intron.io/docs/stt/supported-languages) · [TTS languages and accents](https://docs.voice.intron.io/docs/tts/supported-languages-and-accents) · [TTS enqueue API](https://docs.voice.intron.io/docs/tts/tts-queue) · [TechAfrica, 27 Aug 2026](https://techafricanews.com/2026/08/27/intron-voice-ai-launches-sahara-v25-63-african-languages/)
- Spitch: [Pricing](https://docs.spitch.app/concepts/pricing) · [Speech generation](https://docs.spitch.app/features/speech) · [Transcription](https://docs.spitch.app/features/transcription) · [Voices](https://docs.spitch.app/concepts/voices) · [Usage tiers](https://docs.spitch.app/concepts/usage-limits)
- Meta Omnilingual ASR: [GitHub](https://github.com/facebookresearch/omnilingual-asr/) · [LICENSE (Apache-2.0)](https://github.com/facebookresearch/omnilingual-asr/blob/main/LICENSE) · [Model card](https://huggingface.co/facebook/omniASR-LLM-300M/blob/main/README.md) · [Meta blog](https://ai.meta.com/blog/omnilingual-asr-advancing-automatic-speech-recognition/)
- N-ATLaS: [Model card and terms](https://huggingface.co/NCAIR1/N-ATLaS) · [Licensing summary](https://natlas-docs.vercel.app/licensing)
- Google: [Chirp 3 STT](https://docs.cloud.google.com/speech-to-text/docs/models/chirp-3) · [STT v2 languages](https://docs.cloud.google.com/speech-to-text/docs/speech-to-text-supported-languages) · [STT pricing](https://cloud.google.com/speech-to-text/pricing) · [Chirp 3 HD TTS](https://docs.cloud.google.com/text-to-speech/docs/chirp3-hd) · [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing) · [Live API capabilities and languages](https://ai.google.dev/gemini-api/docs/live-api/capabilities) · [Gemini TTS](https://ai.google.dev/gemini-api/docs/speech-generation) · [Gemini API terms](https://ai.google.dev/gemini-api/terms) · [Zero data retention](https://ai.google.dev/gemini-api/docs/zdr) · [Translate 110 languages (2024)](https://blog.google/products-and-platforms/products/translate/google-translate-new-languages-2024/) · [TranslateGemma](https://blog.google/innovation-and-ai/technology/developers-tools/translategemma/) · [Gemma terms](https://ai.google.dev/gemma/terms) · [Vertex pricing (Imagen)](https://cloud.google.com/vertex-ai/generative-ai/pricing) · [Indemnified services](https://cloud.google.com/terms/generative-ai-indemnified-services) · [Vision OCR languages](https://docs.cloud.google.com/vision/docs/languages) · [MADLAD-400-10B card](https://huggingface.co/google/madlad400-10b-mt/blob/main/README.md)
- Microsoft: [Azure Speech language support (TTS)](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts) · [Pronunciation assessment locales](https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/ai-services/speech-service/includes/language-support/pronunciation-assessment.md) · [Azure Speech pricing](https://azure.microsoft.com/en-us/pricing/details/speech/) · [Translator language support](https://learn.microsoft.com/en-us/azure/ai-services/translator/language-support) · [PhotoDNA](https://www.microsoft.com/en-us/photodna)
- ElevenLabs: [Scribe v2 languages and WER](https://elevenlabs.io/docs/overview/capabilities/speech-to-text) · [Supported languages (TTS)](https://help.elevenlabs.io/hc/en-us/articles/13313366263441-What-languages-do-you-support) · [API pricing](https://elevenlabs.io/pricing/api)
- OpenAI: [API pricing](https://developers.openai.com/api/docs/pricing) · [Moderation upgrade](https://openai.com/index/upgrading-the-moderation-api-with-our-new-multimodal-moderation-model/)
- Lelapa AI: [Vulavula language support](https://docs.lelapa.ai/overview/language-support) · [Plans](https://docs.lelapa.ai/overview/plans)
- Open models: [AfriqueGemma-12B](https://huggingface.co/McGill-NLP/AfriqueGemma-12B) · [Qwen3](https://github.com/QwenLM/Qwen3/) · [Qwen3Guard report](https://arxiv.org/html/2510.14276) · [Llama Guard 4](https://huggingface.co/meta-llama/Llama-Guard-4-12B) · [Llama 4 licence](https://github.com/meta-llama/llama-models/blob/main/models/llama4/LICENSE) · [FLUX.1 schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell) · [FLUX non-commercial licence](https://bfl.ai/legal/non-commercial-license-terms) · [9jaLingo TTS-2 (PyPI)](https://pypi.org/project/naijalingo-tts/) · [YarnGPT card](https://huggingface.co/saheedniyi/YarnGPT-local) · [Rhubarb Lip Sync](https://github.com/DanielSWolf/rhubarb-lip-sync) · [Montreal Forced Aligner](https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner)
- Benchmarks: [AfroBench paper (ACL Findings 2025)](https://aclanthology.org/2025.findings-acl.976.pdf) · [AfroBench leaderboard](https://mcgill-nlp.github.io/AfroBench/leaderboard.html) · [DataLens Africa LLM leaderboard (third-party)](https://datalens.africa/llm-leaderboard) · [Nigerian speech benchmark](https://doi.org/10.31224/6650)
- Other: [Perspective API sunset](https://www.perspectiveapi.com/) · [Thorn Safer Match (AWS Marketplace)](https://aws.amazon.com/marketplace/pp/prodview-dfwekn4bx4ake) · [Groq deprecations](https://console.groq.com/docs/deprecations)
