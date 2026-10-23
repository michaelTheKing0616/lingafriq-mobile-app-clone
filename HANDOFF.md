charter: v2

# Handoff

The Firebase service account, the Apple `.p8`, and the five client AI keys stay in the tree. They were not deleted, revoked, or replaced. A staged untrack of those files was reverted.

## Where this stopped

Work is continuous on `cloud-handoff`. Do not pause between cards. The key files remain tracked.

- Mobile: `cloud-handoff`. Latest card push is P2-043. FSRS-6 matches the published vectors. Fuzzing is off.
- Backend: `cloud-handoff`. Latest card push is P2-038. Flag buckets are stable. HS256 still verifies.
- The key files are still tracked. Copies also exist in `~/.lingafriq/secrets/` (mode 600). History was not rewritten.
- Admin gamification edits were not part of this build. They are in git stash `admin-gamification-wip-not-this-build` on `lingafriq-admin` `cloud-handoff`.
- P2-043 is done. Next card is P2-044. P2-031 stays a live-host switch-on and is not Done. P7-961 does not jump this queue.

## Next 3 steps

1. Build P2-044, then the next card. Build any unfinished dependency first. The host switches below do not stop the queue.
2. Do not stop to ask what is next.
3. Do not remove the Firebase service account, the Apple `.p8`, or the five client AI keys. Intron stays off until its flag and server key are set.

## Gates

Only **G0 Plan approved** has passed (Tope, 2026-10-21). G1–G13 have not.

| Gate | Pass criteria | Passed |
|---|---|---|
| G0 | RTM fully mapped; charter and routing approved; D1–D5 signed; C1–C3 resolved | Yes |
| G1 Containment | 27 P0s closed, including a clean secrets history, keys out of the client, gateway, socket ACL, server XP, age rules, moderation, honest practice | No |
| G2 Platform | CI gates, OpenAPI client, one outbox, auth v2, SLOs, FSRS-6 | No |
| G3 Design + shell | Tokens, fonts, component library, 5-tab shell, scorecards | No |
| G4 Content engine | Counsel-signed licence register, 7 language kits, Studio MVP | No |
| G5–G7 | Stage-1 A1, A2, B1 error and audio gates | No |
| G8 Speech + AI | Scorer, ASR sets, per-language TTS, latency, 300-item evals | No |
| G9 Safety + social | Guardian hub, moderation, report/block, CSAM matching, pen test | No |
| G10–G13 | Feature completeness, personas, release, scale | No |

Full exit text: `docs/build/03_PHASES_GATES.md`.

## Cards

1,079 cards. Counts from `docs/plan/CARD_STATUS.tsv`: Draft 1001, Blocked-External 44, Done 29, Ready 5.

P1 Done (24): P1-007, P1-008, P1-012 through P1-019, P1-023, P1-024, P1-026 through P1-037.

P1 in progress, uncommitted, not reviewed: P1-040 (non-commercial TTS/MT removal) and the provider router from the AI wiring prompt.

P1 not started as implementation, still Draft unless noted: P1-003, P1-004, P1-005, P1-006, P1-009, P1-010, P1-011, P1-020, P1-021, P1-022, P1-025, P1-038 through P1-062. P1-001 and P1-002 are Blocked-External in the card files. Tope has since said not to revoke the Firebase account, the Apple key, or the five client AI keys.

P2–P13, F-001–F-151, and the epic cards are Draft. EXT cards are Blocked-External. Every id is in `docs/plan/CARD_STATUS.tsv`.

## Decisions

- D0–D10, D21, D22, D23 are signed in `docs/build/DECISIONS.md`. D11–D19 were still awaiting a signature in that file.
- 2026-10-22, Tope: do not revoke or replace the Firebase service account, the Apple `.p8`, or the five client AI keys. Build with those same accounts. Copies were moved to `~/.lingafriq/secrets/` because the files were tracked. This is not yet written into `DECISIONS.md`.
- 2026-10-23, Tope (D11): ask for birth year, not a full date of birth. Under the country child threshold, verifiable parental consent comes before any account data is stored. Child mode gates open social, chat, marketplace, and ads, and keeps Historical Personas free chat under child-safe moderation. Teen accounts are private and do not take direct messages from adults. Features are gated, not removed.
- 2026-10-22, Tope: do not revoke JWT material. P1-046 must keep accepting the current HS256 secret. Not yet implemented.
- 2026-10-23, Tope (D27): the vault is Doppler. The backend reads it when `DOPPLER_TOKEN` is set. `.env` remains the local-development fallback. Moving the existing keys stays at the end of the build.
- Curriculum wiring stays paused. AI providers stay off until the flags and keys are set. `AI_EVALS_PASSED` stays false.

## Open questions for Tope

- History still contains the existing key files. They stay. Nothing was rewritten.
- Doppler is the vault (D27). The project and service token are not created yet.
- For P1-010, Play Integrity and App Attest still need to be turned on for `com.cracklog.lingafriq` and `com.owlab.lingafriq` on the existing Play and Apple accounts.
- For P1-025, snaps still store a client-supplied URL. A bucket does not exist yet. Firebase Storage on the existing project, or DigitalOcean Spaces, would issue the signed URLs.

## How to build and test

Env names only. Never commit values.

Flutter (`lingafriq-mobile-app-clone`): `/Users/temitopeolaitanmichael/flutter/bin/flutter pub get`, then `flutter test <path>`, then `flutter analyze`. Backend URL comes from the app config. The five AI keys are still passed as `--dart-define` names `GROQ_API_KEY`, `STABILITY_AI_KEY`, `HUGGINGFACE_TOKEN`, `REPLICATE_API_KEY`, `LEONARDO_API_KEY`.

node-backend: `yarn`, `yarn build`, `yarn dev` (nodemon `dist/server.js`). Tests: `./node_modules/.bin/jest <file> --runInBand --forceExit` outside the sandbox when MongoMemoryServer is used. Names in `.env.example`: `INTRON_API_KEY`, `INTRON_BASE_URL`, `AI_INTRON_ENABLED`, `AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION`, `SPITCH_API_KEY`, `GEMINI_API_KEY`, `AI_GEMINI_ENABLED`, `OPENAI_API_KEY`, `AI_EVALS_PASSED`. Firebase messaging also reads `FIREBASE_SERVICE_ACCOUNT_JSON` or `FIREBASE_SERVICE_ACCOUNT_PATH`. Router unit test: `src/__test__/aiProviderRouter.test.ts` (6 passed).

Admin (`../lingafriq-admin`): `yarn`, `yarn dev` (Vite port 3000, proxy `localhost:4000`).

Voice service (`node-backend/voice-service` and the sibling `lingafriq-voice-service`): Python `main.py` from `voice-service/requirements.txt`. `VOICE_SERVICE_URL` defaults to `http://localhost:5051`. The app STT route no longer proxies Whisper when the uncommitted router is running. It returns `stt_unavailable` until Intron is switched on.

## Pointers

Copies are in `docs/plan/`. Originals:

- `~/LingAfriq/lingafriq/LINGAFRIQ_AI_MODEL_STACK.md`
- `~/LingAfriq/lingafriq/BUILDER_AI_WIRING_PROMPT.md`
- `~/LingAfriq/lingafriq/BUILDER_CURRICULUM_PROMPT.md`
- `curriculum/` in this repo (copied from `~/LingAfriq/lingafriq/curriculum`, about 141 MB, no file over 50 MB, so Git LFS was not required)

Intron is set up and not connected. Do not put `INTRON_API_KEY` in the client.

## Tope to switch on

Decisions for 2026-10-22 are signed in `docs/build/DECISIONS.md`. These still need the live account. None of them stops the build.

- Tope to switch on: two API replicas with health checks and a rolling reload, using `node-backend/infra/pm2/ecosystem.config.cjs`.
- Tope to switch on: Atlas continuous backup with point-in-time restore, then `ATLAS_URI`, `ATLAS_SCRATCH_URI`, and `ATLAS_RESTORE_CONFIRMED=1` for `scripts/ops/atlas_restore_drill.sh`.
- Tope to switch on: create the Doppler project and a service token (`DOPPLER_TOKEN`). Key migration stays at the end of the build. Do not delete the Firebase account, the Apple `.p8`, or the five client AI keys.
- Tope to switch on: Play Integrity and App Attest credentials. `INTEGRITY_MODE` stays `log` until the false-positive review.
- Tope to switch on: the private Cloudflare R2 bucket (`SNAP_STORAGE=r2` plus `R2_ACCOUNT_ID`, `R2_BUCKET`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`).
- Tope to switch on: the named native reviewer for each locale (D18).
- Heritage Fund percent and marketplace share stay blank until EXT-03.
- Tope to switch on: ten profile cold starts on a mid-range Android. Each must be under 2 seconds to the first meaningful frame.
