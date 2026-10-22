charter: v2

# 00 — LingAfriq Master Build Plan (plan of record)

Owner and sole approver: Tope (Fabian Umole). Orchestrator: Fable 5.1 (T4). This plan is the contract the Orchestrator → Worker → Tester → Reviewer pipeline executes. It writes plans; app code is written only through cards.

## Sources (read once; consult by anchor only)
| Doc | File | Anchors |
|---|---|---|
| Senior Audit and Elevation Plan (96 pp) | `docs/source/ELEVATION.md` | `docs/source/ANCHORS.txt`, `RTM.csv` column `anchor` (`§x.y:Lfrom-Lto`) |
| Premium Curriculum Plan (12 pp) | `docs/source/CURRICULUM.md` | same |
| Companion `LINGAFRIQ_AI_MODEL_STACK.md` | **absent** → `EXTERNAL.md` EXT-01; vendor choices carried only as written in the two sources | — |

## Deliverables (this directory)
| File | Purpose |
|---|---|
| `01_TOKEN_CHARTER.md` + `.cursor/rules/00-token-economy.mdc` + `/AGENTS.md` | charter v2 and its enforcement |
| `02_PIPELINE.md` | roles, lifecycle, DoR/DoD, escalation, budgets, handoff packet |
| `03_PHASES_GATES.md` | phases P0–P13, gates G0–G13, exit criteria, hard-stop ordering H1–H10 |
| `04_ROUTING.md` | tiers, Cursor slug map, difficulty score, tuning log |
| `05_UX_DESIGN_BAR.md` · `06_TEST_STRATEGY.md` · `07_REVIEW_STANDARDS.md` | design/UI scorecards, test matrix, reviewer checklist (Stage D) |
| `08_SKILLS_MAP.md` · `ORCHESTRATOR_PROMPT.md` | skill apportioning rules (T0 `assign_skills.py`) and the paste-in prompt for the build orchestrator session |
| `COVERAGE_REPORT.md` · `gates/G0_PACKET.md` | Stage E self-audit (reproducible by the four scripts) and the G0 approval packet |
| `cards/<phase>/*.yaml` · `CARD_BRIEF.md` · `FEATURE_CARD_BRIEF.md` | 1,079 machine-checked cards and the briefs that produced them |
| `RTM.csv` | 2,960 atomic rows; every row ends `Verified-Done`, `Blocked-External` or `Waived-by-Tope` |
| `cards/<phase>/<ID>.yaml` | executable cards from `templates/card.yaml`; feature cards inherit `templates/feature_card_base.yaml` |
| `templates/` | card, feature base, worker/tester/reviewer briefs, gate packet, failure digest, ADR |
| `STATE.md` · `DECISIONS.md` · `LEDGER.csv` · `EXTERNAL.md` · `CONFLICTS.md` · `UNVERIFIED.md` · `OPEN_WORK.md` | compact state, signed decisions, token ledger, human-owned items, conflicts, unverified claims, work that is not done or not done fully |
| `scripts/plan/*.py`, `scripts/check_agent_files.py` | T0 tooling: convert, segment, merge, validate, coverage, dependencies, charter marker |

## Plan rules (apply to every card and review)
| Rule | Meaning |
|---|---|
| No-Cut | nothing removed; "consolidate" = one survivor + written harvest list; 25 unreachable screens revived (`REV-01…25`); 3 dev artefacts to `dev/` (`DEV-01…03`) |
| No-Partial | Done only with all ACs met and evidence; TODO/stub/"for now"/"simulate"/mock-as-real/placeholder/swallowed catch/fake-success ⇒ In Progress; placeholder + fake-success linters scan source code too |
| No-Loss | every RTM row ends `Verified-Done` / `Blocked-External (owner + unblock + artefact)` / `Waived-by-Tope (DECISIONS.md)` |
| Fail loud | typed errors and visible states; no fake-success anywhere |
| Honest by design | no unverified content, random score, mock participant, unlabelled AI persona or invented stat shown as real |
| Spec before code | ACs and test plan exist before a Worker starts |
| Source-anchored | cards cite RTM ids and anchors; never paste source text |
| Hard-stop ordering | H1–H10 in `03_PHASES_GATES.md`; never reordered |

## RTM id schemes
`P0-1…27` · `F-001…151` (+ `.D` defects, `.E` elevation, `.U` UX/render, `.L` lives-in) · `EP-§x.y-nn` · `CP-§x.y-nn` (per-language `CP-§2.4-<yo|ig|ha|pcm|sw|zu|xh>-nn`, `CP-§7-<lang>-nn`) · `AV-step1…7` · `OB-step1…8` · `REV-01…25` · `CON-01…06` · `DEV-01…03` · `RM-P0-01…13`, `RM-P1-nn`, `RM-P2-nn`, `RM-MS-nn`, `RM-STOP-nn` · `D1…D5` · `UNV-Enn/Cnn`.

## Card id schemes
`P<phase>-<nnn>` for engineering cards (e.g. `P1-004`); `P0-INT-nn` intake; `P0-VER-nn` verification; `F-<nnn>-<D|E|U|L|X>` feature cards (X = cross-facet/wiring); `ADR-nnn` decisions; `EXT-nn` external.

## Staged workflow for the planning run
A Ingest ✓ → B Skeleton ✓ → **Checkpoint 1 (Tope)** → C Cards (T2 drafts, T1 feature deltas, Fable reviews ~10% + all P0/safety/legal/design) → D Design/test/review docs → E Self-audit (T0 scripts, zero unmapped) → G0 gate packet → **Tope approves G0**.

## Definition of success
(1) every requirement traceable to a card, external action or signed waiver; (2) every card executable by the cheapest sufficient tier with a bounded budget; (3) every "done" has independent test evidence and independent review; (4) gates stop work where mistakes are costly or unsafe; (5) UX/UI bar numeric, testable, above the benchmark; (6) charter enforced by tooling.
