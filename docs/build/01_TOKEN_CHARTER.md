charter: v2

# 01 — Token Economy Charter v2 and its enforcement

The charter text of record lives in `.cursor/rules/00-token-economy.mdc` (alwaysApply) and is not duplicated here; this file defines how it is enforced.

## Enforcement (Phase 0 cards P0-INT-01…05)

| Mechanism | Where | Trigger | Fails when |
|---|---|---|---|
| Rule file | `.cursor/rules/00-token-economy.mdc` | every Cursor session | absent or edited without `charter: v2` |
| Root pointer | `AGENTS.md` | every agent start | missing reference to the rule |
| Marker check | `scripts/check_agent_files.py` | pre-commit (`--staged`) and CI (`--diff origin/main`) | any new/changed rule, template, brief or card lacks `charter: v2` |
| Brief prefix | `docs/build/templates/*_brief.md` | every Worker/Tester/Reviewer launch | brief does not start with the charter pointer + card |
| Ledger | `docs/build/LEDGER.csv` | every card attempt | row missing; reviewed by Orchestrator at every gate |
| Budget stop | card `token_budget` | 80% → stop and report; 100% → halt | overrun without Orchestrator re-scope |
| Routing tuning | `docs/build/04_ROUTING.md` | every gate | routing changed from taste, not ledger |

## Isolation
Worker, Tester and Reviewer run as Cursor subagents (`Task` tool) with fresh context. Each receives exactly: the brief template, the card YAML, the allowlisted files, the RTM anchors (line ranges). No chat transcript is ever forwarded. If subagents are unavailable, use a fresh chat per role with the same packet.

## Ledger schema
`card_id, role, model_tier, model_slug, tokens_in, tokens_out, attempts, outcome, note`
Token columns record what the provider/Cursor exposes; if not exposed, record `n/a` and the attempt count. Never estimate a price.

## Caps
Worker report ≤15 lines · Tester report ≤15 lines · Reviewer verdict ≤20 lines · gate packet ≤400 words · failure digest ≤10 lines · extraction/triage report ≤5 lines.
