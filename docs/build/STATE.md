charter: v2

# STATE.md — compact orchestrator state (overwrite, do not append history)

| Field | Value |
|---|---|
| Updated | 2026-10-22 |
| Stage | **G0 GO signed by Tope 2026-10-21** → build phase; orchestrator = Grok 4.7 (`ORCHESTRATOR_PROMPT.md`) |
| Gate | G0 passed · next G1 Containment |
| RTM | `RTM.csv` 2,960 rows · unmapped 0 · Blocked-External 5 · `check_rtm_coverage.py --write` applied |
| Cards | 1,079 in `cards/` (build 695 · feature 151 · verification 78 · epic 57 · adr 38 · external 31 · design 29); `validate_cards.py` OK · `check_dependencies.py` OK |
| Docs | 00–08 written; `ORCHESTRATOR_PROMPT.md`; `skills:` on every card (`assign_skills.py`); `COVERAGE_REPORT.md`; templates ×8; `CARD_BRIEF.md`, `FEATURE_CARD_BRIEF.md` |
| Decisions | D1–D10, D11, D21–D26 signed. D12–D19 still awaiting. Key cleanup is deferred (D24) and does not block the build. |
| Conflicts | C1–C5 resolved (ADR-001…003) |
| External | EXT-01…30 open (`EXTERNAL.md`); EXT-01 companion doc still missing |
| Benchmark | UI phases: `docs/build/benchmark/duolingo/` holds the 12 picks; `all/` holds the other 48; `README.md` has source, date, and size. Do not open the images until a card sets `visual_evidence_required`. |
| Audit | `check_agent_files.py` OK (1,092 files) |
| Next | Work stays on the Mac on `cloud-handoff`. Key cleanup is end-of-build (D24). P2-013 is Done. Contract tests check the route inventory and body schemas. Next build card is P2-014. The full Import Media lesson is carded as P7-961 and does not jump ahead of that queue. R1 model update is carded (P4-168, P6-086, P7-945, P7-950, P7-947) and does not jump ahead of the open queue. Curriculum wiring stays paused. Live PM2 stays unverified (EXT-23). |
