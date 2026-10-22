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
