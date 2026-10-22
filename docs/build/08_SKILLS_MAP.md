charter: v2

# 08 — Skills map (who loads which skill, and when)

Skills root: `~/Library/Application Support/Cursor/AgentStores/cursor_agent_stores/u305487884/files/skills/` → `adaptive/` (16 orchestration skills) and `prime/` (334 design/UX/motion/a11y skills). Each card's `skills:` block is written by **T0** `scripts/plan/assign_skills.py --write` from the rules in that file. No model picks skills ad hoc.

## Loading rules (token discipline)
| Rule | Why |
|---|---|
| A subagent reads **only** the `SKILL.md` files named in its packet (card `skills.worker`, plus the one role skill), **never** a skill's `references/` folder unless the SKILL.md tells it to for the exact task | one SKILL.md ≈ 1–4k tokens; three is the cap |
| The Orchestrator loads its three role skills **once** at session start and never reloads them | stable prefix, provider caching |
| Workers get `skills.worker` (≤3). Testers get `06-execution-and-verification` only. Reviewers get `06-execution-and-verification` + `skills.reviewer_extra` when the card has `visual_evidence_required: true` | role-fit, not breadth |
| Skills are never pasted into prompts; the packet lists paths and the agent reads them with its Read tool | no duplication across turns |
| Prime skills are web-first; Flutter specifics come from the card, the design tokens JSON and `05_UX_DESIGN_BAR.md`. When a skill's advice conflicts with the card or the design bar, the card wins | avoid web idioms leaking into Flutter |
| Skills are advisory craft input; acceptance criteria and T0 lints remain the only pass/fail authority | reviewability |

## Role skills (always-on, one load)
| Role | Skills |
|---|---|
| Orchestrator | `adaptive/00-adaptive-orchestrator`, `adaptive/02-model-routing`, `adaptive/03-cost-and-token-efficiency` |
| Worker | `adaptive/08-coding-and-debugging` (+ card `skills.worker`) |
| Tester | `adaptive/06-execution-and-verification` |
| Reviewer | `adaptive/06-execution-and-verification` (+ `skills.reviewer_extra` on visual cards: `critique-visual-hierarchy`, `critique-typography`, `design-to-code-check`) |

## Card-class → worker skills (summary of `assign_skills.py` rules; ≤3 each)
| Card class | Skills |
|---|---|
| Design: benchmark | `design-audit`, `critique-visual-hierarchy` |
| Design: principles / journeys | `design-everyday-things`, `design-brief` |
| Design: art direction | `design-dna`, `illustration-style`, `no-ai-slop` |
| Design: tokens (build cards titled token/theme/font) | `token-compliance`, `theme-audit`, `typography-scale` |
| Design: hi-fi signature screens | `mobile-app-ui-design`, `antislop-ui`, `platform-conventions` |
| Design: component catalogue | `design-system`, `state-machine`, `accessibility-per-component` |
| Design: motion / sound / haptics | `motion-system`, `design-motion-principles`, `microinteractions` |
| Design: copy deck / voice | `ux-writing`, `antislop-copywriting`, `localization-design` |
| Design: wireflows | `navigation-patterns`, `information-architecture`, `user-flow-diagram` |
| Design: usability protocol | `test-scenario`, `click-test-plan`, `accessibility-test-plan` |
| Design: illustration / character bible / avatar chips | `illustration-style`, `design-dna`, `rive` |
| Design: pedagogy flows (SDT, speaking-first) | `hooked-ux` (ethical use only; see guardrails card P10-913), `feedback-patterns`, `onboarding-ux` |
| Design: DPIA / consent / casting | `adaptive/14-safety-and-high-stakes`, `adaptive/09-writing-and-communication` |
| Design: G3 gate review | `design-critique`, `critique-visual-hierarchy`, `design-to-code-check` |
| Feature: social (`under18_social`) | `mobile-app-ui-design`, `error-handling-ux`, `adaptive/14-safety-and-high-stakes` |
| Feature: games | `mobile-app-ui-design`, `microinteractions`, `feedback-patterns` |
| Feature: streaks / goals / leagues / badges | `mobile-app-ui-design`, `hooked-ux`, `feedback-patterns` |
| Feature: chat / tutor / persona | `conversational-ux`, `mobile-app-ui-design`, `error-handling-ux` |
| Feature: settings / privacy / subscription / profile | `form-design`, `mobile-app-ui-design`, `ux-writing` |
| Feature: other | `mobile-app-ui-design`, `feedback-patterns`, `error-handling-ux` |
| Build, user-facing: motion / avatar | `motion-system`, `rive`, `animation-principles` |
| Build, user-facing: a11y | `accessibility`, `fixing-accessibility` |
| Build, user-facing: states kit | `error-handling-ux`, `feedback-patterns`, `state-machine` |
| Build, user-facing: copy / ARB / i18n | `ux-writing`, `localization-design` |
| Build, user-facing: nav / shell | `navigation-patterns`, `mobile-app-ui-design` |
| Build: security / minors / payments / privacy | `adaptive/14-safety-and-high-stakes`, `adaptive/08-coding-and-debugging` |
| Build: evals / scorer / metrics | `adaptive/11-data-and-quantitative-work`, `adaptive/07-research-and-fact-checking` |
| Build: other | `adaptive/08-coding-and-debugging` |
| ADR | `adaptive/10-analysis-and-decision-support`, `diagram-design` |
| Epic integration | `adaptive/13-agent-teams`, `adaptive/06-execution-and-verification` |
| Verification | `adaptive/07-research-and-fact-checking`, `adaptive/06-execution-and-verification` |

## Maintenance
Add or change a rule in `assign_skills.py`, re-run with `--write`, commit. The tuning log in `04_ROUTING.md` records when a skill measurably changed first-pass rate; skills with no measured effect after a phase are dropped from the rules, not kept out of habit.
