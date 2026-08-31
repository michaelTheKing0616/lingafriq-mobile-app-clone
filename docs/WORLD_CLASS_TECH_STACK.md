# World-class tech stack per LingAfriq feature

One **primary** technology per job. Not one vendor for the whole app.
Companion to [Intron integration](INTRON_INTEGRATION.md). This is a
recommendation, not an implementation.

**Rule:** pick the specialist that wins the *linguistic* job. Duolingo-class
UX on top of English-centric ASR/TTS/LLM is not world-class for Yoruba, Igbo,
or Pidgin.

Legend: **Keep** = already the right choice. **Upgrade** = same job, better
engine. **Add** = missing. **Avoid** = looks premium, wrong for African langs.

---

## 1. Stack at a glance

| Job | World-class pick | In the app today | Verdict |
|---|---|---|---|
| Live conversational STT | **Intron Sahara streaming** | On-device `speech_to_text` | **Add** |
| Clip / learner STT | **Intron file sync** (LLM corrections **off**) | Groq Whisper + `/api/voice/stt/transcribe` | **Upgrade** |
| Isolated-word / phoneme score | **faster-Whisper + MFA** + language lexicons | Whisper sidecar + MFA (partially wired) | **Keep + wire** |
| Tone / pitch | **Custom F0 sidecar** (CREPE/WORLD) + phonological rules | Tone trainer API `:5053` | **Keep + harden** |
| Lesson / vocab TTS | **Native CDN gold + Meta MMS-TTS** | `AfricanTtsService` Gold → Silver MMS | **Keep** |
| Pidgin / CS TTS | **Intron TTS** (after bake-off) | MMS English + disclaimer | **Add later** |
| Written translation | **Self-hosted NLLB-200 3.3B** + LLM register post-edit | NLLB distilled-600M via HF + backend | **Upgrade model size** |
| Canonical / proverb phrasing | **AfriTeVa v2** | `CanonicalPhraseService` | **Keep** |
| Orthography | **NFC + `DiacriticsEnforcer` + dictionary** | Enforcer exists (small maps) | **Keep + grow data** |
| Conversation pedagogy (English plan) | **Groq Llama 3.3 70B** (latency) + optional Claude/Gemini teacher | Groq Llama, client key | **Keep model, move key to Node** |
| Target-language utterance | **NLLB 3.3B**, not raw Llama | Hybrid Polie routes some modes to NLLB | **Enforce for all target-lang strings** |
| Grammar of African text | **LLM + NLLB verify + dictionary**, not LanguageTool | Groq JSON grammar prompt | **Keep pattern, stop trusting Llama diacritics** |
| SRS | **FSRS-5** | SM-2 in 4+ services | **Upgrade** |
| Adaptive skill | **Elo/BKT on a skill graph** | `LearnerModelService` + ML curriculum stub | **Keep shape, upgrade math** |
| Live A/V | **LiveKit** | `livekit_client` 2.3 | **Keep** |
| Live translate pipeline | **Intron STT → NLLB → MMS** (Socket.IO) | On-device STT → Socket.IO → MT + TTS | **Upgrade STT only** |
| Chat / tribes / WA-like | **Existing Socket.IO** + correction overlay | Custom chat screens | **Keep transport; invest in pedagogy overlay** |
| IAP | **RevenueCat** | `purchases_flutter` | **Keep** |
| Auth | **JWT + refresh + biometrics**; passkeys next | Djoser-style JWT + `local_auth` | **Keep; add passkeys later** |
| Push | **FCM** | `firebase_messaging` | **Keep** |
| Errors | **Sentry** | `sentry_flutter` | **Keep** |
| Product analytics | **PostHog** (or Mixpanel — token already in secrets) | First-party `/api/telemetry` | **Add** beside first-party |
| Offline | **Hive outbox now**; Drift/SQLite when sync complexity bites | Hive + `PersistedOutboxService` | **Keep for now** |
| Avatars | **Rive** | `rive` | **Keep** |
| 2D games | **Flame + Flutter** | Flame + custom screens | **Keep** |
| OCR / Point and Say | **ML Kit** on-device; Cloud Vision fallback (Amharic) | ML Kit text + objects | **Keep** |
| Moderation (UGC/chat) | **Human native review + LLM assist** | Staff report screens | **Keep humans in the loop** |

---

## 2. Voice

### 2.1 Polie / Ling Chat mic (conversation, roleplay, speak-your-line)

**Use: Intron Sahara streaming STT.**

Only production recognizer with Yo/Ha/Ig/Pidgin **code-switch** models. Apple/
Google on-device locales for those languages are empty; Pidgin is currently
forced to `en-NG`.

Insert behind `PolieVoiceInputService` (keep `PolieVoiceTranscript`). Details:
[INTRON_INTEGRATION.md](INTRON_INTEGRATION.md).

**Avoid:** Groq Whisper as the live mic, Google Chirp 3 (no Igbo/Twi/Pidgin),
SpeechAce/ELSA (English), Deepgram Nova (not African-first).

### 2.2 Live Translate (speech → translation → voice)

**Use: Intron STT → NLLB-200 3.3B → MMS-TTS**, existing Socket.IO session.

Do **not** collapse this into Meta SeamlessM4T / Translatotron as the primary
path. Speech-to-speech models are weaker on Pidgin/Igbo and you lose a
caption you can correct. SeamlessM4T can be a **latency A/B** later, not the
source of truth.

Keep `LiveTranslateRealtimeClient`. Replace only the recognizer.

### 2.3 Tutor translation mic

Same as 2.1: **Intron streaming**. Delete the screen-local `SpeechToText` map.

### 2.4 Speak Mission (10–30s scenario reply)

**Use: Intron file STT** (`use_disable_llm_corrections=TRUE`) + **existing LLM rubric**.

The product is “was the intent/register right?”, not phonemes. Groq Whisper
from `ai_chat_provider_groq.transcribeAudio` is the wrong African engine.

### 2.5 Shadowing

**Use: Intron file STT** for the transcript + **in-app WER** vs reference.

Not MFA unless you add a “sounds like” mode. Disable Intron LLM cleanup so
learner errors survive.

### 2.6 Pronunciation practice, tutor pronunciation, AR pass/fail

**Use: 16 kHz wav (`record`) → faster-Whisper (self-hosted) → Montreal Forced
Aligner → DTW heatmap** (`PronunciationPipeline` already does DTW).

This is the SpeechAce-class architecture, with **African lexicons** instead of
CMUdict-English. World-class here is alignment quality, not a chat STT vendor.

**Keep:** `/api/v2/asr/score`, `/api/pronunciation/advanced/analyze`,
`AsrPronunciationScorer` (wire duel/karaoke here — they are still simulated).

**Avoid:** Intron, Groq confidence-as-score, Google pronunciation API.

### 2.7 Tone / rhythm / Tone Forge / drum games

**Use: dedicated F0 tracker** (CREPE or WORLD) + language tone rules (Yoruba
H/M/L is phonological, not “pitch pretty”).

**Keep** the tone sidecar and `ToneRhythmTrainerScreen` queue. Do not ask STT
for tone.

### 2.8 Lesson, vocab, games, traditional-board “play this word”

**Use: `AfricanTtsService` as-is.**

Gold native MP3 on CDN is the actual world-class tier (better than any neural
TTS). Silver **Meta MMS-TTS** is still the widest African coverage. Bronze
XTTS for cloned contributor voices.

**Avoid:** `flutter_tts` on-network (English system voice speaking Yoruba).
ElevenLabs / PlayHT as default (coverage + accent). Intron TTS as default
until every hub language is verified.

### 2.9 Polie read-aloud of replies

**Use: AfricanTtsService now.** **Add Intron TTS** only for Pidgin and
verified CS replies after an A/B. Pidgin is the one real TTS hole (MMS `eng`).

### 2.10 Native / voice contribution

**Use: raw WAV upload** (gold data). Optional **Intron file STT** as QA
(prompt WER), never as a replacement file.

World-class dictionaries are built from **humans**, then used as Gold TTS.

### 2.11 Passport / proctored speaking

**Use: upload + human/staff review.** MFA as a **reviewer aid**. Intron
transcript in the reviewer UI only.

Auto-pass from conversational STT is an integrity bug.

### 2.12 Classroom / social audio / practice room

**Use: LiveKit** (already on `lingafriq.livekit.cloud`).

World-class realtime media is an SFU, not an STT vendor. Optional later:
LiveKit Agents + Intron for **captions**; Krisp/LiveKit noise suppression;
LiveKit Egress for mentor recordings.

**Avoid:** replacing LiveKit with Daily/Agora unless ops force it. Same job,
migration cost with no language win.

### 2.13 Offline voice

**Use: Gold TTS disk cache + `speech_to_text` + `flutter_tts`.** Intron is
cloud. Show the same degraded-mode copy as MMS-down.

---

## 3. Language AI (text)

Hybrid Polie is the **right architecture**. World-class is enforcing it, not
replacing it with a single GPT.

```
User text/speech
  → Llama/Claude: pedagogy, hints, roleplay plan (often English)
  → NLLB-200 3.3B: actual target-language string
  → AfriTeVa: canonical / proverb / “how a native would say it”
  → DiacriticsEnforcer + dictionary: orthography
  → AfricanTtsService: speak it
```

Llama 3.3 70B is fast and cheap. It is **not** a native Yoruba writer. Raw
Llama output with missing tone marks is the main quality leak today.

### 3.1 Translation (Polie translate, tutor translation, live translate MT)

**Use: self-hosted `facebook/nllb-200-3.3B`** (not the 600M distilled model
on Hugging Face serverless). FLORES codes including `pcm_Latn` — you already
generate that list.

Optional **LLM post-edit** for register (market vs elder) *after* NLLB, then
diacritics pass.

**A/B only:** Google Cloud Translation for Swahili / Afrikaans / French
(high-resource). Do not make Google the default for Yo/Ig/Ha/Pidgin.

**Avoid:** ChatGPT as the translator of record (invented diacritics, code-switch
collapse). AfriTeVa as a general MT (wrong job).

### 3.2 Canonical phrases, proverbs, “say it properly”

**Use: AfriTeVa v2** (`castorini/afriteva_v2_large`) via Node, which you
already call from `CanonicalPhraseService`. **Keep.**

### 3.3 Conversation, roleplay, tutor dialogue, Ling Chat

**Use: Groq `llama-3.3-70b-versatile`** for the interactive loop (you already
have streaming + two-pass persona cognition).

**Upgrade:**

1. Proxy Groq from **Node** (stop shipping the key in `--dart-define`).
2. Every `message_target` goes through **NLLB + diacritics**, not raw Llama.
3. Optional **Gemini or Claude** as a slow teacher pass for long grammar
   explanations / historical personas (router already has a `ModelType.gemini`
   slot).

**Avoid:** putting GPT-4 on every Polie tap (cost/latency). Fine-tuned
InkubaLM/AfroLlama as the *only* chat model until they have a production SLA.

### 3.4 Grammar (tutor grammar, UGC validation, shadowing grammar)

**Use: LLM JSON grammar check (keep) + NLLB/dictionary verify of `corrected`.**

LanguageTool / LanguageTool Premium / Grammarly do not cover Yoruba/Igbo
morphology. Do not add them as primary.

World-class output: error span + type (`tone_mark`, `agreement`, `word_order`)
feeding the learner model — not a vibe score.

### 3.5 Diacritics / orthography

**Use: grow `DiacriticsEnforcer`** (NFC + phrase map + fuzzy) from contribution
gold and curriculum. This is a **data** problem. No model replaces a
Yoruba tone dictionary.

### 3.6 Vocab explanations, flashcards, living dictionary

**Use: human dictionary rows + NLLB gloss + MMS audio.**

SRS: **FSRS-5** (Anki’s current algorithm, open) instead of SM-2 duplicated in
`vocabulary_service`, `vocabulary_progress_service`, `offline/vocabulary_store`,
`learning/spaced_repetition_service`. One implementation, all call sites.

Images: **curated CDN / contributor photos**. Not Stability SDXL of “African
market” (stereotype + wrong objects). ML Kit Point-and-Say photos are better
ground truth.

### 3.7 Stories, listening passages, quiz generation

**Use: Llama/Gemini to draft → native reviewer or UGC validation → NLLB for
target text → MMS for audio.**

Do not auto-publish LLM stories into curriculum. `ugc_validation_feedback_screen`
is the right gate; keep it.

### 3.8 Placement / CEFR / assess mode

**Use: IRT (2PL) item bank** + speaking sample scored by MFA (pron) + Intron+rubric
(Speak Mission). Static percent→CEFR (`_mapScoreToCEFR`) is not world-class.

Keep the placement screens; upgrade the **estimator**, not the UI.

### 3.9 Adaptive curriculum / “what’s next”

**Use: skill graph + BKT or Elo** in `LearnerModelService` (already records
attempts). Duolingo Birdbrain is this idea. Do not add a fifth SM-2 clone.

---

## 4. Comprehension, AR, media

| Feature | World-class pick | Notes |
|---|---|---|
| Listening quiz / practice | **Gold/MMS audio** + MCQ from reviewed items | TTS of an LLM passage is bronze; native clip is gold |
| Point and Say | **ML Kit** OCR + object detect → NLLB → MMS → **MFA score** | Cloud Vision fallback for Fidel/Amharic low confidence |
| Media import → lesson | **Intron file STT** (hub langs) → NLLB → FSRS items | Worker-side; app already POSTs `/media/:id/transcribe` |
| Whiteboard classroom | Keep current widget + LiveKit | Do not bolt STT onto the board |

---

## 5. Games

| Feature | World-class pick |
|---|---|
| Listen-and-pick pronunciation game | MMS/Gold TTS only (already) |
| Duel / karaoke / tongue twister (when real) | `AsrPronunciationScorer` + MFA, not Intron, not random 75–95 |
| Tone / drum / rhythm | F0 sidecar |
| Word match, fill-blank, grammar detective, speed, chef, taxi, etc. | Flutter + curriculum JSON. Flame only if you need a ticker/physics loop |
| Traditional (Ayo, Ludo, Whot, Suwe, Snakes) | Flutter + shared Socket.IO (`BoardGameSocketService` plan). MMS for square audio |
| Roleplay adventure / market bargaining | Polie stack (Intron mic + NLLB + Llama plan) |
| Avatars in games | **Rive** (keep). Lottie for one-shot celebration only |

Do not pull in Unity/Godot. The language loop is the product, not a 3D village.

---

## 6. Social, chat, “WA / Snap” surfaces

World-class for LingAfriq is **language overlay**, not beating WhatsApp.

| Feature | World-class pick |
|---|---|
| Global / tribe / private / community chat | **Keep Socket.IO**. Add: tap-to-NLLB, tap-to-MMS, community corrections |
| WA-like status | Keep custom; FCM for fan-out. Do not migrate to Stream/Sendbird unless delivery SLAs fail |
| Snap camera / streaks | Device camera + your backend. Pedagogy > filters |
| Social gifting / quests / ancestral tree | First-party backend. No extra ML |
| Leaderboards / tribes | First-party + Redis/Postgres. Keep |
| Micro-mentor | LiveKit session + optional Intron transcript for notes + human rating |
| Community corrections | Human votes (you have this) + AfriTeVa suggestion, not auto-overwrite |
| Magazine / history | CMS + CDN. Optional NLLB for reader language. Not an LLM magazine |

**Avoid:** Stream Chat / Sendbird / Twilio Conversations as a rewrite. They do
not know Yoruba corrections. Spend that money on Intron + NLLB 3.3B + native
audio.

---

## 7. Platform (every app that needs it)

These are not language features; they still have to be world-class or the
language stack will not ship.

| Feature | World-class pick | Today |
|---|---|---|
| Client | **Flutter** (keep). One codebase is the right call for Android-first Africa | Flutter 3.35 |
| State | **Riverpod** (keep) | hooks_riverpod 3 |
| API | **Dio + JWT refresh** (keep) | `dio_provider` |
| Auth | JWT + `flutter_secure_storage` + `local_auth`. Next: **passkeys** | Djoser JWT |
| Payments | **RevenueCat** + Play/App Store. Family entitlement already modeled | Keep |
| Push | **FCM** + `flutter_local_notifications` | Keep |
| Crash / ANR | **Sentry** | Keep |
| Product analytics | **PostHog** (self-host or EU cloud) or Mixpanel | First-party telemetry only — add a product tool |
| Offline lessons / SRS / outbox | Hive + Workmanager **until** you need relational queries → **Drift** | Hive is enough for outbox |
| Images | `cached_network_image` + CDN | Keep |
| Fonts | `google_fonts` + **bundled** Noto for Yoruba/Igbo/Amharic marks | Verify tone-mark coverage on-device |
| Search (dictionary) | Postgres trigram now; **Meilisearch/Typesense** if living dictionary scale hurts | Unknown at this client |
| Secrets | Node proxy for Groq, HF, Intron. **No third-party keys in the APK** | Groq/HF dart-defined — fix |
| Moderation | Reports UI (keep) + native-speaker queue. LLM flagger as assist only | Keep humans |
| Family / child accounts | RevenueCat family + first-party parental PIN | Family dashboard exists |

---

## 8. What not to buy

| Pitch | Why it loses here |
|---|---|
| One “best STT” for scoring and chat | Intron ≠ MFA. Inverse also true |
| ElevenLabs / PlayHT as default TTS | Gold natives + MMS cover more African langs authentically |
| GPT/Claude as the Yoruba speaker | Diacritics and CS; use them as the *teacher* |
| LanguageTool / Grammarly | English/European morphology |
| SpeechAce / ELSA / Google pronunciation | English phones |
| SeamlessM4T as Live Translate v1 | Weaker Yo/Ig/Pidgin; no editable caption |
| Stream/Sendbird chat rewrite | No language-learning overlay |
| Firebase Auth beside JWT | Second identity plane |
| Unity village | Cost, no WER win |
| Stability images for vocab | Cultural hallucination |
| On-device NLLB-200 full | 3.3B does not fit phones; distilled is a quality cut. Cache server translations instead |

---

## 9. Priority if we only do five upgrades

1. **Intron streaming** on Polie + Live Translate + tutor translation mics.
2. **NLLB-200 3.3B self-hosted**; force Hybrid Polie to run every target-language
   string through it + `DiacriticsEnforcer`.
3. **Wire `AsrPronunciationScorer` + MFA** to duel/karaoke/tutor; do not Intron.
4. **Move Groq/Intron/HF keys to Node.**
5. **FSRS-5** in one SRS module; delete duplicate SM-2 copies.

Those five move the product from “wide African demo” to “world-class on the
languages we actually teach.” Everything else in this doc is either already
correct (LiveKit, RevenueCat, MMS Gold, AfriTeVa, Rive, Sentry) or correctly
deferred (passkeys, Drift, classroom captions, Intron TTS).
