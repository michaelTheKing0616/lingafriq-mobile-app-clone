charter: v2

# DECISIONS.md — signed decisions (Tope is the only approver)

Format: `ID | date | decision | options considered | chosen | signed by | affects (RTM/cards)`. A waiver is `Waived-by-Tope` only when it appears here.

## Awaiting Tope (G0 — surfaced during card drafting; none blocks G0 approval, each blocks the card listed)

| ID | Decision | Options | Recommended | Source | Blocks |
|---|---|---|---|---|---|
| D20 | Curriculum UI while no language is verified | (a) coming-soon and no lesson list for every language until E-P4/E-P5 fills the verified set; (b) keep showing bundled lessons with a banner | **(a)** — AC4 plus the marketing freeze | P1-029 | P1-029 |

D1–D10 signed 2026-10-21 ("approve all as recommended").

## Signed (G0 batch, 2026-10-21, Tope)

| ID | Decision | Chosen | Source |
|---|---|---|---|
| D0 | Master Build Plan at G0 ("I approve of the plan"); build orchestrated by Grok 4.7 per `04_ROUTING.md` build-phase note | **GO** | — |
| D1 | Three-label policy (Beta / Expert-reviewed / Native-verified); Beta never in checkpoints, placement, credentials, children's mode; interim change to Elevation §6.6 and "human-recorded audio" | **Approve** (see CONFLICTS C1) | CURRICULUM §10:L852 |
| D2 | Licence purchases: Oxford datasets (top), IgboAPI, Zulu dictionary; optional NaijaVoices waiver, HCS | **Approve Oxford + IgboAPI + Zulu now; defer NaijaVoices/HCS to gap analysis at G5/G8** | CURRICULUM §10:L857 |
| D3 | isiXhosa custom voice now vs matched corpus audio + text first | **Commission now** (lead time; G8 dependency) with Option A as the interim | CURRICULUM §10:L859 |
| D4 | Contract 2 part-time linguists per Stage-1 language with consent + IP clause | **Approve**; agent prepares brief and clause list (EXT-11) | CURRICULUM §10:L861 |
| D5 | Build Curriculum Studio in `lingafriq-admin` | **Approve** | CURRICULUM §10:L863 |
| D6 | Resolve CONFLICTS C2 (tone Beta rule) and C3 (L1 audio definition) as recommended | **Approve both** | CONFLICTS.md |
| D7 | Model-tier → Cursor slug map and initial budgets (S 30k / M 80k / L 200k), WIP 3 | **Approve; calibrate after 10 cards** | 04_ROUTING.md |
| D8 | UI distinctiveness panel target (≥60% preference, ≥20-person NG/KE/ZA panel) and usability targets (task success ≥90%, SUS ≥85) — *proposed* | **Approve as proposed** | 05_UX_DESIGN_BAR.md |
| D9 | Supply `LINGAFRIQ_AI_MODEL_STACK.md` (or confirm it does not exist, in which case vendor choices are carried only as written in the two sources) | **Supply if it exists** | EXTERNAL EXT-01 |
| D10 | Font pick: SIL Andika vs Noto (Elevation §3.4 names both) | **Noto Sans (UI) + Andika (learner-facing target-language text)**, both bundled; verify stacked diacritics in goldens | ELEVATION §3.4:L831 |
| D21 | Gateway token and cost clamps (P1-008). Tope 2026-10-21: be conservative | **per request cap 256; missing or invalid max_tokens becomes 128; 20 requests and 4,000 tokens per user per day; monthly cost budget $20; alert at 80 percent; 503 at 100 percent** | Tope, this session |
| D22 | False tone and grammar replacement (P1-030). Tope 2026-10-21: replace with accurate licensed data, using the curriculum plan | **Remove the false claims from shipped assets. Ship a replacement only when the elevation audit or a public-domain source already states it, with a citation and a label other than Native-verified. Do not ship model-written grammar as Beta. Do not copy CC BY-SA or NC text into the shipped file. Clear copied tonal notes instead of rewriting them from model memory. Pattern Library waits on the licence register.** | CURRICULUM plan §0–§2, §8; Tope, this session |
| D23 | Daily XP cap (P1-018). Tope 2026-10-21: set a realistic number and keep it easy to change, including from the admin dashboard | **Default 500 XP per UTC day, a hard stop (`cap_reached`). Admins change it in Gamification Manager, whole numbers 50–5000, stored in `economySettings`. No deploy required.** | Tope, this session |
| D24 | Secrets already in the tree. Tope 2026-10-22: no deletion during the build | **Leave the Firebase service account, the Apple .p8, and the five client AI keys in place. Cleanup or restructuring waits until the end of the build and does not block cards.** | Tope, this session |
| D11 | Age at sign-up. Tope 2026-10-23. Replaces the 2026-10-22 wording. | **Ask for birth year, not a full date of birth. Age for the band is the current calendar year minus the birth year minus one, so a child is not treated as older before that year ends. Under the country child threshold (default 13) is child mode: verifiable parental consent before any account data is stored; no open social, chat, or marketplace; no ads; moderated AI only. Historical Personas free chat stays and runs under child-safe moderation. From the child threshold through 17 is teen mode: private profile, no direct messages from adults. Thresholds live in per-country config. The default child threshold is 13 and the example override is 16. Features are gated, not removed. Social messages stay readable by the platform. Transport stays HTTPS.** | Tope, this session |
| D25 | JWT rotation. Tope 2026-10-22: no revocation | **Keep accepting the current HS256 secret. Do not wait on key revocation. A later asymmetric key must not reject installed sessions.** | Tope, this session |
| D26 | Certificate pinning (P1-054). Tope 2026-10-22 | **Leaf DER SHA-256 on iOS and Android. CERTIFICATE_PIN_HASHES holds the current pin and the next pin. A release with pins fails closed. A build with no pins stays open.** | Tope, this session |
| ADR-004 | Local database. Tope 2026-10-22, owner-approved | **Drift (SQLite). Not Isar.** Hive is what the app uses today. Drift has ordered SQL migrations, encryption through SQLCipher, and current Flutter support. Isar is faster for some document reads and its maintenance has stalled. P2-014 through P2-030 are unblocked. | Tope, this session |
| D12 | Trusted user for auto-hide. Tope 2026-10-22, owner-approved | **(a)** Verified native and reputation at or above a config threshold. Stewards always count. | CURRICULUM L616 |
| D13 | Tone-accuracy gate. Tope 2026-10-22, owner-approved | **(a)** At least 90% native-judged tone accuracy on a 100-item set. Config default, with a per-language override. | ELEVATION L1460 |
| D14 | Historical persona roster. Tope 2026-10-22, owner-approved | **Accept** the curated roster: Yaa Asantewaa, Nkrumah, Shaka, Ahmed Baba, Mofolo. Subject to historian review (EXT-15). This is the curated set only. Free open-ended chat with any African historical figure stays and is not removed or gated off. | ELEVATION §8 |
| D15 | Egyptian Arabic and Moroccan Darija. Tope 2026-10-22, owner-approved | **(a)** Include both in Wave 4. Content waits on a licence and native speakers, as every language does. | ELEVATION L1247 |
| D16 | Dialect policy. Tope 2026-10-22, owner-approved | **(a)** One reference variety plus labelled variants for Stage 1. Multi-variety scoring is revisited at G13. | ELEVATION §6 |
| D17 | Release guardrails. Tope 2026-10-22, owner-approved | **Crash-free users at least 99.5%. ANR rate under 0.47%.** Heritage Fund percent and marketplace share stay blank config until EXT-03. | ELEVATION L1957 |
| D18 | UI translation sign-off. Tope 2026-10-22, owner-approved | **A named native reviewer per locale signs off.** Tope approves the list. | ELEVATION §13.8 |
| D19 | Offline sync. Tope 2026-10-22, owner-approved | **Confirm.** Merge `selective_sync.dart` and `offline_service.dart` into one outbox. | ELEVATION §13.5 |
| P2-031 | Live API. Tope 2026-10-22, owner-approved | **Minimum two replicas, health checks, and rolling deploys.** | Tope, this session |
| P2-032 | Atlas backups. Tope 2026-10-22, owner-approved | **Continuous backup with point-in-time restore, and one documented test restore.** | Tope, this session |
| P1-004 | Secrets manager. Tope 2026-10-22, owner-approved. Destination superseded by D27 on 2026-10-23. | **No secrets in the repo or the client.** Key migration stays at the end of the build. | Tope, this session |
| D27 | Secrets vault. Tope 2026-10-23. | **Doppler.** The backend reads secrets from Doppler when `DOPPLER_TOKEN` is set. A `.env` file is the fallback for local development and tests only. Until the token exists, production keeps the current process environment so the API stays up. That bridge is a builder default, Tope may override. Creating the Doppler project and a service token is a switch-on. Moving the keys already in the tree stays at the end of the build (D24). | Tope, this session |
| P2-021 | On-device tone package. Builder default, Tope may override. 2026-10-23 | **20 MB.** No model is selected. The hook stays unavailable until a commercial-licence model meets the D13 floor. | builder default |
| P2-030 | Background queue. Builder default, Tope may override. 2026-10-23 | **Keep Bull, the client already installed.** A second BullMQ client is not added. Cron runs in the worker process, and the PM2 worker count stays 1 until a shared lease store is connected. The API process does not start workers. | builder default |
| P2-041 | Learner graph. Builder default, Tope may override. 2026-10-23 | **One graph replaces the four models named in ADR-005.** Migration writes events first, then projects nodes, then FSRS-6 schedules, then the old writers stop being read. Raw audio stays off without opt-in. The four models are not deleted by this decision. | builder default |
| P1-010 | App integrity. Tope 2026-10-22, owner-approved | **Play Integrity on Android and App Attest on iOS. Log-only first.** Enforce on sensitive routes after the false-positive rate is reviewed. | Tope, this session |
| P1-025 | Snap storage. Tope 2026-10-22, owner-approved | **Private Cloudflare R2 bucket. Signed short-lived URLs only. No public listing.** | Tope, this session |

Affects: D1/D6 → CONFLICTS C1–C3 closed, ADR-001…003; D2–D5 → EXTERNAL EXT-04/05/06/11/12, P4 studio cards; D7 → 04_ROUTING.md locked pending 10-card calibration; D8 → 05_UX_DESIGN_BAR.md targets; D9 → EXT-01 stays Open until the file arrives; D10 → P3 typography cards.
