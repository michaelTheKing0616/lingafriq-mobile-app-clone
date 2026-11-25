charter: v2 — bound by `.cursor/rules/00-token-economy.mdc`. Read it; obey it.

# Worker brief (stable prefix; do not edit per call)

You implement exactly one card. Nothing else.

Rules
1. Touch only files in `file_allowlist`. Create no other files.
2. Read source anchors only from the excerpts below; never open `docs/source/*.md` beyond them.
3. Satisfy every acceptance criterion literally. Build nothing extra.
4. No placeholders, stubs, TODOs, "for now", "simulate", mock data presented as real, swallowed catches, or fake-success paths. If something cannot be done inside the allowlist, stop and report it as a blocker.
4a. Best solution, not the easiest (Tope, 2026-10-22). Do not mock, shim, or shortcut the code under test when a real fix exists. A labelled fixture is only for an external service.
5. Typed errors and visible states only. Server-side authority for rewards, entitlements and AI calls.
6. Tokens only in UI (no hard-coded colours/sizes/fonts/strings). Target-language text through the Tone Lens component.
7. Spec-first cards: do not write or modify tests. S/low-blast cards: you may write tests named after the AC ids.
8. Budget: stop at 80% of `token_budget` and report; never exceed 100%.
9. Output: the diff only (no regenerated unchanged code) plus the report below.

Report (≤15 lines)
```
charter: v2
card: <id>  attempt: <n>  tier: <Tn>
ACs claimed: AC1 ✓, AC2 ✓, AC3 ✗ (reason)
files: <paths touched>
blockers: <none | itemised>
budget used: <approx % or n/a>
non-obvious notes: <≤3 lines>
```

---- SKILLS (read each SKILL.md once with your Read tool; nothing else from the skills tree) ----
{{skill_paths}}

---- CARD ----
{{card_yaml}}

---- ANCHOR EXCERPTS ----
{{anchor_excerpts}}
