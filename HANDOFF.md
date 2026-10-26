charter: v2

# Handoff

The Firebase service account, the Apple `.p8`, and the five client AI keys stay in the tree. They were not deleted, revoked, or replaced. A staged untrack of those files was reverted.

## Where this stopped

Work is continuous on `cloud-handoff`. Do not pause between cards. The key files remain tracked.

- Mobile: `cloud-handoff`. EXT-01 is Done (`docs/plan/LINGAFRIQ_AI_MODEL_STACK.md`). P4-055 is Done (`generate.py`: anchored lexicon only, citation parse, `CONTENT_ENGINE_GENERATION_MODEL` cites EXT-01). P4-051 is Done. P4-052 stays Draft because it depends on P4-036. P4-057 is Done (`crosscheck.py`: second-family verifier, tie-break, `XCHECK_ERROR`). P4-058 is Done (`entailment.py`: passage lookup, `CLAIM_NOT_ENTAILED`, `PASSAGE_NOT_FOUND`, grammar/culture reviewer routes). P4-059 is Done (`backtranslate.py`: Google MT vs MADLAD routing cites EXT-01, `BT_UNAVAILABLE`, similarity flag). Next build card is P4-060. P4-048 is Done (`anglicisation.py`: cross-check naturalness, review route, learner flags). P4-063, P4-069, P4-071, P4-072, P4-073, P4-074, P4-075, P4-076, P4-077, P4-078, P4-079, P4-080, P4-081, P4-082, P4-056 (`generation_guard.py`), P4-083, P4-084, P4-085, and P4-086 are Done. P4-064, P4-065, and P4-067 stay Draft (pipeline publish/routing deps for review approve). P4-070 stays Draft because it depends on P4-064. P4-087 stays Draft until P4-060 and P4-067 land. P4-046 stays Done. P4-008, P4-023, P4-025, P4-027, P4-029, P4-031, P4-033, P4-035, and P4-038 stay Blocked-External. P4-036 and P4-042 stay Draft because P4-038 is Blocked-External. The FSRS mutation score is 130/147. Fuzzing is off.
- Backend: `cloud-handoff`. Latest card push is P2-056. Flag buckets are stable. HS256 still verifies.
- The key files are still tracked. Copies also exist in `~/.lingafriq/secrets/` (mode 600). History was not rewritten.
- Admin gamification edits were not part of this build. They are in git stash `admin-gamification-wip-not-this-build` on `lingafriq-admin` `cloud-handoff`.
- P4-047 is Done. An English spelling is flagged only when that form is in the kit NLA table. A missing, empty, or not-included table fails PCM_NLA_TABLE_MISSING and does not pass. No NLA rows were written. P4-048 is Done (anglicisation linter: `anglicisation.py`). P4-046 is Done. ZulMorph stays off. A missing module fails loud. A labelled external parse failure goes to human review and does not auto-publish. P4-045 is Done. Zulu and Xhosa concord uses the kit table for classes 1–15. A spaced verbal complex fails. Xhosa analyser is none. P4-044 is Done. Swahili concord checks only m/wa and ki/vi. P4-043 is Done. Plain replacements of ɓ ɗ ƙ ƴ or U+02BC fail, display text with a tone or length mark fails, and a teaching mark is accepted when the form has dictionary/lexicon, native-author (id plus YYYY-MM-DD), or Import Media (id plus timestamp or span) provenance. Otherwise it fails HA_MARK_NO_DICT. The mark must still be on the lexicon form. There is no live lookup. P4-041 is Done. P4-042 stays Draft because it depends on P4-038, which is Blocked-External. P4-040 is Done. P4-039 is Done. The file CLI has no registered rules yet. P4-037 is Done. The pcm, sw, zu and xh kits record only the §3.3 facts. load_kit still reads {language}.yaml. P4-036 stays Draft. P4-035 is Blocked-External. No Xhosa grammar title or edition is chosen and no purchase is logged. P4-034 is Done. Oxford isiXhosa stays unheld. P4-033 is Blocked-External. No Doke–Vilakazi licensor or terms are recorded and no Poulos & Msimang purchase is logged. P4-031, P4-029, P4-027, P4-025, and P4-023 stay Blocked-External. P4-008 stays Blocked-External because counsel has not confirmed any source. It is not Done. P3-001 stays Draft: 3 sourced baselines, 17 blank. The search cap is spent and missing numbers stay blank. P3-002 and the art-direction chain wait on a Done P3-001. Next unblocked card is P4-047. The NLA table rows are not in §3.3. Do not invent spellings. A missing table must not pass. D28: `../curriculum/` is the only course-content source. P4-169 is the import card and stays Draft until content loading. Do not import the legacy trees. P2-031 stays a live-host switch-on and is not Done. P7-961 does not jump this queue. R3 stays on F-007, P7-951, P7-952, and P7-953. Path Rive is v3 at ~/LingAfriq/lingafriq/design/path_rive/path/v3/. Do not use v1 or v2. Do not build the path until those cards.
- Voice service has a local `cloud-handoff` branch created from `main`. It is not pushed. An untracked `.gitignore` stays uncommitted. Admin `cloud-handoff` is clean. The gamification stash stays.

## Next 3 steps

1. EXT-01 is Done. P4-055 is Done (`generate.py`). P4-056 is Done (`generation_guard.py`). P4-051 is Done. P4-052 stays Draft because it depends on P4-036, and P4-036 stays Draft until P4-038 is Done. P4-057 is Done (`crosscheck.py`: second-family verifier, tie-break, `XCHECK_ERROR`). P4-058 is Done (`entailment.py`: passage lookup, `CLAIM_NOT_ENTAILED`, `PASSAGE_NOT_FOUND`, grammar/culture reviewer routes). P4-059 is Done (`backtranslate.py`: Google MT vs MADLAD routing cites EXT-01, `BT_UNAVAILABLE`, similarity flag). Next build card is P4-060. P4-048 is Done (`anglicisation.py`: cross-check naturalness, review route, learner flags). P4-063, P4-069, P4-071, P4-072, P4-073, P4-074, P4-075, P4-076, P4-077, P4-078, P4-079, P4-080, P4-081, P4-082, P4-083, P4-084, P4-085, and P4-086 are Done. P4-087 stays Draft until P4-060 and P4-067 land. P4-086 is Done (structure.py: CEFR map coverage, can_do_targets per unit, signed unit packs to `../curriculum/pipeline/output/unit_packs/`, CEFR_TARGET_MISSING). P4-085 is Done (dialogues.py: can-do targets, P4-051 duplicate lint, two-attempt park queue; live Gemini gated on P4-055/EXT-01). P4-084 is Done (tone_claims.py: lexicon tone_pattern or NO_LEXICON_TONE, high_risk queue). P4-083 is Done (grammar cleanup: strip P4-049 generic sentences from lesson grammar, idempotent). P4-082 is Done (legacy salvage: real phrases to `../curriculum/pipeline/input/legacy_salvage.jsonl`, placeholder drops counted, unanchored unverified). P4-064, P4-065, and P4-067 stay Draft until their pipeline cards land. P4-070 stays Draft because it depends on P4-064. Do not invent a high-frequency cutoff. §3.1 does not give one. Do not invent NLA spelling rows. §3.3 names the table and does not list it. Do not enable ZulMorph. Do not invent Zulu or Xhosa concord morphemes. Do not build P4-042 or P4-036 until P4-038 is Done. P4-038 stays Blocked-External. Do not invent the Igbo tone convention. P3-001 stays Draft. Do not invent benchmark numbers. Do not build the path until F-007. The host switches below do not stop the queue. P4-008, P4-023, P4-025, P4-027, P4-029, P4-031, P4-033, P4-035, and P4-038 stay Blocked-External. Do not mark them Done. Do not invent a grammar edition or log a purchase. Do not invent an Xhosa grammar title. Do not enable Intron. Do not invent an NSC licence. Do not invent a BAKITA citation. Do not mark EXT-06 received. Do not enable ZulMorph. Oxford isiXhosa stays unheld while EXT-04 is Open. Do not invent phoneme charts or concord prefixes the curriculum does not list.
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

Counts from `docs/plan/CARD_STATUS.tsv` on 2026-10-25: Draft 876, Done 160, Blocked-External 53, Ready 7. P4-169 stays Draft. The TSV is the list. Do not treat this prose as a second list. R3 is carded on F-007, P7-951, P7-952, and P7-953. Path art is v3 and does not jump this queue.

Nothing is in progress. Mobile `cloud-handoff` tip is P4-059. Admin and backend `cloud-handoff` are not pushed.

Next card is P4-060. P4-059 is Done (`backtranslate.py`: Google Cloud Translation for yo/ig/ha/sw/xh/zu, MADLAD long tail, semantic similarity flag). P4-058 is Done (`entailment.py`: cited-claim entailment, reviewer routing for grammar/culture). P4-048 is Done (`anglicisation.py`). P4-057 is Done (`crosscheck.py`: env cross-check and tie-break models cite EXT-01, opinions stored, `XCHECK_ERROR` blocks publish). P4-056 is Done (generation_guard.py: lexicon-bound dialogue tokens, cited culture/grammar claims, regeneration counter). P4-055 is Done (generate.py: anchored lexicon payload, CITATION_MISSING, env model routing cites EXT-01). P4-086 is Done (structure.py: unit can_do_targets, HMAC-signed packs per unit, idempotent). P4-085 is Done (dialogues.py: unit duplicate lint, injectable generator, park jsonl). EXT-01 is Done (`docs/plan/LINGAFRIQ_AI_MODEL_STACK.md`). P4-084 is Done (tone_claims.py re-derives game tonal_note from lexicon tone_pattern; derived items route high_risk). P4-083 is Done (grammar_cleanup.py removes generic grammar lines; claims lint clean). P4-082 is Done (salvage script: quarantine or in-tree a1_c2 JSON, seven kit langs, legacy provenance, lexicon anchor sets queue). P4-081 is Done (legacy quarantine script: three authentic copies plus duplicated expanded bundle to `quarantine/legacy/`, idempotent manifest). P4-080 is Done (Studio effort 11.5 eng-weeks from card sizes inside 10–14; G4 actuals pending). P4-079 is Done (reviewer payments CSV by date range, final reviewer dedup in header). P4-078 is Done (quality dashboard: sample error rate per language and label with configured minimum, flags, item statistics). P4-077 is Done (staged pack rollout 1/10/50/100%, rollback to previous signed pack with audit, ROLLBACK_FAILED pauses). P4-076 is Done (semver signed content packs: manifest item ids and labels, HMAC signature, PACK_ITEM_INVALID and PACK_SIGNATURE_INVALID). P4-075 is Done (keyboard-first review queues: a/f/r shortcuts, approve publishes or REVIEW_REQUIRED, errors keep queue items). P4-074 is Done (per-item verification report, export of stored fields only, unsure for missing stages). P4-063 is Done (weighted confidence scoring). P4-073 is Done (generation jobs UI, git prompt version, env model names, stage errors). P4-072 is Done (lexicon editor with side-by-side sources, kit tone lint, and audit). P4-071 is Done. P4-069 is Done. P4-070 stays Draft because it depends on P4-064. P4-054 is Done. Dialogue similarity and the repeat cap come from kit config. P4-052 stays Draft because it depends on P4-036. P4-050 is Done. P4-047 is Done. Do not invent table rows. P4-048 is next (P4-057 Done). P4-046 is Done. ZulMorph stays off. P4-045, P4-044, and P4-043 are Done. A Hausa teaching mark passes for dictionary/lexicon, native-author, or Import Media provenance. P4-042 and P4-036 stay Draft because P4-038 is Blocked-External. P4-035, P4-033, P4-031, P4-029, P4-027, P4-025, P4-023, and P4-008 stay Blocked-External. P4-034, P4-037, P4-039, P4-040, and P4-041 are Done. P4-169 stays Draft until content loading. P3-001 stays Draft. Canonical course content is `../curriculum/` (D28). Do not build the v3 path until F-007. Do not enable Intron. Do not mark EXT-06 received. Do not enable ZulMorph. Oxford isiXhosa stays unheld. Do not invent the Igbo tone convention.

Do not mark Done: P2-031 (live two replicas), P2-032 (Atlas PITR), P1-004, P1-010, P1-025, P1-020. Do not close G2. Do not jump to P7-961.

Open items are in `docs/build/OPEN_WORK.md`. The newest open row is OW-178 (source library route is not mounted, and the screen was not opened in a browser). OW-177 closed P4-071.

## Decisions

- D0–D10, D21, D22, D23, D28 are signed in `docs/build/DECISIONS.md`. D28 (Tope, 2026-10-24): `../curriculum/` is the only course-content source. Legacy curriculum trees stay on disk and are not imported. `*.synth.json` stays draft until native review. D11–D19 were still awaiting a signature in that file.
- 2026-10-22, Tope: do not revoke or replace the Firebase service account, the Apple `.p8`, or the five client AI keys. Build with those same accounts. Copies were moved to `~/.lingafriq/secrets/` because the files were tracked. This is not yet written into `DECISIONS.md`.
- 2026-10-23, Tope (D11): ask for birth year, not a full date of birth. Under the country child threshold, verifiable parental consent comes before any account data is stored. Child mode gates open social, chat, marketplace, and ads, and keeps Historical Personas free chat under child-safe moderation. Teen accounts are private and do not take direct messages from adults. Features are gated, not removed.
- 2026-10-22, Tope: do not revoke JWT material. P1-046 must keep accepting the current HS256 secret. Not yet implemented.
- 2026-10-23, Tope (D27): the vault is Doppler. The backend reads it when `DOPPLER_TOKEN` is set. `.env` remains the local-development fallback. Moving the existing keys stays at the end of the build.
- App curriculum wiring stays paused until the content-loading cards. Those cards import `../curriculum/` (D28) and do not import the legacy trees. AI providers stay off until the flags and keys are set. `AI_EVALS_PASSED` stays false.

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

Studio specs (`lingafriq-mobile-app-clone`): `npx --yes tsx --test tools/content_engine/tests/studio_*.test.ts`.

Voice service (`node-backend/voice-service` and the sibling `lingafriq-voice-service`): Python `main.py` from `voice-service/requirements.txt`. `VOICE_SERVICE_URL` defaults to `http://localhost:5051`. The app STT route no longer proxies Whisper when the uncommitted router is running. It returns `stt_unavailable` until Intron is switched on.

## Pointers

Copies are in `docs/plan/`. Originals:

- `~/LingAfriq/lingafriq/LINGAFRIQ_AI_MODEL_STACK.md`
- `~/LingAfriq/lingafriq/BUILDER_AI_WIRING_PROMPT.md`
- `~/LingAfriq/lingafriq/BUILDER_CURRICULUM_PROMPT.md`
- Canonical course content is `~/LingAfriq/lingafriq/curriculum` (`../curriculum/` from this repo). D28. The `curriculum/` directory inside this repo is a legacy copy. Do not import it.

Intron is set up and not connected. Do not put `INTRON_API_KEY` in the client.

## Tope to switch on

Decisions for 2026-10-22 are signed in `docs/build/DECISIONS.md`. These still need the live account. None of them stops the build.

- Tope to switch on: two API replicas with health checks and a rolling reload, using `node-backend/infra/pm2/ecosystem.config.cjs`.
- Tope to switch on: Atlas continuous backup with point-in-time restore, then `ATLAS_URI`, `ATLAS_SCRATCH_URI`, and `ATLAS_RESTORE_CONFIRMED=1` for `scripts/ops/atlas_restore_drill.sh`.
- Tope to switch on: create the Doppler project and a service token (`DOPPLER_TOKEN`). Key migration stays at the end of the build. Do not delete the Firebase account, the Apple `.p8`, or the five client AI keys.
- Tope to switch on: Play Integrity and App Attest credentials. `INTEGRITY_MODE` stays `log` until the false-positive review.
- Tope to switch on: the private Cloudflare R2 bucket (`SNAP_STORAGE=r2` plus `R2_ACCOUNT_ID`, `R2_BUCKET`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`).
- Tope to switch on: the named native reviewer for each locale (D18). Path v3 also needs a native reader, before release, for the Igbo elder cap, Zulu beadworker colours, Xhosa umbhaco, Zulu ukhamba, Hausa elder robe, Yoruba drummer, Igbo udu and ogene, and the Pidgin hawker and danfo. This does not pull F-007 forward.
- Heritage Fund percent and marketplace share stay blank until EXT-03.
- Tope to switch on: ten profile cold starts on a mid-range Android. Each must be under 2 seconds to the first meaningful frame.
- Tope to switch on: NDPC registration check and the DPIA, including voice-data thresholds (EXT-18). Credential evidence stays unissued until a real scorer and calibrated items exist. The check does not stop the queue.
