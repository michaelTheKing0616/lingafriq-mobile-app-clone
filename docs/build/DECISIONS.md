charter: v2

# DECISIONS.md — signed decisions (Tope is the only approver)

Format: `ID | date | decision | options considered | chosen | signed by | affects (RTM/cards)`. A waiver is `Waived-by-Tope` only when it appears here.

## Awaiting Tope (G0 — surfaced during card drafting; none blocks G0 approval, each blocks the card listed)

| ID | Decision | Options | Recommended | Source | Blocks |
|---|---|---|---|---|---|
| D11 | Under-13 sign-up before the guardian stack exists | (a) block with neutral wording until G9; (b) allow with no social and no data retention | **(a)** — smallest legal surface | ELEVATION §1:L195-L206 | P1-020, P3-082 |
| D12 | "Trusted user" for auto-hide on one flag | (a) verified native + reputation ≥ threshold; (b) stewards only | **(a)**, threshold set in config, stewards always count | CURRICULUM L616 | P5-013, P9-951 |
| D13 | Tone-accuracy gate threshold per tonal voice (source says "judged by natives", gives no number) | (a) ≥90% native-judged tone correct on a 100-item set; (b) ≥85% | **(a)** as config default, per-language override | ELEVATION L1460; CURRICULUM L660 (learner baseline 62%) | E-P6-TTS, P6-050, tts_tonal consumers |
| D14 | Historical persona roster (ADR-031 proposes Yaa Asantewaa, Nkrumah, Shaka, Ahmed Baba, Mofolo) | accept / amend | **accept**, subject to historian review (EXT-15) | ELEVATION §8 | P11-001 (ADR-031), P11-016…018, P1-028 |
| D15 | Wave 2–4 language rosters incl. a deliberate Egyptian Arabic / Moroccan Darija call | (a) include in Wave 4 as Afro-Asiatic; (b) exclude for now | **(a)**, content waits on licence + natives as every language does | ELEVATION L1247 | P4-111 |
| D16 | Dialect policy per language (which variety is "standard" for scoring and voice) | (a) one reference variety + labelled variants; (b) multi-variety scoring | **(a)** for Stage 1; (b) revisited at G13 (Grandma Mode) | ELEVATION §6; P4-115 | P4-115, P4-116 |
| D17 | Release guardrail numbers as config: crash-free sessions, ANR rate, Heritage Fund %, marketplace revenue share | set defaults: crash-free ≥99.5%, ANR <0.47%, fund/marketplace % left blank until EXT-03 | **as listed**, all config not code | ELEVATION L1957, L1992 | P12-016, P13-010, P13-011 |
| D18 | UI-translation sign-off owner (EXT-24) | Tope / named native per locale | **named native per locale**, Tope approves the list | ELEVATION §13.8 | P3-097 |
| D19 | Offline sync harvest pair: `selective_sync.dart` and `offline_service.dart` consolidate into one outbox | confirm the harvest list | **confirm** | ELEVATION §13.5 | P2-016 |
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
| D11 | Under-13 sign-up. Tope 2026-10-22 | **Do not block sign-up. Flag the age. Protect them from harmful content. Social messages stay readable by the platform (not end-to-end encrypted). Transport stays HTTPS.** | Tope, this session |
| D25 | JWT rotation. Tope 2026-10-22: no revocation | **Keep accepting the current HS256 secret. Do not wait on key revocation. A later asymmetric key must not reject installed sessions.** | Tope, this session |
| D26 | Certificate pinning (P1-054). Tope 2026-10-22 | **Leaf DER SHA-256 on iOS and Android. CERTIFICATE_PIN_HASHES holds the current pin and the next pin. A release with pins fails closed. A build with no pins stays open.** | Tope, this session |

Affects: D1/D6 → CONFLICTS C1–C3 closed, ADR-001…003; D2–D5 → EXTERNAL EXT-04/05/06/11/12, P4 studio cards; D7 → 04_ROUTING.md locked pending 10-card calibration; D8 → 05_UX_DESIGN_BAR.md targets; D9 → EXT-01 stays Open until the file arrives; D10 → P3 typography cards.
