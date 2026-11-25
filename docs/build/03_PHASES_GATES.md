charter: v2

# 03 — Phases, gates and hard-stop ordering

Gate types: **Card gates** (automatic DoR/DoD) · **Epic gates** (Orchestrator: integration green, RTM updated, ledger in budget) · **Phase gates** (Tope approves a ≤400-word packet from `templates/gate_packet.md`). No phase starts before its predecessor's gate is approved.

## Phases → gates → RTM scope

| Phase | Gate | RTM scope (id prefixes / sections) | Exit criteria (all measurable) |
|---|---|---|---|
| **P0 Intake** | **G0 Plan approved** | all rows mapped; charter cards; repo map | RTM 100% mapped (zero unmapped per `check_rtm_coverage.py`); routing table, budgets and charter enforcement approved; D1–D5 answered in `DECISIONS.md`; `CONFLICTS.md` C1–C3 resolved; companion-doc gaps listed in `EXTERNAL.md` |
| **P1 Containment** (wks 1–2) | **G1 Containment** | `P0-1…27`, `RM-P0-01…13`, `EP-§0-*`, `EP-§13.1-*` (P0-adjacent) | 27 P0s closed with evidence: secrets revoked + history purged (gitleaks clean); keys out of client; AI gateway with server-owned prompts + quotas; socket identity/room ACL/scoped emits; server XP/currency; age gate + minors' social off; hosted moderation; fake scores removed (honest practice mode); placeholder bundles + false tone/grammar out of build; auth fixes; notification dedupe; licence swaps; purchase verification; IDOR/authz suite green |
| **P2 Platform foundation** | **G2 Platform** | `EP-§13.4-*`, `§13.5`, `§13.9`, `§6.3` (learner model), `§11.3` (item bank), `RM-P1` platform rows | CI gates live (analyze fatal on warnings for new code, placeholder/claim linters, secrets scan, content validator, AI-eval blocker); OpenAPI + generated Dart client; one outbox/sync; auth v2; observability + SLOs; FSRS-6 + Learner Knowledge Graph on an idempotent event log |
| **P3 Design system, IA shell, onboarding v2** | **G3 Design + shell** | `EP-§3.*`, `§17.1–17.4`, `REV-*`, `CON-*`, `DEV-*`, `OB-step1…8`, `EP-§5.*`, `§13.7`, `§13.8` | tokens, bundled fonts, Tone Lens renderer, component library with all states, goldens, a11y baseline, 5-tab+Me shell, Search, Lens, Word Card, All-features directory; UX Scorecard and UI Scorecard ≥ target; art direction approved by ADR; signature screens approved as hi-fi designs |
| **P4 Content engine** | **G4 Content engine** | `CP-§2.*`, `§3.*`, `§8-*`, `§9.1`, `EP-§6.4-*`, `§6.5`, `§6.6`, `§14.*` | licence register counsel-signed [external]; 7 language kits; all linters in CI; Studio MVP; pipeline calibrated on linguist-reviewed pilot set; legacy data quarantined, salvaged, reported |
| **P5 Stage-1 content waves** | **G5 A1 Beta** → **G6 A2 + promotion** → **G7 B1** | `CP-§4-*`, `§5-*`, `§6-*`, `§7-*`, `§9.2`, `§9.3`, `EP-§6.1`, `§6.2`, `§6.7` | labels live; blind-sample error ≤ tier targets (A ≤3%, B ≤5%, C ≤5%); audio gates passed; Beta excluded from checkpoints/placement/credentials/children's mode; G6/G7: promotion by linguist approval, sample error ≤ Expert targets (A ≤1%, B/C ≤1.5%) |
| **P6 Speech and AI** | **G8 Speech + AI** | `EP-§7.*`, `CP-§7-*` gates, `UNV-E05` | scorer r ≥0.7 vs native raters on calibration sets; ASR on 300-utterance sets; TTS gated per language on native tone accuracy; realtime latency targets (first token <400 ms, TTFA <800 ms); AI evals ≥300 items per Stage-1 language |
| **P7 Today / Learn / Speak features** | hub gates (UX+UI Scorecards) | `F-001…F-054` (+ facets), `EP-§17.6`, `§17.7`, `§11.2` | each feature Verified-Done or Blocked-External; hub Scorecards equal-or-better than benchmark; signature differentiators present |
| **P8 Play** | hub gate | `F-055…F-102`, `EP-§10.*` | 10 flagship games on real scoring; every existing game on a shelf; GameKit consolidation harvest lists closed |
| **P9 Village / community / safety / classrooms** | **G9 Safety + social** | `F-103…F-136`, `EP-§9.*`, `§13.3` | guardian hub, age tiers, moderation console, report/block ≤2 taps, CSAM hash matching, E2EE adult DMs, third-party pen test; nothing for under-18 social before this gate |
| **P10 Me hub, monetisation, guardian, credentials, offline, i18n** | **G10 Feature completeness** | `F-137…F-151`, `EP-§12.*`, `§13.2`, `§13.5`, `§13.8`, `§15-*` | RTM shows F-001…F-151 each Verified-Done or Blocked-External; flagship games on real scoring; credentials only on real content + real scoring |
| **P11 Personas and avatars** | **G11 Personas** | `EP-§8.*`, `§4.*`, `AV-step1…7` | historian-reviewed dossiers; AI disclosure; eval suites pass; kill switch; avatar budgets (≤300 KB, ≤2 ms/frame, 60 fps) and golden chip tests |
| **P12 Hardening and release** | **G12 Release readiness** | `EP-§13.6`, `§13.9`, `§15` experimentation, `RM-P2` release rows | staged rollout 1→10→50→100% with crash-free/ANR gates; perf and load targets; a11y audit with disabled users; privacy programme (DPIA, data map, retention, export/delete); credentials only if content + scoring real |
| **P13 Scale** | **G13 Scale** | `RM-P2` wave rows, `RM-MS-*`, `CP-§2.4-later-*`, `CP-§9.2` phases 3–4 | Wave 2–4 and moonshot cards per readiness level, gated by the language-factory gates |

Cross-phase: `RM-STOP-*` (§16.5) are constraints enforced at every gate: no new features until the 151 are finished and wired; new breadth goes into languages.

## Hard-stop ordering (never reorder; enforced by `check_dependencies.py`)

| # | Before | After |
|---|---|---|
| H1 | real scorer (G8) | any score shown to a learner |
| H2 | content real (G5+) **and** scoring real (G8) | Passport credentials |
| H3 | guardian + moderation (G9) | any under-18 social feature |
| H4 | AI disclosure (P1 P0-15 card) | personas enabled |
| H5 | — | Beta content never in checkpoints/placement/credentials/children's mode |
| H6 | ≥2 native approvals | "Native-verified" label |
| H7 | licence-register entry | any source used |
| H8 | licence or waiver | any non-commercial data/model |
| H9 | tone-accuracy gate | TTS for tonal languages |
| H10 | placeholder linter clean | any build |

## Epic naming
`E-<phase>-<SLUG>` (e.g. `E-P1-SECRETS`, `E-P1-SOCKETS`, `E-P3-TOKENS`, `E-P4-LICENCES`). Each epic lists its cards, its integration test and the RTM rows it closes.
