charter: v2

# OPEN_WORK.md — work that is not done, or not done fully

Tope, 2026-10-21: every agent writes here. This is the residual log. It is not a completion claim (RM-STOP-03 still bans new status files that say a thing is finished).

**Rule.** On every card close and every direct task, append one row for each thing that was not done or not done fully. If the work is truly finished, append one row with status `closed` and say what evidence closed it. Do not delete rows. When a row is later finished, change its status to `closed` and add the date and the evidence. Card `risks:` and `LEDGER.csv` stay; they are not a substitute for this file.

A row is required for: skipped acceptance criteria, allowlist leftovers, unmeasured performance bars, unsigned decisions, uncommitted product work, tests that did not run, and behaviour that still uses a client-supplied value.

| ID | Status | Source | What is not done |
|---|---|---|---|
| OW-001 | open | Rive integration, 2026-10-21 | Not committed. Lives in the mobile working tree (`lib/avatars/cast/`, `pubspec.yaml`, `pubspec.lock`, tests, CI, `assets/rive/README.md`). |
| OW-002 | open | Rive integration | Device bar not measured. ≤2 ms/frame on a Tecno/Infinix-class Android, 60 fps, is not claimed. |
| OW-003 | open | Rive integration | Part-swap frame drop is avoided by `artboardToBind` on the already-decoded file. It was not measured on a device. |
| OW-004 | open | Rive integration | Cultural sign-off is open, including Thandi's headwear (umqhele vs isicholo). The `.riv` was not edited. |
| OW-005 | open | Rive integration | Chip goldens exist for macOS only (`test/avatar/goldens/macos/` at 32, 48, 64). Linux CI checks size and that a `RiveWidget` renders. Pixel compare runs only after goldens are recorded on that OS. Widget tests use `Factory.flutter` because the shipped native library has no headless GPU. The app decodes with `Factory.rive`. |
| OW-006 | open | Rive integration | Builder is contract part lists plus body, face, and wheelchair, default preset Learner. No picker for the 17 cast instances. No colour controls for skin, hair, or outfit. |
| OW-007 | open | Rive integration | `assets/rive/lingafriq/` reference notes stay unbundled. Admin and learner screens other than the profile sheet were not all retargeted onto `CastDirector`; legacy `AvatarController` still writes the same session. |
| OW-008 | open | P1-013, commit `3370343` | Membership is process-local. `room.model.ts` builds a schema and is never queried. |
| OW-009 | open | P1-013 | REST `chat.controller` still mints and queries `private_*` ids, so history stays guessable and split from socket UUIDv7s. Not pushed. |
| OW-010 | open | P1-017 | Client self-grant call sites were outside the allowlist and were not removed. |
| OW-011 | open | P1-017 | Non-lesson admin awards still use the request amount and are audit-logged. The `service` role exists only in the spec harness. |
| OW-012 | open | P1-012 | Client still requests 500 tokens. The gateway clamps that to 256 and replaces the client system text with the roleplay template. |
| OW-013 | open | P1-008 | A reserve and a provider failure that cross UTC midnight can skip rollback, because release reads a fresh date. |
| OW-014 | open | P1-026 | Unmatched identity questions still use the in-character prompt and may not disclose. |
| OW-015 | open | P1-032 | wav2vec 200 with omitted fields still fills `overall_score` 0.0. That is not the unreachable path. |
| OW-016 | open | P1-031 | Tests are source scans, not widget pumps. Duel waveform `Random()` is not a score. |
| OW-017 | open | P1-030, D22 | False tone and grammar were pulled. Accurate replacement is not shipped. Grammar is not Beta. CC BY-SA and NC text is not copied. Pattern Library waits on the licence register. |
| OW-018 | open | P1-029 | `curriculum_service.dart` still names removed bundles and was outside the allowlist. D20 (coming-soon until a language is verified) is signed. The verified-language set is empty. |
| OW-019 | open | P1-007 | Client apps still have to ship against the gateway contract (P1-011). |
| OW-020 | closed 2026-10-21 | P1-018, D23 | Client `amount` is no longer copied, and `updateUserPoints` returns 403. Evidence: commit `4e863f3`, Jest `P1-018.serverXp.test.ts` 4/4. The unverified-event gap is OW-028. |
| OW-021 | open | D23 admin UI | Backend `GET/PUT /admin/gamification/economy` is written and uncommitted. The Gamification Manager control was not exercised in a browser. |
| OW-022 | open | Held cards | P1-001 and P1-002 stay Blocked-External (EXT-21 history purge). P1-046 stays Draft until revocations resume. P1-020 stays Draft until D11 is signed. |
| OW-023 | open | Decisions | D11–D19 are unsigned. D20, D21, D22, D23 are signed. |
| OW-024 | open | Plan repo | The plan dump (cards, RTM, STATE, LEDGER, DECISIONS, this file) is not committed. Tope has not asked for that commit. |
| OW-025 | open | P11 avatars | Real-device avatar benchmarks and cultural review are also open on the plan side. See OW-002 and OW-004. |
| OW-026 | closed 2026-10-21 | D23 | The missing daily XP number is no longer what blocks P1-018. Evidence: `economySettings` default 500, admin `GET/PUT /admin/gamification/economy`, Gamification Manager “Daily XP cap”. The rest of the card is OW-020. |
| OW-027 | open | P1-059 | The card allowlist says `admin-panel/`. The console that exists is `lingafriq-admin`. P4 studio and ops cards already use `lingafriq-admin`. The path has not been corrected. |
| OW-028 | open | P1-018, commit `4e863f3` | The award route does not verify that a lesson happened. A new `sourceId` still pays 30 XP until the daily cap. `quiz`, `event`, `tribe`, `daily_checkin`, and `badge` return 400 because they have no server amount. The 20-way test checks one ledger row, not that the other 19 responses say "already awarded" instead of a duplicate-key error. |
| OW-029 | open | P1-015, commit `5853598` | `share_presence` defaults false and no route sets it, so presence is silent in production. Delivered, read, reaction, status, and story trust the client `roomId` and do not call `isRoomMember`. `presence.service.ts` lines 22–25 and 75 are uncovered and accepted. |
| OW-030 | closed 2026-10-21 | Curriculum handoff | The tree is at `~/LingAfriq/lingafriq/curriculum`. Evidence: packs, schema, and `sources/licence_register.md` are on disk. Wiring is OW-032. |
| OW-032 | open | BUILDER_CURRICULUM_PROMPT.md | Curriculum is not wired into the app, backend, or admin. Measured gaps: 69,290 items; 14,214 items have audio; clip URIs are `hf://` (33,764) and `cv27:` (2,844), not https, so they cannot be streamed as stored. Schema omits `crosscheck`, `crosscheck_score`, `crosscheck_ok`, `fix_source`, `text_original`, and `native_check_priority`. Every `label` is `beta`, including 55,157 `needs-review` items. README still says Pidgin has 0 items and that no audio shipped. |
| OW-031 | open | P1-016, commit `5aac1bf` | The authz suite checks `socket.userId` after a spoofed `user_connected`. It does not read the `onlineUsers` map, so a payload write into that map would still pass. |
| OW-033 | open | P1-019, commit `3e2477d` | `--apply` saves the new balance before the `rewardAdjustments` row. A crash drops the stored prior, and a second run will not recreate it. Unbacked currency and points are flagged and left unchanged unless `--include-unbacked`. The suite uses a fixture, not a production snapshot. Historical currency grants are not in `rewardMovements`. |
| OW-034 | open | P1-023, commit `a659b59` | No moderation provider is signed, so `baseline.json` (precision 8/9, recall 4/5) is the policy on fixture scores. A socket replay of an already stored message is emitted again without a new classification. Lesson options, explanations, and vocabulary are not included in the text sent to the gate. |
| OW-035 | open | P1-027, commits `d237c6b` and `fadd072` | A model that returns allow plus `historical_violence` for a harm endorsement still receives the canned allow. The server does not override that decision. No numeric age cutoff is signed. |
| OW-036 | open | P1-028, commit `7036951` | `historian_review` stays `pending` (EXT-15). Yankah also records Fante. The language list is Nzema and English. |
| OW-037 | open | P1-033, commit `7cc9439` | Hive restore clears the vocabulary box before rewriting the backed-up objects. The tests never open Hive, so a throw during restore can drop vocabulary while the recovery text still says the data was unchanged. |
| OW-038 | open | P1-024, commits `62de482` and `72811b2` | A block lookup that throws is treated as not blocked, so delivery fail-opens. |
| OW-039 | open | P1-034, commit `2264fa4` | Map.toString detection depends on a no-quotes heuristic. An odd leftover token can be treated as invalid JSON and every answer is re-asked. |
| OW-040 | open | P1-035, commit `a752635` | `OfflineHandler.initialize` is never called, so that online flush does not run. App start and `OfflineService` still flush the same Hive box. `enqueueLessonProgress` has no production caller. A permanent HTTP error stays in the box. The tests encode the outbox and do not open Hive. Reviewer [P1-035](6437d0fb-2dbc-4f7a-802f-67ce1e4917bf). |
| OW-041 | open | P1-036, commit `7d8050a` | A legacy cache blob stays stored until the caller rebuilds after `CacheIntegrityException`. Decrypt does not return it. Reviewer [P1-036](16499528-1265-44b1-8224-ef04a96b037b). |
| OW-042 | open | P1-037, commit `e00e54b` | After a clean finish the waiter still enters the job when the lease ends. The sent ledger blocks a second push. Overlapping ticks in one process share `workerOwnerId`. Live PM2 was not inspected (EXT-23). Reviewer [P1-037](4a840bd9-96ef-475a-9bdb-ed2933f01a0b). |
| OW-043 | open | P1-038 | Daily and weekly still follow their cron hour. The shared day cap blocks a second job the same local day. Unknown and invalid timezones become UTC and are logged. |
| OW-044 | open | P1-042 | Google Cloud Translation still runs when GOOGLE_CLOUD_API_KEY is set. The live translate screen shows "Translation is unavailable" for that code. |
| OW-045 | open | P1-043 | A correct password on a non-admin account still returns "User is not an admin". Unknown emails and wrong passwords share one 401. |
| OW-046 | open | P1-044 | The backoff numbers, 30 seconds doubling to 15 minutes, are not in the source. The per-IP limiter skips itself when NODE_ENV is test. |
| OW-047 | open | P1-045 | `src/scripts/ensureAdminUser.ts` still requires 6 characters and stores a Django hash. The next successful admin login rehashes it. Tests stub the breach HTTP call; they do not call Have I Been Pwned. |
| OW-048 | open | P1-046 | `src/routes/scraper.route.ts` still verifies with the raw `SCRAPER_SECRET` or `JWT_SECRET`. There is no HS256 cutover date. |
| OW-049 | open | P1-047 | Logout and password change revoke refresh tokens only. An unexpired access JWT stays valid until it expires. A second refresh inside 10 seconds is invalid and does not revoke the family. |
| OW-050 | open | P1-048 | Phone passkeys need the Apple associated-domain file and the Android signing-cert origin for lingafriq.com. |
| OW-051 | open | P1-049 | Android Sign in with Apple has no Services ID in the repo, so that button stays unavailable there. New provider accounts store nationality unspecified. The app pastes a magic-link token until a universal link exists. Tests replace the Google and Apple key fetch and do not call those hosts. |
| OW-052 | open | P1-050 | Auth bodies are schemed. Other POST, PUT, and PATCH routes are listed as an exemption until each handler's body is specified. A route that is not in the inventory fails the test. |
| OW-053 | open | P1-051 | Admin routes may still name a target user in the body. Those lines are marked identity-target. GET rive state still takes user_id from the query. |
| OW-054 | open | P1-052 | Catalog reads and lesson-complete PATCH stay open. Unfollow, private-chat open, classroom, tribe, and room routes stay allowed for the signed-in user. Group chat is not owner-denied. A missing mongoose model fails open. GET rive state still takes user_id from the query. |
| OW-055 | open | P1-053 | The per-IP limiter still skips itself in tests until the suite installs the fake clock. A limiter error in production still allows the request. |
| OW-056 | open | P1-055 | The Android network config does not embed a pin. The Dart client is the check on both platforms. No device proxy test was run. |
| OW-057 | open | P1-056 | The manual sideload tester workflow does not pass --obfuscate. build.yml is disabled and is not the release path. |
| OW-058 | open | P1-057 | The API production audit reports 43 high and 5 critical advisories, so the backend audit workflow fails until those are upgraded. Dev dependencies are omitted. chat_bundle/frontend has no lockfile yet. |
| OW-059 | open | P1-058 | Backend workflows other than the SBOM job still use action tags. The pin lint scans the mobile repo. |
| OW-060 | open | P1-059, commit `9ae8e11` | The built login page responds. An authenticated login and a write were not run because the API was not running and no test account is in the repo. Production audit still reports moderate react-router and yaml findings. yarn.lock was not regenerated. Firebase deploy uses npm ci. Vite 8 needs the esbuild package because the config still minifies with esbuild. |
| OW-061 | open | P1-060 | The scope doc is ready to send. Test account passwords are not issued. EXT-17 stays open until a vendor is booked. |
| OW-062 | open | P1-061, commit `a2c6603` | REVENUECAT_WEBHOOK_SECRET is unset in the repo. The webhook is not deployed (EXT-23). |
| OW-063 | open | P1-062 | Entitlement decisions are cached for 60 seconds. A subscriber who exists only on the old Subscription collection has no entitlement row and is denied. |
| OW-064 | open | P2-001 | Infos are not fatal. Legacy warning counts stay until the file is edited. Android and iOS jobs still check out main, so a pull request is enforced by the analyze-new-code job. |
| OW-065 | open | P2-002 | Placeholder and generic-claim hits in the four legacy bundles, shipped assets, lib, and node-backend stay at the recorded counts. The mobile CI job does not check out node-backend, so that tree is scanned only when it is present. |
| OW-066 | open | P2-003 | Gitleaks scans the new commits, not full history. JWT_SECRET_EXPLANATION.md stays a known redacted hygiene finding until the end-of-build purge. |
| OW-067 | open | P2-002, P7-960, P7-961 | Bundled lessons without a source stay at the recorded counts. P7-960 is a shell. The full lesson (one verbatim sentence, one hidden word, at most 10 sourced cards, no word-as-meaning gloss) is P7-961 and is not built. Runtime lessons stay out of the curriculum lint. |
| OW-068 | open | P2-004 | The four legacy bundles are not v1. The content job stays green only while accepted stays 0. Tone is checked on the lexeme lemma, not on every string. |
| OW-069 | open | P2-005 | The eval gate does not call a live model and does not set AI_EVALS_PASSED. The native set of at least 300 items per language is not in this job. The open pull request differs from main in the model stack doc, so that check stays red until outputs for those bytes meet the thresholds. |
| OW-070 | open | P2-006 | This repo has no package-lock.json, so the production scan prints that the API lockfile is in node-backend. The seeded high advisory is what fails the mobile job. |
| OW-071 | open | P2-007 | The release build number is computed for that run and is not written back to pubspec. Android and iOS jobs still check out main. |
| OW-072 | open | P2-008, P2-059 | Paid on the learning suite: domain coverage 83.3% (1058/1270), gate exit 0. Threshold stays 0.70. A new lib/learning file without a behaviour test drops the rate again. |
| OW-073 | open | P2-009 | Catalog and shared reads stay allowed. They must not return another user's private payload. The mobile workflow does not run the API suite. |
| OW-074 | open | P2-011 | Exempt routes are in the spec without a body schema. A body schema has to be registered before the spec can describe that body. |
| OW-075 | open | P2-013 | A full unauthenticated sweep of every route waits on Mongo for about 10 seconds on handlers that then return 500. The blocking suite covers the route inventory and every operation that declares a body schema. |
| OW-076 | open | P2-031 | /health stays 200 when MongoDB is down and /ready returns 503. Two API instances behind the live load balancer have not been inspected. |
| OW-077 | open | P2-036 | Winston scrubs secret keys and secret-shaped strings. A log written with console.log does not pass through that scrub. |
| OW-078 | open | P2-033 | Spans are accepted in-process. No collector URL is set, so they are not shipped off the machine. |
| OW-079 | open | P2-034 | OpenAI and Groq stamp first-token time from the stream. Gemini and Hugging Face still return one finished body, so those calls do not stamp it. |
| OW-080 | open | P2-037 | The rollout gate uses crash-free users 0.995 and ANR rate 0.0047. An Android ANR exit is not read from the OS yet. |
| OW-081 | open | P2-014 | Reads come from the Drift snapshot. Hive is still written as a mirror so an existing install can be imported if the sqlite file is missing. |
| OW-082 | open | P2-016 | Legacy sync types post to their existing endpoints from the one outbox. Those endpoints do not yet store an idempotency receipt, so a lost 200 can be sent again. |
