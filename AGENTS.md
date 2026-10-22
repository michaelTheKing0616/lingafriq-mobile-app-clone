charter: v2

# AGENTS.md — LingAfriq

Every agent, subagent, background agent and future bot in this repository is bound by the **Token Economy Charter v2** at `.cursor/rules/00-token-economy.mdc` (alwaysApply). Read it first; it is not optional.

| Need | Where |
|---|---|
| Plan of record, phases, gates | `docs/build/00_README_PLAN.md`, `docs/build/03_PHASES_GATES.md` |
| Roles, card lifecycle, escalation | `docs/build/02_PIPELINE.md` |
| Model routing (tiers, Cursor slug map) | `docs/build/04_ROUTING.md` |
| Requirements (never reread the PDFs) | `docs/build/RTM.csv`; anchors in `docs/source/ANCHORS.txt`; text by line range in `docs/source/ELEVATION.md` / `CURRICULUM.md` |
| Cards | `docs/build/cards/<phase>/<ID>.yaml` (schema: `docs/build/templates/card.yaml`) |
| Briefs you receive | `docs/build/templates/{worker,tester,reviewer}_brief.md` |
| State, decisions, ledger, unfinished work | `docs/build/STATE.md`, `DECISIONS.md`, `LEDGER.csv`, `OPEN_WORK.md` |
| Skills per card (read ≤3, by path) | `docs/build/08_SKILLS_MAP.md`; card `skills:` block |
| Design, test and review bars | `docs/build/05_UX_DESIGN_BAR.md`, `06_TEST_STRATEGY.md`, `07_REVIEW_STANDARDS.md` |

Rules that bind code work (see 00_README_PLAN.md §3): No-Cut · No-Partial · No-Loss · Fail loud · Honest by design · Spec before code · Source-anchored · Hard-stop ordering.

**Best solution, not the easiest.** Tope, 2026-10-22. A mock, shim, pin, or shortcut is a defect when the real module, dependency, or runtime can be fixed. Tests load the real code under test. External services may use a labelled fixture. If the real path cannot be reached, stop and say why. Orchestrator: every worker, tester, and reviewer packet includes this rule.

CI/pre-commit: `python3 scripts/check_agent_files.py` fails on any agent-facing file without `charter: v2`.
