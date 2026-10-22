<!-- page 1 -->
LingAfriq: Senior Audit and Elevation Plan
Prepared for: Tope (Fabian Umole) · Date: 17 October 2026 · Scope: Flutter app (lingafriq-mobile-app-
clone, 1,039 Dart files, ~306k lines), Node/TypeScript backend (node-backend, 1,120 TS files, 76 route files,
107 models), React admin (lingafriq-admin), Python voice service (lingafriq-voice-service), curriculum
bundles and the pasted Rive avatar plan.
Method. Static review of a read-only copy of the source (keys and media were stripped from most of the
copy before review; a few secrets were still in it, listed in §1). I mapped routes, screens, providers and
backend routes, then checked each feature against its code. Every finding below cites file:line or a
reproducible data measurement. Where I could not verify something (a missing media file, production
config, the live server) it is marked [Unverified]. Nothing was run against production. No code was
modified.
How to read this. §0 is the verdict. §1 is the P0 list (fix before anything else). §2 is the feature inventory
with a status for each feature. §3 to §15 are the deep sections Tope asked for. §16 is the roadmap. §17 is
the new information architecture (every feature gets a home) and §18 is the complete Feature
Catalogue with a deep-dive for every user-facing feature, grouped by hub. No feature is cut anywhere
in this plan; duplicate implementations are consolidated only when the feature itself survives. The
companion document LINGAFRIQ_AI_MODEL_STACK.md gives the commercially licensed model choices,
coverage per language, integration plan and costs.
0. The verdict in one page
LingAfriq has enormous surface area and very little load-bearing substance. The repo contains 319
status Markdown files in the app root alone (ALL_FIXES_COMPLETE_FINAL.md,
PRODUCTION_READY_100_PERCENT_COMPLETE.md, WORLD_CLASS_IMPLEMENTATIONS_COMPLETE.md ...) and roughly 150
more in the backend. The code tells a different story:
1. The curriculum, the product's core, is mostly placeholder or template output. Three of the four
curriculum bundles contain literal placeholders ("word": "word1a", "meaning": "example meaning",
"question": "Sample MCQ", "answer": "a"). My script found 24,234 of 48,847 vocabulary entries
(49.6%) across the bundles are placeholders. The "authentic" A1–C2 file, the best content in the
repo, has only 85 to 111 unique vocabulary items per language, recycled across 126 lessons per
language. 126 of 126 dialogues per language repeat lines. The same two grammar sentences
appear in 1,546 lessons, and one of them is false for most of the languages it is attached to (details
in §6). No curriculum file references a single audio file.
2. Pronunciation and tone feedback, the main reason to choose an African-language app over a
phrasebook, is mostly fake. Pronunciation Duel never opens the microphone and returns a random
75–95% (screens/games/pronunciation_duel_game.dart:105-129). Karaoke's pitch score is 60 +
rng.nextInt(35) (pronunciation_karaoke_screen.dart:155). The tutor's "Rhythm" score is score * 0.9
(tutor_pronunciation_mode_screen.dart:114). The voice service's tone endpoint is labelled #
Placeholder and reuses text similarity (lingafriq-voice-service/main.py:262-274).
3. Private conversations are not private. Any signed-in user can join any socket room (node-
backend/src/services/socket.service.ts:263-268), and private rooms are named
private_<smallerId>_<largerId> (:106-109), so they can be guessed. A client can also claim to be any
user id (:249-260) and then receive that user's snaps and streak events (:84-90). Read receipts,
presence and reactions go to every connected user through io.emit (:817, 830, 840, 852).
<!-- page 2 -->
4. Children are in scope, but child safety is not. Onboarding collects 'child' as an age category
(unified_onboarding_screen.dart:745). The app ships private DMs, voice/video calls, Snapchat-style
disappearing media and a public X-style feed. There is no age gate, no parental consent and no
guardian controls anywhere (grep for parental|coppa|guardian|age.?gate finds nothing relevant).
Chat "moderation" is a 4-word English list plus 7 African words matched by substring
(services/toxicityFilter.ts:9-30). It flags the Yoruba word ode inside "code" and "mode" and flags
the English word "were", and it only records a score; nothing is blocked.
5. Secrets are committed. A live-format Firebase Admin SDK service-account private key for project
lingafriq-15d2a sits at node-backend/sample.json, and .gitignore does not cover it. An Apple .p8
private key (AuthKey_QWGCD23R6B.p8) is in the mobile repo root and is also not ignored. The parent
reported Admin SDK JSONs inside node-backend/dist/services/ on the Mac. build.yml compiles five
paid AI provider keys into the app binary (.github/workflows/build.yml:99-113), where anyone
can extract them.
6. The economy and leaderboards can be cheated with one HTTP call. POST
/api/gamification/currency/award ("admin/system use") lets any signed-in user mint unlimited
currency for themselves (routes/gamification/currency.route.ts:100-125). POST
/accounts/update_points/ adds any positive number of points
(controllers/accounts.controller.ts:360-378). POST /api/gamification/xp/award allows 10 × 1,000
XP per minute (routes/gamification/xp.route.ts:22,37).
7. Updates log every user out and repeat onboarding. Any semver change, even 1.6.1 → 1.6.2, clears
tokens, credentials and onboarding (providers/auth_provider.dart:54-75). Retention resets with
every release.
8. A huge, ambitious feature set with no spine connecting it to the course. There are WhatsApp-
style (wa-*), Snapchat-style (snap-*) and X-style (x-*) surfaces, a Clubhouse-style audio room,
villages, tribes, classrooms, micro-mentors and a culture magazine (my_app.dart:277-480). Each has
real potential, but none is yet tied into the learning loop. On top of that, 88 finished screens are
unreachable from main.dart (330 files by reachability; 183 files that no file imports at all), including
the moderation tools, native-speaker verification, offline downloads, lesson recap, the guardian
dashboard and the Tone Forge game: the very tools this product most needs. §17.5 revives 25 of
them.
The opportunity is real and unclaimed. No app in 2026 teaches African languages with tone-accurate
audio, native-validated content, real pronunciation and tone feedback, and culturally grounded AI.
LingAfriq already has the right instincts: the Intron proxy, tone service scaffolding, a learner model,
persona registries with primary-source fields, CEFR framing and a village metaphor. The plan below is to
harden, connect and deepen every feature: one coherent learning loop that every feature plugs into, one
trustworthy social layer, one design system, and content that can survive a native speaker reading it.
Nothing is cut; every feature gets a home in the new IA (§17) and its own elevation (§18).
1. P0: fix now (security, safety, integrity, data loss)
# Finding Evidence Fix Effort
P0-1 Firebase Admin
SDK private key
committed
node-backend/sample.json:4-5 (service_account,
firebase-adminsdk-us33e@lingafriq-15d2a);
.gitignore covers *firebase-adminsdk*.json but
not sample.json; messagingService.ts:29 loads a
key JSON from src/services/; parent reports
dist/services/*firebase-adminsdk*.json on the
Mac
Revoke the key in GCP IAM
today, scrub git history (git
filter-repo), move to
Workload Identity or a secret
manager, add
gitleaks/trufflehog pre-
commit and CI gates
S
<!-- page 3 -->
# Finding Evidence Fix Effort
P0-2 Apple .p8 key
in repo root
lingafriq-mobile-app-
clone/AuthKey_QWGCD23R6B.p8 (PEM private key), not in
.gitignore
Revoke in the Apple
Developer portal, purge from
history, store as a CI secret
only
S
P0-3 Paid AI keys
compiled into
the app
build.yml:99-113 passes GROQ_API_KEY,
HUGGINGFACE_TOKEN, STABILITY_AI_KEY,
REPLICATE_API_KEY, LEONARDO_API_KEY as --dart-
define; read in lib/services/env_config.dart:43-
60; direct calls in
lib/providers/persona_providers.dart:16-45,
ai_chat_provider_groq.dart:1404,1762,1967,
ai_chat_provider.dart:44-58
Rotate all five. Delete every
direct provider call from the
client. All AI goes through an
authenticated, metered
backend gateway (§7)
M
P0-4 Any user can
listen to any
private chat
socket.service.ts:263-268 (join_room joins any
room); :106-109 predictable room ids
Server-side membership
check on every join (room
ACL from DB). Derive room
ids server-side and make
them opaque (UUIDv7)
S
P0-5 Socket identity
spoofing
socket.service.ts:249-260 overwrites userId from
the client payload; :84-90 routes per-user events by that
map
Delete user_connected.
Identity comes only from the
verified JWT
S
P0-6 Global
metadata leak
io.emit for
delivered/read/presence/reactions/status/story
(:817,830,840,852,861,881); full online-user list to
everyone on every connect (:915-921), which is also O(N2)
Emit to room or participant
sockets only. Presence is
limited to contacts and opt-
in
S
P0-7 Self-mint
currency
routes/gamification/currency.route.ts:100-125:
requireSignin only, amount unbounded (:44)
Admin/service-only. Grants
come from server-side event
rules (lesson completed →
reward), never from a client
amount
S
P0-8 Self-award
points/XP
controllers/accounts.controller.ts:360-378;
routes/gamification/xp.route.ts:22,37
Server computes XP from
verified events with
idempotency keys
(sourceId unique per user)
and daily caps
S
P0-9 Open LLM
proxy
controllers/aiCompletion.controller.ts:65-79:
client supplies systemPrompt, any role (incl. system),
max_tokens unbounded; route has only requireSignin
(routes/ai.route.ts:12)
Server-owned prompt
templates selected by mode
enum; clamp tokens; per-
user quotas and cost
budgets; strip client system
roles
M
P0-10 No child safety
or age
assurance
unified_onboarding_screen.dart:745 collects
child; DMs, calls, snaps, public feed exist; no consent flow
Age gate before account
creation. Under-13: no
DMs/calls/snaps/public feed,
guardian consent (NDPA
2023, GDPR Art. 8, COPPA if
US users). 13–17: restricted
defaults. See §13
M
P0-11 Moderation is
cosmetic
services/toxicityFilter.ts:9-73 (11 terms,
substring match, score only)
Layered moderation (§9):
classifier + per-language
lexicons with word
boundaries + image/video
hash matching + human
queue + block/report UX
M
<!-- page 4 -->
# Finding Evidence Fix Effort
P0-12 "Disappearing"
snaps never
disappear
soft delete only
(controllers/snap.controller.ts:104-111);
media_url is any client-supplied URL (:52-68)
Hard-delete blobs on expiry.
Media only via signed upload
URLs to your own bucket.
Reject external URLs. Under-
18: disable snaps
S
P0-13 Persona
missions silently
fail in release
persona_providers.dart:22-45 uses the client Groq
key; build-and-release.yml:216,234 injects no AI key;
historical_roleplay_controller.dart:322-329
returns "I hear you. Let us continue." on any error
Route through backend.
Show an honest error state
with Retry
S
P0-14 Persona safety
filter blocks
harmless
learners
roleplay_safety_filter.dart:24-30,158-160:
substring matching blocks "skill" (contains kill), "whatever"
(contains hate), and "discrimination" when talking to
Mandela
Replace with a model-based
policy classifier plus persona-
specific rules. Historical
violence is discussable at an
age-appropriate level
S
P0-15 Persona told to
deny being AI
node-
backend/src/services/historicalPersonality.serv
ice.ts:314 "Do not mention... being an AI model"
Always disclose ("AI
recreation based on
sources"). EU AI Act Art. 50
transparency duties apply
from 2 Aug 2026; minors are
in the audience
S
P0-16 Curriculum is
placeholder or
template
§6 measurements Freeze marketing claims. Pull
placeholder bundles from
the build. Start the content
pipeline (§6)
L
P0-17 False tone and
grammar
teaching
assets/data/game_content.json word 1: "High tone
on àárọ̀ marks respect" (àárọ̀ carries low tones; respect
comes from the honorific Ẹ). The phonetic guide equals the
tonal note for 1,409/1,409 words. "Affixes carry tense and
person" is attached to Yoruba, Pidgin, Twi and others; "SVO
default" is attached to Somali and Amharic (both SOV)
Pull until native-reviewed (§6
pipeline)
M
P0-18 Fake
pronunciation
scores
pronunciation_duel_game.dart:105-129 (no
recording, random score),
pronunciation_karaoke_screen.dart:155,
tutor_pronunciation_mode_screen.dart:114
Remove the random scores
today. Show "practice mode,
no scoring" until real scoring
ships (§7)
S
P0-19 Pronunciation
backend lies
with HTTP 200
services/advancedPronunciation.service.ts:26-
28 defaults to localhost:8001-8003; on failure returns
200 {overall_score:0...} (:211-224), so the client's
Whisper fallback never runs
(tutor_pronunciation_mode_screen.dart:90-95)
Return 503 with
retryable:true. Client
falls back or shows
"unavailable"
S
P0-20 Every release
logs everyone
out
providers/auth_provider.dart:54-75 Delete the semver reset. Use
schema-versioned
migrations for local data
S
P0-21 Onboarding
answers
corrupted
unified_onboarding_screen.dart:354 stores
Map.toString();
providers/onboarding_provider.dart:496-503
fromJson fails silently and resets
jsonEncode, typed model,
migration for existing
corrupted values
S
P0-22 Offline queue
drops data
services/offline/offline_handler.dart:120-152
marks ops completed and removes them while
_syncOperation is a stub ("For now, simulate sync"); used
by services/lesson/lesson_item_service.dart:22
Single durable outbox (§13),
delete the stub
M
<!-- page 5 -->
# Finding Evidence Fix Effort
P0-23 Push spam,
duplicated
workers/notificationScheduler.ts:17-80: every 2 h,
no "already sent today" check, server timezone, N+1 queries
over all users; scheduler starts both in-process
(app.ts:216-221) and in the separate PM2 worker
(ecosystem.config.js:27-28) → up to 24 "streak at
risk" pushes a day if both PM2 apps run [Unverified on
server]
One scheduler (leader-
elected job queue), per-user
local-time window, max one
reminder per day, quiet
hours
S
P0-24 Non-
commercial
model licences
in a paid app
node-backend/mms-tts-service/main.py:46 uses
facebook/mms-tts-* (CC-BY-NC 4.0); coqui-xtts-
service/app.py:64 uses XTTS-v2 (Coqui Public Model
License, non-commercial); NLLB_API_URL in
secrets_manager.dart:85 (NLLB-200 is CC-BY-NC)
Legal review. Swap to the
commercial replacements in
LINGAFRIQ_AI_MODEL_STA
CK.md §1.1
(Intron/Spitch/Azure TTS,
custom isiXhosa voice,
Google/Azure MT, MADLAD-
400)
M
P0-25 Login
enumeration,
no lockout
controllers/auth.controller.ts:120,135 ("User not
Found" vs "Password is not a match"); limiter is 10/min per
IP only
Generic error; per-account
progressive delay; breached-
password check; passkeys
(§13)
S
P0-26 Unofficial
Google
Translate
scraping in prod
services/freeGoogleTranslate.service.ts:7
(@vitalets/google-translate-api)
Remove. ToS and IP-ban risk,
and quality is poor for tonal
orthography
S
P0-27 Purchases not
verified server-
side
No RevenueCat webhook or receipt route in
routes/subscription.route.ts; RC keys are read from
.env/secure storage (revenuecat_service.dart:21-
25) and not injected by the release workflow [Unverified:
may be provided another way]
RevenueCat webhooks →
entitlement table; backend
enforces premium gates
M
P0 count: 27. Most of them are one to three days each. P0-1 to P0-9 should be done this week.
2. Feature inventory and verified status
Status key: Works (wired end to end, quality aside) · Partial (wired, with material defects) · Broken (fails in
normal use) · Fake (shows outcomes it does not compute) · Stub (scaffold only) · Dead (not reachable from
the app).
# Feature Entry point(s) Status Headline defect (evidence)
1 Startup / splash main.dart,
screens/splash/splash_
screen_material3.dart
Partial About 15 sequential awaited inits before
runApp (main.dart 40-200); 1.2 s artificial
delay (splash...:28); 30 s timeout falls back to
Login, so offline users are kicked out (:39-48);
Sentry starts after everything else, so startup
crashes are not captured
2 Onboarding OnboardingScreenMateri
al3 →
UnifiedOnboardingScree
n (9 steps)
Partial 9 question screens before any learning;
"learning style" step (VARK myth) (:93);
answers stored as Map.toString() (:354); 3
other full onboarding flows are dead
(enhanced_* 2,530 lines, kijiji_* 1,629,
modern_* 750)
3 Placement test placement_test_screen.
dart via dialog after
onboarding
Partial Offered in an AlertDialog after 9 screens;
placement_quiz_screen.dart is a
duplicate
<!-- page 6 -->
# Feature Entry point(s) Status Headline defect (evidence)
4 Auth world_class_login_scre
en.dart,
world_class_signup_scr
een.dart, email verify, reset
Partial Enumeration (P0-25); 7-day HS256 token, and
the "refresh" endpoint just re-signs an
unexpired access token
(auth.controller.ts:320-364); is_admin
in the JWT payload (DB re-checked server-side,
good); no passkeys/OAuth; 4 legacy auth
screens remain
5 Home / dashboard tabs_view_material3.da
rt (Home, Courses, AI,
Social, Profile) + 36-item
drawer
Partial Feature dump IA; two dashboards
(modern_dashboard_screen.dart
unreachable, consolidated into Today)
6 Courses /
curriculum map
'curriculum' →
LessonsMapEntryScreen;
services/curriculum_se
rvice.dart
Partial Master index is loaded first from the
placeholder
lingafriq_FINAL_curriculum/master_in
dex.json
(curriculum_service.dart:113-118);
"Coming Soon" for missing levels
(curriculum_screen_material3.dart:367
)
7 Lesson flow 'lesson-flow',
screens/lesson*
Partial 10 declared stages, but content is template-
driven (§6) and there is no audio
8 Grammar hub grammar-hub,
grammar_exercise_scree
n.dart (1,300 lines)
Partial Grammar copy is generic (§6)
9 Vocabulary /
flashcards / SRS
my-vocabulary,
flashcard-review,
local_database_service
.dart:226
Partial Four separate memory models: SM-2 locally
(local_vocabulary.dart:13), HLR in the
learner model
(learning/core/hlr_forgetting_curve.d
art), backend aiChatSRS and gameSRS
models. None of them is FSRS
10 Listening / writing
practice
listening-practice,
writing-practice
Partial No audio corpus ships (§6)
11 Tutorials / features
guide
features_guide,
game_onboarding_overla
y.dart
Partial Feature tours rather than skill tutorials
12 Quizzes (language,
history, random,
unit)
language_quiz/,
history_quiz/,
random_quiz/, unit quizzes
Partial Unit quizzes in placeholder bundles are
"Sample MCQ"/"a"; no item analysis or
calibration
13 Games ( ≈ 45
screens)
screens/games/*,
games/*
Partial/Fake Random pronunciation scores; tone trainer
forces a 3-tone H/M/L model on all languages
(tone_trainer_game.dart:63); finished
game code is unreachable (Tone Forge and the
mastery results screen are revived; older
templates and loaders are consolidated into
GameKit, §17.5)
14 Pronunciation /
speak lab / tone
tutor_pronunciation_mo
de_screen.dart, speak-
engine-lab, tone-
rhythm-trainer; backend
advancedPronunciation.
service.ts;
services/tone-
service/app.py
Fake/Broken P0-18/19; tone service falls back to "Install
librosa" (app.py:241-248) and compares
tone strings position by position
<!-- page 7 -->
# Feature Entry point(s) Status Headline defect (evidence)
15 Polie AI chat polie_workspace_screen
.dart (6,485 lines),
ai_chat_provider_groq.
dart (2,516)
Partial Direct Groq calls with a client key, or a non-
streaming backend fallback (:1302-1330); 4
dead chat screens
16 AI tutor modes
(story, grammar,
dialogue, assess,
translation,
pronunciation)
screens/tutor/* Partial Prompt-only, with no grounding in curriculum
items; JSON parsing with no schema validation
on the server
17 Roleplay scenarios roleplay_scenario_sele
ction_screen.dart,
ai/modes/roleplay_engi
ne.dart
Partial Same client-key issue
18 Historical Personas
+ missions
historical-personas →
PersonalitySelectionSc
reen (backend),
persona_missions/*
(client Groq)
Partial/Broken Two persona systems (27 client personas in
historical_persona_registry.dart,
backend seeds in
scripts/extendedHistoricalPersonas/*
); missions fail silently (P0-13); no retrieval
grounding, sources: [], confidence:
0.9 hard-coded
(historicalPersonality.service.ts:195
); factual slips (Nkrumah listed as
English/Twi, personas-e01.ts:20; he
was Nzema)
19 Live translate live_translate_screen.
dart, socket
live_translate_event
Partial Built on the unofficial Google Translate scraper
(P0-26) [Unverified which path is live]
20 Point-and-say (OCR
/ object detection)
point-and-say, ML Kit Partial ML Kit labels are English; the translation path is
the same issue as #19
21 Culture magazine /
heritage archive /
living dictionary
cultural-hub, flb-
heritage-archive,
living-dictionary
Partial culture_magazine_screen.dart is an
unreachable older version (consolidated,
§17.5); backend scraper
(cultureScraper.service.ts) raises
copyright questions
22 Tribes tribe-selection, my-
tribe, tribal-duel,
inter-tribe-
leaderboard
Partial Duplicate routes (tribe, tribe-hub, tribe-
discovery all → selection); the channel-
subscription handlers in
socket/handlers.ts:107-145 are never
registered (only attachSocketInstance is
used, socket.service.ts:192), so
tribe/leaderboard live updates have no
subscribers, while join_room lets anyone join
any tribe:* room
23 Villages villages-hub, language-
village, market/cafe/elder
hut
Partial/Fake flashcard_focus_screen.dart:26-34
shows mock participants as live co-learners
24 Classrooms (live,
LiveKit)
classroom-lobby,
classroomV2.route.ts
Partial live_classroom_screen.dart and
classroom_chat_livekit_screen.dart
are unreachable older versions (consolidated
into the live screen, §17.5); no teacher tooling
for assignments/grading in the app
25 Global chat chat.route.ts:69, socket
send_message
Partial No moderation (P0-11); rooms by language
name
<!-- page 8 -->
# Feature Entry point(s) Status Headline defect (evidence)
26 Private chat
(WhatsApp-style)
private-chat-inbox, wa-
*
Broken
(privacy)
P0-4/5/6; no E2EE;
private_chat_screen_material3.dart
unreachable (consolidated)
27 Snaps / stories
(Snapchat-style)
snap-* Broken
(safety)
P0-12; streak counts are client-supplied
(socket.service.ts:888-905)
28 X-style feed x-*, feed.route.ts Partial Public by default (feed.route.ts:23); no
minor protections
29 Social audio rooms social_audio/*,
socialAudio.route.ts
Partial No recording consent or moderation tooling
[Unverified]
30 Friends,
connections, friend
quests
connections, friend-
quests
Partial friendQuest.controller.ts:325 takes
amount from the body
31 Micro-mentors micro-mentor-hub, staff
reports
Partial Paid/peer tutoring without safeguarding
(background checks, session recording policy)
32 UGC / voice
contribution
ugc, contribute_voice Partial native_speaker_contribution_screen.d
art and
lesson_item_verification_screen.dart
are unreachable (revived in §17.5/§18.6); no
contributor consent or licensing terms for voice
data
33 Gamification (XP, 3
currencies, leagues,
hearts, badges,
streaks, magic
items, ancestral
tree)
routes/gamification/*
(15 route files)
Broken
(integrity)
P0-7/8; 3 currencies (ngwenya, cowries,
ancestral_beads) with no clear sinks
34 Passport /
proficiency
credential
passport-proctored,
passport-credential
Partial A "credential" built on template content and
random scoring is a liability
35 Avatars (Rive) lib/avatars/* (2,594 lines
of scaffolding),
assets/rive/
Not built yet The Rive avatars have not been made yet
(confirmed by Tope, 17 Oct 2026), so there are
no visuals to judge. The code scaffolding
should be replaced rather than finished:
avatar_engine.dart:68-90 references 12
.riv files that don't exist, wires deprecated
state-machine inputs (:106-219), and the
three avatar engines disagree on parameters.
§4 is a forward design and production brief
36 Profile / settings settings_screen_materi
al3.dart (1,286 lines)
Partial Not audited line by line
37 Notifications FCM,
workers/notificationSc
heduler.ts
Broken P0-23; streak-loss copy ("Your N-day streak is at
risk!")
38 Subscriptions revenuecat_service.dar
t,
subscription.route.ts
Partial P0-27
39 Offline / sync 7 competing systems:
offline_handler,
background_sync_servic
e, sync_v2_service,
persisted_outbox_servi
ce,
backend_sync_provider,
plus 2 feature queues
Broken P0-22; AES via the encrypt package default
mode (SIC/CTR) with no authentication tag
(cache_encryption.dart:25-28)
<!-- page 9 -->
# Feature Entry point(s) Status Headline defect (evidence)
40 Localization (UI) l10n/*.arb (20 locales) Partial Only 103 keys exist; 1,104 hard-coded
Text('...') literals vs 35 localization
lookups; Yoruba strings lack tone marks and
subdots (app_yo.arb: "E kaabo si LingAfriq",
"Tesiwaju", "Ko")
41 Accessibility — Partial 471 Semantics( uses (good start); no audit of
text scaling, contrast, captions for audio, or
reduced motion
42 Admin panel lingafriq-admin (React
18, Vite 4, Redux)
Partial No native-review workflow, no content
versioning, 0 tests; session token in
sessionStorage
(store/reducers/userReducer.ts:12-40)
43 Voice services lingafriq-voice-
service/main.py, node-
backend/{whisper-
asr,mms-tts,tts-
mms,coqui-xtts,voice}-
service,
intron.route.ts
Partial No auth on the voice service endpoints; the
Intron proxy is never called by the app (0
references in lib/); placeholder tone
endpoint; licensing (P0-24)
44 Platform: CI/CD,
observability, tests
.github/workflows/*,
Sentry, Jest
Partial flutter analyze --no-fatal-warnings;
64 Flutter test files for 306k lines; 52 backend
tests; single PM2 fork instance with in-memory
presence and rate limits; workers duplicated
Feature areas audited: 44 (this table). The complete per-feature catalogue, 151 user-facing features each
with its own deep-dive, is in §18. Unreachable code: 183 Dart files / 49,074 lines are never imported by
any file; a stricter reachability scan from main.dart finds 330 unreachable files, 88 of them screens. These
are not deleted: §17.5 revives 25 screen-level features, consolidates older duplicates into the surviving
feature, and moves 3 developer examples out of the build.
3. Product thesis, information architecture and design system
3.1 Design read (Playbook law 1)
LingAfriq is a daily, voice-first practice companion that gets diaspora, heritage and curious learners speaking
African languages correctly, tones included, and gives them a place to use the language with real people. Every
screen should serve one of three jobs: learn it (comprehensible input + retrieval), say it (pronunciation,
tone, conversation), live it (community, culture, people). Every existing feature is mapped to at least one of
these jobs (§18); a feature that doesn't yet serve one is redesigned until it does, not removed.
3.2 What is wrong today
Breadth without a spine. my_app.dart:277-480 registers roughly 120 named routes, including
WhatsApp-, Snapchat- and X-style surfaces. The 36-item drawer
(screens/tabs_view/app_drawer/app_drawer_material3.dart) is a symptom: features compete for
attention instead of feeding one learning loop, and none has yet been taken to its full potential. The
fix is placement and depth (§17, §18), not removal.
Seven design systems at once: utils/african_theme.dart, app_colors.dart, design_system.dart,
modern_griot_design_system.dart, pan_african_design_system.dart, polie_design_tokens.dart,
stitch_theme_extensions.dart, plus theme/ and pan_african_ui.dart. There are 740 hard-coded
<!-- page 10 -->
Color(0x...) literals and 10+ font families (Nunito, Plus Jakarta Sans, Playfair, Lato, Philosopher, IM
Fell English, Cinzel, JetBrains Mono...). Bundled Dosis is almost unused.
google_fonts fetches fonts at runtime. On a first offline launch the fonts fall back, and stacked
Yoruba diacritics (ọ̀, ẹ́) can mis-render in fallback fonts [Unverified on device].
Every state does not exist (Playbook law 8). Errors are caught and swallowed in most screens, for
example catch (e) { /* fall through */ } in the tutor and the persona fallbacks above. Users see
wrong data rather than an error state.
3.3 Target IA (five tabs + Me; every feature kept)
Tab Contains Brings together
Today One adaptive session (10–15 min) mixing review, new input,
speaking and a cultural moment; challenges, quests, events,
streak
Home, dashboard variants, daily goals, daily
challenges, quests, seasonal events
Learn CEFR-aligned Path, lessons, Words & Review, Grammar,
Listening, Writing, Tone Gym, Culture shelf, Passport,
Downloads
Courses, curriculum, authentic path, learning
path, grammar, vocabulary, magazine, heritage
Speak Polie with all tutor modes, Scenarios, Historical Personas &
Missions, Shadowing, Code-Switch and Respect coaches
AI tab, tutor modes, persona missions, speak-
engine lab
Play The Arcade: every game on skill shelves, Traditional Games,
Multiplayer
All three game catalogues, cultural and
traditional games
Village Map, Circles, Square feed, Chats, Status, Clips, Radio, School,
Elder Hut, Corrections, Create & Contribute
Social hub, tribes, villages, wa-, snap-, x-*, social
audio, classrooms, mentors, UGC
Me (avatar,
top-left)
Avatar, progress, achievements, leagues, family, Plus, settings,
All features directory
Profile, achievements, badges, leaderboards,
settings, features guide
Global Search, the Lens camera (Point & Say, Live Translate, Import Media) and the long-press Word Card
(Living Dictionary) are available on every tab. Games are a full destination (Play) and are surfaced inside
Today and Path as practice formats, so they update the learner model. The full nav map, sitemap and
unlocking rules are in §17; every feature's place is in §18.
3.4 Design system: one source of truth
Tokens in one package (lib/design/): colour roles in OKLCH ramps (Playbook law 3, one accent with
one meaning), a 4-pt spacing scale, radius, elevation, motion curves (ease-out cubic-
bezier(0.23,1,0.32,1), ≤ 300 ms for product UI, Playbook §6.2–6.3). Generate them from a single
JSON shared with the admin panel and the Rive files (colours bound through Rive data binding, §4).
Typography for African orthographies. Pick faces by glyph coverage, not taste alone. Test every
candidate with: Ẹ kú àárọ̀ · Ọ̀ ṣun · Ị́ bịa · ɓaƙo ɗan ƴaƴa · Ɛyɛ · ŋ ɲ ɔ̃ · ሰላም · ߒߞߏ· ⵜⴰⵎⴰⵣⵉⵖⵜ
· LgMLgMLgMLgMLgM. Recommended: SIL Andika (designed for literacy, unambiguous letterforms and diacritics)
or Noto Sans for target-language text; Noto Sans Ethiopic / N'Ko / Tifinagh / Adlam for those
scripts; one characterful display face verified against the string. Bundle all of them (no runtime
fetch). Target-language text never below 18 sp, with leading ≥ 1.5 so tone marks don't collide.
A signature visual language for tone: the "Tone Lens". Every target-language word can show a
thin pitch contour above it (H/M/L/rising/falling/downstep), derived from orthography and validated
audio. It looks the same in lessons, chat, games, personas and the dictionary. It is LingAfriq's
equivalent of Duolingo's owl: instantly recognisable and actually pedagogical. It must never be
colour-only (accessibility); use contour shape plus optional colour.
Cultural art direction without cliché. The Playbook flags the generic "tasteful" palettes, and kente
stripes on every card are the same trap. Commission a pattern library per culture (adire, uli/nsibidi
motifs, kente, bogolan, Ndebele geometry, Ethiopian tilf) used sparingly as unit and region identity,
credited to the artists, with a cultural consultant's sign-off.
<!-- page 11 -->
States kit: skeletons matching layout, empty states that point forward, error anatomy (what
happened, why, what to do; Playbook §15.4), offline state, "AI unavailable" state, and "content under
review" state.
Motion: celebrations only in the rare tier (lesson complete, level up). Answer feedback ≤ 160 ms with
haptic plus sound. Honour reduced motion (gentler, not zero; Playbook §6.8).
Kill the slop tells (Playbook §9): emoji as icons (the notification copy uses 🔥 ), fake-precise numbers
(the "confidence 0.9" chips), "World-class"/"Elite" copy in UI strings.
4. Avatar system: design and production brief (avatars not yet built)
Status: the Rive avatars have not been made yet, so this section judges no existing visuals. It is a brief for
when Tope, or Cursor working with Tope, builds them. It takes Tope's pasted Rive plan (hierarchy, 0–100
expression numbers, Triggers (Boolean), the Idle...LessonComplete states, the 200×200 artboard, the hair
library, Solos/visibility toggles, ViewModel data binding) as the starting point. It keeps what is strong, flags
what to change before any artwork is drawn, and specifies the contract, pipeline, acceptance tests and build
order. The only thing that exists today is Dart scaffolding (lib/avatars/*), which should be rebuilt against
this contract.
4.1 What to keep from the pasted plan
A modular hierarchy (head, face parts, hair, body, clothing), a state list close to what a tutor needs (Idle,
Listening, Thinking, Speaking, Correct, Incorrect, Celebrating, Encouraging, Hint, LevelUp,
LessonComplete), idle micro-motion (breathing, blink variance, eye darts), anticipation, overshoot and
follow-through, and a nod to data binding. That is a solid start.
4.2 What to change before building (decide now; it is cheap before artwork exists and
expensive after)
1. Don't build on the deprecated contract. The plan is built around state machine inputs (Triggers
(Boolean), Numbers: emotion, energy, confidence). As of rive 0.14.x, Rive marks state-machine input
and text-run access as deprecated in favour of View Model data binding (rive 0.14.10 changelog).
The existing scaffolding pins rive: ^0.12.4 (pubspec.yaml) and avatar_engine.dart:106-219 wires
SMINumber/SMITrigger, so replace it rather than extend it. Plan for rive ≥ 0.14.11 with rive_native,
RiveWidgetController, DataBind from day one.
2. "Triggers (Boolean)" is a category error. Triggers and booleans are different property types.
correctAnswer, celebrate and the others are Triggers; isListening and isSpeaking are Booleans, or
better, one Enum.
3. 0–100 magic numbers for categorical things. "Eyes: Neutral (0), Happy (33), Excited (66), Curious
(100)" and "Mouth: Neutral 0 ... Frown 100" encode categories as a continuous number. Blending
between 33 and 66 produces in-between faces nobody designed, and the codes are undocumented.
Per the Rive skill guidance: closed sets are Enums (expression:
neutral|happy|proud|curious|concerned|surprised|thinking|encouraging). Continuous dimensions
are normalised Numbers 0..1 (intensity, energy, gazeX/Y in −1..1). The specs already disagree
three ways, so settle one contract before drawing: assets/rive/README.md says emotion 0–5 and
confidence 0–1; Tope's plan says 0–100; avatar_engine.dart adds
mouthOpenness/lipRounding/mouthShape.
4. No lip-sync contract. "Jaw movement for speech" is not lip-sync. A speaking tutor in a pronunciation
app needs viseme-accurate mouths. The current lip_sync_engine.dart:184-230 maps letters to
visemes ("simplified version, production would use phoneme analysis"). Plan the real pipeline from
<!-- page 12 -->
day one (§4.3), because letter mapping fails on digraphs (Yoruba gb, kp), nasal vowels, Zulu clicks
(c/q/x) and Amharic syllabary.
5. One monolithic state machine. Body states, facial expression, gaze, blink and mouth all fight for
the same timeline. Use layers: L1 body/gesture, L2 expression, L3 gaze/head, L4 blink (autonomous),
L5 mouth/viseme (driven every frame during speech). Layers must not key the same properties (Rive
skill: "avoid layers unintentionally animating the same property").
6. No nested artboards / components. Hair, headwear and garments should be nested artboards
swapped through Artboard properties in data binding, not visibility toggles of every variant (file
size and draw-call bloat). The plan's "Rive Solos or Visibility toggles" approach does not scale past
about 10 options.
7. No cultural design bible. The plan's hair library is "Afro, Crop, Braids, Ponytail, Locs, Modern". There
are no named regional styles (Fulani braids, Shuku, Bantu knots, Irun kiko threading, cornrows,
Ethiopian albaso), no headwear (gele, fila, kufi, tignon, duku, Maasai beadwork, Hausa hula), no
textiles, no skin-tone system (needs at least 10 tones with correct undertones and lighting), no
scarification or tribal marks policy (cultural sensitivity: opt-in, reviewed), and no disability
representation (glasses, hearing aids, wheelchair-seated pose, vitiligo, albinism, which matters in
African contexts).
8. 64 px legibility is ignored. A 200×200 artboard scaled to 64 px loses brows and pupils. Silhouette
and expression must read at 32, 48 and 64 px. Make a dedicated "chip" artboard: simplified face,
exaggerated brows and mouth, 2-px minimum strokes at 64 px, no thin hair strands, and test it as a
1-bit silhouette.
9. Add a runtime, performance and accessibility contract. The plan needs: file-size budget per
artboard, draw-call budget, renderer choice (Rive Renderer vs Flutter/Impeller), offscreen pause,
battery behaviour, reduced motion (idle loops stop, blinking continues), and screen-reader semantics
("Polie looks proud").
10. Add economy and identity design. Avatars are a retention engine only if they express identity and
progress. Decide up front what is earned, what is bought, what shows mastery, and what is shared
(§4.4).
4.3 Production contract (View Models) to build against
File: lingafriq_cast.riv
Artboards: Character (full), CharacterChip (64px), Bust (chat/persona), + nested: Hair/*,
Headwear/*, Top/*, Bottom/*, Accessory/*, Prop/*
State Machine: CharacterSM with layers:
L1 Body (activity enum)
L2 Face (expression enum + intensity)
L3 Gaze/Head (gazeX, gazeY, headTilt)
L4 Blink (autonomous; blinkRate)
L5 Mouth (viseme enum + jawOpen, driven per frame)
ViewModel CharacterVM
activity: Enum(idle, listening, thinking, speaking, celebrating, encouraging, hinting,
sleeping) app→rive
expression: Enum(neutral, happy, proud, curious, concerned, surprised, playful, focused)
app→rive
intensity: Number 0..1 (default 0.6)
app→rive
energy: Number 0..1 (time-of-day + streak mood)
app→rive
gazeX/Y: Number -1..1 (look at the word being taught, at the mic button, at the user)
app→rive
viseme: Enum(sil, PP, FF, TH, DD, kk, CH, SS, nn, RR, aa, E, I, O, U, + lab-velar KP/GB,
click C/Q/X, nasal N~) app→rive
jawOpen: Number 0..1 (from audio RMS, smoothed)
<!-- page 13 -->
app→rive
correct, incorrect, celebrate, levelUp, wave, nod, shrug: Trigger
app→rive
skinTone: Color; hairColor: Color; outfitPrimary/Secondary: Color
app→rive
hair, headwear, top, bottom, accessory, prop: Artboard properties
app→rive
reducedMotion: Boolean
app→rive
tapped: Trigger
rive→app
Lip-sync pipeline: the TTS or recorded audio comes with phoneme timings, either from forced alignment
(Montreal Forced Aligner with per-language dictionaries, or a CTC aligner on an Omnilingual-ASR/wav2vec2
encoder) or from the TTS engine's own alignment. Phonemes map to visemes through a per-language
table (extend PhonemeVisemeMap), so the app schedules viseme changes against the audio clock and adds
jawOpen from audio RMS for liveliness. Fallback for unaligned audio: RMS-only jaw. Never use letter-based
mapping. Tooling and licences (Omnilingual CTC aligner, Apache-2.0; Rhubarb Lip Sync, MIT) are in
LINGAFRIQ_AI_MODEL_STACK.md §3.8.
4.4 Cast, customisation and economy
Cast: Polie (guide), plus the village archetypes already used in onboarding (Elder, Weaver, Griot,
Timekeeper, Rhythm Master, Pathfinder), plus per-language hosts (a Lagos host, an Accra host, a
Nairobi host, a Durban host...). Each has a voice and a personality bible. The learner's own avatar
uses the same rig.
Customisation that means something: items unlock by demonstrated skill, not just XP. Examples:
finish the Yoruba "Greetings & respect" can-do → unlock fila and gele. Pass a tone checkpoint →
"Talking Drum" prop that animates to your best phrase. Region-authentic outfits are reviewed by the
cultural consultant, and each item has a 1-line cultural note ("Aso-oke: hand-woven by Yoruba
weavers, worn at ceremonies").
No pay-to-look-better pressure on kids; cosmetics bought with real money are adult-only and
never loot boxes (§12).
Social use: stickers and reactions generated from the rig (the avatar saying a learned phrase with
correct mouth shapes) for Village chat. Shareable "I can now say..." cards render the avatar speaking
the phrase, with audio.
4.5 Flutter integration
Upgrade to rive ^0.14.11, call RiveNative.init() in main.dart, load files once into a cache, and use
one RiveWidgetController per visible character. Pause offscreen; drop to the static chip in long lists.
An AvatarDirector service (Riverpod) translates learning events (answer graded, mic open, AI
streaming, persona emotion tag) into View Model writes, so screens never touch Rive directly. Build it
fresh; retire the three scaffolding engines in avatars/*.
Budgets: ≤ 300 KB per character file with nested artboards streamed (assets via Rive's out-of-band
asset loading), ≤ 2 ms frame cost on a 2020 mid-range Android (e.g., Tecno/Infinix class, which
matters for the African market), 60 fps target and graceful at 30.
Tests: golden tests of chip renders at 32/48/64 px; a contract test that fails CI if a View Model
property named in Dart is missing from the .riv (load the file and enumerate properties).
<!-- page 14 -->
4.6 Build order, deliverables and acceptance criteria (for Tope / Cursor)
Step Deliverable Done when
1. Character bible 1 page per character: personality, voice, region, palette,
silhouette sketches at 64 px; cultural consultant sign-off
Silhouettes are distinguishable as 1-bit
shapes at 48 px; reviewer approves dress and
hair references
2. Rig spike (one
character, Polie)
lingafriq_cast.riv with Character + CharacterChip
artboards, layers L1–L5, the full CharacterVM from §4.3
(enums, not 0–100 codes)
Every property in §4.3 exists and is bound;
enumerating the View Model in a Dart test
matches the contract
3. States Idle, listening, thinking, speaking, correct, incorrect,
celebrating, encouraging, hint, levelUp, lessonComplete
as activity values and triggers
Each state reads correctly at 64 px in a 5-
person hallway test; transitions ≤ 300 ms; no
layer keys another layer's properties
4. Lip-sync Viseme enum incl. KP/GB, click C/Q/X, nasal; sidecar
timing JSON from forced alignment
Native viewers rate sync "natural" on ≥ 80%
of 20 clips per Stage-1 language
5. Customisation Hair/headwear/garments as nested artboards (start with
6 hair styles from the expanded library, 4 headwear, 10
skin tones)
File ≤ 300 KB; swapping an item causes no
frame drop on a Tecno/Infinix-class device
6. Integration rive ^0.14.11 + rive_native, AvatarDirector,
reduced-motion path, semantics labels
≤ 2 ms/frame on the reference device;
offscreen pause verified; screen reader
announces expression changes
7. Cast expansion Village archetypes, then per-language hosts Each passes steps 3–6
Keep a single .riv source in version control with a changelog, export from one Rive file version, and add a
CI contract test (step 2) so art and code can't drift.
5. Onboarding and first-session magic
5.1 Current state
Order: splash (1.2 s forced delay) → 9-step "village" questionnaire → placement dialog → login/sign-
up → (email verification) → home. A first-time user answers about 9 screens of questions and creates
an account before hearing one word of the language.
Steps (unified_onboarding_screen.dart:58-123): Welcome, Elder (native language), Weaver (target
language), Elder's Question (age + why), Path Chooser (goal), Rhythm Master (learning style),
Timekeeper (schedule), Griot (tone and gamification), Naming Ceremony (profile).
Defects: answers serialised with Map.toString() (P0-21); "learning styles" have no evidence base
(matching instruction to a self-reported style does not improve outcomes; Pashler et al. 2008 and
later reviews), so the step wastes time and sets false expectations; age is collected with no
consequence (P0-10); every release resets onboarding (P0-20); three alternative onboarding flows sit
in the repo unused.
5.2 Target flow: "speak in 60 seconds, account later"
1. Language pick, one screen. Show the languages with a native speaker greeting audio on each tile
(tap to hear "Ẹ kú àbọ̀", "Karibu", "Sannu"). Detect a heritage link with one optional chip: "My family
speaks this".
2. Instant first win ( ≤ 60 s). Polie greets the learner in the language with the Tone Lens visible. The
learner taps to hear, then says it back. The real scorer gives honest, encouraging feedback on the
one syllable that matters ("your kú was mid; lift it high"). The learner has now spoken a tonal greeting
correctly. That moment is the hook, and no competitor does it well for African languages.
<!-- page 15 -->
3. Micro-placement, adaptive and disguised as a conversation (2–3 min, skippable). Three or four
items selected by item response theory (IRT): recognise a greeting, pick a reply, understand a short
audio. Heritage speakers often understand far more than they can say, so measure listening and
speaking separately.
4. Goal and time, one screen. "Why?" (heritage/family, travel, partner, work, school, curiosity) and
"How much time a day?" (5/10/15/20). The why drives content themes (family vocabulary first for
heritage learners).
5. Age assurance before anything social (neutral date-of-birth picker, not leading). Under-13 goes to
the guardian flow (§13.3).
6. Save progress = create account (passkey, Google, Apple or email magic link). Prompt only after the
first lesson is finished: "Save your progress and your streak."
7. Notifications ask in context after lesson 1: "Want a nudge at 7:30 pm? That's when you practised
today."
8. Avatar creation is optional and later (unlocked after lesson 2), framed as part of the village story.
5.3 Details that make it feel premium
Persist every step locally (typed, jsonEncode) so a kill or crash resumes exactly where the learner left
off.
Honest copy. Replace "Who are you, and why do you seek knowledge?" (:774) with plain questions;
keep the village warmth in the art and voice, not in riddles. Grade-7 reading level (Playbook §15.4).
Localised onboarding. French, Portuguese, Arabic and Swahili UI for continental learners
(Francophone Africa is a huge market for Wolof, Lingala, Bambara).
Measure it: funnel events per step, time-to-first-spoken-word, D1/D7 retention by entry path,
placement accuracy vs later performance.
6. Pedagogy and curriculum
6.1 Curriculum audit (measured, not sampled)
Bundle Shipped in app? Content Verdict
lingafriq_FINAL_curricu
lum/languages/*.json (7
langs)
Yes (pubspec.yaml assets);
master index loaded first
(curriculum_service.da
rt:113-118)
1 lesson per level, "vocab":
[{"word":"example","meaning":"sample"}
], grammar "Sentence structure","Verb
tense usage" for Yoruba
Placeholder
curriculum_bundle/curri
culum/* (7 langs, A1–B1)
Yes, fallback "word1a", "example meaning", "Sample
MCQ", answer "a"; Yoruba A1/A2/B1 files are
52,978/52,979/52,979 bytes (templated)
Placeholder
curriculum_expanded_bun
dle/*
Duplicated inside
lingafriq_full_curricu
lum_bundle/ (shipped)
"Yor_word1a", "Example sentence with
Yor_word1a."; also ships .py import scripts
and a .dart file as app assets
Placeholder
assets/data/lingafriq_a
uthentic_curriculum_a1_
c2.json (15 keys, 14 langs +
duplicate pidgin)
Yes, preferred Real phrases with correct-looking diacritics, but
see below
Thin
template
The "authentic" file in numbers (script over all lessons): - 126 lessons per language, but only 85 (Lingala)
to 111 (Yoruba) unique vocabulary items per language. A real A1 alone needs about 500–800 items; B2
needs about 4,000; C2 is beyond 10,000 word families. - Every dialogue repeats lines (126/126 for each
language). Example, Yoruba A1 U1 L1: A: "Mo ń kọ́ èdè Yorùbá" / B: "Orúkọ mi ni" (an unfinished "My name
is...") / A: "Ó dára", then the same three lines shuffled. This is not a conversation. - Grammar is two generic
<!-- page 16 -->
sentences pasted into 1,546 lessons: "Pattern: subject → verb → object" and "Listen for the verb stem;
affixes carry tense and person". Somali and Amharic are SOV. Yoruba, Nigerian Pidgin, Twi and Ewe mark
tense and aspect with preverbal particles, not affixes, and Yoruba verbs don't inflect for person. Teaching
this is actively harmful. - cultural_notes at unit level is a template ("Yoruba cultural immersion for
Discovery & Sound."). - Three identical 11.3 MB copies ( ...a1_a2_b1.json, ...a1_c1.json, ...a1_c2.json share
md5 20c36058...), about 34 MB of APK bloat, plus the duplicated bundles. - Zero audio references in any
curriculum file. audio_manifest.json lists 1,363 entries pointing at assets/audio/... and
cdn.lingafriq.com/audio/v2/... with non-ASCII diacritic filenames (e.g., yoruba-mo-ń-kọ-èdè-yorùbá.mp3).
That breaks across NFC/NFD normalisation (macOS/iOS file systems, some CDNs). Note also that the file
name drops the tone mark on kọ́ while the text keeps it, so file-name and text keys will not match reliably.
assets/audio is not in pubspec.yaml assets [Unverified: media was stripped from the copy]. - Sample
label errors to send to native review: Twi C1 "Idioms" subtitled Akontabuo (which means
accounting/calculation, not proverbs; proverbs are mmɛ/ɛbɛ), Twi A1 Akyiade for "Greetings" [needs native
check].
Game content (assets/data/game_content.json, 1,409 words across 14 languages, about 85–118 each):
phonetic_guide is a copy of tonal_note for all 1,409, so there is no IPA or syllable breakdown. The first
entry teaches a false tone rule (P0-17). 3 topics are truncated mid-parenthesis.
UI translations: app_yo.arb has 62 of 103 keys and no Yoruba tone marks or subdots ("E kaabo si
LingAfriq" should be along the lines of "Ẹ káàbọ̀ sí LingAfriq"; "Tesiwaju" → "Tẹ̀síwájú"). A Yoruba app that
writes Yoruba without diacritics tells Yoruba speakers it isn't serious.
Offline phrase packs (services/offline_phrase_pack_manager.dart:561,
services/translation/offline_translation_service.dart:554): "Omo", "Eniyan", "Okunrin" without
diacritics (Ọmọ, Ènìyàn, Ọkùnrin).
6.2 Learning science the app should be built on
Principle What it means for LingAfriq Current
Comprehensible input
(Krashen; input slightly
above level)
Every unit is anchored in authentic-style audio stories and dialogues at i+1,
with graded readers and listening first
Template dialogues
Retrieval practice and
spacing
Every item has a memory state; sessions are built from due items + new
items; FSRS-6 scheduler (open-source, benchmarked well ahead of SM-2)
running on device with server sync, parameters optimised per learner
after about 1,000 reviews
4 competing SRS
models
Interleaving and
variability
Mix item types (listen, say, choose, build, translate), voices
(male/female/elder/child), and contexts for the same item
Each game is siloed
Desirable difficulty
with high success
Aim for about 80–85% success; adapt in real time Fixed
Output and
interaction (Swain,
Long)
Speaking from session 1; negotiated meaning with Polie; recasts rather
than red marks
Text-heavy
Explicit focus on form,
minimally
Short grammar "aha" cards with contrastive examples, then practice.
Grammar is taught as patterns
Generic sentences
Tone and orthography
as first-class skills
Tone perception (minimal pairs: Yoruba ọkọ́ hoe / ọkọ̀ vehicle / ọkọ
husband), tone production with pitch feedback, diacritic typing practice
with a tone-aware keyboard, downstep for Igbo, Hausa vowel length and
tone (usually unwritten, so taught via audio), Zulu/Xhosa clicks and
depressor consonants, Amharic fidel syllabary, Wolof vowel length
Tone trainer forces a 3-
tone model on all
languages, mid tone
written as ā (non-
standard for Yoruba)
Can-do outcomes Every unit maps to CEFR / ACTFL can-do statements ("I can greet an elder
appropriately in the morning and respond to their greeting"); learners
self-assess and are tested on them
Objectives are
templates
<!-- page 17 -->
Principle What it means for LingAfriq Current
Mastery learning A unit is "mastered" when its can-dos are demonstrated (speaking +
listening + reading) and its items reach a stability threshold, not when
screens are clicked
Unlock rule
previous_lesson_co
mpleted
Feedback quality Immediate, specific, actionable ("lower the second syllable"); elaborated
feedback beats right/wrong
Random scores in places
Cultural pragmatics Greetings by time and status, honorifics (Yoruba ẹ vs o), kinship terms,
prostration/kneeling customs, proverb usage; taught as communicative
competence
Mostly notes
Motivation (self-
determination
theory)
Autonomy (choose themes), competence (visible skill growth), relatedness
(family/community). The heritage angle is the strongest motivator: "say it
to your grandmother"
Streak pressure
6.3 Learner model (one, not four)
A single Learner Knowledge Graph per user and language: - Nodes: lexemes (with senses), grammar
patterns, phonological skills (each tone pattern, each difficult phoneme), pragmatic skills, can-do
statements. - Per node: FSRS memory state (stability, difficulty, retrievability), production vs recognition
strength, last evidence, error taxonomy counts (tone error, segmental error, word order, register). -
Evidence sources: lesson items, games, Polie conversations (graded turns), persona missions,
pronunciation attempts. Each event goes into the knowledge graph through an idempotent event log
(learning_event with client_event_id). - Uses: session builder, Polie's prompt context ("learner struggles
with low-tone on àárọ̀; recycle it"), persona mission targets, teacher dashboards, credential evidence. -
Privacy: on-device first; raw audio is not stored unless the learner opts in.
6.4 Languages: Stage 1, then as many as possible, as fast as possible
Goal: breadth is a first-class goal. LingAfriq should teach dozens of African languages within two years
and keep going, without ever shipping unvalidated content. Breadth comes from (a) a repeatable content
and QA pipeline, (b) the readiness levels below, so a language can go live early at a small but correct scope
and deepen over time, and (c) an AI stack chosen for long-tail coverage (LINGAFRIQ_AI_MODEL_STACK.md §2
and §4).
Readiness levels (each language moves up independently): - L0 "Taste": greetings, numbers, 50–100
words, a culture card; native-recorded audio. - L1 "Starter": A1 with native audio for every item and ASR
"were you understood?" feedback. - L2 "Core": A1–A2 with tone and pronunciation scoring, dynamic TTS,
and AI tutor modes. - L3 "Full": A1–B1, realtime voice conversation, personas, and checkpoints toward the
credential.
Stage 1 (Wave 1, building now): 7 languages. Yoruba, Igbo, Hausa, Nigerian Pidgin (Naijá), Swahili,
isiXhosa, isiZulu. Target: all seven at L1 within the first quarter of the content programme and L2 within
two quarters, with L3 first for whichever languages pass the realtime and persona evals. AI coverage
check: - ASR: Intron covers all seven (code-switching in six). - Dynamic TTS: - Intron covers yo, ig, ha, pcm
and sw. - Azure covers isiZulu. - isiXhosa needs a commissioned custom voice, because no commercial
vendor voice exists. - Realtime native audio: Gemini Live covers yo, ha, sw and zu; ig, pcm and xh use the
cascade. - Tone scoring: in-house. It matters most for yo, ig and ha.
Wave 2 (next, about 14 languages; start L0 once Stage 1 reaches L1): Amharic, Twi (Akan), Somali,
Kinyarwanda, Afrikaans, Shona, Wolof, Oromo, Luganda, Lingala, Sesotho, Setswana, Chichewa/Nyanja,
Malagasy. They were chosen for speaker numbers, diaspora demand, and existing vendor coverage (most
have Intron ASR, Gemini Live or Google support), which makes them the fastest to bring to L1/L2.
<!-- page 18 -->
Wave 3 (about 25 languages; L0 → L1): Tigrinya, Ewe, Fon, Fula/Fulfulde (Latin + Adlam), Bambara (Latin +
N'Ko), Kikongo, Kikuyu, Dholuo, Kirundi, Tamazight (Tifinagh + Latin), Ga, Efik/Ibibio, Tiv, Kanuri, Edo (Bini),
Sango, Krio, Cape Verdean Kriolu, Sepedi (Northern Sotho), Xitsonga, Tshivenda, siSwati, isiNdebele,
Kamba, Mauritian Creole. Make a deliberate decision on Egyptian Arabic and Moroccan Darija (large
demand, strong competitors).
Wave 4, the "Living Archive" (50+ languages, community-built L0 starter kits that can grow): Urhobo,
Nupe, Igala, Idoma, Ijaw (Izon), Itsekiri, Ebira, Bemba, Tonga, Lozi, Makhuwa, Sena, Umbundu, Kimbundu,
Tshiluba, Mende, Temne, Dagbani, Dagaare, Mooré, Dyula, Soninke, Serer, Kabiye, Sidamo, Wolaytta, Afar,
Hadiyya, Dinka, Nuer, Acholi, Lugbara, Runyankole, Kalenjin, Maasai, Luhya, Gusii, Chaga, Sukuma,
Nyamwezi, Hassaniya, Nobiin, Khoekhoe (Nama), N|uu (critically endangered; only with community
consent and benefit-sharing), Ge'ez (liturgical), plus Ajami, N'Ko, Adlam, Tifinagh and Ge'ez script tracks.
Partner with Masakhane, Lanfrica/NaijaVoices, African Next Voices, Lelapa, Intron, university linguistics
departments (UNILAG, UI Ibadan, UNN, ABU Zaria, Makerere, UDSM, Wits, UCT, Rhodes, Addis Ababa
University) and community and diaspora associations.
Running total: 7 → about 21 → about 46 → 95+ languages, each at the readiness level its validated content
supports. Dates depend on reviewer capacity; treat these as planning targets, not promises.
How to pick the next language (score 1–5 each, revisit quarterly): speakers (L1+L2) and diaspora demand
(waitlist, search data); availability of paid native reviewers and voice talent; AI coverage (ASR/TTS/MT/LLM
eval results from the AI stack doc); partner support; mission value (endangerment).
6.4.1 The fast-scaling content and QA pipeline ("language factory")
1. Language kit (week 0–1): orthography spec (Unicode, NFC, diacritics, keyboard layout), dialect
standard, phone inventory and tone system, a phoneme-to-viseme table, a seed lexicon from
licensed corpora, and a native reviewer panel ( ≥ 3, paid, contracts with consent and licence terms).
2. AI bootstrap (week 1–3): LLM and MT draft the frequency lexicon, glosses, example sentences,
dialogues within the lexicon, distractors, cultural-note drafts with citations, and eval sets. Spitch
handles tone-mark suggestions for Yoruba, and an LLM with validators handles other languages.
Everything is tagged ai_assisted: true.
3. Native validation (week 2–6): two independent natives plus linguist adjudication for every learner-
facing string. Tone marks, cultural claims and audio are never AI-only. Disagreements become
dialect notes.
4. Audio (week 3–6): native recordings of every item ( ≥ 2 voices at L0/L1, ≥ 4 at L2), forced alignment
for highlighting, scoring references and lip-sync.
5. Speech enablement (parallel): ASR via Intron or Omnilingual, evaluated on a 300-utterance set. TTS
via vendor or custom voice, gated on native MOS and tone-error rate. Tone-scoring calibration with
native judges.
6. Pilot and stats (week 6–8): a beta cohort, item statistics, and the "report a problem" queue.
Promote to the next readiness level only when the gates pass.
7. Throughput target: one content squad (lead, 2 writers, linguist time, per-language reviewer panels)
runs 4–6 languages in parallel, so 2–3 squads clear a wave of 14 within about two quarters
[planning assumption]. Tooling (content studio §14, validators §6.5, eval harness) is shared, so each
new language costs mainly reviewer and voice time.
What AI may bootstrap vs what natives must validate: the full matrix is in LINGAFRIQ_AI_MODEL_STACK.md
§7. In short: AI drafts word lists, glosses, examples, dialogues, distractors, explanations and UI translations.
Natives must approve every learner-facing string, all tone and diacritic marks, cultural notes and persona
facts. Curriculum audio is always human-recorded.
<!-- page 19 -->
Dialect policy: declare the standard taught (Standard Yoruba, Central Igbo + Onitsha/Owerri variants as
audio, Kano Hausa, Asante Twi, Kiswahili Sanifu + Kenyan colloquial notes, Sheng as a fun side track) and
mark regional variants explicitly. The existing dialectPreference model is a good hook.
6.5 Content schema (replace all four bundles)
Lexeme:
id: yo.lex.ọkọ.vehicle # stable, language-scoped
lemma: "ọkọ̀" # NFC-normalised, full diacritics
orthography: {standard: "ọkọ̀", ascii_fallback: "oko", script: Latn}
ipa: "/ɔ̄kɔ̀/" # with tone diacritics or Chao numbers
tone_pattern: [M, L]
syllables: ["ọ", "kọ̀"]
senses: [{gloss_en: "vehicle", gloss_fr: "véhicule", domain: transport, register: neutral}]
minimal_pairs: [yo.lex.ọkọ.husband, yo.lex.ọkọ.hoe]
audio: [{voice_id: yo_f_lagos_01, speed: natural, uri: audio/yo/9f2c...ogg, aligned_phones: [...]},
{voice_id: yo_m_ibadan_02, speed: slow, ...}]
image: {uri, alt_text, cultural_review: approved}
cefr: A1; frequency_rank: 812
provenance: {author, source, licence, created_at}
review: {status: approved, reviewers: [native_1, linguist_1], tone_checked: true, audio_checked:
true, version: 3}
Pattern (grammar): id, description_l1, form, examples[], contrasts[], common_errors[], cefr
Dialogue: id, scene, roles, turns[{speaker, text, gloss, audio, tone_pattern}],
comprehension_items[], can_do_ids[]
Item (exercise): id, type, stimulus refs, answer spec (with accepted variants incl. diacritic-
insensitive matching rules), distractor rationale, IRT params (a, b), skill tags
Unit: id, can_do_ids[], input (story/dialogue), patterns[], lexemes[], items[], speaking tasks[],
culture card, checkpoint
Rules: file names are content hashes (ASCII), never orthography. All text is NFC. The validator rejects
missing tone marks for tonal languages, mismatched audio, unreviewed items, and placeholder patterns
(/word\d|example|sample|lorem/i) in CI.
6.6 Authoring and review pipeline
1. Syllabus design by an applied linguist per language: can-do map, frequency-based lexicon (from
corpora such as JW300 alternatives with clear licences, Masakhane datasets, news, radio transcripts,
plus community elicitation), pattern sequence.
2. Drafting: human writers, with LLMs allowed for variants and distractors only, on a grounded prompt
with the approved lexicon. Every AI-drafted string is tagged ai_assisted: true.
3. Native review, two independent reviewers (different regions where dialects differ) plus linguist
adjudication. Checks: orthography and tone, naturalness, register, cultural appropriateness,
translation accuracy. Track inter-reviewer agreement; disagreement becomes dialect notes, not silent
edits.
4. Audio production: studio or high-quality remote recording with ≥ 2 voices per language at L0/L1
and ≥ 4 at L2+ (gender, age, region), natural and slow takes, forced alignment for word and phone
timings, QA listen-through. Contributors sign clear licence and consent forms with revenue share or
fair payment (the UGC voice contribution feature becomes this pipeline, with consent).
5. Pilot: release to a beta cohort; collect item statistics (p-value, discrimination, time, hint use) and
learner reports ("this is wrong" button on every item, routed to reviewers).
6. Versioning: content packs are semver'd and signed; the app downloads diffs; every item keeps its
history.
<!-- page 20 -->
6.7 How content is displayed across features
One renderer for target-language text (Tone Lens, tap-to-hear, long-press for gloss/IPA/minimal
pairs, save to deck) used by lessons, chat, Polie, personas, games, the magazine and the dictionary.
Diacritic-aware input: a custom keyboard bar for each language (ẹ ọ ṣ + tone keys for Yoruba; i ̣ ọ ụ
ṅ for Igbo; ɓ ɗ ƙ ƴ for Hausa; ɛ ɔ for Twi), with "lenient" grading that accepts missing tone marks in
early levels but always shows the correct form, then tightens with level.
Script learning tracks for Ge'ez/Fidel (Amharic, Tigrinya), N'Ko, Adlam, Tifinagh and Ajami, with
stroke-order animation and handwriting recognition practice.
7. AI modes and voice: best-in-class architecture
7.1 Current state
Three paths to the LLM: direct client calls to Groq/OpenAI/Hugging Face with compiled keys (P0-3),
a backend completion proxy that accepts the client's system prompt (P0-9), and backend persona
chat. Mode logic is spread across ai_chat_provider_groq.dart (2,516 lines),
polie_workspace_screen.dart (6,485 lines), ai/modes/*, ai/pedagogy/*, ai/persona_cognition/* (a
two-pass "self-critique" orchestrator run on the phone).
No streaming on the backend fallback (ai_chat_provider_groq.dart:1302), so release users wait for
full completions.
Client-side post-processing as a safety net: DiacriticsEnforcer.enforceWithMetadata patches
model output. Diacritic restoration is a hard NLP problem; a regex pass can introduce errors as easily
as it fixes them.
Voice: STT through Groq Whisper and a Hugging Face serverless call (lingafriq-voice-
service/main.py:46-60) with no authentication on that service; TTS through device flutter_tts
(most Android/iOS devices have no Yoruba/Igbo/Hausa/Twi voice), MMS-TTS and XTTS-v2 (licensing,
P0-24). The Intron proxy (routes/intron.route.ts, utils/intronLanguageMap.ts) is well built and
never called by the app.
Pronunciation: see P0-18/19. Whisper-family models normalise or drop tone diacritics, so
"toneScore" computed from them (tutor_pronunciation_mode_screen.dart:115) does not measure
tone.
7.2 Target architecture (model choices: see LINGAFRIQ_AI_MODEL_STACK.md)
App (Flutter)
├─ Realtime voice session (WebRTC via LiveKit; you already ship livekit_client)
└─ HTTPS (text modes, grading, content)
│
AI Gateway (backend service, TypeScript or Python)
├─ AuthN/Z, per-user quotas, cost budgets, kill switches, feature flags
├─ Prompt registry (versioned templates per mode; no client prompts)
├─ Grounding: curriculum KG + learner model + persona source index (RAG)
├─ Model router (per language × task × tier), fallbacks, caching
├─ Safety: input/output classifiers, age-tier policies, PII scrubbing
├─ Structured output (JSON schema validation, retries)
└─ Telemetry: traces, token cost, latency, eval sampling
│
Speech stack (self-hosted GPU + vendors)
├─ STT: Intron (African-accent STT, already integrated) | Omnilingual ASR (Apache-2.0, 1,600+
langs) fine-tuned | vendor fallbacks
├─ TTS: licensed/commissioned voices per language (see 7.5)
<!-- page 21 -->
├─ Pronunciation & tone scorer (see 7.4)
└─ Forced aligner (lip-sync + highlighting)
7.3 Modes that should exist (and how each is grounded)
Mode What it does Grounding and guardrails
Polie Conversation Free conversation at the learner's level,
with recasts, a hint ladder, and "say it
better" suggestions
Learner model (known words, target words due), CEFR-
controlled vocabulary; output validator flags out-of-level
words; every turn tagged with the skills practised
Scenario Roleplay Market bargaining, taxi, family visit, clinic,
job interview, church/mosque etiquette
Scenario scripts with goals and success criteria authored by
humans; the model improvises inside them
Tutor: Explain Grammar and usage questions answered
in the learner's L1
RAG over the approved pattern library only; must cite the
pattern card; refuses to invent rules
Tutor: Correct my
writing
Diacritic and tone restoration, grammar,
register
Hybrid: rule and lexicon checks first, model second, with
uncertainty shown ("tone uncertain here, listen to native
audio")
Story Mode Graded micro-stories with audio, tap-to-
gloss, comprehension questions
Generated from the approved lexicon; human-approved
before publishing to the shared library; personal stories
are labelled as AI-generated
Shadowing /
Pronunciation
coach
Listen, repeat, see the pitch contour vs
the native contour, targeted feedback
Real scorer (7.4)
Translator with
teaching
Translate and explain why Only behind a quality gate per language pair; never the
unofficial Google scraper
Live Translate /
Point-and-say
Camera or voice to target language Same; plus a visible confidence indicator
7.4 Pronunciation and tone scoring (the signature capability)
1. Segmental scoring: goodness-of-pronunciation (GOP) using a multilingual CTC acoustic model
(Omnilingual wav2vec2/CTC, Apache-2.0, fine-tuned per language on native recordings; not MMS
weights, which are CC-BY-NC) forced-aligned to the expected phone sequence. Per-phone scores,
with substitutions mapped to learner-friendly advice ("your gb sounded like b; close lips and the back
of the tongue together").
2. Tone scoring: extract F0 (pYIN or CREPE), normalise per speaker (semitones relative to the speaker's
median, z-scored), segment by aligned syllables, then compare the contour to the expected pattern
with a small classifier trained on native recordings, per language. Handle Yoruba H/M/L + glides,
Igbo H/L/downstep, Hausa H/L/falling, Twi H/L, Zulu depressor effects. Output per-syllable tone
correctness with a confidence value, plus a visual of the learner's contour overlaid on the native one
(Tone Lens).
3. Fluency: speech rate, pause distribution, self-repairs.
4. Calibration: collect human ratings (native raters, 1–5) on a few thousand attempts per language; fit
the scorer to agree with them (target Pearson r ≥ 0.7 with raters, inter-rater as the ceiling). Publish
the methodology.
5. Honesty rules: when confidence is low (noise, clipping), say so and ask for a retry; never fabricate a
number. Run on the server at first; distil a small on-device model for offline tone practice later (the
300M Omnilingual variant is a candidate for offline use [Unverified on-device performance]).
7.5 TTS strategy
Commission native voice talent per Stage-1 language ( ≥ 2 voices; mandatory for isiXhosa, which
has no commercial vendor voice) under a commercial licence, then fine-tune a commercially licensed
<!-- page 22 -->
TTS architecture on them. Prefer recorded human audio for all curriculum items and use TTS for
dynamic AI turns.
Vendors to evaluate (verify licences, quality and tone accuracy per language before committing):
Intron (TTS for yo/ig/ha/pcm/sw; STT for all seven), Spitch (yo/ig/ha/pcm), Azure (zu, sw),
Google/ElevenLabs/Gemini TTS (sw; ElevenLabs also ha). YarnGPT is CC-BY-NC-SA and so not usable
commercially. Full licence and coverage research is in LINGAFRIQ_AI_MODEL_STACK.md §3.5. Run blind
native MOS tests with a tone-accuracy rubric.
Never ship a voice that gets tones wrong. For tonal languages, a mis-toned TTS teaches errors at
scale. Gate each voice per language on a tone-accuracy threshold judged by natives.
7.6 LLM choices for low-resource languages
Frontier models handle Swahili, Amharic, Hausa and Yoruba unevenly, and diacritics and tones are
the usual failure point. Use a router: frontier model for reasoning and English explanations; a model
that tests best on each target language for generation (evaluate Gemini, GPT and Claude, plus
commercially licensed open models such as Gemma 3/AfriqueGemma and Qwen3, fine-tuned with
licensed data; Aya models are CC-BY-NC and N-ATLaS is capped at 1,000 users without a licence; see
LINGAFRIQ_AI_MODEL_STACK.md §2.4); always constrain generation to the approved lexicon at lower
levels.
Evals before launch and on every prompt or model change: a per-language test set ( ≥ 300 items
per Stage-1 language, and per language before it reaches L2) scored by natives and automated
checks (diacritic completeness, out-of-level vocabulary rate, factuality for culture, refusal correctness,
persona fidelity). Block deploys on regression.
Cost and latency: cache deterministic outputs (explanations, story drafts), use small models for
classification and grading, stream all chat, set a time-to-first-audio target of under 800 ms for voice
turns and under 400 ms for first text token, and set per-user daily budgets by tier.
7.7 Realtime voice conversation
LiveKit Agents (or similar) running a cascaded pipeline per turn: VAD → streaming STT
(Intron/Omnilingual) → LLM (streaming) → TTS (streaming) → client, with barge-in, end-of-turn detection
tuned for each language's prosody, and avatar lip-sync from TTS alignments (§4.3). Use speech-native
"realtime" models only for the languages where blind native tests show they pronounce tones correctly. A
"push-to-talk" fallback for noisy environments and low bandwidth (Opus at 16–24 kbps; text fallback on
2G/3G).
8. Historical Personas: from chatbot to revelation
8.1 Current state
Two independent systems. Client registry: 27 personas
(ai/personas/historical_persona_registry.dart, 1,455 lines) with eras, core events, voice profiles
and scenario templates whose branches: {} are empty (e.g., :270-272). Backend: seeds in
scripts/extendedHistoricalPersonas/personas-e01...e08.ts with primary_sources fields, but chat uses
a plain system prompt with no retrieval, and responses are stored with sources: [] and a hard-
coded confidence: 0.9 (historicalPersonality.service.ts:195).
The selection screen uses the backend (services/ai/historical_personality_service.dart), which
tries four URL variants per call (:310-313, 366-369, 407-410), so every 404 multiplies latency.
Persona missions use the client Groq key and fail silently in release builds (P0-13).
Safety is a substring blocklist that blocks the core content of these personas: anti-colonial war (Yaa
Asantewaa), apartheid discrimination (Mandela), the Zulu kingdom's military history (Shaka). It also
<!-- page 23 -->
blocks "skill" and "whatever" (P0-14).
Deception: "Do not mention... being an AI model" (P0-15).
Factual slips show the lack of historian review: Nkrumah's languages English/Twi (personas-
e01.ts:20; he was Nzema from Nkroful); "First sub-Saharan colony to reach independence" (:39)
needs nuance (Sudan became independent in 1956).
8.2 Vision: "Sit with history"
Each persona is a short, authored, replayable experience with three layers: a narrative quest, a language
lesson, and a history lesson, all grounded and honest.
Example: "The Golden Stool" with Yaa Asantewaa (Twi, A2–B1, 25 min, 4 chapters). 1. Kumasi, 1900. An
era-accurate illustrated scene with ambient sound (talking drums, market). The learner is a young
messenger. Objective: greet the Queen Mother correctly (honorifics, the Twi greeting sequence). The Tone
Lens is on; the avatar kneels if the learner chooses the respectful option. 2. The demand. The British
governor's demand for the Golden Stool is read in English. Yaa Asantewaa responds in Twi with subtitles
toggled by level. The learner must understand three key sentences (comprehension checkpoint). 3. The
council. The learner argues a position in simplified Twi (scaffolded sentence builders). The persona answers
in character, grounded in sources, and marks clearly when something is inferred ("Historians are not certain
what I said here; the record tells us..."). 4. Aftermath. A historian's note (human-written) and a mini-quiz,
plus a "Primary source" card (photo of an archival document or museum object with attribution) and a
vocabulary set added to the learner's deck.
8.3 Grounding and integrity
Source dossier per persona, curated by a historian: primary sources (speeches, letters, court
records, oral histories), reputable secondary sources, contested points, known myths, and respectful-
portrayal guidance from descendants or community bodies where they exist. Store it as a retrieval
index; every persona turn retrieves from it.
Answer contract: {speech_text, language_teaching_points[], claims:[{text, support:
documented|inferred|legend, source_ids[]}], emotion, next_beat}, validated server-side. The UI
shows a small "Source" chip on documented claims and an "Inferred" label on speculation.
Knowledge horizon: the persona knows nothing after their death. When the learner asks about later
events, the persona answers in character with curiosity ("I did not live to see that; tell me..."). A
classifier decides this, not keyword lists.
Sensitivity rules written with historians: violence is discussed historically and age-appropriately,
never glorified; no slurs reproduced even if in sources (paraphrase with a note); living-memory
figures (Mandela, Sankara, Lumumba) are handled with family/estate guidance and possibly limited
to narrated "as told by" modes. Some figures should get a narrator rather than first person.
Disclosure: a persistent "AI recreation" badge, and an opening line that explains how the persona
was built.
8.4 Craft
Voice: a voice actor per persona speaking the target language with appropriate regional accent,
cloned only with consent and a licence (or synthesised voices clearly labelled as such). Avatar busts
with era-accurate dress, reviewed.
Branching: fill the empty branches with authored beats; let the model improvise between beats and
keep the story on rails.
Classroom mode: teachers assign a persona chapter; students' turns are graded against can-dos; a
debrief sheet is generated for the teacher.
<!-- page 24 -->
Collections: "Queens of Africa", "Scholars of Timbuktu", "Independence Generation", "Writers &
Thinkers" (e.g., Thomas Mofolo, Ahmed Baba, Cheikh Anta Diop), each pairing figures with the
languages they spoke.
Evals: historian-rated fidelity on 50 scripted probes per persona, an adversarial suite (jailbreaks,
anachronism traps, attempts to make the persona endorse atrocities), and language-quality checks
by natives.
9. Community: tribes, villages, classrooms, chat
9.1 Current state
Familiar surfaces that aren't yet learning-native. WhatsApp-style chat (wa-*: status, starred,
media gallery), Snapchat-style (snap-*: camera, stories, streaks), X-style feed (x-*: compose, explore,
lists, notifications), social audio rooms, tribes, villages, classrooms, micro-mentors, friend quests.
Familiar patterns lower the learning curve, which is valuable; but each one is shallow today and none
uses the target language, and together they triple the moderation surface. All are kept and elevated
(§18.6).
Security: P0-4/5/6 (room joins, identity spoofing, global broadcasts). The live socket server's default
origin list includes http://localhost:5500 and http://localhost:3000 in production unless
CORS_ORIGINS is set (socket.service.ts:141-147); a second, unused socket server with '*' CORS sits
in socket/handlers.ts (dead code that will confuse the next developer). Tokens are accepted in the
query string (socket.service.ts:199), where they end up in proxy logs. Tribe, village and competition
channels can be joined by anyone through join_room, and the intended subscription handlers were
never wired up.
Scale: presence and the socket map are in process memory (onlineUsers), PM2 runs a single fork
(ecosystem.config.js:11-12), and there is no Socket.IO Redis adapter, so it cannot scale past one
node. Every connect broadcasts the full online list to everyone (O(N2)).
Safety: no age tiers, no block/mute UX audit, cosmetic toxicity filter, soft-deleted "disappearing"
snaps, external media_url allowed (tracking pixels, malicious content), a public feed by default, and
no CSAM hash matching on uploads.
Fake social proof: mock co-learners in Village flashcards (village/flashcard_focus_screen.dart:26-
34).
9.2 Target: one "Village" social layer built for learning
Principle: every social feature must create language practice with real people or belonging. Copy what made
WhatsApp, TikTok and Snapchat work (speed, voice, ephemerality, creativity), but point it at learning.
Surface What it is Why it is better than a clone
Circles (tribes renamed;
villages and friends kept
as their own places)
Small groups (5–50): family circle, study
circle, class, language village
Small groups have higher engagement and are easier
to moderate than giant rooms
Chat 1:1 and group, text + voice notes as the
primary medium, reactions, replies, read
state (contacts only)
Voice notes are how much of Africa already
communicates; LingAfriq adds learning overlays:
Tone Lens on messages, tap any word to gloss/save,
"check my message" before sending, and optional AI
transcription of voice notes with gloss
Practice Rooms
(alongside Village Radio
audio rooms)
Scheduled or drop-in voice rooms with a
host, topic and level; the AI can act as a
facilitator that suggests prompts and
vocabulary
Structured speaking, not open mic
<!-- page 25 -->
Surface What it is Why it is better than a clone
Clips (the Snap camera
and stories, made
learning-native; the X-
style feed stays as the
Square)
15–60 s vertical video or audio clips:
"phrase of the day", proverb explainers,
tongue twisters, duets ("say it after me"
split-screen like TikTok duets), stitch-style
corrections from native speakers
Short video drives discovery; duets turn content into
practice
Native Corrections Learners post a phrase or voice note;
verified natives correct it (HiNative-style),
with reputation
Peer correction at scale, which also feeds content QA
Classrooms Teacher dashboard (web), roster import,
assignments (lessons, persona chapters,
speaking tasks), auto-graded speaking with
teacher override, progress by can-do, live
sessions (LiveKit) with recording consent
Schools, diaspora Saturday schools and
churches/mosques running language classes are a
real B2B market
Events Seasonal festivals (Ọdún Ọ̀ṣun, Eid, Timkat,
Durbar, Homowo, Umhlanga), live cultural
sessions
Culture as a reason to come back
9.3 Private messaging done properly
E2EE for 1:1 and small groups using MLS (RFC 9420, designed for group messaging) or the Signal
protocol (libsignal). Server stores ciphertext only. Learning overlays (gloss, Tone Lens) run on device;
anything needing a server model is opt-in per message.
Under-18 accounts: no E2EE DMs with unknown adults. Messaging is allowed only within guardian-
approved circles and classrooms, where messages are not E2EE so they can be moderated; this
trade-off is explained to families. Adult accounts get E2EE by default.
Delivery: durable server-side message log with per-device cursors, idempotent client message ids
(the backend already has messageIdempotency.guard.ts, which is good), offline queue, push via
FCM/APNs with data-only payloads (no message content in pushes for E2EE chats).
Media: signed upload URLs, server-side transcoding (Opus for voice, HEVC/AV1 or H.264 for video),
size limits, EXIF stripping, perceptual hashing and known-CSAM matching (PhotoDNA or equivalent
via a vendor) on unencrypted surfaces, hard deletion on expiry.
9.4 Moderation and child safety stack
1. Prevention: age tiers, default-private profiles for minors, no location sharing, no contact discovery
for minors, rate limits on new accounts, friction for first DMs.
2. Detection: multilingual toxicity classifiers evaluated on African languages and code-switching
(Pidgin/English, Sheng, Swahili/English); word-boundary-aware lexicons curated by native
moderators per language (fix the ode/"code" problem); grooming-pattern heuristics; image/video
classifiers; hash matching.
3. Response: block, mute, report on every message and profile in at most two taps; a moderator
console with queues, evidence, and SLAs; escalation to law enforcement and the relevant hotline
(e.g., NCMEC CyberTipline reporting for US-linked CSAM, plus local equivalents) handled by a trained
safety lead.
4. Transparency: community guidelines written in plain language and in the supported UI languages,
appeals, and a periodic transparency report.
9.5 Realtime infrastructure
Socket.IO with the Redis adapter (or a managed service such as Ably/Pusher/Stream Chat if speed matters
more than control), horizontally scaled with sticky sessions; presence in Redis with TTL; per-room
<!-- page 26 -->
authorisation middleware; event schemas versioned and validated (zod) on both sides; backpressure and
per-socket rate limits; load-tested to 10k concurrent connections per node before launch events.
10. Games: fun, educational, and honest
10.1 Current state
About 45 game screens (screens/games/*, games/*) built on a shared "gamekit". Problems: (a) fake scoring
in the speaking games (P0-18); (b) content comes from a 85–118-word pool per language with no audio
and with tone errors; (c) tone trainer applies one H/M/L model with one correct tone per word for all
languages (tone_trainer_game.dart:47-66); (d) games are a separate destination rather than part of spaced
practice, so playing them does not reliably update the learner model; (e) finished game code is unreachable
(Tone Forge, the mastery results screen, and a GameKit rewrite of Proverb Unlocker), and all of it is revived
in §17.5.
10.2 Design rules for every game
Every game is a retrieval or perception exercise in disguise, reads and writes the learner
knowledge graph (§6.3), and uses due items first.
Sessions of 60–180 s, one core verb, instant feedback ≤ 160 ms, juicy but brief celebration, a "why
was I wrong" explanation with audio.
Difficulty adapts (target 80–85% success). Multiplayer is matched by level.
No dark patterns: no energy gates on core learning, no loot boxes, no fake opponents presented as
real people (label bots as bots).
10.3 Ten flagship games (headliners; every existing game stays in the Arcade)
Game Core loop Skill trained Notes
Talking Drum
(tone
perception)
A phrase is "drummed" (pitch contour played on a
talking-drum timbre); the learner picks the phrase
whose tones match, then speaks it and sees their
contour vs the drum
Tone perception
and production
A culturally rooted mechanic
(Yoruba dùndún, Akan atumpan
really do "speak" tone); per-
language tone inventories
Minimal Pair
Duel
Hear one of 2–4 near-identical words (ọkọ/ọkọ̀/ọkọ́),
tap the right picture; head-to-head async with
friends
Tone and vowel
discrimination
Uses the minimal_pairs field;
leagues by accuracy, not speed
only
Market Haggle Voice roleplay with a market trader (AI, scripted
goals): get the price down without being rude;
numbers, politeness and bargaining phrases
Speaking,
numbers,
pragmatics
Scored on goal achieved +
politeness + correctness;
replayable traders with
personalities
Danfo / Matatu
Rush
Listen to rapid conductor calls and stop names; tap
to board the right bus before it leaves
Listening at
native speed
Real recorded audio with
accents; difficulty by speed
Proverb Weaver Assemble a proverb from fragments, hear it, then
pick the situation where it applies
Advanced
vocabulary,
culture
B1+; proverbs reviewed by
elders/linguists
Griot's Story
Chain
Collaborative story: each player records a sentence
continuing the story; AI checks grammar and
suggests a fix; the result plays as an illustrated audio
story
Speaking,
creativity
Great for classrooms and circles
Word Forge
(morphology)
Build Swahili/Zulu words from noun-class prefixes
and verb slots (a-na-ku-penda); see the meaning
change live
Bantu
morphology,
agglutination
Language-specific; Yoruba
variant builds serial verbs
<!-- page 27 -->
Game Core loop Skill trained Notes
Fidel Flight /
Script Sprint
Trace and recognise Ge'ez/N'Ko/Adlam/Tifinagh
characters in a flying game
Script literacy Handwriting recognition on
device
Greeting
Gauntlet
Fast scenarios: time of day × person (elder, peer,
child) × setting; respond with the right greeting and
gesture
Pragmatics Avatar performs the gesture
(kneel, bow, handshake style)
Echo Karaoke
(rebuilt)
Sing or chant short songs, children's rhymes and
praise phrases with a live pitch line
Rhythm, tone,
fluency
Real F0 tracking; licensed or
commissioned music
These ten are the headliners of the Arcade. Several are elevations of existing games (Talking Drum ← Drum
Word and Drum Rhythm; Market Haggle ← Market Bargaining; Danfo/Matatu Rush ← Taxi Survival; Proverb
Weaver ← Proverb Unlocker; Greeting Gauntlet ← Greeting Diplomacy; Echo Karaoke ← Pronunciation
Karaoke). Every other existing game stays on its skill shelf, with its own elevation in §18.5, and Tone Forge
is revived as a featured tone game.
10.4 Meta-game
Weekly Village Festival themes (food, family, travel) that rotate content across all games; a Mastery Map
showing which skills each game improved; co-op goals with circles ("our circle learned 300 words this
week") rather than pure competition.
11. Tutorials and quizzes
11.1 Current state
"Tutorials" are mostly feature tours (features_guide, game_onboarding_overlay.dart, four
unreachable *_preloader.dart help screens, revived as contextual first-use tips in §18) rather than
skill tutorials.
Quizzes exist in four disconnected systems (language quiz, history quiz, random quiz, unit quizzes)
with separate backend models (languageQuiz, historyQuiz, randomQuiz, curriculum unit_quiz).
Placeholder bundles contain "Sample MCQ" with answer "a". There is no item bank, no difficulty
calibration, no distractor rationale and no link to the learner model.
11.2 Tutorials that teach (micro-lessons with a "learn it, see it, try it" shape)
Sound tutorials per language, 60–90 s each with native video of the mouth: Yoruba tones and the
subdot vowels, gb/kp; Igbo vowel harmony and the dotted vowels; Hausa implosives ɓ/ɗ and ejective
ƙ; Zulu/Xhosa clicks c/q/x with the slow-motion mouth view; Amharic ejectives and gemination;
Swahili noun classes (as a visual "class wheel"). Each ends with a 30-second perception check and a
speaking try.
Orthography tutorials: typing diacritics with the LingAfriq keyboard bar; why tone marks matter
(the minimal-pair demo).
Culture tutorials: greeting choreography (who greets first, kneeling/prostrating, handshake styles),
naming customs, taboo topics.
Just-in-time coaching: tips appear the first time a learner hits a pattern, not in a tour at install.
11.3 Quizzes that measure
One item bank (schema in §6.5) with IRT parameters calibrated from pilot data; adaptive placement
and checkpoint tests (CAT) that end in 8–15 items with a reported confidence.
<!-- page 28 -->
Item types: listen-and-choose, tone identification, picture matching, dictation (diacritic-aware
grading), sentence building, speaking prompts scored by the real scorer, short conversation tasks
scored against can-dos.
Feedback design: after every item, show the correct form with audio and the Tone Lens, and for
wrong answers one sentence on why (distractor rationale written by the content team).
Checkpoint per unit maps to can-do statements; passing updates the credential evidence (§12.4).
Integrity for credentials: proctoring only where stakes justify it (the Passport), with clear privacy
terms; never use random or opaque scores for credentials.
12. Gamification and retention without dark patterns
12.1 Current state
XP, three currencies (ngwenya, cowries, ancestral_beads), leagues, hearts (models/userHearts.model.ts),
badges, streaks, magic items, ancestral tree, heritage milestones, competitions, gifting, launch events. The
integrity layer is broken (P0-7/8): currency and points can be self-minted. Push reminders spam and guilt-
trip (P0-23: "Your N-day streak is at risk! ... 🔥 "). Three currencies with unclear sinks inflate and confuse.
12.2 Principles
Reward learning, not tapping. XP is computed server-side from evidence of learning (items recalled
at spaced intervals, speaking tasks passed, can-dos demonstrated), with diminishing returns for
grinding easy items.
One soft currency (keep Cowries: culturally resonant and historically real as money) with clear sinks:
cosmetic avatar items, streak repair, persona chapters early access, donating to a community
language-preservation fund (visible impact).
Streaks that respect life: "weekly streak" option, freeze tokens earned by practice, a forgiving repair
window, and no loss-aversion copy at night. Reminders at most once a day, within the learner's
chosen window and timezone, and quiet hours by default. Celebrate milestones rather than
threatening losses.
Hearts: keep the feature, but move it out of core lessons into an opt-in Challenge Mode (lessons
and games played "on hearts" for bragging rights and a badge). Mistakes are how people learn;
punishing them in core lessons is a Duolingo pattern that drew criticism.
Leagues: opt-in, matched by time zone and activity level, ranked on learning XP; minors see only
circle or class leagues.
Collaborative goals: circle and classroom quests, family challenges ("teach grandma's phrase of the
week back to her"), a "Heritage Tree" that grows as family members learn.
Meaningful status: "Can-do badges" verified by checkpoints ("Can bargain in a market, Yoruba A2")
are shareable and valuable, unlike generic badges.
12.3 Ethical guardrails
No loot boxes. No real-money purchases by minors. No fake scarcity timers. No fake "friends are waiting"
pushes. No mock participants presented as real: replace the hard-coded co-learners in
flashcard_focus_screen.dart:26-34 with real matched learners or clearly labelled practice bots (the group-
study feature stays). Every monetised item states exactly what it does.
12.4 Credentials (Passport)
Rebuild the Passport only after content and scoring are real: evidence-based (a portfolio of passed can-do
tasks plus a proctored CAT), aligned to CEFR descriptors with a published methodology, signed and
<!-- page 29 -->
verifiable (W3C Verifiable Credentials or Open Badges 3.0), revocable.
13. Security, privacy, reliability, performance, offline, accessibility,
i18n, testing
13.1 Security hardening (beyond the P0 list)
Auth: short-lived access tokens (10–15 min) plus rotating refresh tokens stored server-side
(revocable, reuse-detected); move from HS256 shared secrets to asymmetric keys (EdDSA/RS256)
with kid rotation; passkeys first, then Google/Apple sign-in, then email magic link; drop the legacy
Django password hash on next login (rehash with Argon2id); enforce at least 8 characters with a
breached-password check (login accepts anything of 6+ characters, auth.controller.ts:107; the
sign-up rule is unverified). The controller trims JWT_SECRET (auth.controller.ts:23) but the
middleware and socket do not (middleware/auth.middleware.ts:20-27); a trailing newline in the env
var would make every token fail verification in middleware.
API: zod/Joi validation on every route (some exist); object-level authorisation tests for every /:id
route (IDOR suite); remove client-supplied identity fields everywhere; request size limits per route
(the global 10 MB JSON limit, app.ts:162, is too generous).
Logging: stop logging the first 40 characters of the Authorization header
(middleware/requestLogger.middleware.ts:26) and the password length at login
(auth.controller.ts:108-113).
Mobile: certificate pinning is passed as a dart-define but the Android network config leaves pinning
commented out with YOUR_CERTIFICATE_PIN_HERE placeholders
(android/app/src/main/res/xml/network_security_config.xml:17-26); decide and implement
consistently. Use authenticated encryption (AES-GCM) for cached data
(lib/services/offline/cache_encryption.dart:28 uses Encrypter(AES(key)), the encrypt package's
default SIC/CTR mode, with no MAC). Play Integrity / App Attest on the AI gateway and reward
endpoints to cut bot abuse. Obfuscate release builds (--obfuscate --split-debug-info; the release
workflow has split-debug-info, add obfuscate).
Secrets hygiene: gitleaks in pre-commit and CI; a secrets manager (Doppler, 1Password, GCP Secret
Manager); a quarterly rotation calendar. scripts/secrets-hygiene-check.mjs exists; wire it into CI as a
blocking step.
Supply chain: Dependabot/Renovate, npm audit --omit=dev blocking on high, flutter pub outdated
monthly, SBOM generation, pinned GitHub Actions by SHA. The admin panel runs React 18 + Vite 4
(2023-era); upgrade.
Pen test by a third party before any school or child-focused launch.
13.2 Privacy and compliance
Nigeria: NDPA 2023 (it superseded the NDPR as the primary law) and the NDPC's implementation
directive; register with the NDPC as a data controller of major importance if thresholds are met
[verify thresholds with counsel]; DPIA for voice data and minors. Kenya Data Protection Act 2019,
South Africa POPIA, Ghana Data Protection Act 2012, EU/UK GDPR (diaspora users), US COPPA if
any US children use it, plus the UK Age Appropriate Design Code if marketing there.
Voice data is biometric-adjacent: explicit opt-in to store recordings, default deletion after scoring,
separate consent for contributing recordings to model training (with payment or benefit-sharing for
contributors), and data-subject export and deletion (the backend has userExport.ts and
deleteUserAccount; expose both in the app).
AI transparency: label AI-generated content and personas (EU AI Act Art. 50).
Data map and retention schedule per collection (107 Mongo models today); purge jobs, logged.
<!-- page 30 -->
13.3 Minors and families
Age assurance at sign-up; guardian account that links children, approves circles and classrooms,
sets time limits and sees progress; school accounts provisioned by teachers with school consent.
Child experience: no public profile, no DMs outside approved circles, no snaps or public feed, no ads,
no purchases, AI conversations with a stricter policy and no persistent memory of personal details.
A named safety lead, documented incident response, and moderator training on grooming patterns.
13.4 Reliability and observability
Fail loud, not silent. Remove every "return a fake success" path: pronunciation zeros with HTTP 200,
the persona "I hear you", the offline queue stub. Replace with typed errors and visible states.
Startup: parallelise init, defer non-critical services until after the first frame, start Sentry first, and
target <2 s cold start to first meaningful frame on a mid-range Android. Stop the 1.2 s artificial delay.
Backend: one deployable API + separate worker service on a job queue (BullMQ with Redis, which is
already partly present) using leader election for cron; health and readiness probes; graceful
shutdown; at least two API instances behind the load balancer; MongoDB Atlas with backups and
point-in-time restore tested quarterly.
Observability: OpenTelemetry traces across app → API → AI gateway → speech services; RED metrics
per route; SLOs (API p95 <300 ms for reads, chat delivery p95 <500 ms, AI first token <400 ms); cost
dashboards per AI feature; an alert on the "fallback path rate" (how often a fallback ran).
API contract: one versioned OpenAPI spec generated from code, with a generated Dart client;
delete the client's multi-path guessing (lib/services/ai/historical_personality_service.dart:310-
314, which tries five URL variants) and legacyBackendUrlPrefixes of raw http:// IPs
(lib/services/env_config.dart:35-38).
13.5 Offline-first, for real
One local database (Drift/SQLite or Isar) and one durable outbox with idempotency keys,
exponential backoff and a visible sync state. Consolidate the five parallel sync implementations
(offline_handler.dart, background_sync_service.dart, sync_v2_service.dart,
persisted_outbox_service.dart, backend_sync_provider.dart) into one, built on the best of them.
This is infrastructure only: every offline feature (Downloads, Point & Say queue, offline review) keeps
working on top of it.
Downloadable units (content pack + audio, typically 10–30 MB per unit with Opus audio), with
storage management and Wi-Fi-only by default. Offline speaking practice with on-device tone
feedback (distilled model) as a later milestone.
Low-bandwidth mode: text-first AI, compressed audio, image-light UI; respect Android Data Saver.
13.6 Performance
APK/AAB size: remove the duplicated curriculum JSONs (about 34 MB of identical files plus duplicated
bundles, Python and Dart files shipped as assets), the unused fonts, and the 3 developer example
files (move to dev/); older duplicate screens shrink the build as they are consolidated into their
surviving feature (§17.5). Ship large content as downloadable language packs. Target under 40 MB
download.
Split the god files (polie_workspace_screen.dart 6,485 lines, ai_chat_provider_groq.dart 2,516,
api_provider.dart 2,468, game_provider.dart 2,139) into feature modules with clear boundaries.
Image and Rive budgets; const widgets; list virtualisation; avoid rebuild storms from large Riverpod
providers.
<!-- page 31 -->
13.7 Accessibility
Screen-reader labels on every interactive element (471 Semantics( already exist; audit for coverage
and meaningful labels), large-text support up to 200% without clipping, WCAG 2.2 AA contrast,
captions and transcripts for all audio and video, haptic and visual alternatives to sound-only cues,
Tone Lens not colour-only, switch/keyboard navigation on tablets and web, reduced motion, dyslexia-
friendly option (Andika is a good base), and hearing-impaired paths (visual pitch feedback is a gift
here).
13.8 Internationalisation
Move all 1,104 hard-coded UI strings to ARB; professional translation of the UI into French,
Portuguese, Arabic, Swahili, Amharic, Hausa, Yoruba and Igbo, with full diacritics reviewed by
natives; pseudo-localisation in CI to catch overflow; RTL layouts for Arabic/Ajami.
Explanations are delivered in the learner's L1 (French speakers learning Wolof, for example), not
English only.
13.9 Testing and CI/CD
Gates: flutter analyze fatal on warnings for new code; unit tests for the learner model, FSRS,
graders and validators; golden tests for the design system and Rive chips; integration tests for
onboarding → first lesson → sync; backend contract tests from the OpenAPI spec; an authorisation
test suite; content validator (§6.5) as a blocking job; AI eval suite (§7.6, §8) blocking for prompt and
model changes.
Coverage target: 70% on domain logic, not vanity totals. Today there are 64 Flutter test files for 306k
lines and 52 backend tests.
Release: trunk-based with feature flags (a featureFlag.model.ts already exists); staged rollouts (1%
→ 10% → 50% → 100%) with crash-free and ANR gates; Shorebird or similar for Dart patching if policy
allows; remove the auto-increment commit-and-push step in build-and-release.yml:59-66 (CI
committing to the main branch races with developers).
Repo hygiene: move the roughly 470 status Markdown files into /docs/archive, write one honest
README, one ARCHITECTURE.md and one STATUS.md that is generated from tests and feature flags
rather than prose.
14. Admin and content operations
14.1 Current state
lingafriq-admin has 33 pages (lesson builder, quiz builder, lexicon manager, media library, telemetry,
subscriptions, tribes/villages, culture magazine...) but no review workflow, no roles beyond admin, no
content versioning, no audit trail UI, and 0 tests. Lesson drafts autosave to localStorage
(src/pages/LessonBuilder.tsx:258). The app-side native verification tools are dead code.
14.2 Target: a content studio built around review
Roles: Owner, Content Lead (per language), Writer, Native Reviewer, Linguist, Audio Producer,
Historian (personas), Moderator, Support, Analyst. Least privilege enforced on the server.
Workflow: Draft → AI-assist (optional, flagged) → Native review ×2 → Linguist approve → Audio
recorded and aligned → QA → Scheduled publish → Monitor item stats → Revise. Every state change
is audited.
<!-- page 32 -->
Editors that understand the content: a tone-aware text field (diacritic palette, NFC enforcement,
live Tone Lens preview), audio waveform with alignment view, minimal-pair linker, dialogue editor
with per-turn audio, can-do mapper, and an item preview that renders exactly like the app.
Quality dashboards: item difficulty and discrimination, "report a problem" queue, reviewer
agreement, audio coverage per language and level, placeholder detector, untranslated UI string
count.
Moderation console: report queues with evidence, user history, actions (warn, mute, suspend, ban),
appeals, law-enforcement escalation workflow, CSAM handling restricted to trained staff.
Persona console: source dossiers, claims audit, eval results per persona, kill switch.
AI ops: prompt registry with versions and diffs, eval runs, cost per feature, model routing table,
incident switches.
Tech: upgrade to current React and Vite, typed API client generated from OpenAPI, SSO for staff with
mandatory 2FA, server-side sessions or httpOnly cookies instead of sessionStorage tokens,
Playwright tests on critical flows.
15. Analytics, experimentation and copy
North-star metric: weekly learners who demonstrated a new can-do (learning outcome), with
guardrails on D1/D7/D30 retention, minutes practised, speaking minutes, and crash-free sessions.
Do not optimise on streak length alone.
Event taxonomy (one schema, versioned): session_started, item_answered{item_id, correct,
latency, hints}, speech_attempt_scored{phones_ok, tone_ok, confidence}, cando_demonstrated,
ai_turn{mode, tokens, latency, fallback_used}, content_reported. Send on-device aggregates
where possible (privacy).
Experimentation: feature-flag-based A/B with pre-registered hypotheses and minimum detectable
effects; never experiment on minors' safety settings.
Learning-outcome research: an external efficacy study (pre/post oral proficiency interview with
blinded raters) for two Stage-1 languages (one tonal West African language such as Yoruba, one
Bantu language such as isiZulu) within a year. That result is your best marketing asset, and it must be
real (no invented stats; Playbook §9).
Copy: warm, clear, specific; grade-7 reading level; verb-first buttons ("Start lesson", "Hear it again");
name continuity ("Publish" → "Published"); no em dashes in UI strings; no "World-
class/Elite/Seamless" in product copy (Playbook §9 and §15.4). The village voice lives in characters,
not in every label. Error copy follows "what happened, why, what next" (e.g., "Couldn't score that
recording. It was too quiet. Try again closer to the mic.").
16. Prioritized roadmap
Effort key: S ≤ 3 engineer-days · M 1–2 weeks · L 3–6 weeks · XL a quarter or more. Estimates assume a
small team (3–4 engineers, 1 designer, a content lead, and paid native reviewers). They are judgement calls
and should be re-estimated with the team.
<!-- page 33 -->
16.1 P0, week 1–2 ("stop the bleeding")
# Action Fixes Effort
1 Revoke and rotate the Firebase service-account key (firebase-adminsdk-us33e, plus the ...
bc5f413f35 key file loaded by messagingService.ts:29 and any copies that sat in node-
backend/dist/services on the Mac), the Apple .p8 key, and every AI key ever shipped in
an app build. Purge them from git history (git filter-repo) and from every machine and
backup. Add gitleaks to CI.
P0-1/2/3 S
2 Stand up a server-side AI gateway (auth, quotas, server-owned prompts, cost caps) and move
every client Groq/HF/Stability/Replicate/Leonardo call behind it. Ship an app update that
removes the keys.
P0-3/9/13 M
3 Socket lockdown: identity only from the verified JWT, server-authorised join_room, room-
scoped emits instead of io.emit, friend-scoped presence, token from auth not the query
string.
P0-4/5/6 M
4 Make reward endpoints server-only; compute XP from verified events; reconcile balances and
remove fraudulent ones.
P0-7/8 S–M
5 Turn off DMs, snaps, calls and the public feed for under-18s (and for unknown ages) until §13.3
ships; add an age gate.
P0-10 S
6 Replace the toxicity filter with a hosted moderation API plus report/block flows; hard-delete
expired snaps with server-uploaded media only.
P0-11/12 M
7 Persona fixes: AI disclosure, remove "don't mention being an AI", replace the substring safety
filter, show an honest error instead of the canned fallback, correct the Nkrumah data.
P0-13/14/15 S
8 Remove fake scoring (random scores, zero-on-failure HTTP 200s) and keep those games visible
in an honest practice mode (no score shown, "scoring coming soon") until a real scorer exists;
remove the false tone claims and the placeholder bundles from the build.
P0-
16/17/18/19
S
9 Delete the semver logout, fix onboarding persistence, replace the stub offline queue with the
existing persisted outbox (pick one) and stop marking unsent ops complete.
P0-20/21/22 M
10 Notification dedupe (one per user per day, local timezone, quiet hours) and workers run only in
the worker process.
P0-23 S
11 Swap out non-commercial models (MMS-TTS, XTTS-v2, NLLB) and the unofficial Translate
scraper; get legal sign-off on every model and dataset licence.
P0-24/26 M
12 Generic login errors, per-account lockout and backoff, shorter tokens with revocable refresh. P0-25 S
13 RevenueCat webhooks and server-side entitlement checks. P0-27 S–M
16.2 P1, months 1–3 ("make it true")
Action Section Effort
Content studio and language factory (§6.4.1, §14): schema, validators, two-native review, audio
recording and alignment. All seven Stage-1 languages (Yoruba, Igbo, Hausa, Pidgin, Swahili,
isiXhosa, isiZulu) at L1, with native audio for every item; start Wave 2 at L0
§6, §14 XL (content),
L (tooling)
Learner model + FSRS-6 scheduling + one item bank; adaptive placement §6.3,
§11.3
L
New IA (Today / Learn / Speak / Play / Village + Me, Search, Lens, Word Card, All-features directory)
and one design system with tokens; re-render every feature on it; revive the 25 unreachable features
and consolidate duplicate implementations into the surviving feature; retire the six extra design
systems (code, not features)
§3, §17,
§18
L
Onboarding v2: speak in 60 seconds, account later, guardian path §5, §13.3 M
Real pronunciation and tone scoring v1 (GOP + F0 contour against native references) for Yoruba,
Igbo and Hausa first, then the other Stage-1 languages, with confidence and an "unsure" state
§7.4 L
Avatar v1 (first build; avatars don't exist yet): character bible, then Polie plus one host on the View
Model contract, following §4.6 steps 1–6, with lip-sync from aligned audio, all tutor states, verified on
device
§4 L
<!-- page 34 -->
Action Section Effort
Personas v1: five rigorously sourced personas with dossiers, citations, historian review, eval suite §8 L
Village v1 for adults: circles and classrooms with moderation, report/block, server-authorised rooms §9 L
Observability, SLOs, OpenAPI contract with a generated Dart client, CI gates, staged rollouts §13.4,
§13.9
M
Privacy programme: DPIA, data map, retention, export/delete in-app, NDPC registration check,
privacy policy rewrite
§13.2 M
UI string extraction to ARB and native-reviewed translations with diacritics §13.8 M
Gamification rebalance: one currency, ethical streaks, hearts moved to opt-in Challenge Mode §12 M
16.3 P2, months 4–9 ("make it loved")
Action Effort
Stage 1 to L2 (L3 where evals pass). Wave 2 (14 languages: Amharic, Twi, Somali, Kinyarwanda, Afrikaans, Shona,
Wolof, Oromo, Luganda, Lingala, Sesotho, Setswana, Chichewa, Malagasy) L0 → L1. Wave 3 L0 kits begin.
Community contributor programme with paid, credited native speakers
XL
Custom TTS voices for languages without vendor voices (isiXhosa first, then Wave 2 gaps), trained on commissioned
recordings
L
Realtime voice tutor (speech-to-speech with barge-in) on the gateway, with tone-aware feedback L
Flagship games from §10 on real scoring (Tone Lens duels, Market Haggle, Talking Drum) L
Guardian and school accounts, teacher dashboards, curriculum alignment for schools L
E2EE for private messages (MLS), group calls, Stories for circles L
Offline-first content packs with downloadable units and offline review M–L
Passport credential v1 with verifiable credentials, published methodology M
Efficacy study design and recruitment M
Accessibility audit with disabled users and fixes to WCAG 2.2 AA M
16.4 Moonshots (9–24 months)
Moonshot Why it matters Effort
95+ languages via the Living Archive (Wave 4 community
starter kits growing to L1)
Makes LingAfriq the home of African
languages, not just the big ten
XL
Open tone corpus and on-device tone model for 10+ tonal
African languages, built with paid contributors and released
under an open licence
Becomes the industry reference for African
tonal-language scoring; a real moat and a
public good
XL
"Grandma Mode": family members record phrases in their own
dialect and the app turns them into lessons for the
grandchildren in the diaspora
Emotional hook no competitor has;
generates authentic dialect content with
consent
L
Living history: personas grounded in archives (with museum
and university partners) and AR scenes at heritage sites
Turns history into an experience;
partnerships open institutional funding
XL
Ajami, Nsibidi, Adinkra and Ge'ez script journeys Celebrates African writing systems, which
other apps ignore
L
Heritage Language Fund: a share of revenue funds
documentation of endangered languages, with progress shown
in-app
Mission credibility, press, grant funding M
(programme)
Teacher marketplace: verified native tutors for live sessions,
with fair revenue share
Human connection at scale and a second
revenue line
L
<!-- page 35 -->
16.5 What to stop doing
Stop starting new features until the existing 151 are finished and connected. Every one of them is
kept (§18); the next 9 months are about taking each to its potential and wiring it into the learning
loop. Put new breadth into languages.
Stop writing status Markdown files that claim completion; let tests and flags speak.
Stop shipping AI-generated language content without native review.
Stop treating the WhatsApp-, Snapchat- and X-style screens as copies; keep their familiar patterns
and make each one learning-native (Language Status, Clips, the Square with Tone Lens; §18.6), so the
Village becomes something only LingAfriq can offer.
17. Information architecture: every feature has a home
Tope's rule: no feature is lost or cut. Today the app has about 125 named routes (my_app.dart:278-627), a
35-item drawer (app_drawer_material3.dart), 5 tabs (Home, Courses, AI, Social, Profile) and 88 built-but-
unreachable screens. The problem is not too many features. The problem is that nothing tells a learner
which feature to use when. The new IA gives every feature a home, a reason to appear, and a level at
which it opens.
17.1 Navigation map
Five tabs + Me + three global tools.
Surface What lives there Brings together (today's entry points)
Today (tab 1) One 10-minute plan: due reviews, next lesson, a
speaking moment, a challenge, events, streak
Home tab, dashboard, Daily Goals, Quests, Daily
Challenges (revived), Seasonal Events
Learn (tab 2) The Path (units by CEFR level), lessons, Words &
Review, Grammar, Listening, Writing, Tone Gym,
Culture shelf (Magazine, Heritage, History,
Mannerisms, Cultural Hub), Passport, Downloads
Courses tab, Lessons, Authentic Path, Learning
Path, Grammar hub, Vocabulary Builder, Phrase
DNA, Tone & Rhythm, Culture Magazine, Heritage,
Passport
Speak (tab 3) Polie (all tutor modes as chips), Scenarios,
Personas & Missions, Shadowing, Code-Switch
and Respect coaches, Speak Missions, Coach
insights
AI tab, AI Chat, Polie modes, tutor dashboard,
Historical Personas, Persona Missions, Speak
Engine Lab, conversation scenarios
Play (tab 4) The Arcade: every game on skill shelves (Tone &
Sound, Words, Grammar, Speaking, Culture,
Traditional, Multiplayer)
Games catalogues ×3, cultural games, traditional
games, Tone Forge (revived)
Village (tab 5) Map of places, Circles (tribes), Square (feed,
rooms), Chats, Status, Clips, Radio (audio rooms),
School (classroom), Elder Hut (mentors),
Corrections, Create, Contribute
Social tab, Global/Private/Tribe chat, wa-, snap-, x-*,
villages, tribes, classroom, social audio, micro-
mentors, UGC, voice contribution
Me (avatar, top-left) Profile, avatar wardrobe, Progress, Achievements,
Leagues, Family, Plus, Settings, All features,
About
Profile tab, settings, badges, leaderboards, magic
items, features guide, Stitch hub
Search (top bar,
global)
Words ( → Word Card / Living Dictionary), people,
circles, lessons, games, features by name
search_languages_page, community search, people
search
Lens (top bar
camera button,
global)
Point & Say, Live Translate (Conversation Bridge),
Import Media
Drawer items Point & Say, Live translate, Import
Media
<!-- page 36 -->
Surface What lives there Brings together (today's entry points)
Word Card (long-
press any target-
language word,
anywhere)
Meaning, audio (dialects), Tone Lens, examples,
"save", "practise"
Living Dictionary, My Words
Nothing is lost when the drawer goes. The drawer is replaced by Me → All features: an A–Z, searchable
directory of every feature in §18, grouped by hub, with locked ones showing "unlocks at..." and a preview.
Global Search also finds features by name ("ludo", "status", "proverb").
17.2 Sitemap
LingAfriq
Today
Daily plan
Daily Challenges
Quests
Events & Festivals
Streaks
Learn
Path & Lessons
Lesson Recap
Words & Review
Review Rush
Grammar · Phrase
DNA
Listening · Writing
Tone Gym
Culture shelf
Passport · Downloads
Speak
Polie + 6 tutor modes
Scenarios
Personas & Missions
Shadowing
Code-Switch /
Respect
Speak Missions
Coach insights
Play
Arcade shelves:
Tone & Sound
Words · Grammar
Speaking · Culture
Traditional
Multiplayer
Tone Forge
Village
Village map
Circles · Square
Chats · Status
Clips · Radio
School · Elder Hut
Corrections
Create · Verify
Me
Profile & avatar
Progress
Achievements
Leagues · Family
Plus · Settings
All features
About
Global tools, available on every tab:
Lens camera
Point & Say
Conversation Bridge
Import Media
Living DictionarySearch
Word Card
long-press any word
My Words & Review
17.3 Contextual surfacing: features find the learner
Moment Surfaces
Learner finishes a lesson Lesson Recap → "say it" → a matching game ("Tone twins in Play")
A word appears anywhere (lesson, chat, feed, status,
game)
Long-press → Word Card → Living Dictionary, save, practise
Camera button or a lesson about objects Lens → Point & Say; the lesson offers "find 3 of these at home"
Learner struggles with tones Tone Gym drill in Today; Tone Forge and Talking Drum in Play
Learner reaches a scenario unit (market) Scenario Theatre → Market Haggle game → Village Market place
Weekend Circle Clash, Village Radio show, Festival event
<!-- page 37 -->
Moment Surfaces
Learner is A2+ and active "Try Native Corrections", "Post a Status in Yoruba"
Inactivity One honest reminder with a 2-minute session (not 12 pushes a day,
P0-23)
17.4 Progressive unlocking
Adults are never hard-blocked: a locked feature shows "unlocks at..." with a Preview and an "Open
anyway" option. The exception is safety gates for minors (§13), which are enforced on the server.
Stage Opens
Day 1 (no account
needed)
Today, first unit, Polie basic, Lens (Point & Say), 3 games, Word Card, read-only Magazine and Events
Account created Streaks, all games, Circles (join), Square (read), Global handle
Week 1 / A1 unit 3 Personas, Scenarios, Chats (adults), Status, Practice Rooms
A2 Clips, Native Corrections (post), Passport, Code-Switch and Respect coaches, Radio (speak)
B1 Create (UGC), Contribute/Verify (native speakers at any level), host rooms, mentoring
Under 18 Circles only with guardian-approved contacts, no public feed posting, no DMs with adults, no calls;
School and games fully open
17.5 Re-audit of unreachable code: revive, consolidate, never cut
The earlier "183 unused files" figure counted Dart files that no file imports. A stricter reachability scan
from lib/main.dart finds 330 files unreachable, 88 of them screens (an unreachable screen can still be
imported by another unreachable file). Re-auditing all 88 screens:
Revive (25 screen-level features, wired into the new IA): Tone Forge; Conversation Analytics;
Review Dashboard and vocabulary dashboard (Words & Review); Roleplay Completion Summary;
Roleplay Progress Dashboard; Chat Search; Contact Info (block/report); Moderation Tools; Chat
Welcome & Guidelines; Lesson Item Verification; Native Speaker Contribution; Game Mastery
Results; Teacher Classroom Dashboard; Daily Challenges; help preloaders ×4 → first-use tips; Lesson
Recap; Offline Downloads; Global Handle edit; Review Rush (gamified review); Social Audio Following;
Scheduled Sessions; Family/Guardian Dashboard; Subscription (no live paywall exists today); About
Us; Shadowing.
Consolidate (an older or parallel version of a feature that survives; best parts harvested): 5 AI
chat variants → Polie workspace; 4 classroom variants → live classroom; 6 onboarding variants and
placement quiz → unified onboarding (Kijiji's village story kept); 7 game templates, universal
loading/game screens, start guide and victory results → GameKit; games/proverb_unlocker GameKit
rewrite replaces the live random-logic version; older chat, feed, profile, settings, curriculum,
translation, practice and UGC "enhanced" variants → their live counterparts (full list in the per-feature
"Code" lines of §18).
Developer artefacts (not features, so nothing user-facing is lost):
examples/errorhandler_integration_example.dart, examples/performance_utilities_example.dart,
ai_chat/polie_tsx_flutter_mapping.dart. Move them to a dev/ folder outside the app build.
17.6 Exemplar deep-dive: Point & Say
What it is. Point the camera at an object or a sign, learn the word in your language, say it, get feedback. It
is the most "magical" feature in the app and the best hook for the first session.
Current state (evidence). screens/ar/point_and_say_screen.dart (982 lines), route point-and-say
(my_app.dart:500-506) and a drawer item.
<!-- page 38 -->
The photo is downscaled (:176). Object labels come from on-device google_mlkit_object_detection,
best effort (:195-219). Text comes from ML Kit's Latin TextRecognizer via
media_import_service.dart:89-93.
English labels are translated through hybrid_polie/translation_service.dart. The fallback chain is
backend → Hugging Face NLLB-200 (:32, CC-BY-NC, not licensed for commercial use, P0-24) → the
free MyMemory API (:280-290).
The learner records audio. The flow is a voice-service health check → OfflineFallbackPolicy →
PointAndSayQueueService (153 lines; an offline queue with optional tone evaluation via learning v2).
Defects.
1. The target language is typed as free text ("Enter a language (e.g., yoruba)", :427-430), so typos break
it.
2. ML Kit's generic labels are English, coarse ("Food", "Home good") and culturally blind: no ọ̀gẹ ̀dẹ ̀ vs
plantain distinction, no agbada, no jollof.
3. Translation is word-level with a non-commercial model and an anonymous free API, so quality and
licence are both unsafe.
4. There's no native audio for the word, so the learner imitates nothing.
5. The scoring path depends on a placeholder tone endpoint (§1 P0-18/19).
6. Latin-only OCR mangles stacked diacritics [Unverified on device] and cannot read Ge'ez or Ajami.
Elevation: "Lens".
1. Recognise. On-device detection for instant boxes, then a server vision model (multimodal Gemini 3
Flash; AI stack §3.1, with §3.13 for OCR) for culturally specific labels with a confidence score. A
curated African object set (foods, clothing, household items, market goods) is grounded in the Living
Dictionary.
2. Teach. Each tag becomes a Word Card: word with tones, native audio (from the verified lexicon, or
labelled TTS), example sentence, dialect variants, and a plural or classifier where relevant (Zulu noun
class prefixes, Swahili m-/mi-).
3. Say. Hold to speak. Real GOP plus tone scoring (§7.4), with the native contour overlaid on yours.
4. Collect. Words go to a personal Lens collection and into FSRS review. Weekly "Home Safari" quests:
find 5 kitchen items.
5. Share. Optionally turn the photo into a Clip with the phrase overlay (Village → Clips). Faces are
blurred before sharing.
6. Signs and menus. OCR mode translates signs, menus and labels and offers "read it aloud". A
diacritic-restoring pass handles stacked tone marks.
7. Offline. An offline pack of the top 300 objects per language with cached audio. The existing queue
service syncs scores when back online (after the P0-22 fix).
8. Privacy. Photos are processed then deleted unless saved. Minors' photos never leave the device
without consent.
UX and render. Full-screen camera with soft rounded boxes that "breathe". Tapping a box flips it into a
Word Card with the target word at 28 sp, a tone contour line under the syllables and a large mic button.
The language comes from the learner profile (no text box), with a chip to switch. Haptics on a successful
pronunciation; the avatar appears in the corner to celebrate. A reduced-motion variant is included.
Lives in. The Lens button in the top bar on every tab; Learn (object lessons: "find these at home"); Today
(Home Safari challenge); Play (Flashcard Safari uses the same pipeline); Word Card → "see it in the wild".
17.7 Exemplar deep-dive: Living Dictionary
What it is. The app's word store, which learners can add to.
<!-- page 39 -->
Current state (evidence).
Client: screens/vocabulary/living_dictionary_screen.dart (620 lines) with
services/learning/living_dictionary_service.dart. It does GET/POST/DELETE on
ApiContract.learningV2.livingDictionaryEntries, caches in SharedPreferences, and shows an offline
banner (:390) and an "Add to living dictionary" action (:244).
Backend: learningV2.route.ts:150-165 (requireSignin) and
controllers/learningV2.controller.ts:834-930. listLivingDictionary queries {userId} and creates
LivingLexemeModel entries with that userId, so it is a per-user personal word list, not a shared
dictionary.
Admin: a separate CRUD/import exists (routes/admin/livingDictionary.admin.route.ts:13-18,
requireAdmin). User entries have no review status.
Defects.
1. The name promises a living, shared lexicon; the product is a private notes list.
2. Learner-entered words have no verification, so if they were shared they would spread errors.
3. There are no audio, tone, dialect or example fields in the learner flow.
4. It is not linked from lessons, chat or games, so words have to be retyped.
5. The admin lexicon and user entries are separate stores with no promotion path.
Elevation: a two-layer living lexicon.
1. Verified Lexicon (shared). Every entry has a lemma with full tone marks, IPA, part of speech, noun
class, plural, dialect variants, 2–3 native audio recordings (age and gender spread), example
sentences from real corpora, cultural notes, register (formal/elder/slang), etymology and loanword
origin, and related proverbs. Each entry carries a status: AI-drafted → native-verified → linguist-
approved, shown as a badge. This is the engine of the language factory (§6.4.1): one schema for all 7
Stage-1 languages and then every wave.
2. My Words (personal). What the current endpoint already does, kept: saved words, personal notes
and the learner's own recordings. Each saved word links to its verified entry when one exists.
3. Living loop. A learner suggests a word or meaning → it goes to the Verify queue (§18 Village →
Contribute) → native speakers confirm → it is promoted into the Verified Lexicon with credit to the
suggester ("Added by @ada, verified by 3 speakers"). Corrections from Native Corrections and the
Square ("How do you say...?") feed the same queue.
4. Everywhere. Long-press any word in a lesson, chat, feed, status, game or Lens result to open the
Word Card. Global Search starts with words. A daily "word of the day" with its story appears in Today.
5. Pan-African view. "Same idea in other languages": water = omi / mmiri / ruwa / maji / amanzi,
linking languages and celebrating cognates. It powers Multilingual Relay.
6. Offline. A per-language lexicon pack (top 5k entries plus audio) syncs the personal layer.
UX and render. The Word Card is a bottom sheet with a large lemma (tone marks never clipped; Noto Sans
with diacritic-safe line height), a Tone Lens contour, play buttons for each speaker, dialect chips, examples
with audio, and Save and Practise buttons. The full entry page adds proverbs, culture and the "same idea in
other languages" strip. Verification badges are honest ("AI draft, awaiting native check").
Lives in. Global Search (first result type); long-press on any word; Learn → Words (My Words and Review);
Lens results; Village → Contribute → Verify.
18. Feature catalogue and deep-dives (every feature kept)
151 user-facing features, each with its own deep-dive below, grouped by hub. Where several screens
implement one feature (old and new versions), they are one row and the best version wins (consolidation);
<!-- page 40 -->
no feature is dropped. 21 catalogue entries revive previously unrouted screens (25 screen-level
features: some entries revive two or more related screens together; see §17.5). Evidence lines are
generated from a static scan of each file (line counts, direct Groq calls, Random, mock markers, swallowed
catches, hard-coded Text( vs l10n) plus the routing graph; they are signals, not proof of behaviour, and on-
device behaviour is [Unverified] unless a file:line is cited.
State legend: Works = reachable and functional in code; Works (client AI) = works only while a paid key is
compiled into the app (P0-3); Partial = reachable but thin, duplicated or cheatable; Simulated / Faked =
shows fake activity or scores; Unrouted → revive = built but unreachable today.
18.1 Catalogue summary
# Feature Hub State Elevation in one line Lives in
1 Home / Today
session
Today Works Make it a single adaptive "Today" session (10–
15 min), a playlist built by the learner model:
3 due reviews → 1 new input (story or
dialogue) → 1 spea...
Today tab (root).
2 Daily Goals Today Works
(client AI)
Goals become intent-based ("speak for 5
minutes", "learn 10 words", "one
conversation") rather than XP.
Today → goal ring; Me
→ Settings → Goals.
3 Daily Challenges Today Unrouted →
revive
Revive as the Challenge board behind the
Today widget.
Today → Challenges
strip → board.
4 Quests Today Works
(client AI)
Story quests set in the village narrative ("Help
Mama Ngozi prepare for the naming
ceremony": learn kinship words, greet the
elder, haggle for yams in...
Today → Quest card;
Play → Quests.
5 Seasonal Events /
Village Festival
Today Works A cultural calendar: Ọdún Ọ̀ṣun, Eid, Timkat,
Durbar, Homowo, Umhlanga, Kwanzaa and
Heritage Day.
Today → Event
banner; Village →
Events.
6 Streaks & reminders Today Works Ethical streaks (§12): a weekly-streak option,
earned freezes and repair windows.
Today header; Me →
Progress.
7 Lessons map /
Courses
Learn Works One Path map per language: CEFR bands as
regions of a village-to-city journey, units as
stops, each showing its can-do ("I can greet
elders correctly"...
Learn tab (root).
8 Authentic Path (A1–
C1)
Learn Works Becomes the "Real-world track": authentic
materials (radio clips, songs, market
recordings, Nollywood/Bongo scenes,
licensed) with scaffolding, unlock...
Learn → Path → "Real-
world" lane (A2+).
9 Lesson Flow Learn Works An adaptive lesson player: input → noticing
(Tone Lens) → guided practice → speaking →
mini-check, with stages skipped when
mastered.
Opened from Path
and Today.
10 Lesson detail & Level
certificate
Learn Works Lesson detail shows can-dos, words and the
culture note, with a preview audio.
Learn → Path →
lesson; Me →
Credentials.
11 Learning Path
(personal plan)
Learn Works Make it the "My plan" view of Path: the
learner's goal (heritage, travel, exam)
mapped to units and weekly targets, with an
ETA to the next can-do.
Learn → Path → "My
plan".
12 Placement test Learn Works An adaptive 3-minute CAT placement with
listening, reading and one speaking prompt.
Onboarding; Learn →
Path → "Retake
placement".
<!-- page 41 -->
# Feature Hub State Elevation in one line Lives in
13 Grammar Hub Learn Works A Pattern Library: each pattern card has a
plain-language explanation in the learner's
language, 5 audio examples, contrasts and
common errors.
Learn → Patterns.
14 Vocabulary Builder Learn Works Themed word packs (market, family, body,
church/mosque, football) with native audio,
Tone Lens, pictures reviewed for cultural
accuracy, and "add all ...
Learn → Words →
Packs.
15 My Words & Review
(SRS)
Learn Unrouted →
revive
One FSRS-6 review fed by every feature (save
a word anywhere and it appears).
Learn → Words →
Review / Insights;
Today pulls due items.
16 Review Rush
(gamified review)
Learn Unrouted →
revive
Revive as Review Rush: a 90-second sprint
over due cards with combo multipliers that
only reward accuracy.
Learn → Words →
Review → "Rush"; Play
→ Quick games.
17 Listening Practice Learn Works Ear training: graded listening at native speed
with accents (Lagos, Ibadan, Kano, Nairobi,
Durban), a slow-down slider, dictation with
diacritic-aware...
Learn → Skills →
Listening.
18 Writing Practice Learn Works
(client AI)
Write & check: a diacritic keyboard bar, tone-
aware grading that is lenient early and strict
later, and AI feedback through the gateway
that shows unc...
Learn → Skills →
Writing.
19 Phrase DNA Learn Works Turn it into sentence frames you can speak: "I
want to buy ___" with slot fillers from the
learner's own words.
Learn → Skills →
Phrase DNA; Speak →
Warm-ups.
20 Tone & Rhythm
Trainer
Learn Works The Tone Gym, LingAfriq's signature:
perception drills (minimal pairs), production
with a live pitch contour against the native
one, per-language tone...
Speak → Tone Gym
(also Learn → Skills).
21 Tonal Lesson (Village) Learn Works Becomes the story-led tone lesson (an elder
teaches greetings with tone), linked to the
Tone Gym for practice and placed on the Path
where tone is int...
Learn → Path (tone
units); Speak → Tone
Gym → Lessons.
22 Language Quiz Learn Works Merge into the item bank: unit checkpoints
and adaptive quizzes with rationales and
audio (§11.3), while keeping the familiar "take
a quiz" entry.
Learn → Path →
Checkpoints; Today →
"Quick quiz".
23 History & History
Quiz
Learn Works Living History: short illustrated stories with
sources, linked to Historical Personas ("Meet
her" button) and quizzes that cite the story.
Learn → Culture →
History; Speak →
Personas cross-link.
24 Mannerisms &
etiquette
Learn Works Etiquette cards with practice: kneeling and
prostration greetings, handshakes, eating
etiquette, taboo topics.
Learn → Culture →
Etiquette.
25 Cultural Hub Learn Works Becomes the Culture landing inside Learn,
organising Magazine, History, Etiquette,
Heritage archive, Proverbs and Music in one
place.
Learn → Culture (root).
26 Culture Magazine Learn Works
(client AI)
A bilingual magazine: articles at the reader's
level with tap-to-gloss, audio narration by
native voices, "words from this article" to
save, and autho...
Learn → Culture →
Magazine; Today →
culture card.
<!-- page 42 -->
# Feature Hub State Elevation in one line Lives in
27 Heritage Milestones Learn Works Family milestones for heritage learners:
"Greeted grandma in Yoruba", "Understood a
family WhatsApp voice note", "Said a prayer
at a naming ceremony".
Me → Heritage; Today
celebrates milestones.
28 FLB Heritage Archive Learn Works The Living Archive (Wave 4 languages):
folktales, praise poetry (oríkì), songs and
proverbs recorded with community consent,
each with transcript, tra...
Learn → Culture →
Archive.
29 Dialect Preference Learn Works Real dialect lanes: audio variants per item
(Ọ̀yọ́ vs Ìjẹ̀bú Yoruba; Owerri vs Onitsha Igbo;
Kenyan vs Tanzanian Swahili), with notes
where words diff...
Me → Settings →
Language & dialect;
Word Card toggle.
30 Living Dictionary Learn Works See exemplar deep-dive Global: search bar +
long-press on any
word; Learn → Words.
31 Offline Downloads Learn Unrouted →
revive
Revive as Downloads: per-unit packs (text +
Opus audio), storage meter, Wi-Fi-only toggle,
auto-download of the next unit, and an offline
Tone Gym onc...
Me → Downloads;
Path shows a
download icon per
unit.
32 Language detail &
Suggest a language
Learn Works Language pages show speakers, regions,
readiness level (L0–L3) and a sample phrase.
Learn → language
switcher → "All
languages".
33 Passport (proctored
test & credential)
Learn Works The LingAfriq Passport: evidence portfolio
plus an adaptive proctored test, mapped to
CEFR descriptors with a published
methodology, issued as a verif...
Me → Credentials
(unlocks at A2).
34 Lesson Recap Learn Unrouted →
revive
Revive as the 60-second recap after every
lesson: three retrieval questions, the new
words with audio and Tone Lens, one
sentence to say aloud (scored...
End of every lesson
(Learn → lesson →
recap).
35 Polie AI Tutor
workspace
Speak Works
(client AI)
Polie becomes a voice-first companion: hold-
to-talk with live transcript and Tone Lens on
Polie's replies, recasts ("You said X; natives
say Y"), a hi...
Speak tab (root) →
Polie.
36 Tutor: Dialogue mode Speak Works
(client AI)
Scripted-goal dialogues ("order food", "ask
directions") where Polie improvises inside
human-authored scenarios and scores goal
completion, politeness...
Speak → Polie → mode
chips.
37 Tutor: Grammar
mode
Speak Works
(client AI)
Answers come only from the Pattern Library
(retrieval), cite the pattern card, and spawn a
3-item micro-drill.
Speak → Polie → mode
chips.
38 Tutor: Story mode Speak Works
(client AI)
Choose-your-path stories at the learner's
level using known plus due words, narrated
by native TTS, with comprehension checks.
Speak → Polie → mode
chips.
39 Tutor: Translation
mode
Speak Works
(client AI)
Translate & teach: shows the translation,
word-by-word alignment, register options
(formal/informal/elder) and why.
Speak → Polie → mode
chips.
40 Tutor: Pronunciation
mode
Speak Works
(client AI)
Real scoring (§7.4): per-syllable tone and
phone feedback with the native contour
overlay.
Speak → Polie → mode
chips.
41 Tutor: Assess mode Speak Works
(client AI)
An oral proficiency interview lite: a 5-minute
adaptive conversation rated against can-do
descriptors, with native-rater calibration.
Speak → Polie → mode
chips.
<!-- page 43 -->
# Feature Hub State Elevation in one line Lives in
42 Tutor dashboard Speak Works Coach view: Polie recommends the next
mode based on weak skills; the progress tab
shows speaking minutes, tone accuracy trend
and conversation goals a...
Speak → Polie →
"Coach".
43 Shadowing Speak Unrouted →
revive
Revive as Shadow Me: a native clip plays and
the learner speaks along a fraction of a
second behind, with karaoke-style word
highlighting from forced ...
Speak → Practice →
Shadowing; Today
slot.
44 Conversation
Scenarios & Roleplay
Speak Unrouted →
revive
Scenario Theatre: a library of real-life scenes
with goals and a cast.
Speak → Scenarios.
45 Conversation
Analytics
Speak Unrouted →
revive
Revive as "How I speak": words used vs
avoided, average utterance length, code-
switch rate, tone accuracy over time and the
most frequent corrections,...
Speak → Coach →
Insights; Me →
Progress.
46 Speak Engine Lab
(code-switch &
register coach)
Speak Works Split into two named features. Speak → Practice →
Code-Switch Coach /
Respect Coach.
47 Speak Missions Speak Works
(client AI)
Weekly speaking missions in the real world
("Greet three people in Yoruba today and
record one"), with a rubric-based evaluation
and an optional share...
Speak → Missions;
Today → Challenges.
48 Historical Personas Speak Works See exemplar deep-dive Speak → Personas.
49 Persona Missions Speak Works
(client AI)
The story-chapter format from §8: era scene,
objective (greet the Queen Mother correctly),
branching dialogue, cultural debrief with
sources, and a re...
Speak → Personas →
Missions.
50 LingChat AI
conversation
Speak Works Becomes "Practice with Polie" inside chat:
open a practice DM with Polie or a persona
from the chat list, so AI practice sits where
conversations alre...
Village → Chats →
pinned "Polie (AI)".
51 Synthetic Voice Styles Speak Works Voice picker with commercial voices per
language (Intron, Spitch, Azure, custom; AI
stack §3.5): preview, gender, region, speed.
Me → Settings →
Voice; Speak → Polie
settings.
52 Point & Say Speak Works See exemplar deep-dive Global Lens button;
Learn/Speak
contextual.
53 Live Translate Speak Works Conversation Bridge: two people, two
languages, one phone.
Global Lens →
"Bridge"; Speak →
Practice.
54 Import Media (OCR &
clips)
Speak Works Learn from anything: import a song, a
WhatsApp voice note, a sermon clip or a sign
photo, and LingAfriq turns it into a personal
lesson (transcript, g...
Global Lens →
"Import"; share-sheet
target from other
apps.
55 Games Arcade (hub &
catalogue)
Play Works One Arcade with shelves: "For you today"
(games that train the learner's weakest skills),
Tone & Sound, Words, Grammar, Speaking,
Culture, Traditional...
Play tab (root).
56 Game shell, guides &
results
Play Unrouted →
revive
One GameKit frame. Inside every game.
57 Word Match Play Partial (thin
content)
Due-word driven matching with audio on
every tap and a "tone twin" round where two
words differ only in tone.
Play → Words shelf.
<!-- page 44 -->
# Feature Hub State Elevation in one line Lives in
58 Word Match (audio) Play Partial (thin
content)
Listening-first: hear it, match it. Play → Tone & Sound
shelf.
59 Fill in the Blank Play Partial (thin
content)
Cloze from real dialogues with diacritic-aware
typing and a hint that plays the audio.
Play → Grammar shelf.
60 Picture–Word
Association
Play Partial (thin
content)
Culturally reviewed illustrations (local foods,
clothing, places) and a "say it" bonus that
awards points only for real scored speech.
Play → Words shelf.
61 Memory Map Play Partial (thin
content)
Audio-card variant (flip to hear) and family-
themed decks, so heritage learners memorise
kinship terms.
Play → Words shelf.
62 Speed Challenge Play Partial (thin
content)
Adaptive speed that targets 80–85% success,
with a "calm mode" without a timer for
accessibility.
Play → Words shelf.
63 Speed Round Play Partial (thin
content)
Merge mechanics with Speed Challenge as
two modes of one game ("Sprint" and
"Rounds"); both survive as modes.
Play → Words shelf.
64 Story Builder Play Partial (thin
content)
Builds illustrated audio stories from the
learner's level; finished stories can be shared
to circles.
Play → Grammar shelf.
65 Grammar Detective Play Partial (thin
content)
Cases framed as village mysteries; each
solved case unlocks a Pattern Library card.
Play → Grammar shelf.
66 Grammar Jam Play Partial (thin
content)
Rhythm-paced sentence building over
Afrobeats/amapiano-style beats
(commissioned), with rhythm tied to syllables.
Play → Grammar shelf.
67 Greeting Diplomacy Play Partial (thin
content)
Becomes Greeting Gauntlet (§10.3): time ×
person × setting, with avatar gestures and
spoken answers.
Play → Culture shelf.
68 Market Bargaining Play Partial (thin
content)
Becomes Market Haggle: voice roleplay with
trader personalities, real numbers practice,
and politeness scoring.
Play → Speaking shelf.
69 Quiz Chef Play Partial (thin
content)
Recipes as lessons: cook jollof, egusi, ugali or
chakalaka by following spoken instructions in
the target language.
Play → Culture shelf.
70 Roleplay Adventure Play Partial (thin
content)
Shares the Scenario Theatre engine;
adventures become multi-scene trips (Lagos
→ Ibadan → Ọ̀ṣogbo).
Play → Speaking shelf.
71 Taxi Survival Play Partial (thin
content)
Becomes Danfo/Matatu Rush: real recorded
conductor calls at native speed; board the
right bus.
Play → Tone & Sound
shelf.
72 Tone Trainer Play Partial (thin
content)
Per-language tone inventories with minimal
pairs and real audio; feeds the Tone Gym
ladder.
Play → Tone & Sound
shelf.
73 Pronunciation Duel Play Faked → fix Real recording and scoring; async duels with
friends on minimal pairs; honest "practice
mode" (no score) until the scorer ships.
Play → Speaking shelf.
74 Pronunciation Game Play Partial (thin
content)
Merge its rounds into the Tone Gym ladder as
a game mode; real scoring.
Play → Speaking shelf.
75 Pronunciation
Karaoke
Play Faked → fix Becomes Echo Karaoke: real F0 line, licensed
songs, children's rhymes and praise phrases.
Play → Speaking shelf.
76 Emoji Translator Play Partial (thin
content)
Emoji stories → sentences, then send the
sentence as a chat sticker made from your
avatar.
Play → Words shelf.
<!-- page 45 -->
# Feature Hub State Elevation in one line Lives in
77 Elders' Blessings Play Partial (thin
content)
An elder character (avatar) gives blessings for
life events (birth, marriage, travel); the
learner responds correctly.
Play → Culture shelf.
78 Folktale
Reconstruction
Play Partial (thin
content)
Àlọ́ / hadithi / iintsomi storytelling: rebuild the
tale, then narrate it with scoring.
Play → Culture shelf.
79 Clan Lineage Story
Builder
Play Partial (thin
content)
Teaches kinship vocabulary through a family
tree you build; links to the Ancestral Tree
feature.
Play → Culture shelf.
80 Conversation Relay Play Partial (thin
content)
Classroom and circle relay: each player adds a
turn by voice; AI checks; the chain plays back
as an audio drama.
Play → Speaking shelf.
81 Board Word Games Play Partial (thin
content)
Diacritic-aware word puzzles (Wordle-like with
tone marks as a mechanic).
Play → Words shelf.
82 Cultural Games
collection
Play Partial (thin
content)
Becomes the Arcade's "Culture" shelf (the
screen remains as a themed shelf).
Play → Culture shelf.
83 Accent Puzzle Play Partial (thin
content)
Decode the same sentence spoken in
different regional accents; builds real-world
listening.
Play → Tone & Sound
shelf.
84 Call & Response Play Partial (thin
content)
Musical call-and-response with real singers;
responses scored on rhythm and tone.
Play → Speaking shelf.
85 Cultural Etiquette Play Partial (thin
content)
Linked to Etiquette cards; consequences
shown kindly ("Mama is surprised you didn't
kneel").
Play → Culture shelf.
86 Drum Word Play Partial (thin
content)
Becomes Talking Drum (§10.3): drummed
tone contours → words, then speak it.
Play → Tone & Sound
shelf.
87 Flashcard Safari Play Partial (thin
content)
Shares the Point & Say camera pipeline: a
scavenger hunt ("find something red, say it").
Play → Words shelf.
88 Food Quest Play Partial (thin
content)
Market-to-pot quests with regional dishes;
ties to Quiz Chef recipes.
Play → Culture shelf.
89 Liar Liar Play Partial (thin
content)
Social bluffing: friends submit sentences,
some wrong; others spot the lie.
Play → Grammar shelf.
90 Multilingual Relay Play Partial (thin
content)
Pan-African relay: one word passed through
several languages (Yoruba → Swahili → Zulu),
celebrating cognates and loanwords.
Play → Words shelf.
91 Phrase Sniper Play Partial (thin
content)
Listening reflex game with native audio;
accessibility mode without time pressure.
Play → Tone & Sound
shelf.
92 Proverb Unlocker Play Partial (thin
content)
Becomes Proverb Weaver (§10.3). Play → Culture shelf.
93 Rhythm Typing Play Partial (thin
content)
Diacritic typing trainer to rhythm; builds tone-
mark keyboard fluency.
Play → Words shelf.
94 Tongue Twister Race Play Partial (thin
content)
Real scoring with fluency metrics; native
tongue twisters per language; shareable duet
clips.
Play → Speaking shelf.
95 Village Quest Play Partial (thin
content)
Becomes the playable layer of the Village
map: talk to NPCs in each place (market, café,
elder hut).
Play → Speaking shelf.
96 Ayo (mancala) Play Partial (thin
content)
Keep the authentic game; questions become
due-word reviews; online play with friends; a
cultural history card.
Play → Traditional
shelf.
<!-- page 46 -->
# Feature Hub State Elevation in one line Lives in
97 Snakes & Ladders
(cultural)
Play Partial (thin
content)
Family mode for heritage households (pass-
and-play), with questions at each player's
own level.
Play → Traditional
shelf.
98 Language Ludo Play Partial (thin
content)
Multiplayer with friends and circles; speaking
challenges on special squares.
Play → Traditional
shelf.
99 Suwe (hopscotch) Play Partial (thin
content)
Kids-friendly counting and body-movement
vocabulary; a guardian-safe offline mode.
Play → Traditional
shelf.
100 Whot! Play Partial (thin
content)
Card names and calls in the target language
("Check up!", "Last card!"); online play with
friends.
Play → Traditional
shelf.
101 Drum Rhythm Play Partial (thin
content)
Merge with Talking Drum as its rhythm mode;
rhythm mapped to syllable timing.
Play → Tone & Sound
shelf.
102 Tone Forge Play Unrouted →
revive
Revive as a headline Tone & Sound game:
forge words by shaping their pitch contour on
the Tone Lens (drag syllables up and down),
hear the result and ...
Play → Tone & Sound
(featured).
103 Villages hub &
Language Villages
Village Works The Village is the community home: an
illustrated map per language where each
place is a real activity.
Village tab (root).
104 Swahili Village Map Village Works The template for every language: Yoruba
compound, Igbo obi, Hausa birni, Zulu umuzi,
Xhosa village, a Lagos street for Pidgin.
Village → map (per
language).
105 Village Market Village Works Live Market Haggle stall, price and number
drills, and the Magic Items shop (cosmetics
only, no paid power).
Village → map →
Market.
106 Village Café Village Works Doorway to Practice Rooms and audio rooms:
"3 tables open in Yoruba A2 right now".
Village → map → Café.
107 Elder Hut Village Works Home of Micro-Mentors and proverbs: book a
10-minute session with a verified native
speaker or elder, hear a proverb of the day
with its story, and as...
Village → map → Elder
Hut.
108 Practice Rooms &
Sessions
Village Simulated →
make real
Real small-group rooms (2–6 learners at the
same level) with a structured script: warm-up,
topic, roleplay and a recap.
Village → Café →
Practice Rooms; Today
when a room
matches.
109 Flashcard Focus
(group)
Village Simulated →
make real
Replace the mocks with real matched
learners or clearly labelled practice bots;
study together with a shared deck and a race
to recall.
Village → Café → Study
together.
110 Matching Pairs
(group)
Village Works Becomes the multiplayer mode of Memory
Map: turn-based with friends, audio cards.
Village → Café; Play →
Words.
111 Tribes Village Partial
(P0/dupes)
Keep the feature, rename to Circles (study
teams of 5–30) with optional language or city
themes.
Village → Circles.
112 Tribe vs Tribe, Tribal
Duel & Inter-tribe
Leaderboard
Village Partial
(P0/dupes)
Circle Clash: weekend team events where
points come only from verified learning
(reviews done, lessons passed, scored
speaking).
Village → Circles →
Clash; Today → Events.
113 Global Chat Village Works Language Squares: public rooms per
language and level with a "target-language
only" mode, Tone Lens on messages, tap-to-
translate, and one-tap "correc...
Village → Square →
Rooms.
<!-- page 47 -->
# Feature Hub State Elevation in one line Lives in
114 Private Chat (DMs) Village Unrouted →
revive
Language-exchange DMs: each message can
be written in the target language with an
inline "check my message" (AI suggestion
before sending) and a partn...
Village → Chats.
115 Call History Village Works Each call entry shows minutes spoken in the
target language and words learned (opt-in
transcript), and offers "save phrases from this
call".
Village → Chats →
Calls.
116 Chat Welcome &
Community
Guidelines
Village Unrouted →
revive
Revive as the first-entry pledge: 3 friendly
rules (be kind, help learners, no harassment)
with an illustrated agreement, shown once
before the first ...
Village first entry; Me
→ Safety.
117 Moderation Tools Village Unrouted →
revive
Revive as Community Stewards tools for circle
leaders and trusted volunteers: reported
queue, mute/timeout, slow mode, pinned
rules, with escalation t...
Village → Circles →
Steward tools (role-
gated).
118 Social Hub &
Connections
Village Works Language partners: suggested partners who
speak the language you learn and learn the
one you speak (tandem matching), with
friend profiles showing lan...
Village → People.
119 Friend Quests &
Challenge a Friend
Village Works Buddy quests: shared weekly goals (both
practise five days), async challenges on real
skills (tone duel, review race), and nudges
that don't nag.
Village → People →
Quests; Today.
120 Share Progress Village Works Beautiful share cards: the learner's avatar
saying a phrase they learned (short clip),
Passport stamps and streak milestones in the
target language.
Me → Progress →
Share; after
milestones.
121 Social Gifting Village Partial
(P0/dupes)
Gift a lesson / streak freeze / cosmetic using
server-validated currency; send a voice
blessing with the gift ("Ẹ ku odun!").
Village → People →
Gift.
122 Community
Corrections
Village Works Native Corrections: learners post short
writing or audio; verified natives correct with
inline edits and audio; reputation for helpful
correctors; bes...
Village → Corrections.
123 Ancestral Tree Village Works Family Tree in your language: heritage
learners build their family tree with kinship
terms (ìyá àgbà, nne nne, ugogo), record
relatives' names with co...
Me → Heritage; Learn
→ Culture.
124 Micro-Mentors Village Works Book a native for 10–20 minute focused
sessions (pronunciation clinic, heritage
conversation, exam prep), with verified
mentors, ratings, safeguarding...
Village → Elder Hut →
Mentors.
125 Live Classroom Village Works School in the Village: scheduled live classes by
level with a teacher, raise-hand speaker
queue, shared whiteboard with Tone Lens,
auto-notes (transcr...
Village → School.
126 Teacher Classroom
Dashboard
Village Unrouted →
revive
Revive as LingAfriq for Schools: class roster,
assign units, see weak skills per student, run
a live game (Conversation Relay, Liar Liar) on
a project...
Me → Teaching (role-
gated); web.
<!-- page 48 -->
# Feature Hub State Elevation in one line Lives in
127 Social Audio Rooms Village Unrouted →
revive
Village Radio: scheduled audio shows hosted
by natives (folktale night, Pidgin news, Zulu
music talk), learner rooms by level, and
revived following a...
Village → Radio.
128 Status (WhatsApp-
style)
Village Works Language Status: post a daily status in the
target language (text, photo or voice) with a
word-of-the-day sticker; friends react with
corrections or "...
Village → Status.
129 Starred Messages &
Media Gallery
Village Works Starred = Saved phrases: starring a message
adds it to My Words with audio; the media
gallery doubles as a personal phrasebook of
voice notes.
Village → Chats →
Saved.
130 Snaps & Streaks
(Snapchat-style)
Village Partial
(P0/dupes)
Clips: send a photo or 10-second video with a
phrase overlay in the target language
(camera labels from Point & Say suggest
words); streaks count only...
Village → Clips; Lens
camera.
131 Community Feed (X-
style)
Village Works The Square feed: posts in the target language
with Tone Lens and tap-to-translate; native
"verified speaker" badges; threads for
questions ("How do yo...
Village → Square.
132 Explore, Search &
Community Profile
Village Works Explore becomes the Square's discover page
(trending phrases, events, top correctors);
search folds into the global Search;
community profiles show la...
Village → Square →
Discover; global
Search.
133 Create Content (UGC) Village Works Creator Studio: templates for mini-lessons,
quizzes and stories; AI checks for diacritics
and accuracy; native-review queue; published
content credite...
Village → Create
(unlocks at B1).
134 Voice Contribution Village Works Lend your voice: natives record prompted
sentences with explicit consent and licence
choice (AI stack §5), get credited, and earn
currency or cash.
Village → Contribute.
135 Native Speaker
Contribution &
Lesson Item
Verification
Village Unrouted →
revive
Revive as the Verify queue: native speakers
swipe through AI-drafted lesson items
(correct / fix / reject), add audio, and earn
reputation.
Village → Contribute →
Verify (verified
natives).
136 Native Content
Review
Village Works Becomes the reviewer dashboard above the
Verify queue: stats, disagreements and
escalations to linguists.
Village → Contribute →
Review.
137 Profile Me Partial
(P0/dupes)
My LingAfriq identity: avatar (§4), languages
and levels, heritage story (optional), Passport
stamps, contributions and circles.
Me (avatar, top-left).
138 Global Handle (@id) Me Unrouted →
revive
Revive in onboarding (after account creation)
and profile: choose an @handle, with
suggestions in the target language (e.g.
Me → Profile →
Handle; onboarding.
139 Progress Dashboard Me Works Can-do progress: CEFR can-do statements
ticked with evidence, skill radar (listen, speak,
read, write, tone), words known, speaking
minutes and foreca...
Me → Progress.
140 Achievements &
Badges
Me Works Cultural badges earned by real milestones:
first proverb used correctly, 100 tones nailed,
first native conversation.
Me → Achievements.
<!-- page 49 -->
# Feature Hub State Elevation in one line Lives in
141 Leaderboards Me Works Leagues of 30 similar learners with weekly
promotion, an opt-out, and circle and country
boards; points only from verified learning.
Me → Leagues; Village
→ Circles.
142 Magic Items Me Works Cosmetic and helper shop: avatar outfits from
regional designers, streak freezes and hint
tokens; server-validated currency; nothing
pay-to-win.
Me → Wardrobe &
Shop; Village →
Market.
143 Settings, Privacy &
Appearance
Me Partial
(P0/dupes)
Grouped settings: Learning (daily goal,
reminders, voice), Privacy & Safety (who can
message me, discoverability, data
export/delete per NDPA), Appear...
Me → Settings.
144 Subscription & Plans Me Unrouted →
revive
Revive as LingAfriq Plus: free core learning
forever; Plus adds unlimited Polie voice,
offline packs, mentor credits and family
sharing.
Me → Plus.
145 Family / Guardian
Dashboard
Me Unrouted →
revive
Revive as the Guardian hub: link child profiles,
see progress, set safe-social rules (circles
only, no DMs), screen time and a weekly
report.
Me → Family
(guardians).
146 About & Policy Me Unrouted →
revive
Revive About as Our Story: the mission, the
native-speaker community, language-credit
roll (contributors) and AI transparency (which
models, how data ...
Me → About.
147 Sign in, Sign up &
Email Verification
Me Partial
(P0/dupes)
Try-before-signup (first lesson without an
account), then passkey, Google/Apple, phone
OTP (key for Nigeria/Kenya) and email;
generic error messages; ...
Before the app; Me →
Account.
148 Onboarding &
Placement
Me Partial
(P0/dupes)
See exemplar deep-dive First run.
149 Splash Me Works A 1-second greeting in the learner's target
language, with the avatar waving (Rive),
cached for offline.
Launch.
150 Features Guide,
Navigation Hub &
First-use Tips
Me Unrouted →
revive
Becomes the All features directory (A–Z,
searchable, with locked items showing
"unlocks at..." and a preview), which replaces
the drawer so nothing is...
Me → All features;
contextual first use.
151 Staff & Micro-mentor
Reports
Me Works Keep in-app for staff on the go, behind
server-checked roles, with a fuller version in
the admin console (§14).
Me → Staff (role-
gated).
18.2 Today hub (6 features)
Home / Today session
What it is. The landing screen: continue-learning card, streak, stats and shortcuts.
Code. screens/tabs_view/home/home_tab.dart, screens/dashboard/dashboard_screen_material3.dart,
screens/dashboard/modern_dashboard_screen.dart. Scan: 3 file(s), 2,515 lines; 7 mock/fake marker(s);
40 Text( widgets vs 0 l10n lookups; not reachable from main.dart: modern_dashboard_screen.dart.
Current state. Works (routed as tab 1). modern_dashboard_screen.dart is an unrouted earlier version.
Defects. Two dashboards compete. "Continue learning" falls back to a placeholder card when no
lesson is resolved (dashboard_screen_material3.dart:472,616). Shortcuts are a grid of features rather
than a plan for today.
<!-- page 50 -->
Elevation. Make it a single adaptive "Today" session (10–15 min), a playlist built by the learner
model: 3 due reviews → 1 new input (story or dialogue) → 1 speaking moment (Polie or a persona
line) → 1 culture card → 1 game round. One big "Start" button and a ring that fills. Underneath sit a
"Because you..." shelf (contextual surfacing of other features) and the streak/quest strip. Port the
best widgets from modern_dashboard_screen.dart into the new layout (consolidation; the feature
survives).
UX and render. A hero card with an avatar greeting in the target language (Tone Lens on the
greeting). Skeletons matching the layout while loading. Empty state on day 1: "Your first session
takes 6 minutes." Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Today tab (root).
Daily Goals
What it is. Set a daily XP or minutes target and track it.
Code. screens/goals/daily_goals_screen.dart. Scan: 1 file(s), 486 lines; 1 direct Groq-client call site(s)
(P0-3 dependency); 12 Text( widgets vs 0 l10n lookups.
Current state. Works (route daily_goals). Calls Groq from the client (see evidence).
Defects. Goals are XP-based, and XP can be self-minted (P0-8). The AI goal suggestion depends on
the client Groq key (P0-3).
Elevation. Goals become intent-based ("speak for 5 minutes", "learn 10 words", "one conversation")
rather than XP. The weekly goal flexes with real life (travel mode, exam mode). The AI suggestion
goes through the gateway and explains itself ("You are strong at listening; let's push speaking").
UX and render. Goal ring on Today. Edit sheet with three presets and a custom option; no guilt copy.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Today → goal ring; Me → Settings → Goals.
Daily Challenges (revived)
What it is. Three rotating micro-challenges a day (for example "use 5 new words in chat").
Code. screens/goals/daily_challenges_screen.dart,
widgets/gamification/daily_challenges_widget.dart. Scan: 2 file(s), 910 lines; 7 Text( widgets vs 0
l10n lookups; not reachable from main.dart: daily_challenges_screen.dart.
Current state.Unrouted screen (REVIVE). The widget and provider are live
(providers/daily_challenges_provider.dart), but the full screen is not reachable.
Defects. There is no detail view, so challenges can only be seen, not explored. Challenge completion
must be verified server-side (P0-7/8).
Elevation. Revive as the Challenge board behind the Today widget. Challenges are generated from
the learner's weak skills and cross-link features (one challenge says "Point & Say three things in your
kitchen"). Each challenge deep-links into the feature that completes it, which is the main contextual-
discovery engine for lesser-known features.
UX and render. Three cards with progress chips and a "Do it" deep-link. Completion uses a modest
animation (rare tier). Rendered on the single unified design system (§3.4), with tone-safe Noto fonts,
48 dp targets, dark mode and l10n.
Lives in. Today → Challenges strip → board.
Quests
What it is. Multi-step quests with rewards.
Code. screens/gamification/quest_screen.dart. Scan: 1 file(s), 677 lines; 2 direct Groq-client call
site(s) (P0-3 dependency); 18 Text( widgets vs 0 l10n lookups.
<!-- page 51 -->
Current state. Works (route quest). Client Groq calls detected.
Defects. Quest generation relies on client AI (P0-3). Rewards can be minted client-side (P0-7).
Elevation. Story quests set in the village narrative ("Help Mama Ngozi prepare for the naming
ceremony": learn kinship words, greet the elder, haggle for yams in Market Haggle). Chapters unlock
weekly and tie together Learn, Speak and Play.
UX and render. Quest map with illustrated stops; each stop is a deep-link. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Today → Quest card; Play → Quests.
Seasonal Events / Village Festival
What it is. Time-limited cultural events.
Code. screens/gamification/seasonal_events_screen.dart. Scan: 1 file(s), 543 lines; 2 mock/fake
marker(s); 10 Text( widgets vs 0 l10n lookups.
Current state. Works (route events) and falls back to hard-coded events when the API fails
(seasonal_events_screen.dart:49-54).
Defects. The hard-coded fallback can show stale or wrong-date events. Event content isn't reviewed
for cultural accuracy.
Elevation. A cultural calendar: Ọdún Ọ̀ṣun, Eid, Timkat, Durbar, Homowo, Umhlanga, Kwanzaa and
Heritage Day. Each event bundles a story, 20 words, a persona appearance, a themed game rotation
and a circle challenge. Events are localised by region, and there's an honest "no events right now"
state instead of fake events.
UX and render. Event banner on Today; event page with a countdown, a culture explainer (reviewed)
and activities. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Today → Event banner; Village → Events.
Streaks & reminders
What it is. The daily streak counter and push reminders.
Code. screens/snap/snap_streaks_screen.dart. Scan: 1 file(s), 103 lines; 4 Text( widgets vs 0 l10n
lookups.
Current state. Works but harmful: reminders every 2 h with no dedupe (P0-23). Snap streak counts
are client-supplied (socket.service.ts:888-905).
Defects. Loss-aversion copy at night, duplicate pushes, and streaks that can be faked.
Elevation. Ethical streaks (§12): a weekly-streak option, earned freezes and repair windows. One
reminder in the learner's chosen window, written by their favourite character in the target language
("Ẹ kú alẹ́! Two minutes with me?"). Celebrate milestones.
UX and render. Streak flame becomes a calabash that fills; tap for history; no red alarms. Rendered
on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and
l10n.
Lives in. Today header; Me → Progress.
18.3 Learn hub (28 features)
Lessons map / Courses
What it is. The course map of units and lessons per language.
Code. screens/lessons/lessons_map_entry_screen.dart,
screens/tabs_view/courses/courses_tab.dart, lessons/screens/lessons_list_screen.dart,
screens/curriculum/curriculum_screen_material3.dart, screens/curriculum/curriculum_screen.dart,
screens/tutor/curriculum_viewer_screen.dart. Scan: 6 file(s), 1,998 lines; 5 mock/fake marker(s); 29
<!-- page 52 -->
Text( widgets vs 0 l10n lookups; not reachable from main.dart: curriculum_screen.dart,
curriculum_viewer_screen.dart.
Current state. Works (routes curriculum, Courses tab). curriculum_screen.dart and
tutor/curriculum_viewer_screen.dart are unrouted variants (CONSOLIDATE).
Defects. The map draws from placeholder or template curriculum (P0-16). Four entry points to the
same thing. No can-do framing.
Elevation. One Path map per language: CEFR bands as regions of a village-to-city journey, units as
stops, each showing its can-do ("I can greet elders correctly"). Downloadable per unit. Checkpoints
sit at region borders. Keep the useful views of the variants as modes of the same map (list view,
curriculum outline for teachers).
UX and render. Vertical journey with region art; a progress ring per unit; the current unit pinned;
offline badge. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Learn tab (root).
Authentic Path (A1–C1)
What it is. A curated "authentic" A1–C2 track.
Code. screens/curriculum/authentic_curriculum_entry_screen.dart,
screens/lesson/authentic_lesson_flow_screen.dart. Scan: 2 file(s), 518 lines; 1 direct Groq-client call
site(s) (P0-3 dependency); 8 Text( widgets vs 0 l10n lookups.
Current state. Works (route authentic-path). Content is template-repetitive (126 lessons/language,
85–111 unique words, grammar lines repeated 1,546×; §6).
Defects. Content quality (P0-16). The name implies the main course is not authentic.
Elevation. Becomes the "Real-world track": authentic materials (radio clips, songs, market
recordings, Nollywood/Bongo scenes, licensed) with scaffolding, unlocked from A2. It sits alongside
the core Path rather than competing with it.
UX and render. Media-first lesson cards with a transcript toggle, Tone Lens and tap-to-gloss.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Learn → Path → "Real-world" lane (A2+).
Lesson Flow
What it is. The 10-stage lesson player.
Code. screens/lesson/lesson_flow_screen.dart, screens/lesson/lesson_flow_stages.dart. Scan: 2
file(s), 661 lines; 1 Random use(s); 3 silently swallowed catch(es); 6 Text( widgets vs 0 l10n lookups.
Current state. Works (route lesson-flow). No audio in content (§6).
Defects. Template content, no audio, and stages that don't adapt.
Elevation. An adaptive lesson player: input → noticing (Tone Lens) → guided practice → speaking →
mini-check, with stages skipped when mastered. Every item has native audio and a "Why?" sheet.
UX and render. Full-screen, one task per screen, haptic feedback within 160 ms; progress bar
segmented by stage. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts,
48 dp targets, dark mode and l10n.
Lives in. Opened from Path and Today.
Lesson detail & Level certificate
What it is. Lesson overview and a certificate on finishing a level.
Code. screens/curriculum/lesson_detail_screen.dart,
screens/curriculum/level_certificate_screen.dart. Scan: 2 file(s), 1,009 lines; 21 Text( widgets vs 0
l10n lookups.
<!-- page 53 -->
Current state. Works (pushed from curriculum).
Defects. Certificates aren't evidence-based or verifiable.
Elevation. Lesson detail shows can-dos, words and the culture note, with a preview audio.
Certificates become verifiable can-do badges (Open Badges 3.0) that are shareable and link to the
Passport.
UX and render. Certificate rendered with the learner's avatar and a QR verification link. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Path → lesson; Me → Credentials.
Learning Path (personal plan)
What it is. A personalised learning-path screen.
Code. screens/learning/learning_path_screen.dart. Scan: 1 file(s), 514 lines; 10 Text( widgets vs 0
l10n lookups.
Current state. Works (route learning-path).
Defects. Duplicates the course map conceptually.
Elevation. Make it the "My plan" view of Path: the learner's goal (heritage, travel, exam) mapped to
units and weekly targets, with an ETA to the next can-do.
UX and render. Timeline with milestones; editable goal. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Path → "My plan".
Placement test
What it is. Placement during onboarding.
Code. screens/onboarding/placement_test_screen.dart,
screens/onboarding/placement_quiz_screen.dart. Scan: 2 file(s), 1,021 lines; 18 Text( widgets vs 0
l10n lookups; not reachable from main.dart: placement_quiz_screen.dart.
Current state. Works (placement_test_screen.dart); placement_quiz_screen.dart is an unrouted
variant (CONSOLIDATE).
Defects. Not adaptive; no speaking.
Elevation. An adaptive 3-minute CAT placement with listening, reading and one speaking prompt.
Results place the learner on the Path and are retakeable.
UX and render. Calm, one item per screen, with a clear "skip, I'm a beginner" option. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Onboarding; Learn → Path → "Retake placement".
Grammar Hub
What it is. Grammar topics, lessons and exercises.
Code. screens/grammar/grammar_hub_screen.dart, screens/grammar/grammar_lesson_screen.dart,
screens/grammar/grammar_exercise_screen.dart. Scan: 3 file(s), 2,067 lines; 37 Text( widgets vs 0 l10n
lookups.
Current state. Works (routes grammar-hub, grammar-lesson, grammar-exercise).
Defects. Grammar content is the repeated template lines (§6).
Elevation. A Pattern Library: each pattern card has a plain-language explanation in the learner's
language, 5 audio examples, contrasts and common errors. Interactive pattern builders (Word Forge
for Bantu noun classes, serial verbs for Yoruba). Linked from every lesson and from Polie's
explanations.
UX and render. Cards with colour-coded morphology (not colour-only); swipe through examples.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
<!-- page 54 -->
Lives in. Learn → Patterns.
Vocabulary Builder
What it is. Themed vocabulary sets with images.
Code. screens/content/vocabulary_builder_screen.dart. Scan: 1 file(s), 1,209 lines; 3 mock/fake
marker(s); 7 Text( widgets vs 0 l10n lookups.
Current state. Works (route vocabulary-builder).
Defects. Images are stock or remote with spinners; words have no audio or tone data.
Elevation. Themed word packs (market, family, body, church/mosque, football) with native audio,
Tone Lens, pictures reviewed for cultural accuracy, and "add all to review". Each word opens the
Living Dictionary card.
UX and render. Grid of picture cards; tap to hear; long-press for the Word Card. Rendered on the
single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Words → Packs.
My Words & Review (SRS) (revived)
What it is. Saved words and flashcard review.
Code. screens/vocabulary/vocabulary_screen.dart,
screens/vocabulary/flashcard_review_screen.dart,
screens/vocabulary/vocabulary_flashcard_screen.dart,
screens/ai_chat/review_dashboard_screen.dart, screens/ai_chat/vocabulary_dashboard_screen.dart.
Scan: 5 file(s), 2,781 lines; 57 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
vocabulary_flashcard_screen.dart, review_dashboard_screen.dart,
vocabulary_dashboard_screen.dart.
Current state. Works (my-vocabulary, flashcard-review). vocabulary_flashcard_screen.dart is an
unrouted variant (CONSOLIDATE). review_dashboard_screen.dart and
vocabulary_dashboard_screen.dart are unrouted analytics screens (REVIVE as tabs).
Defects. Four separate SRS implementations (§6.3). No FSRS. Saved words in chat, personas and
games don't flow here.
Elevation. One FSRS-6 review fed by every feature (save a word anywhere and it appears). The
revived dashboards become the "Insights" tab: forecast of due cards, retention curve, hardest words,
and tone-error patterns.
UX and render. Review card with audio first, then meaning, then a speak-it button; swipe grading;
dashboard charts generated from real data. Rendered on the single unified design system (§3.4),
with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Words → Review / Insights; Today pulls due items.
Review Rush (gamified review) (revived)
What it is. Timed, gamified review of saved words.
Code. screens/review/gamified_review_screen.dart. Scan: 1 file(s), 367 lines; 10 Text( widgets vs 0
l10n lookups; not reachable from main.dart: gamified_review_screen.dart.
Current state.Unrouted (REVIVE). Uses apiProvider, gamificationProvider and userProvider, so it
is wired to real data.
Defects. Not reachable from any menu.
Elevation. Revive as Review Rush: a 90-second sprint over due cards with combo multipliers that
only reward accuracy. Reachable from Review and from the Play shelf. Results update FSRS like
normal review.
UX and render. Arcade skin over the same card component; reduced-motion version. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
<!-- page 55 -->
Lives in. Learn → Words → Review → "Rush"; Play → Quick games.
Listening Practice
What it is. Listening exercises and a listening quiz.
Code. screens/content/listening_practice_screen.dart, screens/tutor/listening_quiz_screen.dart.
Scan: 2 file(s), 1,241 lines; 16 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
listening_quiz_screen.dart.
Current state. Works (route listening-practice). tutor/listening_quiz_screen.dart is unrouted
(CONSOLIDATE as a mode).
Defects. Content lacks real audio (§6).
Elevation.Ear training: graded listening at native speed with accents (Lagos, Ibadan, Kano, Nairobi,
Durban), a slow-down slider, dictation with diacritic-aware grading, and the quiz mode merged in.
Danfo/Matatu Rush (new game) reuses the same audio.
UX and render. Waveform with tap-to-replay segments; transcript reveal after answering. Rendered
on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and
l10n.
Lives in. Learn → Skills → Listening.
Writing Practice
What it is. Writing exercises with AI feedback.
Code. screens/content/writing_practice_screen.dart. Scan: 1 file(s), 920 lines; 2 direct Groq-client
call site(s) (P0-3 dependency); 11 Text( widgets vs 0 l10n lookups.
Current state. Works (route writing-practice); AI feedback calls Groq from the client.
Defects. Client key dependency (P0-3). A regex diacritic "enforcer" can introduce errors (§7.1).
Elevation.Write & check: a diacritic keyboard bar, tone-aware grading that is lenient early and strict
later, and AI feedback through the gateway that shows uncertainty ("tone unclear here, listen").
Handwriting mode for Ge'ez, N'Ko and Adlam scripts.
UX and render. Inline corrections with an explanation popover; never auto-replace text. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Skills → Writing.
Phrase DNA
What it is. Phrase templates that learners recombine (sentence frames).
Code. screens/learning/phrase_dna/phrase_dna_templates_screen.dart,
screens/learning/phrase_dna/phrase_dna_session_screen.dart. Scan: 2 file(s), 460 lines; 6 Text(
widgets vs 0 l10n lookups.
Current state. Works (routes phrase-dna-templates plus the session).
Defects. Templates come from the same thin content.
Elevation. Turn it into sentence frames you can speak: "I want to buy ___" with slot fillers from the
learner's own words. The learner sees how the tone changes in context (tone sandhi where relevant)
and says the full sentence with scoring. A strong bridge from words to speaking.
UX and render. Slot chips that snap into place; Tone Lens updates live. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Skills → Phrase DNA; Speak → Warm-ups.
Tone & Rhythm Trainer
What it is. Tone and rhythm practice.
<!-- page 56 -->
Code. screens/learning/tone_rhythm/tone_rhythm_trainer_screen.dart,
screens/practice/tone_drill_screen.dart. Scan: 2 file(s), 1,009 lines; 4 silently swallowed catch(es);
20 Text( widgets vs 0 l10n lookups; not reachable from main.dart: tone_drill_screen.dart.
Current state. Works (route tone-rhythm-trainer). practice/tone_drill_screen.dart is unrouted
(CONSOLIDATE as "Drills").
Defects. Tone models are simplified (one H/M/L scheme for all languages; §10.1).
Elevation. The Tone Gym, LingAfriq's signature: perception drills (minimal pairs), production with a
live pitch contour against the native one, per-language tone inventories (Yoruba H/M/L + glides, Igbo
downstep, Hausa falling) and a progression ladder. Fed by the real scorer (§7.4).
UX and render. Large pitch canvas; the native contour in a calm colour, the learner's overlaid; shape
plus label, never colour-only. Rendered on the single unified design system (§3.4), with tone-safe
Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Tone Gym (also Learn → Skills).
Tonal Lesson (Village)
What it is. A tone-focused lesson inside the Village.
Code. screens/village/tonal_lesson_screen.dart. Scan: 1 file(s), 324 lines; 2 Text( widgets vs 0 l10n
lookups.
Current state. Works (route tonal-lesson).
Defects. Sits in the Village with no link to the Tone Gym or Path.
Elevation. Becomes the story-led tone lesson (an elder teaches greetings with tone), linked to the
Tone Gym for practice and placed on the Path where tone is introduced.
UX and render. Character-led scene with the Tone Lens on every line. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Path (tone units); Speak → Tone Gym → Lessons.
Language Quiz
What it is. Section quizzes per language.
Code. language_quiz/screens/language_quiz_sections_screen.dart,
screens/tabs_view/home/take_quiz_screen.dart. Scan: 2 file(s), 740 lines; 3 Random use(s); 1 Text(
widgets vs 0 l10n lookups.
Current state. Works (pushed from home). Placeholder MCQs exist in bundles ("Sample MCQ"; §11).
Defects. Placeholder items; no calibration.
Elevation. Merge into the item bank: unit checkpoints and adaptive quizzes with rationales and
audio (§11.3), while keeping the familiar "take a quiz" entry.
UX and render. Clean MCQ/listening item templates; result screen with a can-do update. Rendered
on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and
l10n.
Lives in. Learn → Path → Checkpoints; Today → "Quick quiz".
History & History Quiz
What it is. History reading list and history quizzes.
Code. history/screens/history_list_screen.dart,
history_quiz/screens/history_quiz_sections_screen.dart. Scan: 2 file(s), 527 lines; 1 Random use(s).
Current state. Works (pushed from home/drawer).
Defects. Facts aren't sourced or reviewed (see persona data errors, §8).
Elevation.Living History: short illustrated stories with sources, linked to Historical Personas ("Meet
her" button) and quizzes that cite the story. Reviewed by historians.
<!-- page 57 -->
UX and render. Story cards with a "Sources" footer; persona portrait chip. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Culture → History; Speak → Personas cross-link.
Mannerisms & etiquette
What it is. Cultural mannerisms list.
Code. mannerisms/screens/mannerism_list_screen.dart. Scan: 1 file(s), 185 lines.
Current state. Works (pushed from home).
Defects. Text list only; no practice.
Elevation.Etiquette cards with practice: kneeling and prostration greetings, handshakes, eating
etiquette, taboo topics. Each card has a short video (commissioned), "why", and a Greeting Gauntlet
round; the avatar demonstrates.
UX and render. Card stack with gesture illustrations; regional variants flagged. Rendered on the
single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Culture → Etiquette.
Cultural Hub
What it is. Hub for cultural content.
Code. screens/content/cultural_hub_screen.dart. Scan: 1 file(s), 898 lines; 16 Text( widgets vs 0
l10n lookups.
Current state. Works (route cultural-hub).
Defects. One of several culture entry points (magazine, heritage, history, mannerisms).
Elevation. Becomes the Culture landing inside Learn, organising Magazine, History, Etiquette,
Heritage archive, Proverbs and Music in one place.
UX and render. Editorial layout with one featured story and shelves. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Culture (root).
Culture Magazine
What it is. Editorial cultural articles.
Code. screens/magazine/culture_magazine_screen_enhanced.dart,
screens/magazine/culture_magazine_screen.dart,
screens/magazine/culture_magazine_enhanced_features.dart. Scan: 3 file(s), 2,256 lines; 15 direct
Groq-client call site(s) (P0-3 dependency); 2 mock/fake marker(s); 2 silently swallowed catch(es); 22
Text( widgets vs 2 l10n lookups; not reachable from main.dart: culture_magazine_screen.dart.
Current state. Works (route magazine → enhanced). culture_magazine_screen.dart is an unrouted
earlier version (CONSOLIDATE). AI features call Groq from the client (12 call sites in
culture_magazine_enhanced_features.dart).
Defects. Client key dependency (P0-3). Backend cultureArticleGenerator.service.ts uses gpt-4o to
generate articles, which is unreviewed AI content.
Elevation. A bilingual magazine: articles at the reader's level with tap-to-gloss, audio narration by
native voices, "words from this article" to save, and author credits for African writers (commissioned,
paid). AI-assisted drafts are labelled and reviewed.
UX and render. Typography-led layout with Andika/Noto; reading progress; offline save. Rendered
on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and
l10n.
Lives in. Learn → Culture → Magazine; Today → culture card.
Heritage Milestones
<!-- page 58 -->
What it is. Heritage-learner milestone tracker.
Code. screens/learning/heritage_milestones_screen.dart. Scan: 1 file(s), 137 lines; 4 Text( widgets
vs 0 l10n lookups.
Current state. Works (route heritage-milestones).
Defects. Milestones are generic.
Elevation.Family milestones for heritage learners: "Greeted grandma in Yoruba", "Understood a
family WhatsApp voice note", "Said a prayer at a naming ceremony". Self-reported with an optional
audio memory saved to a private family album.
UX and render. Timeline with photos and voice memories; private by default. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Heritage; Today celebrates milestones.
FLB Heritage Archive
What it is. An archive of heritage items (folklore, legends, background) with detail pages.
Code. screens/heritage/flb_heritage_archive_screen.dart,
screens/heritage/flb_heritage_detail_screen.dart. Scan: 2 file(s), 468 lines; 2 mock/fake marker(s).
Current state. Works (routes flb-heritage-archive, flb-heritage-detail).
Defects. Provenance and licensing of items are unclear.
Elevation. The Living Archive (Wave 4 languages): folktales, praise poetry (oríkì), songs and
proverbs recorded with community consent, each with transcript, translation, Tone Lens, contributor
credit and licence. It is also how endangered-language starter kits are presented.
UX and render. Museum-like detail pages with audio first, then text. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Learn → Culture → Archive.
Dialect Preference
What it is. Choose the dialect variant.
Code. screens/learning/dialect_preference_screen.dart. Scan: 1 file(s), 30 lines; 1 Text( widgets vs
0 l10n lookups.
Current state. Works (route dialect-preference).
Defects. Dialect choice doesn't change content (no dialect-tagged content yet).
Elevation. Real dialect lanes: audio variants per item (Ọ̀yọ́ vs Ìjẹ̀bú Yoruba; Owerri vs Onitsha Igbo;
Kenyan vs Tanzanian Swahili), with notes where words differ and a "hear other dialects" toggle on
every Word Card.
UX and render. Map-based picker with sample audio per dialect. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Settings → Language & dialect; Word Card toggle.
Living Dictionary
What it is. A searchable dictionary that learners can add to.
Code. screens/vocabulary/living_dictionary_screen.dart,
services/learning/living_dictionary_service.dart. Scan: 2 file(s), 750 lines; 21 Text( widgets vs 0
l10n lookups.
Current state. Works (route living-dictionary). See the deep-dive in §17.7.
Defects. Per-user word list only (the backend filters by userId); no shared verified lexicon.
Elevation. See §17.7 (exemplar deep-dive).
UX and render. See §17.7. Rendered on the single unified design system (§3.4), with tone-safe Noto
fonts, 48 dp targets, dark mode and l10n.
Lives in. Global: search bar + long-press on any word; Learn → Words.
<!-- page 59 -->
Offline Downloads (revived)
What it is. Manage downloaded lessons and content for offline use.
Code. screens/offline/offline_content_screen.dart. Scan: 1 file(s), 375 lines; 17 Text( widgets vs 0
l10n lookups; not reachable from main.dart: offline_content_screen.dart.
Current state.Unrouted (REVIVE). Wired to offlineContentProvider, offlineDownloadProvider and
subscriptionProvider.
Defects. Offline is a key need in the target markets, but this screen is unreachable.
Elevation. Revive as Downloads: per-unit packs (text + Opus audio), storage meter, Wi-Fi-only toggle,
auto-download of the next unit, and an offline Tone Gym once the on-device model ships. Ties into
the single outbox (§13.5).
UX and render. List with size per pack, progress and a clear sync status. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Downloads; Path shows a download icon per unit.
Language detail & Suggest a language
What it is. Per-language info page and a form to request new languages.
Code. screens/tabs_view/home/language_detail_screen.dart,
screens/tabs_view/profile/suggest_language_screen.dart. Scan: 2 file(s), 508 lines; 3 Text( widgets
vs 0 l10n lookups.
Current state. Works (pushed from home and profile).
Defects. Suggestions go nowhere visible.
Elevation. Language pages show speakers, regions, readiness level (L0–L3) and a sample phrase.
Suggest a language becomes the public waitlist for Waves 2–4, with a "sign up as a native reviewer"
path. It directly feeds the language-selection score (§6.4).
UX and render. Language page with a map, audio sample and readiness badge; waitlist counter.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Learn → language switcher → "All languages".
Passport (proctored test & credential)
What it is. A proctored proficiency test and credential.
Code. screens/passport/passport_proctored_session_screen.dart,
screens/passport/passport_credential_screen.dart. Scan: 2 file(s), 354 lines; 11 Text( widgets vs 0
l10n lookups.
Current state. Works as UI (routes passport-proctored, passport-credential).
Defects. Scoring and content aren't valid yet (§12.4); proctoring privacy terms are unclear.
Elevation. The LingAfriq Passport: evidence portfolio plus an adaptive proctored test, mapped to
CEFR descriptors with a published methodology, issued as a verifiable credential. Launch only after
real scoring.
UX and render. Formal, calm design; clear privacy explanation before the camera turns on.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Me → Credentials (unlocks at A2).
Lesson Recap (revived)
What it is. End-of-lesson recap screen (328 lines).
Code. screens/learning/lesson_recap_screen.dart. Scan: 1 file(s), 328 lines; 6 Random use(s); 6 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: lesson_recap_screen.dart.
<!-- page 60 -->
Current state.Unrouted (REVIVE).
Defects. Lessons end without consolidation, so there is no retrieval moment.
Elevation. Revive as the 60-second recap after every lesson: three retrieval questions, the new
words with audio and Tone Lens, one sentence to say aloud (scored), and "what's next". New words
enter FSRS review automatically.
UX and render. Card stack with large type; one celebratory moment, not confetti spam. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. End of every lesson (Learn → lesson → recap).
18.4 Speak hub (20 features)
Polie AI Tutor workspace
What it is. Polie, the AI tutor: free chat plus mode selection (conversation, explain, correct and
others).
Code. screens/ai_chat/polie_workspace_screen.dart, screens/ai_chat/ai_chat_select_screen.dart,
screens/ai_chat/ai_mode_selection_screen.dart,
screens/ai_chat/polie_mode_selection_screen.dart,
screens/ai_chat/ai_chat_language_setup_screen.dart, screens/ai_chat/ai_chat_screen.dart (+4
more). Scan: 10 file(s), 10,869 lines; 37 direct Groq-client call site(s) (P0-3 dependency); 2 Random
use(s); 4 mock/fake marker(s); 9 silently swallowed catch(es); 93 Text( widgets vs 7 l10n lookups; not
reachable from main.dart: ai_chat_screen.dart, ai_chat_screen_new.dart,
ai_chat_screen_with_tracking.dart, conversation_enhanced_screen.dart,
ai_language_selection_screen.dart.
Current state. Works (AI tab; routes ai_chat_select, polie_mode_selection). Client-side Groq calls
throughout (11 in the workspace alone). Five unrouted earlier versions (CONSOLIDATE; harvest the
tracking and "enhanced conversation" features).
Defects. 6,485-line god screen. Client keys (P0-3). No streaming on the backend fallback
(ai_chat_provider_groq.dart:1302). Silent fallbacks.
Elevation. Polie becomes a voice-first companion: hold-to-talk with live transcript and Tone Lens on
Polie's replies, recasts ("You said X; natives say Y"), a hint ladder, and "save this phrase". Modes are
chips at the top: Chat, Explain, Correct me, Roleplay, Story and Translate. Polie knows the learner
model, so it uses due words naturally. All through the AI gateway with streaming. Avatar lip-sync (§4).
UX and render. Chat surface with large target-language text (18 sp+), a gloss on tap, and the avatar
bust in the header reacting (listening/thinking/speaking). Honest "AI unavailable" state. Rendered on
the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak tab (root) → Polie.
Tutor: Dialogue mode
What it is. Guided dialogues with the tutor.
Code. screens/tutor/tutor_dialogue_mode_screen.dart. Scan: 1 file(s), 799 lines; 11 direct Groq-client
call site(s) (P0-3 dependency); 5 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation. Scripted-goal dialogues ("order food", "ask directions") where Polie improvises inside
human-authored scenarios and scores goal completion, politeness and accuracy. Learners can replay
with a different character (elder, child, trader).
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
<!-- page 61 -->
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
Tutor: Grammar mode
What it is. Ask grammar questions, get explanations and drills.
Code. screens/tutor/tutor_grammar_mode_screen.dart. Scan: 1 file(s), 795 lines; 12 direct Groq-client
call site(s) (P0-3 dependency); 1 mock/fake marker(s); 17 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation. Answers come only from the Pattern Library (retrieval), cite the pattern card, and spawn
a 3-item micro-drill. Explanations in the learner's L1 (English, French, Portuguese, Arabic).
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
Tutor: Story mode
What it is. AI-generated graded stories.
Code. screens/tutor/tutor_story_mode_screen.dart. Scan: 1 file(s), 1,008 lines; 11 direct Groq-client
call site(s) (P0-3 dependency); 3 silently swallowed catch(es); 11 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation.Choose-your-path stories at the learner's level using known plus due words, narrated by
native TTS, with comprehension checks. Labelled AI-generated; the best stories go to human review
and then the shared library.
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
Tutor: Translation mode
What it is. Translate with explanation.
Code. screens/tutor/tutor_translation_mode_screen.dart. Scan: 1 file(s), 730 lines; 14 direct Groq-
client call site(s) (P0-3 dependency); 14 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation.Translate & teach: shows the translation, word-by-word alignment, register options
(formal/informal/elder) and why. Uses the commercial MT stack (AI stack §3.7); confidence badge per
language pair. Merges the unrouted enhanced_translation_screen.dart features (CONSOLIDATE).
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
<!-- page 62 -->
Tutor: Pronunciation mode
What it is. Record and get pronunciation feedback.
Code. screens/tutor/tutor_pronunciation_mode_screen.dart. Scan: 1 file(s), 701 lines; 6 direct Groq-
client call site(s) (P0-3 dependency); 4 mock/fake marker(s); 1 silently swallowed catch(es); 16 Text(
widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation. Real scoring (§7.4): per-syllable tone and phone feedback with the native contour overlay.
Replaces the fake rhythm score (score*0.9, P0-18). Merges unrouted
practice/pronunciation_practice_screen.dart (CONSOLIDATE).
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
Tutor: Assess mode
What it is. AI-run assessment conversation.
Code. screens/tutor/tutor_assess_mode_screen.dart. Scan: 1 file(s), 586 lines; 11 direct Groq-client
call site(s) (P0-3 dependency); 1 silently swallowed catch(es); 9 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (pushed from the tutor dashboard); the AI calls Groq directly from the
client (see evidence).
Defects. Client key dependency (P0-3): in release builds these modes fail and fall back silently. No
grounding in approved content.
Elevation. An oral proficiency interview lite: a 5-minute adaptive conversation rated against can-
do descriptors, with native-rater calibration. Feeds the Passport evidence portfolio.
UX and render. Shared tutor shell: header with avatar and mode chip, transcript, mic button, and a
feedback drawer. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Speak → Polie → mode chips.
Tutor dashboard
What it is. Entry to the tutor modes and tutor progress.
Code. screens/tutor/tutor_dashboard_screen.dart,
screens/ai_chat/tutor_progress_dashboard_screen.dart. Scan: 2 file(s), 860 lines; 15 Text( widgets vs
0 l10n lookups; not reachable from main.dart: tutor_progress_dashboard_screen.dart.
Current state. Works. ai_chat/tutor_progress_dashboard_screen.dart is an unrouted progress view
(CONSOLIDATE as the dashboard's "Progress" tab).
Defects. Modes are listed rather than recommended.
Elevation.Coach view: Polie recommends the next mode based on weak skills; the progress tab
shows speaking minutes, tone accuracy trend and conversation goals achieved.
UX and render. Cards with "Recommended" ribbon; small charts. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Polie → "Coach".
Shadowing (revived)
What it is. Listen-and-repeat shadowing exercise.
<!-- page 63 -->
Code. screens/tutor/shadowing_exercise_screen.dart. Scan: 1 file(s), 385 lines; 2 direct Groq-client
call site(s) (P0-3 dependency); 8 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
shadowing_exercise_screen.dart.
Current state.Unrouted (REVIVE). Client Groq calls detected.
Defects. Unreachable; client key dependency.
Elevation. Revive as Shadow Me: a native clip plays and the learner speaks along a fraction of a
second behind, with karaoke-style word highlighting from forced alignment and a tone contour
comparison. Daily 2-minute shadowing appears in Today.
UX and render. Lyrics-style scrolling transcript; dual waveform; "slow" toggle. Rendered on the
single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Practice → Shadowing; Today slot.
Conversation Scenarios & Roleplay (revived)
What it is. Scenario-based roleplay (market, taxi, clinic) with summaries and progress.
Code. screens/content/conversation_scenarios_screen.dart,
screens/ai_chat/roleplay_scenario_selection_screen.dart,
screens/ai_chat/roleplay_completion_summary_screen.dart,
screens/ai_chat/roleplay_progress_dashboard_screen.dart. Scan: 4 file(s), 2,651 lines; 3 direct Groq-
client call site(s) (P0-3 dependency); 1 mock/fake marker(s); 29 Text( widgets vs 0 l10n lookups; not
reachable from main.dart: roleplay_scenario_selection_screen.dart,
roleplay_completion_summary_screen.dart, roleplay_progress_dashboard_screen.dart.
Current state. Scenarios work (route conversation-scenarios). Scenario selection (CONSOLIDATE),
completion summary (REVIVE) and progress dashboard (REVIVE) are unrouted.
Defects. Without summary and progress, roleplay has no closure or progression. Client AI
dependency.
Elevation.Scenario Theatre: a library of real-life scenes with goals and a cast. The revived
completion summary shows goals met, best phrases, corrected mistakes and words to save. The
revived progress dashboard becomes a "scene passport" collecting stamps per scenario and level.
Market Haggle and Greeting Gauntlet share the engine.
UX and render. Scene cards with illustrated settings; summary screen with replay of key moments.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Speak → Scenarios.
Conversation Analytics (revived)
What it is. Analytics of the learner's AI conversations.
Code. screens/ai_chat/conversation_analytics_screen.dart. Scan: 1 file(s), 615 lines; 10 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: conversation_analytics_screen.dart.
Current state.Unrouted (REVIVE). Wired to conversationAnalyticsServiceProvider.
Defects. Insight data is collected but never shown.
Elevation. Revive as "How I speak": words used vs avoided, average utterance length, code-switch
rate, tone accuracy over time and the most frequent corrections, with one actionable suggestion per
week.
UX and render. Simple, honest charts with an explanation line under each. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Coach → Insights; Me → Progress.
Speak Engine Lab (code-switch & register coach)
What it is. Experimental lab: code-switching sessions and a register (formality) coach.
<!-- page 64 -->
Code. screens/learning/speak_engine_lab_screen.dart. Scan: 1 file(s), 189 lines; 12 Text( widgets vs
0 l10n lookups.
Current state. Works (route speak-engine-lab), backed by code_switch_session_service.dart and
register_coach_service.dart.
Defects. "Lab" framing hides two genuinely novel features.
Elevation. Split into two named features. Code-Switch Coach: practise natural Yoruba-English or
Swahili-English mixing the way people really talk, scored for naturalness. Respect Coach: rewrite a
sentence for an elder, peer or child, with honorifics (Yoruba ẹ/ọ, Igbo titles, Zulu hlonipha). Both are
rare in the market.
UX and render. Side-by-side "casual vs respectful" cards with audio. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Practice → Code-Switch Coach / Respect Coach.
Speak Missions
What it is. Speaking missions evaluated by AI.
Code. screens/content/speak_mission_evaluate_screen.dart. Scan: 1 file(s), 233 lines; 4 direct Groq-
client call site(s) (P0-3 dependency); 2 silently swallowed catch(es); 5 Text( widgets vs 0 l10n lookups.
Current state. Works as UI; evaluation calls Groq from the client and records audio.
Defects. Client AI dependency; evaluation not grounded in a rubric.
Elevation.Weekly speaking missions in the real world ("Greet three people in Yoruba today and
record one"), with a rubric-based evaluation and an optional share to the circle. Ties to Daily
Challenges.
UX and render. Mission card with checklist; recording sheet; rubric feedback. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Missions; Today → Challenges.
Historical Personas
What it is. Chat with historical African figures.
Code. screens/personalities/personality_selection_screen.dart,
screens/personalities/personality_chat_screen.dart. Scan: 2 file(s), 776 lines; 16 Text( widgets vs 0
l10n lookups.
Current state. Works as UI (route historical-personas). Backend persona service flagged: told not
to mention being AI (P0-15); confidence 0.9 with empty sources; data errors (Nkrumah listed as Twi).
Defects. P0-13/14/15; ungrounded answers.
Elevation. See §8: grounded, cited, AI-disclosed personas with illustrated story chapters (Yaa
Asantewaa and the Golden Stool), voice in the target language, and historian review. Collections:
Queens & Warriors, Builders of Nations, Writers & Thinkers, Scientists & Healers.
UX and render. Portrait busts (Rive), a sources drawer on every answer, and an "AI recreation" label.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Speak → Personas.
Persona Missions
What it is. Goal-based missions with personas.
Code. screens/persona_missions/persona_missions_hub_screen.dart,
screens/persona_missions/persona_mission_setup_screen.dart,
screens/persona_missions/persona_mission_session_screen.dart. Scan: 3 file(s), 427 lines; 2 direct
Groq-client call site(s) (P0-3 dependency); 10 Text( widgets vs 0 l10n lookups.
Current state. Works as UI; session calls Groq from the client (silently fails in release, P0-13).
<!-- page 65 -->
Defects. P0-13 canned fallback "I hear you. Let us continue."
Elevation. The story-chapter format from §8: era scene, objective (greet the Queen Mother
correctly), branching dialogue, cultural debrief with sources, and a reward that ties to the persona's
history.
UX and render. Illustrated scene header, ambient audio, objective tracker. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Speak → Personas → Missions.
LingChat AI conversation
What it is. An AI conversation partner inside the chat section.
Code. screens/chat/lingchat_ai_conversation_screen.dart. Scan: 1 file(s), 45 lines; 1 direct Groq-
client call site(s) (P0-3 dependency).
Current state. Works (route lingchat_ai); a thin 45-line wrapper over Polie modes.
Defects. Duplicates Polie in a different place.
Elevation. Becomes "Practice with Polie" inside chat: open a practice DM with Polie or a persona
from the chat list, so AI practice sits where conversations already happen. It reuses Polie
(consolidated engine) but keeps this entry point.
UX and render. Appears as a pinned contact in Chats with an "AI" label. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Chats → pinned "Polie (AI)".
Synthetic Voice Styles
What it is. Choose the synthetic voice style used for TTS.
Code. screens/settings/synthetic_voice_styles_screen.dart. Scan: 1 file(s), 196 lines; 4 Text(
widgets vs 0 l10n lookups.
Current state. Works (route synthetic-voice-styles).
Defects. Voices come from non-commercial models (MMS-TTS, XTTS-v2; P0-24).
Elevation.Voice picker with commercial voices per language (Intron, Spitch, Azure, custom; AI stack
§3.5): preview, gender, region, speed. The chosen voice also becomes Polie's voice. Clearly labelled
synthetic.
UX and render. Voice cards with a play sample and region tag. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Settings → Voice; Speak → Polie settings.
Point & Say
What it is. Point the camera at an object or text, learn the word and say it.
Code. screens/ar/point_and_say_screen.dart, services/offline/point_and_say_queue_service.dart.
Scan: 2 file(s), 1,135 lines; 7 silently swallowed catch(es); 22 Text( widgets vs 0 l10n lookups.
Current state. Works (route point-and-say). See the deep-dive in §17.6.
Defects. See §17.6.
Elevation. See §17.6 (exemplar deep-dive).
UX and render. See §17.6. Rendered on the single unified design system (§3.4), with tone-safe Noto
fonts, 48 dp targets, dark mode and l10n.
Lives in. Global Lens button; Learn/Speak contextual.
Live Translate
What it is. Real-time speech translation session (on-device STT streamed over Socket.IO).
<!-- page 66 -->
Code. screens/live_translate/live_translate_screen.dart,
services/live_translate/live_translate_client.dart. Scan: 2 file(s), 632 lines; 2 mock/fake
marker(s); 3 silently swallowed catch(es).
Current state. Works as UI (drawer item). It uses on-device speech recognition streamed through
live_translate_event (live_translate_client.dart:6,35,75).
Defects. On-device recognisers rarely support Yoruba, Igbo, Hausa, Xhosa or Pidgin, so the source
side fails for those languages. The socket inherits P0-4/5 weaknesses.
Elevation.Conversation Bridge: two people, two languages, one phone. Each speaks in turn;
server-side ASR (Intron) handles African languages and the commercial MT stack translates. Every
turn shows Tone Lens and "learn this phrase". A learning feature, not just a utility: the transcript
becomes a saved mini-lesson.
UX and render. Split-screen facing layout (one half upside-down for the other person); big mic
buttons; confidence indicator. Rendered on the single unified design system (§3.4), with tone-safe
Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Global Lens → "Bridge"; Speak → Practice.
Import Media (OCR & clips)
What it is. Import images, audio or video to extract text, transcribe and generate learning material.
Code. screens/media/import_media_screen.dart, screens/media/media_clip_player_screen.dart.
Scan: 2 file(s), 163 lines.
Current state. Works (route import_media). ML Kit Latin OCR (media_import_service.dart:93);
transcription and generation through the backend.
Defects. ML Kit Latin OCR mangles stacked tone marks [verify on device]. Generated content isn't
reviewed.
Elevation.Learn from anything: import a song, a WhatsApp voice note, a sermon clip or a sign
photo, and LingAfriq turns it into a personal lesson (transcript, glosses, Tone Lens, 10 flashcards, a
shadowing clip). Server OCR with a diacritic-aware second pass (AI stack §3.13). Private by default;
copyright notice for sharing.
UX and render. Import sheet (camera/files/share-sheet target); processing steps shown honestly.
Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark
mode and l10n.
Lives in. Global Lens → "Import"; share-sheet target from other apps.
18.5 Play hub (48 features)
Games Arcade (hub & catalogue)
What it is. The catalogue of all games.
Code. screens/games/games_screen_material3.dart, screens/games/games_screen.dart,
screens/games/games_screen_enhanced_with_all_games.dart, screens/games/game_catalog.dart,
screens/games/game_router.dart, screens/games/language_games_screen.dart (+2 more). Scan: 8
file(s), 2,993 lines; 3 silently swallowed catch(es); 22 Text( widgets vs 0 l10n lookups; not reachable
from main.dart: language_games_screen.dart, language_games_screen_components.dart,
lazy_game_list.dart.
Current state. Works (routes games, games_api_languages, games_enhanced_catalog: three routed
catalogues). language_games_screen*.dart and lazy_game_list.dart are unrouted variants
(CONSOLIDATE).
Defects. Three competing catalogues; games are a separate destination and don't update the
learner model reliably.
Elevation. One Arcade with shelves: "For you today" (games that train the learner's weakest skills),
Tone & Sound, Words, Grammar, Speaking, Culture, Traditional Games, Multiplayer and Classroom.
<!-- page 67 -->
Each game card shows the skill it trains and the learner's mastery. Lazy loading from
lazy_game_list.dart is kept as the loading strategy.
UX and render. Shelf layout with game art (one consistent illustration style); skill chips; "New" and
"Event" ribbons. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48
dp targets, dark mode and l10n.
Lives in. Play tab (root).
Game shell, guides & results (revived)
What it is. Shared game frame: how-to-play guide, loading and results.
Code. screens/games/templates/game_template_shell.dart,
screens/games/game_onboarding_overlay.dart, screens/games/game_start_guide_screen.dart,
screens/games/game_mastery_results_screen.dart, screens/games/victory_results_screen.dart,
screens/games/universal_loading_screen.dart (+2 more). Scan: 8 file(s), 1,943 lines; 9 Random use(s);
27 Text( widgets vs 0 l10n lookups; not reachable from main.dart: game_start_guide_screen.dart,
game_mastery_results_screen.dart, victory_results_screen.dart, universal_loading_screen.dart,
universal_game_screen.dart, template_timed_quiz.dart.
Current state. Overlay and shell work. game_mastery_results_screen.dart (REVIVE as the standard
results screen). Start guide, victory results, universal loading, universal game screen and six
templates are unrouted (CONSOLIDATE into GameKit).
Defects. Inconsistent results screens; no mastery feedback after play.
Elevation. One GameKit frame. A 10-second how-to (from the start guide) on first play; the revived
mastery results screen shows which words and skills improved, mistakes with audio, "add to
review", and a replay button. Every game reports to the learner model.
UX and render. Consistent header (timer, score, quit), results with skill bars; confetti only on personal
bests. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets,
dark mode and l10n.
Lives in. Inside every game.
Word Match
What it is. Match words to meanings.
Code. screens/games/word_match_game.dart. Scan: 1 file(s), 455 lines; 4 Text( widgets vs 0 l10n
lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Due-word driven matching with audio on every tap and a "tone twin" round where two
words differ only in tone.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Word Match (audio)
What it is. Match heard words to meanings.
Code. screens/games/word_match_audio_game.dart. Scan: 1 file(s), 527 lines; 2 Random use(s); 3 Text(
widgets vs 1 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
<!-- page 68 -->
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Listening-first: hear it, match it. Speakers rotate across regions to build accent tolerance.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Fill in the Blank
What it is. Complete sentences.
Code. screens/games/fill_in_the_blank_game.dart. Scan: 1 file(s), 528 lines; 2 Random use(s); 11 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Cloze from real dialogues with diacritic-aware typing and a hint that plays the audio.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Grammar shelf.
Picture–Word Association
What it is. Match a word to an image.
Code. screens/games/picture_word_association_screen.dart. Scan: 1 file(s), 399 lines; 1 Random use(s);
1 mock/fake marker(s); 2 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Culturally reviewed illustrations (local foods, clothing, places) and a "say it" bonus that
awards points only for real scored speech.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Memory Map
What it is. 3×4 card flip memory of word ↔ meaning pairs.
Code. screens/games/memory_map_screen.dart. Scan: 1 file(s), 419 lines; 2 Random use(s).
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Audio-card variant (flip to hear) and family-themed decks, so heritage learners memorise
kinship terms.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
<!-- page 69 -->
Lives in. Play → Words shelf.
Speed Challenge
What it is. Timed vocabulary challenge.
Code. screens/games/speed_challenge_game.dart. Scan: 1 file(s), 620 lines; 15 Text( widgets vs 0 l10n
lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Adaptive speed that targets 80–85% success, with a "calm mode" without a timer for
accessibility.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Speed Round
What it is. Rapid-fire rounds.
Code. screens/games/speed_round_game.dart. Scan: 1 file(s), 424 lines; 4 Text( widgets vs 0 l10n
lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Merge mechanics with Speed Challenge as two modes of one game ("Sprint" and
"Rounds"); both survive as modes.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Story Builder
What it is. Arrange sentences into a story.
Code. screens/games/story_builder_game.dart. Scan: 1 file(s), 457 lines; 4 Random use(s); 1 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Builds illustrated audio stories from the learner's level; finished stories can be shared to
circles.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Grammar shelf.
Grammar Detective
<!-- page 70 -->
What it is. Find grammar errors.
Code. screens/games/grammar_detective_game.dart. Scan: 1 file(s), 471 lines; 4 Random use(s); 6 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Cases framed as village mysteries; each solved case unlocks a Pattern Library card.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Grammar shelf.
Grammar Jam
What it is. Music-paced grammar game.
Code. screens/games/grammar_jam_screen.dart. Scan: 1 file(s), 506 lines; 4 Random use(s); 2 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Rhythm-paced sentence building over Afrobeats/amapiano-style beats (commissioned),
with rhythm tied to syllables.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Grammar shelf.
Greeting Diplomacy
What it is. Choose the right greeting for the situation.
Code. screens/games/greeting_diplomacy_screen.dart. Scan: 1 file(s), 384 lines; 5 Random use(s); 3
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes Greeting Gauntlet (§10.3): time × person × setting, with avatar gestures and
spoken answers.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Market Bargaining
What it is. Haggle with a trader (random asking price, market_bargaining_screen.dart:84).
Code. screens/games/market_bargaining_screen.dart. Scan: 1 file(s), 392 lines; 3 Random use(s); 8
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
<!-- page 71 -->
turns and effects; any scoring use is called out in the description.
Defects. Asking price is random (:84), which is fine as a mechanic; there is no politeness or language
scoring. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes Market Haggle: voice roleplay with trader personalities, real numbers practice,
and politeness scoring.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Quiz Chef
What it is. Cooking-themed quiz.
Code. screens/games/quiz_chef_screen.dart. Scan: 1 file(s), 771 lines; 1 Random use(s); 3 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Recipes as lessons: cook jollof, egusi, ugali or chakalaka by following spoken instructions
in the target language.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Roleplay Adventure
What it is. Branching roleplay adventure.
Code. screens/games/roleplay_adventure_game.dart. Scan: 1 file(s), 406 lines; 2 Random use(s); 4 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Shares the Scenario Theatre engine; adventures become multi-scene trips (Lagos →
Ibadan → Ọ̀ṣogbo).
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Taxi Survival
What it is. Navigate a taxi ride using the language.
Code. screens/games/taxi_survival_screen.dart. Scan: 1 file(s), 426 lines; 2 Random use(s); 1 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
<!-- page 72 -->
Elevation. Becomes Danfo/Matatu Rush: real recorded conductor calls at native speed; board the
right bus.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Tone Trainer
What it is. Identify tones (one H/M/L scheme for all languages, tone_trainer_game.dart:47-66).
Code. screens/games/tone_trainer_game.dart. Scan: 1 file(s), 552 lines; 3 Random use(s); 5 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Applies one High/Mid/Low scheme to every language (tone_trainer_game.dart:47-66),
which is false for Swahili (no lexical tone) and incomplete for Igbo downstep (P0-17). Thin content; no
learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Per-language tone inventories with minimal pairs and real audio; feeds the Tone Gym
ladder.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Pronunciation Duel
What it is. Head-to-head pronunciation (never records; random 75–95 score, :105-129, P0-18).
Code. screens/games/pronunciation_duel_game.dart. Scan: 1 file(s), 367 lines; 6 Random use(s); 5 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Never opens the microphone; random 75–95% score (pronunciation_duel_game.dart:105-
129, P0-18). Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Real recording and scoring; async duels with friends on minimal pairs; honest "practice
mode" (no score) until the scorer ships.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Pronunciation Game
What it is. Pronunciation practice game.
Code. screens/games/pronunciation_game.dart. Scan: 1 file(s), 606 lines; 15 Text( widgets vs 0 l10n
lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. No verified scoring path [Unverified whether it records]. Thin content; no learner-model
updates; inconsistent results screen; hard-coded strings.
<!-- page 73 -->
Elevation. Merge its rounds into the Tone Gym ladder as a game mode; real scoring.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Pronunciation Karaoke
What it is. Follow advancing words and hold the mic to "sing" (pitch score 60 + rng.nextInt(35),
:155).
Code. screens/games/pronunciation_karaoke_screen.dart. Scan: 1 file(s), 469 lines; 3 Random use(s); 2
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Pitch score is 60 + rng.nextInt(35) (pronunciation_karaoke_screen.dart:155, P0-18). Thin
content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes Echo Karaoke: real F0 line, licensed songs, children's rhymes and praise
phrases.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Emoji Translator
What it is. Translate emoji sequences into words.
Code. screens/games/emoji_translator_screen.dart. Scan: 1 file(s), 414 lines; 1 Random use(s); 2 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Emoji stories → sentences, then send the sentence as a chat sticker made from your
avatar.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Elders' Blessings
What it is. Learn blessings and proverbs from elders.
Code. screens/games/elders_blessings_screen.dart. Scan: 1 file(s), 380 lines; 2 Random use(s); 1 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. An elder character (avatar) gives blessings for life events (birth, marriage, travel); the
learner responds correctly. Content reviewed by cultural consultants.
<!-- page 74 -->
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Folktale Reconstruction
What it is. Reorder folktale scenes.
Code. screens/games/folktale_reconstruction_screen.dart. Scan: 1 file(s), 501 lines; 2 Random use(s);
3 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Àlọ́ / hadithi / iintsomi storytelling: rebuild the tale, then narrate it with scoring. Tales
come from the Living Archive.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Clan Lineage Story Builder
What it is. Build a lineage story (clan/kinship).
Code. screens/games/clan_lineage_story_builder_screen.dart. Scan: 1 file(s), 554 lines; 7 Random
use(s); 1 mock/fake marker(s); 2 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Teaches kinship vocabulary through a family tree you build; links to the Ancestral Tree
feature.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Conversation Relay
What it is. Multi-turn chain using bundled scenarios plus Polie.
Code. screens/games/conversation_relay_screen.dart. Scan: 1 file(s), 215 lines; 2 direct Groq-client
call site(s) (P0-3 dependency); 1 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Classroom and circle relay: each player adds a turn by voice; AI checks; the chain plays
back as an audio drama.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
<!-- page 75 -->
Board Word Games
What it is. Word seed puzzles with spaced letters and a category hint.
Code. screens/games/board_word_games.dart. Scan: 1 file(s), 540 lines; 8 Random use(s); 9 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Diacritic-aware word puzzles (Wordle-like with tone marks as a mechanic).
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Cultural Games collection
What it is. Launcher for the cultural games set.
Code. screens/games/cultural_games.dart. Scan: 1 file(s), 15 lines.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes the Arcade's "Culture" shelf (the screen remains as a themed shelf).
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Accent Puzzle
What it is. Accent decoding puzzle.
Code. screens/games/cultural/accent_puzzle_game.dart. Scan: 1 file(s), 375 lines; 2 Random use(s); 7
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Decode the same sentence spoken in different regional accents; builds real-world
listening.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Call & Response
What it is. Respond to calls (traditional call-and-response).
Code. screens/games/cultural/call_response_game.dart. Scan: 1 file(s), 411 lines; 3 Random use(s); 7
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
<!-- page 76 -->
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Musical call-and-response with real singers; responses scored on rhythm and tone.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Cultural Etiquette
What it is. Etiquette scenarios.
Code. screens/games/cultural/cultural_etiquette_game.dart. Scan: 1 file(s), 360 lines; 2 Random
use(s); 7 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Linked to Etiquette cards; consequences shown kindly ("Mama is surprised you didn't
kneel").
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Drum Word
What it is. Match drum patterns to words.
Code. screens/games/cultural/drum_word_game.dart. Scan: 1 file(s), 363 lines; 3 Random use(s); 8 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes Talking Drum (§10.3): drummed tone contours → words, then speak it.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Flashcard Safari
What it is. AR-style vocabulary scanning.
Code. screens/games/cultural/flashcard_safari_game.dart. Scan: 1 file(s), 351 lines; 4 Random use(s);
7 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Shares the Point & Say camera pipeline: a scavenger hunt ("find something red, say it").
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
<!-- page 77 -->
Lives in. Play → Words shelf.
Food Quest
What it is. Food vocabulary quest.
Code. screens/games/cultural/food_quest_game.dart. Scan: 1 file(s), 391 lines; 3 Random use(s); 7
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Market-to-pot quests with regional dishes; ties to Quiz Chef recipes.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Liar Liar
What it is. Detect grammatical errors.
Code. screens/games/cultural/liar_liar_game.dart. Scan: 1 file(s), 377 lines; 4 Random use(s); 8 Text(
widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Social bluffing: friends submit sentences, some wrong; others spot the lie. A multiplayer
grammar game.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Grammar shelf.
Multilingual Relay
What it is. Relay race across languages.
Code. screens/games/cultural/multilingual_relay_game.dart. Scan: 1 file(s), 405 lines; 2 Random
use(s); 10 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Pan-African relay: one word passed through several languages (Yoruba → Swahili → Zulu),
celebrating cognates and loanwords.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Phrase Sniper
What it is. Hit the right phrase quickly.
<!-- page 78 -->
Code. screens/games/cultural/phrase_sniper_game.dart. Scan: 1 file(s), 392 lines; 3 Random use(s); 7
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Listening reflex game with native audio; accessibility mode without time pressure.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Proverb Unlocker
What it is. Fill-in-the-blank ancestral tablet.
Code. screens/games/cultural/proverb_unlocker_game.dart. Scan: 1 file(s), 440 lines; 3 Random use(s);
1 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes Proverb Weaver (§10.3). CONSOLIDATE with the unrouted GameKit rewrite
games/proverb_unlocker/*, which its header says replaces the old random logic, so the better
implementation becomes the live one.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Culture shelf.
Rhythm Typing
What it is. Type to a rhythm.
Code. screens/games/cultural/rhythm_typing_game.dart. Scan: 1 file(s), 337 lines; 8 Text( widgets vs
0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Diacritic typing trainer to rhythm; builds tone-mark keyboard fluency.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Words shelf.
Tongue Twister Race
What it is. Rapid tongue-twister race.
Code. screens/games/cultural/tongue_twister_game.dart. Scan: 1 file(s), 346 lines; 9 Text( widgets vs
0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
<!-- page 79 -->
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Real scoring with fluency metrics; native tongue twisters per language; shareable duet
clips.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Village Quest
What it is. NPC conversation game.
Code. screens/games/cultural/village_quest_game.dart. Scan: 1 file(s), 406 lines; 3 Random use(s); 6
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Becomes the playable layer of the Village map: talk to NPCs in each place (market, café,
elder hut).
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Speaking shelf.
Ayo (mancala)
What it is. Ayo with a gloss MCQ when capturing.
Code. screens/games/traditional/ayo_mancala_screen.dart. Scan: 1 file(s), 552 lines; 3 Random use(s);
5 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Keep the authentic game; questions become due-word reviews; online play with friends; a
cultural history card.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Traditional shelf.
Snakes & Ladders (cultural)
What it is. Snakes and ladders with language questions.
Code. screens/games/traditional/cultural_snakes_ladders_screen.dart. Scan: 1 file(s), 470 lines; 7
Random use(s); 1 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Family mode for heritage households (pass-and-play), with questions at each player's own
level.
<!-- page 80 -->
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Traditional shelf.
Language Ludo
What it is. Ludo with language challenges.
Code. screens/games/traditional/language_ludo_screen.dart. Scan: 1 file(s), 552 lines; 5 Random
use(s); 4 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Multiplayer with friends and circles; speaking challenges on special squares.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Traditional shelf.
Suwe (hopscotch)
What it is. Hopscotch with gloss challenges.
Code. screens/games/traditional/suwe_hopscotch_screen.dart. Scan: 1 file(s), 445 lines; 3 Random
use(s); 3 Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Kids-friendly counting and body-movement vocabulary; a guardian-safe offline mode.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Traditional shelf.
Whot!
What it is. The Nigerian card game Whot with language rules.
Code. screens/games/traditional/whot_card_screen.dart. Scan: 1 file(s), 543 lines; 4 Random use(s); 10
Text( widgets vs 0 l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Card names and calls in the target language ("Check up!", "Last card!"); online play with
friends.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Traditional shelf.
Drum Rhythm
<!-- page 81 -->
What it is. Drum rhythm game (GameKit).
Code. games/drum_rhythm/drum_rhythm_screen.dart. Scan: 1 file(s), 318 lines; 7 Text( widgets vs 0
l10n lookups.
Current state. Works (launched from the Arcade via game_router.dart). Content comes from the
shared 85–118-word pool with no audio (§10.1). Random is used (see evidence), mostly for shuffling, AI
turns and effects; any scoring use is called out in the description.
Defects. Thin content; no learner-model updates; inconsistent results screen; hard-coded strings.
Elevation. Merge with Talking Drum as its rhythm mode; rhythm mapped to syllable timing.
UX and render. GameKit frame; one illustration style; audio on every target-language item; reduced-
motion variant. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Play → Tone & Sound shelf.
Tone Forge (revived)
What it is. A tone-crafting game; its header calls it the "flagship implementation" on GameKit.
Code. games/tone_forge/tone_forge_screen.dart. Scan: 1 file(s), 399 lines; 2 Text( widgets vs 0 l10n
lookups; not reachable from main.dart: tone_forge_screen.dart.
Current state.Unrouted (REVIVE). 5 files under games/tone_forge/, never imported from the app.
Defects. A flagship tone game that nobody can reach.
Elevation. Revive as a headline Tone & Sound game: forge words by shaping their pitch contour on
the Tone Lens (drag syllables up and down), hear the result and its meaning change (ọkọ/ọkọ̀/ọkọ́),
then speak it. Pairs with the Tone Gym.
UX and render. Tactile contour editor; blacksmith-forge art direction (a nod to Ogun / the West
African smithing tradition), reviewed. Rendered on the single unified design system (§3.4), with tone-
safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Play → Tone & Sound (featured).
18.6 Village hub (34 features)
Villages hub & Language Villages
What it is. Themed language villages (one per language) with places to visit.
Code. screens/village/villages_hub_screen.dart, screens/social/language_villages_screen.dart,
screens/village/language_village_place_screen.dart. Scan: 3 file(s), 894 lines; 1 direct Groq-client
call site(s) (P0-3 dependency); 11 Text( widgets vs 0 l10n lookups.
Current state. Works (routes villages, language-village, language-village-place).
Defects. Places are static screens; little living activity; hard-coded strings.
Elevation.The Village is the community home: an illustrated map per language where each place
is a real activity. Market = haggling games and buy/sell vocabulary; Café = live practice rooms; Elder
Hut = mentors and proverbs; Square = feed and events; School = live classroom; Story Tree =
folktales. Live presence dots show friends practising now (privacy-safe, opt-in).
UX and render. Hand-illustrated map per region (not one generic village); tap-to-enter places;
ambient soundscape (optional). Rendered on the single unified design system (§3.4), with tone-safe
Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village tab (root).
Swahili Village Map
What it is. A Swahili-specific village map.
Code. screens/village/swahili_village_map_screen.dart. Scan: 1 file(s), 367 lines; 4 Text( widgets vs
0 l10n lookups.
<!-- page 82 -->
Current state. Works (route swahili-village-map).
Defects. The only language with a map; others are generic.
Elevation. The template for every language: Yoruba compound, Igbo obi, Hausa birni, Zulu umuzi,
Xhosa village, a Lagos street for Pidgin. Each map is reviewed by cultural consultants.
UX and render. Same map engine, regional art direction. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → map (per language).
Village Market
What it is. Market place in the village.
Code. screens/village/village_market_screen.dart. Scan: 1 file(s), 507 lines; 15 Text( widgets vs 0
l10n lookups.
Current state. Works (route village-market).
Defects. Mostly static.
Elevation. Live Market Haggle stall, price and number drills, and the Magic Items shop (cosmetics
only, no paid power). Weekly market-day event.
UX and render. Stalls as cards; trader NPC avatar. Rendered on the single unified design system
(§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → map → Market.
Village Café
What it is. Social café space.
Code. screens/village/village_cafe_screen.dart. Scan: 1 file(s), 523 lines; 10 Text( widgets vs 0
l10n lookups.
Current state. Works (route village-cafe).
Defects. Little actual activity.
Elevation. Doorway to Practice Rooms and audio rooms: "3 tables open in Yoruba A2 right now".
Small-talk prompts on each table.
UX and render. Tables showing level and topic; join button. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → map → Café.
Elder Hut
What it is. Elder wisdom space.
Code. screens/village/elder_hut_screen.dart. Scan: 1 file(s), 582 lines; 8 Text( widgets vs 0 l10n
lookups.
Current state. Works (route elder-hut).
Defects. Static content.
Elevation. Home of Micro-Mentors and proverbs: book a 10-minute session with a verified native
speaker or elder, hear a proverb of the day with its story, and ask cultural questions (answered by
humans, labelled).
UX and render. Warm interior art; mentor cards with verified badge. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → map → Elder Hut.
Practice Rooms & Sessions
What it is. Set up and join group practice sessions, with a collaborative room and summary.
<!-- page 83 -->
Code. screens/village/practice_room_setup_screen.dart,
screens/village/practice_session_screen.dart,
screens/village/practice_room_collaborative_screen.dart,
screens/village/session_summary_screen.dart. Scan: 4 file(s), 2,303 lines; 8 Random use(s); 1 silently
swallowed catch(es); 27 Text( widgets vs 0 l10n lookups.
Current state. UI works (routes practice-room-*, practice-session, session-summary). The active
speaker is simulated with random numbers (practice_session_screen.dart:112).
Defects. Fake activity; no real matching; no safety controls.
Elevation.Real small-group rooms (2–6 learners at the same level) with a structured script: warm-
up, topic, roleplay and a recap. Polie acts as a facilitator (turn prompts, vocabulary hints) and the
session summary lists words used and corrections. Adult-only, or teacher-supervised for minors.
UX and render. Video/audio tiles; speaking-time meter to encourage balance; report and block in
one tap. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Village → Café → Practice Rooms; Today when a room matches.
Flashcard Focus (group)
What it is. Group flashcard session.
Code. screens/village/flashcard_focus_screen.dart. Scan: 1 file(s), 451 lines; 3 Text( widgets vs 0
l10n lookups.
Current state. UI works (route flashcard-focus); participants are hard-coded mocks
(flashcard_focus_screen.dart:26-34).
Defects. Fake participants.
Elevation. Replace the mocks with real matched learners or clearly labelled practice bots; study
together with a shared deck and a race to recall.
UX and render. Participant avatars with "bot" labels where applicable. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Café → Study together.
Matching Pairs (group)
What it is. Matching pairs in the village.
Code. screens/village/matching_pairs_screen.dart. Scan: 1 file(s), 302 lines; 3 Text( widgets vs 0
l10n lookups.
Current state. Works (route matching-pairs).
Defects. Duplicates Memory Map mechanics.
Elevation. Becomes the multiplayer mode of Memory Map: turn-based with friends, audio cards.
Both entry points stay.
UX and render. Shared board; turn indicator. Rendered on the single unified design system (§3.4),
with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Café; Play → Words.
Tribes
What it is. Join a tribe (team), discover tribes, tribe hub and tribe chat.
Code. screens/gamification/tribe_selection_screen.dart, screens/village/tribe_hub_screen.dart,
screens/village/tribe_discovery_screen.dart, screens/village/my_tribe_screen.dart,
screens/chat/tribe_chat_screen.dart, screens/chat/tribe_chat_screen_material3.dart. Scan: 6
file(s), 2,391 lines; 1 silently swallowed catch(es); 51 Text( widgets vs 0 l10n lookups.
Current state. Works (routes tribe, tribe-selection, tribe-hub, tribe-discovery, my-tribe).
Duplicate routes for the same screens.
<!-- page 84 -->
Defects. "Tribe" naming can read as ethnic grouping in an African context; duplicate routes; tribe
chat inherits the socket flaws (P0-4/5/6).
Elevation. Keep the feature, rename to Circles (study teams of 5–30) with optional language or city
themes. Weekly team goals and a team streak; circle chat with moderation; leaders get tools. The
"tribe" word remains available for playful naming by users.
UX and render. Circle crest builder (patterns from adire, kente, kanga, Ndebele — reviewed); team
progress ring. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp
targets, dark mode and l10n.
Lives in. Village → Circles.
Tribe vs Tribe, Tribal Duel & Inter-tribe Leaderboard
What it is. Team competitions and leaderboards between tribes.
Code. screens/social/tribe_vs_tribe_screen.dart, screens/village/tribal_duel_screen.dart,
screens/village/inter_tribe_leaderboard_screen.dart. Scan: 3 file(s), 1,441 lines; 6 mock/fake
marker(s); 33 Text( widgets vs 0 l10n lookups.
Current state. Works as UI (routes tribe_vs_tribe, tribal-duel, inter-tribe-leaderboard). Points
can be self-awarded (P0-8).
Defects. Cheatable scoring; competition without learning value.
Elevation.Circle Clash: weekend team events where points come only from verified learning
(reviews done, lessons passed, scored speaking). Server-side scoring; fair leagues by size.
UX and render. Event banner, live team bars, highlights reel at the end. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Circles → Clash; Today → Events.
Global Chat
What it is. Public chat rooms per language.
Code. screens/chat/global_chat_screen_material3.dart, screens/chat/global_chat_screen.dart,
screens/chat/community_chat_screen.dart, screens/chat/community_chat_screen_material3.dart.
Scan: 4 file(s), 2,206 lines; 4 silently swallowed catch(es); 35 Text( widgets vs 0 l10n lookups; not
reachable from main.dart: global_chat_screen.dart, community_chat_screen.dart,
community_chat_screen_material3.dart.
Current state. Works (route global_chat). Variants: global_chat_screen.dart and community chat
screens unrouted (CONSOLIDATE into the village and global chat).
Defects. P0-4/5/6 socket flaws; moderation cosmetic (P0-11); open to minors (P0-10).
Elevation.Language Squares: public rooms per language and level with a "target-language only"
mode, Tone Lens on messages, tap-to-translate, and one-tap "correct me" requests. Real moderation
and slow-mode.
UX and render. Chat with level badges and pinned daily topic. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Square → Rooms.
Private Chat (DMs) (revived)
What it is. One-to-one messaging with search and contact info.
Code. screens/chat/private_chat_list_screen.dart, screens/chat/private_chat_screen.dart,
screens/chat/private_chat_screen_material3.dart, screens/chat/chat_search_screen.dart,
screens/chat/contact_info_screen.dart. Scan: 5 file(s), 2,853 lines; 3 mock/fake marker(s); 3 silently
swallowed catch(es); 22 Text( widgets vs 1 l10n lookups; not reachable from main.dart:
private_chat_screen_material3.dart, chat_search_screen.dart, contact_info_screen.dart.
<!-- page 85 -->
Current state. List and chat work (route private-chat-inbox). chat_search_screen.dart and
contact_info_screen.dart (block/report) are unrouted (REVIVE); the material3 chat variant is
unrouted (CONSOLIDATE).
Defects. P0-4/5/6; no reachable block/report UI; open to minors.
Elevation.Language-exchange DMs: each message can be written in the target language with an
inline "check my message" (AI suggestion before sending) and a partner correction feature. Revived
chat search finds words and media; revived contact info gives block, report, mute and shared-words
history.
UX and render. WhatsApp-familiar layout made learning-native; correction bubbles in a distinct
colour. Rendered on the single unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets,
dark mode and l10n.
Lives in. Village → Chats.
Call History
What it is. Log of voice/video calls.
Code. screens/chat/call_history_screen.dart. Scan: 1 file(s), 268 lines; 5 Text( widgets vs 0 l10n
lookups.
Current state. Works (route call-history).
Defects. Calls carry no learning value afterwards.
Elevation. Each call entry shows minutes spoken in the target language and words learned (opt-in
transcript), and offers "save phrases from this call".
UX and render. List with minutes chip. Rendered on the single unified design system (§3.4), with
tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Chats → Calls.
Chat Welcome & Community Guidelines (revived)
What it is. Welcome screen for the chat section.
Code. screens/chat/welcome_screen.dart. Scan: 1 file(s), 332 lines; 1 mock/fake marker(s); 2 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: welcome_screen.dart.
Current state.Unrouted (REVIVE).
Defects. Community norms never shown.
Elevation. Revive as the first-entry pledge: 3 friendly rules (be kind, help learners, no harassment)
with an illustrated agreement, shown once before the first message, plus a link in settings.
UX and render. Short illustrated cards; one-tap agree. Rendered on the single unified design system
(§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village first entry; Me → Safety.
Moderation Tools (revived)
What it is. Tools for moderators.
Code. screens/chat/moderation_tools_screen.dart, screens/social_audio/moderation_screen.dart.
Scan: 2 file(s), 531 lines; 25 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
moderation_tools_screen.dart.
Current state. chat/moderation_tools_screen.dart unrouted (REVIVE); social-audio moderation
works.
Defects. No moderation surface for chat.
Elevation. Revive as Community Stewards tools for circle leaders and trusted volunteers: reported
queue, mute/timeout, slow mode, pinned rules, with escalation to staff. Training module required.
UX and render. Queue cards with context and quick actions. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
<!-- page 86 -->
Lives in. Village → Circles → Steward tools (role-gated).
Social Hub & Connections
What it is. Friends, connections, friend profiles and people search.
Code. screens/social/social_hub_screen.dart, screens/social/user_connections_screen.dart,
screens/social/friend_profile_screen.dart, screens/chat/user_search_global_id_screen.dart,
screens/social/global_people_search_screen.dart. Scan: 5 file(s), 2,427 lines; 1 mock/fake marker(s);
42 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
global_people_search_screen.dart.
Current state. Works (routes social-hub, connections, friend-profile).
global_people_search_screen.dart unrouted (CONSOLIDATE into the global-ID search).
Defects. Find-anyone search with no age or privacy controls.
Elevation.Language partners: suggested partners who speak the language you learn and learn the
one you speak (tandem matching), with friend profiles showing languages, level and shared goals.
Under-18s never appear in adult discovery.
UX and render. Partner cards with "speaks / learns" pills. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → People.
Friend Quests & Challenge a Friend
What it is. Create quests with friends and challenge them.
Code. screens/social/friend_quests_screen.dart, screens/social/create_friend_quest_screen.dart,
screens/social/challenge_friend_screen.dart. Scan: 3 file(s), 1,875 lines; 35 Text( widgets vs 0 l10n
lookups.
Current state. Works (routes friend-quests, create-friend-quest, challenge-friend).
Defects. Challenges are score-only, and scores can be faked (P0-8, P0-18).
Elevation.Buddy quests: shared weekly goals (both practise five days), async challenges on real
skills (tone duel, review race), and nudges that don't nag.
UX and render. Paired progress bars; challenge cards in chat. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → People → Quests; Today.
Share Progress
What it is. Share achievements externally.
Code. screens/social/share_progress_screen.dart. Scan: 1 file(s), 417 lines; 2 TODO(s); 15 Text(
widgets vs 0 l10n lookups.
Current state. Works (route share-progress).
Defects. Generic share cards.
Elevation.Beautiful share cards: the learner's avatar saying a phrase they learned (short clip),
Passport stamps and streak milestones in the target language. Privacy-checked (no exact location,
kids can't share publicly).
UX and render. Story-format cards (9:16) with the brand system. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Progress → Share; after milestones.
Social Gifting
What it is. Send gifts to friends.
<!-- page 87 -->
Code. screens/social/social_gifting_screen.dart. Scan: 1 file(s), 379 lines; 20 Text( widgets vs 0
l10n lookups.
Current state. Works as UI; opened from a friend profile (friend_profile_screen.dart:367).
Currency can be self-minted (P0-7).
Defects. Cheatable economy.
Elevation.Gift a lesson / streak freeze / cosmetic using server-validated currency; send a voice
blessing with the gift ("Ẹ ku odun!").
UX and render. Gift-wrap animation; message composer. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → People → Gift.
Community Corrections
What it is. Native speakers correct learners' submissions.
Code. screens/social/community_corrections_screen.dart. Scan: 1 file(s), 336 lines; 9 Text( widgets
vs 0 l10n lookups.
Current state. Works as UI; opened from the Social Hub (social_hub_screen.dart:125).
Defects. No reputation or quality control for correctors.
Elevation.Native Corrections: learners post short writing or audio; verified natives correct with
inline edits and audio; reputation for helpful correctors; best corrections feed the Living Dictionary as
usage examples (with consent).
UX and render. Diff-style inline edits; audio replies. Rendered on the single unified design system
(§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Corrections.
Ancestral Tree
What it is. Family tree feature.
Code. screens/social/ancestral_tree_screen.dart. Scan: 1 file(s), 419 lines; 10 Text( widgets vs 0
l10n lookups.
Current state. Works (route ancestral_tree).
Defects. Not connected to learning.
Elevation.Family Tree in your language: heritage learners build their family tree with kinship
terms (ìyá àgbà, nne nne, ugogo), record relatives' names with correct tones, and invite family to add
voice notes. Private by default.
UX and render. Tree with avatar nodes; kinship terms on edges. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Heritage; Learn → Culture.
Micro-Mentors
What it is. Short sessions with mentors.
Code. screens/community/micro_mentor_hub_screen.dart,
screens/community/micro_mentor_session_detail_screen.dart. Scan: 2 file(s), 830 lines; 38 Text(
widgets vs 0 l10n lookups.
Current state. Works (route micro-mentor-hub).
Defects. No verification, safeguarding or payment flow visible [verify].
Elevation.Book a native for 10–20 minute focused sessions (pronunciation clinic, heritage
conversation, exam prep), with verified mentors, ratings, safeguarding rules, and payouts in local
currency. Mentors earn from LingAfriq: jobs for native speakers.
UX and render. Mentor profiles with sample audio; booking sheet. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
<!-- page 88 -->
Lives in. Village → Elder Hut → Mentors.
Live Classroom
What it is. Live online classes with lobby, notes, speaker queue, roster, assignments and privacy.
Code. screens/chat/live_classroom_screen_material3.dart,
screens/classroom/classroom_lobby_screen.dart, screens/classroom/classroom_notes_screen.dart,
screens/classroom/speaker_queue_screen.dart, screens/classroom/classroom_roster_screen.dart,
screens/classroom/classroom_assignments_screen.dart (+5 more). Scan: 11 file(s), 5,676 lines; 1 direct
Groq-client call site(s) (P0-3 dependency); 2 Random use(s); 4 silently swallowed catch(es); 112 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: live_classroom_screen.dart,
live_classroom_mobile_screen.dart, classroom_session_screen.dart,
classroom_chat_livekit_screen.dart.
Current state. Works (routes live-classroom, classroom-*, speaker-queue). Four older classroom
screens unrouted (CONSOLIDATE into live_classroom_screen_material3.dart).
Defects. Five parallel implementations; safeguarding for minors not visible.
Elevation.School in the Village: scheduled live classes by level with a teacher, raise-hand speaker
queue, shared whiteboard with Tone Lens, auto-notes (transcript → key phrases), and assignments
that land in the learner's Review. Recordings opt-in.
UX and render. Classroom grid; hand-raise queue; notes panel. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → School.
Teacher Classroom Dashboard (revived)
What it is. Dashboard for teachers to manage a class.
Code. screens/gamification/classroom_dashboard_screen.dart. Scan: 1 file(s), 739 lines; 19 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: classroom_dashboard_screen.dart.
Current state.Unrouted (REVIVE).
Defects. Teachers have no management surface.
Elevation. Revive as LingAfriq for Schools: class roster, assign units, see weak skills per student, run
a live game (Conversation Relay, Liar Liar) on a projector. A B2B channel with Nigerian, Kenyan and
South African schools (and diaspora Saturday schools).
UX and render. Desktop/tablet-friendly layout; class heatmap. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Teaching (role-gated); web.
Social Audio Rooms (revived)
What it is. Clubhouse-style audio rooms: discover, create, room detail, following and schedule.
Code. screens/social_audio/room_discovery_screen.dart,
screens/social_audio/create_room_screen.dart, screens/social_audio/room_detail_screen.dart,
screens/social_audio/following_screen.dart,
screens/social_audio/scheduled_sessions_screen.dart. Scan: 5 file(s), 1,669 lines; 6 mock/fake
marker(s); 39 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
following_screen.dart, scheduled_sessions_screen.dart.
Current state. Discovery, create and detail are reachable (not orphans; no named route, entry point
unverified). following_screen.dart and scheduled_sessions_screen.dart are unrouted (REVIVE).
Defects. No scheduling or following, so rooms are empty; moderation for minors.
Elevation.Village Radio: scheduled audio shows hosted by natives (folktale night, Pidgin news, Zulu
music talk), learner rooms by level, and revived following and schedule so people come back. Live
captions with Tone Lens; replays become listening lessons.
<!-- page 89 -->
UX and render. Schedule cards; speaker stage; captions bar. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Radio.
Status (WhatsApp-style)
What it is. 24-hour status updates.
Code. screens/wa/wa_status_list_screen.dart, screens/wa/wa_status_create_screen.dart,
screens/wa/wa_status_view_screen.dart. Scan: 3 file(s), 758 lines; 16 Text( widgets vs 0 l10n lookups.
Current state. Works (routes wa-status, wa-status-create, wa-status-view).
Defects. Status events broadcast globally (P0-6).
Elevation.Language Status: post a daily status in the target language (text, photo or voice) with a
word-of-the-day sticker; friends react with corrections or "I learned this". Prompt: "Say what you ate
today in Igbo".
UX and render. Familiar ring UI; stickers with the learner's avatar. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Status.
Starred Messages & Media Gallery
What it is. Starred messages and shared media.
Code. screens/wa/wa_starred_messages_screen.dart, screens/wa/wa_media_gallery_screen.dart.
Scan: 2 file(s), 441 lines; 15 Text( widgets vs 0 l10n lookups.
Current state. Works (routes wa-starred, wa-media-gallery).
Defects. Starred items aren't reusable for learning.
Elevation.Starred = Saved phrases: starring a message adds it to My Words with audio; the media
gallery doubles as a personal phrasebook of voice notes.
UX and render. Grid with phrase overlays. Rendered on the single unified design system (§3.4), with
tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Chats → Saved.
Snaps & Streaks (Snapchat-style)
What it is. Disappearing photo/video snaps, stories and streaks.
Code. screens/snap/snap_camera_screen.dart, screens/snap/snap_inbox_screen.dart,
screens/snap/snap_story_feed_screen.dart, screens/snap/snap_streaks_screen.dart,
screens/snap/snap_viewer_screen.dart. Scan: 5 file(s), 629 lines; 13 Text( widgets vs 0 l10n lookups.
Current state. Works (routes snap-*). Snaps never actually disappear (P0-12).
Defects. Privacy promise broken; content risks for minors.
Elevation.Clips: send a photo or 10-second video with a phrase overlay in the target language
(camera labels from Point & Say suggest words); streaks count only when both sides use the
language. Real deletion, kids restricted to circles.
UX and render. Camera with phrase chips; AR text in correct diacritics. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Clips; Lens camera.
Community Feed (X-style)
What it is. Twitter/X-style public feed: home, compose, threads, explore, lists, profiles, notifications.
Code. screens/feed/x_feed_home_screen.dart, screens/feed/x_compose_screen.dart,
screens/feed/x_post_detail_screen.dart, screens/feed/feed_post_thread_screen.dart,
screens/feed/x_explore_screen.dart, screens/feed/x_lists_screen.dart (+3 more). Scan: 9 file(s),
<!-- page 90 -->
2,183 lines; 4 mock/fake marker(s); 1 silently swallowed catch(es); 46 Text( widgets vs 0 l10n
lookups; not reachable from main.dart: post_detail_screen.dart, post_detail_clean_screen.dart.
Current state. Works (routes x-feed-*). Older post-detail screens unrouted (CONSOLIDATE).
Defects. Moderation cosmetic (P0-11); generic feed with no learning hook.
Elevation.The Square feed: posts in the target language with Tone Lens and tap-to-translate; native
"verified speaker" badges; threads for questions ("How do you say...?") that resolve into the Living
Dictionary; lists by language and topic.
UX and render. Feed cards with language tag; translate toggle. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Square.
Explore, Search & Community Profile
What it is. Community discovery, search and profiles.
Code. screens/feed/explore_community_screen.dart, screens/feed/search_community_screen.dart,
screens/feed/community_profile_screen.dart. Scan: 3 file(s), 324 lines; 3 mock/fake marker(s); 7
Text( widgets vs 0 l10n lookups.
Current state. Works (routes explore-community, search-community, community-profile).
Defects. Overlaps with the X explore screen.
Elevation. Explore becomes the Square's discover page (trending phrases, events, top correctors);
search folds into the global Search; community profiles show languages, contributions and badges.
UX and render. Discover grid. Rendered on the single unified design system (§3.4), with tone-safe
Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Square → Discover; global Search.
Create Content (UGC)
What it is. Users create lessons, quizzes and stories, with validation feedback.
Code. screens/ugc/ugc_hub_screen.dart, screens/ugc/create_lesson_screen.dart,
screens/ugc/create_quiz_screen.dart, screens/ugc/create_story_screen.dart,
screens/ugc/ugc_validation_feedback_screen.dart, screens/ugc/create_lesson_screen_enhanced.dart
(+2 more). Scan: 8 file(s), 2,318 lines; 57 Text( widgets vs 0 l10n lookups; not reachable from
main.dart: create_quiz_screen_enhanced.dart, create_story_screen_enhanced.dart.
Current state. Works (route ugc). Enhanced variants unrouted (CONSOLIDATE, harvesting their
features).
Defects. No editorial pipeline; content quality unknown.
Elevation.Creator Studio: templates for mini-lessons, quizzes and stories; AI checks for diacritics
and accuracy; native-review queue; published content credited to the creator, with revenue share for
top creators.
UX and render. Editor with live preview; review status chips. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Create (unlocks at B1).
Voice Contribution
What it is. Record voice samples for the dataset.
Code. screens/voice_contribution/voice_contribution_screen.dart. Scan: 1 file(s), 514 lines; 1
silently swallowed catch(es); 18 Text( widgets vs 0 l10n lookups.
Current state. Works (route contribute_voice).
Defects. Consent and licensing of recordings unclear [verify].
Elevation.Lend your voice: natives record prompted sentences with explicit consent and licence
choice (AI stack §5), get credited, and earn currency or cash. Feeds the TTS/ASR data flywheel.
<!-- page 91 -->
UX and render. Prompt card, quality meter, consent sheet. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Contribute.
Native Speaker Contribution & Lesson Item Verification (revived)
What it is. Natives contribute content and verify lesson items.
Code. screens/contribute/native_speaker_contribution_screen.dart,
screens/contribute/lesson_item_verification_screen.dart. Scan: 2 file(s), 1,500 lines; 41 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: native_speaker_contribution_screen.dart,
lesson_item_verification_screen.dart.
Current state.Both unrouted (REVIVE).
Defects. The human-validation loop the language factory needs (§6.4.1) is unreachable.
Elevation. Revive as the Verify queue: native speakers swipe through AI-drafted lesson items
(correct / fix / reject), add audio, and earn reputation. This powers the fast-scaling waves.
UX and render. Swipe cards with audio; fix-inline editor. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Contribute → Verify (verified natives).
Native Content Review
What it is. Review queue for native content.
Code. screens/content/native_content_review_screen.dart. Scan: 1 file(s), 258 lines; 8 Text( widgets
vs 0 l10n lookups.
Current state. Works (route native-content-review).
Defects. Overlaps with the revived verification screens.
Elevation. Becomes the reviewer dashboard above the Verify queue: stats, disagreements and
escalations to linguists.
UX and render. Dashboard with queue counts. Rendered on the single unified design system (§3.4),
with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Village → Contribute → Review.
18.7 Me hub (15 features)
Profile
What it is. The learner profile, with editing.
Code. screens/tabs_view/profile/profile_tab_material3.dart,
screens/profile/profile_screen_material3.dart,
screens/tabs_view/profile/profile_edit_screen.dart, screens/settings/edit_profile_screen.dart,
screens/profile/user_profile_screen.dart. Scan: 5 file(s), 2,302 lines; 5 mock/fake marker(s); 9
Text( widgets vs 0 l10n lookups; not reachable from main.dart: user_profile_screen.dart.
Current state. Works (Profile tab). user_profile_screen.dart unrouted (CONSOLIDATE). Two edit-
profile screens.
Defects. Duplicate edit flows; profile is stats-heavy, identity-light.
Elevation.My LingAfriq identity: avatar (§4), languages and levels, heritage story (optional),
Passport stamps, contributions and circles. One edit flow.
UX and render. Avatar hero; language pills; stamp shelf. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me (avatar, top-left).
Global Handle (@id) (revived)
<!-- page 92 -->
What it is. Pick a unique @handle used across chat and the feed.
Code. screens/profile/global_handle_edit_screen.dart,
screens/profile/profile_global_id_section.dart. Scan: 2 file(s), 666 lines; 18 Text( widgets vs 0
l10n lookups; not reachable from main.dart: global_handle_edit_screen.dart,
profile_global_id_section.dart.
Current state.Unrouted (REVIVE). The live chat search already uses global IDs
(user_search_global_id_screen.dart).
Defects. People can be searched by global ID but can't set one.
Elevation. Revive in onboarding (after account creation) and profile: choose an @handle, with
suggestions in the target language (e.g. @ade_learns_igbo) and safety checks.
UX and render. Inline availability check. Rendered on the single unified design system (§3.4), with
tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Profile → Handle; onboarding.
Progress Dashboard
What it is. Charts of learning progress.
Code. screens/progress/progress_dashboard_screen.dart,
screens/global/global_progress_screen.dart. Scan: 2 file(s), 904 lines; 1 mock/fake marker(s); 11
Text( widgets vs 0 l10n lookups; not reachable from main.dart: global_progress_screen.dart.
Current state. Works (route progress). global_progress_screen.dart unrouted (CONSOLIDATE as a
tab).
Defects. Vanity metrics (XP) rather than ability.
Elevation.Can-do progress: CEFR can-do statements ticked with evidence, skill radar (listen, speak,
read, write, tone), words known, speaking minutes and forecast ("A2 in about 6 weeks at this pace").
Tabs: Me, Languages, Global.
UX and render. Calm charts; evidence links to recordings. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Progress.
Achievements & Badges
What it is. Achievements and a badge collection.
Code. screens/achievements/achievements_screen.dart,
screens/gamification/badge_collection_screen_material3.dart,
screens/gamification/badge_collection_screen.dart. Scan: 3 file(s), 1,115 lines; 20 Text( widgets vs
0 l10n lookups.
Current state. Works (routes achievements, badges).
Defects. XP awards can be self-awarded (P0-8); badges for volume, not mastery.
Elevation.Cultural badges earned by real milestones: first proverb used correctly, 100 tones nailed,
first native conversation. Artwork from regional craft traditions (adire, kente, Zulu beadwork),
reviewed. Server-verified.
UX and render. Badge cabinet with stories behind each design. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Achievements.
Leaderboards
What it is. Global and country leaderboards.
Code. screens/gamification/leaderboard_screen.dart,
screens/tabs_view/standings/standings_tab_material3.dart. Scan: 2 file(s), 782 lines; 9 Text(
widgets vs 0 l10n lookups.
<!-- page 93 -->
Current state. Works (route leaderboard, standings tab).
Defects. Cheatable (P0-8); demotivating for beginners.
Elevation.Leagues of 30 similar learners with weekly promotion, an opt-out, and circle and country
boards; points only from verified learning.
UX and render. League ladder; your row pinned. Rendered on the single unified design system
(§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Leagues; Village → Circles.
Magic Items
What it is. Power-ups and items.
Code. screens/gamification/magic_items_screen.dart. Scan: 1 file(s), 491 lines; 20 Text( widgets vs 0
l10n lookups.
Current state. Works (route magic_items).
Defects. Economy self-mintable (P0-7).
Elevation.Cosmetic and helper shop: avatar outfits from regional designers, streak freezes and
hint tokens; server-validated currency; nothing pay-to-win.
UX and render. Shop grid with try-on on the avatar. Rendered on the single unified design system
(§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Wardrobe & Shop; Village → Market.
Settings, Privacy & Appearance
What it is. App settings, privacy, password change, dark mode, account deletion.
Code. screens/settings/settings_screen_material3.dart, screens/settings/settings_screen.dart,
screens/settings/privacy_settings_screen.dart, screens/settings/change_password_screen.dart,
screens/tabs_view/profile/change_password_screen.dart,
screens/tabs_view/profile/delete_account_dialogue.dart. Scan: 6 file(s), 3,184 lines; 1 mock/fake
marker(s); 32 Text( widgets vs 1 l10n lookups; not reachable from main.dart: settings_screen.dart.
Current state. Works (route settings; dark mode toggle in drawer). Older settings screen unrouted
(CONSOLIDATE). Two change-password screens.
Defects. Privacy controls thin for minors; duplicates.
Elevation. Grouped settings: Learning (daily goal, reminders, voice), Privacy & Safety (who can
message me, discoverability, data export/delete per NDPA), Appearance (theme, text size, reduced
motion), Account.
UX and render. Standard grouped list; search in settings. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Settings.
Subscription & Plans (revived)
What it is. Plans and purchase.
Code. screens/subscription/subscription_screen.dart. Scan: 1 file(s), 286 lines; 5 Text( widgets vs 0
l10n lookups; not reachable from main.dart: subscription_screen.dart.
Current state.Unrouted (REVIVE). No live paywall in the app (rg for
Paywall/RevenueCat/purchasePackage in live files: none); purchases not verified server-side (P0-27).
Defects. No monetisation surface.
Elevation. Revive as LingAfriq Plus: free core learning forever; Plus adds unlimited Polie voice,
offline packs, mentor credits and family sharing. Local pricing (NGN, KES, ZAR) and mobile-money
options; server-verified receipts.
UX and render. Honest comparison table; no dark patterns. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
<!-- page 94 -->
Lives in. Me → Plus.
Family / Guardian Dashboard (revived)
What it is. Family plan management.
Code. screens/subscription/family_dashboard_screen.dart. Scan: 1 file(s), 529 lines; 10 Text(
widgets vs 0 l10n lookups; not reachable from main.dart: family_dashboard_screen.dart.
Current state.Unrouted (REVIVE).
Defects. No guardian controls although onboarding collects "child" (P0-10).
Elevation. Revive as the Guardian hub: link child profiles, see progress, set safe-social rules (circles
only, no DMs), screen time and a weekly report. Required for kids' mode.
UX and render. Child cards with progress and controls. Rendered on the single unified design
system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Family (guardians).
About & Policy (revived)
What it is. About the company and legal policies.
Code. screens/tabs_view/profile/about_us_screen.dart,
screens/tabs_view/profile/app_policy_screen.dart. Scan: 2 file(s), 102 lines; not reachable from
main.dart: about_us_screen.dart.
Current state. About is unrouted (REVIVE); policy works (route policy).
Defects. No mission story in the app.
Elevation. Revive About as Our Story: the mission, the native-speaker community, language-credit
roll (contributors) and AI transparency (which models, how data is used).
UX and render. Editorial page with photos of contributors (with consent). Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → About.
Sign in, Sign up & Email Verification
What it is. Authentication flows.
Code. screens/auth/world_class_login_screen.dart, screens/auth/world_class_signup_screen.dart,
screens/auth/forgot_password_screen.dart, screens/auth/email_verification_screen.dart,
screens/auth/login_screen.dart, screens/auth/sign_up_screen.dart. Scan: 6 file(s), 2,972 lines; 30
Text( widgets vs 0 l10n lookups; not reachable from main.dart: login_screen.dart,
sign_up_screen.dart.
Current state. Works. Older login/sign-up unrouted (CONSOLIDATE). Login enumeration and no
lockout (P0-25); every release logs users out (P0-20).
Defects. P0-20, P0-25.
Elevation. Try-before-signup (first lesson without an account), then passkey, Google/Apple, phone
OTP (key for Nigeria/Kenya) and email; generic error messages; lockout.
UX and render. Short, branded flows. Rendered on the single unified design system (§3.4), with tone-
safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Before the app; Me → Account.
Onboarding & Placement
What it is. First-run onboarding and placement test.
Code. screens/onboarding/unified_onboarding_screen.dart,
screens/onboarding/placement_test_screen.dart,
screens/onboarding/kijiji_onboarding_screen.dart,
<!-- page 95 -->
screens/onboarding/enhanced_onboarding_flow_screen.dart,
screens/onboarding/modern_onboarding_screen.dart, screens/onboarding/onboarding_screen.dart (+2
more). Scan: 8 file(s), 8,766 lines; 1 mock/fake marker(s); 110 Text( widgets vs 0 l10n lookups; not
reachable from main.dart: kijiji_onboarding_screen.dart, enhanced_onboarding_flow_screen.dart,
modern_onboarding_screen.dart, onboarding_screen.dart, placement_quiz_screen.dart.
Current state. Unified onboarding works; answers stored as Map.toString() (P0-21). Five other
onboarding variants and placement quiz unrouted (CONSOLIDATE; harvest Kijiji's village story).
Defects. P0-21; long forms before value.
Elevation. See §5: 90 seconds to the first spoken word. Choose language and why, speak one
greeting, meet your avatar, get a 3-minute adaptive placement. Kijiji's village-arrival story becomes
the narrative frame.
UX and render. Full-screen illustrated steps; skip always available. Rendered on the single unified
design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. First run.
Splash
What it is. Launch screen.
Code. screens/splash/splash_screen.dart. Scan: 1 file(s), 13 lines.
Current state. Works.
Defects. Plain wait screen [verify content].
Elevation. A 1-second greeting in the learner's target language, with the avatar waving (Rive),
cached for offline.
UX and render. Brand mark + greeting. Rendered on the single unified design system (§3.4), with
tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Launch.
Features Guide, Navigation Hub & First-use Tips (revived)
What it is. A guide to app features, a navigation hub, and per-feature intro screens.
Code. screens/help/features_guide_screen.dart, screens/help/stitch_navigation_hub_screen.dart,
screens/help/feature_preloader_screen.dart, screens/help/games_preloader.dart,
screens/help/gamification_preloader.dart, screens/help/polie_preloader.dart. Scan: 6 file(s), 1,353
lines; 1 mock/fake marker(s); 9 Text( widgets vs 0 l10n lookups; not reachable from main.dart:
feature_preloader_screen.dart, games_preloader.dart, gamification_preloader.dart,
polie_preloader.dart.
Current state. Guide and Stitch hub work (routes features_guide, stitch-hub). The four preloaders
are unrouted (REVIVE as contextual tips).
Defects. Features are explained in one long list instead of in context.
Elevation. Becomes the All features directory (A–Z, searchable, with locked items showing "unlocks
at..." and a preview), which replaces the drawer so nothing is lost. The revived preloaders become
first-use tips: a 3-card intro the first time someone opens Polie, games or gamification.
UX and render. Directory grouped by hub with icons; tips as bottom sheets. Rendered on the single
unified design system (§3.4), with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → All features; contextual first use.
Staff & Micro-mentor Reports
What it is. Staff view of mentor reports.
Code. screens/staff/micro_mentor_reports_screen.dart. Scan: 1 file(s), 340 lines; 15 Text( widgets vs
0 l10n lookups.
Current state. Works (route staff-micro-mentor-reports; drawer item).
<!-- page 96 -->
Defects. Staff tooling in the consumer app; role checks need verification [verify].
Elevation. Keep in-app for staff on the go, behind server-checked roles, with a fuller version in the
admin console (§14).
UX and render. Role-gated; compact queue. Rendered on the single unified design system (§3.4),
with tone-safe Noto fonts, 48 dp targets, dark mode and l10n.
Lives in. Me → Staff (role-gated).
Method note: every finding cites file and line in the read-only copy dated as provided on 17 Oct 2026. Items
marked [unverified] or [verify] could not be confirmed from source alone (server configuration, deployed
environment variables, store-console settings, or legal thresholds). No .riv files, audio or .git history were
present in the copy, so audio quality and the secret history in git were not inspected directly. The Rive avatars have
not been built yet (confirmed by Tope), so §4 is a forward brief, not an audit.
