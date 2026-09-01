# Intron integration plan (LingAfriq)

Recommendation for **Sahara Voice AI / Intron** against the stack that is already
in this Flutter app. This is an architecture plan, not an implementation.

See also: [world-class tech stack per feature](WORLD_CLASS_TECH_STACK.md).

Related bake-off harness (PR #87): `tool/stt_bakeoff/`. Do not flip production
defaults until that probe has real WAVs.

Intron docs: [STT languages](https://docs.voice.intron.io/docs/stt/supported-languages),
[streaming STT](https://docs.voice.intron.io/docs/stt/streaming),
[file STT (sync)](https://docs.voice.intron.io/docs/stt/file-upload-sync),
[TTS languages](https://docs.voice.intron.io/docs/tts/supported-languages-and-accents).

---

## 1. What to use Intron for (and what not to)

Intron is a **cloud conversational STT** vendor with strong West/East African
**code-switch** models (Yoruba–English, Hausa–English, Igbo–English,
Pidgin–English, plus Swahili, Zulu, Wolof, Amharic, Afrikaans). Published
conversational WER is on the order of **~34%**. That is good enough to drive a
chat/roleplay mic. It is **not** good enough to score a single word against a
phoneme target.

| Job | Use | Why |
|---|---|---|
| Live conversational STT (mic → text while speaking) | **Intron streaming** `wss://infer.voice.intron.io/stt/v1/stream` | Only vendor with dedicated Yo/Ha/Ig/Pidgin CS models. On-device `speech_to_text` locales for these languages are empty or English-fallback on most phones. |
| Short utterance STT after record-stop (10–30 s clip) | **Intron file sync** `POST …/file/v1/upload/sync` | Same models, simpler than a WS client. Call with `use_disable_llm_corrections=TRUE` so the model does not “fix” learner errors. |
| Isolated-word / phoneme / tone scoring | **Keep Whisper sidecar + MFA + tone** | Intron has no phoneme aligner and CS WER ~34% will pass wrong words. Bake-off gate: isolated-word WER ≤ 15% before even considering a swap. |
| Lesson / vocab / game “play this word” audio | **Keep `AfricanTtsService`** (Gold CDN → Silver MMS `/api/tts` → Bronze XTTS) | Intron TTS covers a **narrower** set than Meta MMS. Do not assume it can replace playback for all 11 hub languages. |
| Polie read-aloud of AI replies | Keep `AfricanTtsService` now; **optional Intron TTS later** only for verified languages (especially Pidgin / CS replies) | Pidgin today falls back to MMS English + disclaimer. That is the one TTS gap Intron might close after an A/B. |
| Offline | Keep on-device `speech_to_text` + `flutter_tts` | Intron is cloud-only. |
| Native-speaker gold recordings | Keep file upload. Optional Intron **offline QA** (does the clip match the prompt?) | Do not transcribe-and-replace native audio. |
| Live classroom / social audio media plane | Keep LiveKit | Intron is not a media SFU. Captions would be a **new subscriber**, not a replacement. |

**Security:** never put `INTRON_API_KEY` in the APK or `--dart-define`. Proxy every
call through Node (`admin.lingafriq.com`), same pattern as MMS-TTS. Client holds
only the user’s Bearer token.

---

## 2. Current voice stack (how well placed we are)

### Overall

| Layer | Readiness | Score | Notes |
|---|---|---|---|
| TTS playback | Centralized, gated | **8 / 10** | `AfricanTtsService` + `tool/tts_purity_gate.dart` already own every lesson voice. Adding Intron TTS is a localized Silver-tier change **after** a language bake-off. |
| Live STT (mic → partial text) | Fragmented | **4 / 10** | Three independent `speech_to_text` clients, duplicated locale maps, no shared stream interface that a WebSocket can plug into except Polie’s `PolieVoiceTranscript` stream. |
| File STT (clip → transcript) | Fragmented | **4 / 10** | `VoiceApiService`, `EnhancedSTTService`, Groq Whisper in `ai_chat_provider_groq.dart`, and `/api/v2/asr/score` all exist. Screens pick at random. |
| Pronunciation / tone scoring | Dedicated, do not disturb | **7 / 10** | MFA + Whisper sidecar + `/api/pronunciation/advanced/analyze` + tone trainer. Ready to **leave alone**. `AsrPronunciationScorer` is written but **not wired** to any game screen. |
| Realtime transport | Partial | **6 / 10** | Live Translate already streams text over Socket.IO. LiveKit already carries classroom audio. Missing: an Intron WS client and a Node proxy. `web_socket_channel` is not a dependency yet. |
| Secrets / env | Pattern exists | **6 / 10** | `EnvConfig` dart-defines Groq / HF / MFA URL. Intron key must **not** follow that client-side pattern. |
| Language codes | Duplicated | **5 / 10** | Polie uses BCP-47 (`yo-NG`); Intron uses ISO (`yo`, `pcm`, `tw`). Bake-off JSON already has the Intron map. |
| Evaluation | Harness only | **6 / 10** | `tool/stt_bakeoff/probe.py` is stdlib-only and self-tests. No gold WAVs or API keys in-repo. |

We are **well placed to add Intron as a new live-STT backend** if we introduce
one service and swap three call sites. We are **poorly placed to spray Intron
into every mic button** — scoring, contribution, and LiveKit would regress.

### What already exists (do not invent a fourth STT path)

| Existing piece | Role today | Intron fit |
|---|---|---|
| `PolieVoiceInputService` | On-device `speech_to_text`; emits `PolieVoiceTranscript` (partial + final) | **Best insertion point.** Keep this public API; swap the engine. |
| `LiveTranslateScreen` | Own `SpeechToText` instance → Socket.IO → backend translate + TTS | Second insertion. Replace only the recognizer. |
| `TutorTranslationModeScreen` | Own `SpeechToText` + duplicated `_sttLocaleFor` | Third insertion. Delete the local locale map when the shared service lands. |
| `VoiceApiService.transcribeAudio*` | `POST /api/voice/stt/transcribe` | Point Node at Intron file-sync **or** keep as Whisper bronze. |
| `EnhancedSTTService` | Enhanced STT + fallback to basic | Dead-ish wrapper. Fold into the new service; do not grow it. |
| `EnhancedVoiceService` | Speculative Wav2Vec2 / ensemble comments | Do not revive. |
| Groq `transcribeAudio` / `shadowingExercise` | Direct Groq Whisper-large-v3 from the app | Replace Speak Mission + shadowing **transcript** with Intron file-sync via Node. Groq Whisper is general multilingual, weak on Pidgin/Igbo CS. |
| `AsrPronunciationScorer` → `/api/v2/asr/score` | Whisper sidecar for games | **Keep.** Not used by UI yet; wire games here, not to Intron. |
| `AfricanTtsService` | Gold/Silver/Bronze TTS | **Keep.** Optional Intron TTS experiment later. |
| LiveKit rooms | Classroom + practice + social audio | **Keep.** Optional caption tap later. |

---

## 3. Target shape (one STT resolver, mirror TTS)

Add `AfricanSttService` next to `AfricanTtsService`. Screens keep talking to
thin wrappers (`PolieVoiceInputService`, `VoiceApiService`).

```
Flutter
  AfricanSttService
    Gold    Intron streaming   (online conversational; Node WS proxy)
    Silver  Intron file sync   (record-then-transcribe; Node HTTP)
    Bronze  existing Whisper   POST /api/voice/stt/transcribe or /api/v2/asr/score
    Device  speech_to_text     offline / Intron outage / mic-permission fallback

  AfricanTtsService            unchanged (CDN → MMS → XTTS → flutter_tts)

Node (admin.lingafriq.com)
  WS  /api/stt/intron/stream   proxies to wss://infer.voice.intron.io/stt/v1/stream
  POST /api/stt/transcribe     Intron file/v1/upload/sync  (disable LLM corrections)
  existing /api/tts, /api/v2/asr/score, /api/pronunciation/*, tone sidecar
```

Language codes: one map, sourced from `tool/stt_bakeoff/eval_set.json`
`providers.intron.stt_codes` (hub slug → Intron `yo` / `pcm` / …).

Rollout order (only after bake-off `code_switch` pass on Yo/Ha/Ig/Pidgin):

1. Node proxy + `AfricanSttService` behind a feature flag.
2. Swap `PolieVoiceInputService` internals (same `transcripts` stream).
3. Live Translate recognizer.
4. Tutor translation mic.
5. Speak Mission + shadowing transcript (file sync).
6. Media-import backend transcribe for African-language clips.
7. Optional: contribution QA, classroom captions, Intron TTS A/B.

---

## 4. Per-feature matrix (every voice surface)

Hub languages that must work: Yoruba, Hausa, Igbo, Swahili, Zulu, Xhosa,
Amharic, Pidgin, Twi, Wolof, Afrikaans (`kGamesHubLanguageSlugs`). Contribute
also mentions Shona (`sn`) — Intron STT lists it; Intron TTS may not.

Legend: **Intron-S** = streaming STT, **Intron-F** = file STT, **Intron-TTS** =
TTS (later, verified langs only), **Keep** = current engine, **Skip** = no STT/TTS job.

### 4.1 Polie / AI chat (highest ROI)

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Polie conversation / roleplay mic | `lib/screens/ai_chat/polie_workspace_screen.dart` + `lib/services/ai/polie_voice_input_service.dart` | On-device `speech_to_text`. Pidgin mapped to `en-NG` (English ASR). Locales like `yo-NG` / `ig-NG` are missing on most Android/iOS images. | **Intron-S.** Keep `PolieVoiceTranscript` so the workspace does not change. This is the single highest-value swap in the app: learners actually code-switch. |
| Polie read-aloud of replies | `tts_provider.dart` / `AfricanTtsService` | Gold → MMS | **Keep TTS.** Later: A/B **Intron-TTS** for Pidgin and CS replies only. |
| Polie translate tab (typed) | same workspace | Text MT, not STT | **Skip** STT. If a mic is added on that tab, reuse Polie voice input. |
| Groq `transcribeAudio` | `lib/providers/ai_chat_provider_groq.dart` | Direct Groq Whisper from the client | Stop using this as a production African STT path. Route callers through `AfricanSttService` Silver. |

### 4.2 Live translate

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Live Translate | `lib/screens/live_translate/live_translate_screen.dart` | On-device STT → Socket.IO `/api/live-translate/session` → cloud MT + optional TTS | **Intron-S** for source captions. Keep Socket.IO + MT. Keep existing TTS for the **target** language (MMS). Intron STT here is why Yo↔En and Pidgin↔En will start working; Google on-device will not. |

### 4.3 Tutor

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Translation mode mic | `lib/screens/tutor/tutor_translation_mode_screen.dart` | Own `SpeechToText` + `_sttLocaleFor` | **Intron-S.** Delete the duplicated locale map. |
| Pronunciation mode | `lib/screens/tutor/tutor_pronunciation_mode_screen.dart` | Record 16 kHz → `POST /api/pronunciation/advanced/analyze` (`include_tone_analysis`) | **Keep Whisper/MFA/tone. Do not Intron.** Scoring is the product. |
| Shadowing | `lib/screens/tutor/shadowing_exercise_screen.dart` → Groq `shadowingExercise` | Groq Whisper transcript + WER vs reference | **Intron-F** for the transcript (learner speech). Keep WER math in-app. Do **not** use Intron as a phoneme scorer. Disable LLM corrections. |
| Listening quiz | `lib/screens/tutor/listening_quiz_screen.dart` | `ttsProvider` plays a generated passage; user answers MCQ | **Keep AfricanTtsService.** No STT. |
| Story / grammar / dialogue modes | `tutor_*_mode_screen.dart` | Text + TTS playback | **Keep TTS.** If dialogue grows a speak-your-line mic, that mic is **Intron-S** (comprehension), not pronunciation scoring. |

### 4.4 Games

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Pronunciation (listen + pick English) | `lib/screens/games/pronunciation_game.dart` | TTS only (`ttsProvider`) | **Keep AfricanTtsService.** No STT. |
| Pronunciation duel | `lib/screens/games/pronunciation_duel_game.dart` | **Simulated** score (random 75–95). Mic is cosmetic. | When made real: **Keep** `AsrPronunciationScorer` (Whisper sidecar). Not Intron. |
| Pronunciation karaoke | `lib/screens/games/pronunciation_karaoke_screen.dart` | Hold-to-record UI; no ASR | Same: **Keep** Whisper/MFA when wired. |
| Template shell | `lib/screens/games/templates/template_pronunciation.dart` | Layout only | Skip. |
| `AsrPronunciationScorer` | `lib/services/games/asr_pronunciation_scorer.dart` | Ready client for `POST /api/v2/asr/score` — **unused by any screen** | Wire duel/karaoke/tone-forge here. Still not Intron. |
| Traditional (Ayo, Ludo, Whot, Suwe, Snakes) | `lib/screens/games/traditional/*` | `AfricanTtsService.speak` for words | **Keep TTS.** |
| Base game screen | `lib/screens/games/base_game_screen.dart` | Shared TTS helper | **Keep TTS.** |
| Tone Forge / Drum rhythm | `lib/games/tone_forge/*`, `lib/games/drum_rhythm/*` | Game audio / rhythm, not ASR | **Keep** tone sidecar if scoring pitch; Intron has no F0 tracker. |
| Gamekit / universal | `lib/games/gamekit/*` | Shell | Follow the game type (TTS vs Whisper score). |

### 4.5 Practice, vocab, curriculum, AR

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Pronunciation practice (lessons) | `lib/screens/practice/pronunciation_practice_screen.dart` | `PronunciationAnalysisService` → MFA analyze | **Keep scoring stack.** |
| Tone + rhythm trainer | `lib/screens/learning/tone_rhythm/tone_rhythm_trainer_screen.dart` | Record → tone API (`/api/voice/pronunciation/tone`), offline queue | **Keep tone sidecar.** Intron cannot replace pitch/tone. |
| Listening practice (clip + questions) | `lib/screens/content/listening_practice_screen.dart` | Plays hosted clips | **Skip** STT. Playback is CDN/lesson audio, not Intron TTS. |
| Vocabulary / flashcards / builder | `vocabulary_screen.dart`, `vocabulary_builder_screen.dart` | TTS playback | **Keep AfricanTtsService.** |
| Curriculum audio | `lib/services/content/curriculum_audio_service.dart` | Forced through `AfricanTtsService` | **Keep.** |
| Point and Say (AR) | `lib/screens/ar/point_and_say_screen.dart` | Detect object → TTS target → record → `VoiceApiService` pronunciation + optional tone; offline queue | **Keep scoring.** Intron-F is only useful as a **secondary** “what did they say?” caption, never as the pass/fail grade. |
| Speak Mission | `lib/screens/content/speak_mission_evaluate_screen.dart` | Record 10–30 s → Groq Whisper transcript → `POST` rubric (`SpeakMissionService`) | **Intron-F** for transcript (scenario speech, CS expected). **Keep** LLM rubric. This is file STT, not streaming. |

### 4.6 Contribution / UGC / media

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Native speaker contribution | `lib/screens/contribute/native_speaker_contribution_screen.dart` | Record gold prompts, upload | **Keep upload.** Optional **Intron-F QA** on the server: reject clips whose transcript is far from the prompt (WER vs prompt, not vs a scoring model). Never replace the WAV. |
| Voice contribution | `lib/screens/voice_contribution/voice_contribution_screen.dart` | Pick/upload file to `/api/voice/contributions` | Same: upload + optional Intron-F QA. |
| Media import transcribe | `lib/screens/media/import_media_screen_enhanced.dart` → `/media/:id/transcribe` | Backend async transcribe (likely generic Whisper) | **Intron-F on the Node/Python worker** for hub-language media. User never talks to Intron from the app. |
| UGC create lesson/story/quiz | `lib/screens/ugc/*` | Text/content; no mic | **Skip** unless a “read this story aloud” tool is added — then Intron-S. |

### 4.7 Live people (classroom, village, social audio, mentors)

These already have a media plane. Intron does not replace LiveKit.

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Live classroom | `lib/screens/chat/live_classroom_screen_material3.dart` | LiveKit A/V | **Keep LiveKit.** Phase-2: optional **Intron-S captions** from a mixed or per-participant tap. Hard: diarization, consent, cost. Do not block Polie on this. |
| Classroom LiveKit chat | `lib/screens/chat/classroom_chat_livekit_screen.dart` | Same | Same. |
| Collaborative practice room | `lib/screens/village/practice_room_collaborative_screen.dart` | LiveKit | Same. |
| Social audio rooms | `lib/services/social_audio/social_audio_service.dart` + `room_detail_screen.dart` | Spaces-like LiveKit audio | Same: media stays LiveKit. Captions later. |
| Micro-mentor session | `lib/screens/community/micro_mentor_session_detail_screen.dart` | Record mentor/learner clips, upload | **Keep upload** for the human session. Optional Intron-F transcript for session notes. Not a grade. |
| Village café / places / elders | village screens | Mostly text/social | **Skip** unless a mic is added. |

### 4.8 Assessment / passport

| Surface | File | Job today | Recommendation |
|---|---|---|---|
| Proctored passport session | `lib/screens/passport/passport_proctored_session_screen.dart` | Record per prompt, `PassportService.uploadRecording`, staff/device review | **Keep human / MFA review.** Optional Intron-F **transcript for the reviewer UI** only. Auto-pass with conversational STT would be an integrity bug. |

### 4.9 Offline / fallback

| Surface | Job | Recommendation |
|---|---|---|
| No network | Lesson TTS from disk cache; mic | **Keep** Gold cache + `flutter_tts` + `speech_to_text`. Intron unavailable. Show the same copy we use when MMS is down. |
| Intron outage | Live mic | Bronze Whisper file STT or on-device. Partial transcripts may go English; better than a dead mic. |

### 4.10 Intentionally unused / do not grow

| Piece | Recommendation |
|---|---|
| `EnhancedVoiceService` (Wav2Vec2 ensemble comments) | Ignore. |
| `EnhancedSTTService` as a parallel API | Fold into `AfricanSttService`. |
| Client Groq Whisper as default African STT | Remove after Speak Mission + shadowing migrate. Groq may remain for English-only debug. |
| Intron Voice Bots / robocall APIs | Out of scope. We have Polie + Groq for dialogue. |
| Intron widget embed | Out of scope. Native Flutter mic UX already exists. |

---

## 5. Language coverage vs the app

All **11 hub languages** are on Intron STT. Core four are **code-switched with English**,
which is exactly how Polie and Live Translate are used.

| Hub slug | Intron STT code | CS with English | App STT today | App TTS today |
|---|---|---|---|---|
| yoruba | `yo` | yes | `yo-NG` on-device (usually missing) | MMS / CDN |
| hausa | `ha` | yes | `ha-NG` | MMS / CDN |
| igbo | `ig` | yes | `ig-NG` | MMS / CDN |
| pidgin | `pcm` | yes | **`en-NG` (wrong engine)** | MMS **English** + disclaimer |
| swahili | `sw` | yes | `sw-KE` | MMS / CDN |
| zulu | `zu` | yes | `zu-ZA` | MMS / CDN |
| xhosa | `xh` | no | `xh-ZA` | MMS / CDN |
| amharic | `am` | yes | `am-ET` | MMS / CDN |
| twi | `tw` | no (Akan `ak` is CS) | `tw-GH` | MMS / CDN |
| wolof | `wo` | yes | `wo-SN` | MMS / CDN |
| afrikaans | `af` | yes | `af-ZA` (often present) | MMS / CDN |
| shona (contribute) | `sn` | no | `sn-ZW` | MMS if mapped |

Twi: prefer Intron `tw`; if CS Akan/English shows up in roleplay, try `ak` in the bake-off.

**TTS:** Intron TTS is a **separate, smaller** list. Until each hub language is
verified on [supported languages and accents](https://docs.voice.intron.io/docs/tts/supported-languages-and-accents),
playback stays on `AfricanTtsService`. Pidgin is the only TTS gap worth an
early Intron experiment.

---

## 6. Code changes when we implement (do not do this yet)

Implementation belongs in a later PR, gated on bake-off. Sketch only:

1. **Node** (backend repo, not this app): proxy with the Intron key; stream
   PCM 16 kHz mono from the client; map `language=yo` etc.; set
   `use_disable_llm_corrections` on learner paths.
2. **Flutter:** `lib/services/audio/african_stt_service.dart` with the same
   singleton + telemetry hooks as TTS (`onResolution`).
3. **Swap:** `PolieVoiceInputService` delegates to it; Live Translate and Tutor
   translation drop their local `SpeechToText`.
4. **Speak Mission / shadowing:** `transcribeAudio` goes to
   `POST /api/stt/transcribe`, not Groq.
5. **Flag:** `--dart-define=INTRON_STT=true` or remote config, default off until
   bake-off.
6. **Do not** change `AfricanTtsService` order, MFA URLs, or LiveKit token flow.

Contract to preserve: `PolieVoiceTranscript { text, isFinal, confidence }` so
the 6k-line Polie workspace does not churn.

---

## 7. Risks

- **Scoring contamination:** someone will want one vendor for “all voice.”
  Isolated-word WER above 15% will silently pass wrong pronunciations in games.
- **LLM corrections:** Intron can clean transcripts. Fatal for learners and for
  contribution QA. Always disable on those paths.
- **Key in the client:** Groq is already dart-defined into the app. Do not copy
  that mistake for Intron.
- **Cost / latency:** streaming STT on every Polie tap is the cost center.
  File-sync is enough for Speak Mission. Classroom captions are the expensive
  optional extra.
- **Twi / Xhosa / Shona:** not all are CS models. Bake-off may show on-device
  or Whisper bronze winning there; allow per-language routing.
- **Karaoke / duel still fake:** wiring them to Intron would look live and
  score noise. Wire them to `AsrPronunciationScorer` instead.

---

## 8. Decision rule (from the bake-off)

| Scenario | Max WER | If Intron fails |
|---|---|---|
| `code_switch` (Yo/Ha/Ig/Pidgin) | 0.35 | Do not replace Polie/Live Translate mics. |
| `short_phrase` | 0.20 | Do not use for Speak Mission / dictation. |
| `isolated_word` | 0.15 | **Never** use for games, tutor pronunciation, AR pass/fail, passport auto-grade. |
| `learner` | 0.20 | If Intron “corrects” the attempt, keep `use_disable_llm_corrections`. |

Pick Intron for **live roleplay / Polie / live translate** if it wins
`code_switch`. Leave pronunciation scoring on Whisper + MFA regardless of a
code-switch win.
