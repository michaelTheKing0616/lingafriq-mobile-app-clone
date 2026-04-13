# Epic domain tracking (Phase C)

Work **vertical slices** in this order unless the screen matrix shows a blocker elsewhere.

| Order | Domain | Folder(s) | Exit criteria |
|-------|--------|-----------|---------------|
| 1 | Onboarding / auth / email | `screens/auth`, splash | Guest vs authed flows; tokens |
| 2 | Settings / profile / policy | `screens/settings`, `tabs_view/profile` | Preferences persisted |
| 3 | Lessons / path / recap / hub | `screens/lesson`, `screens/learning`, `navigation/lesson_hub_navigation.dart` | SSOT hub; API-backed path |
| 4 | Games | `screens/games`, providers | Canonical `GamesScreenMaterial3`; lexicon + content messaging |
| 5 | Village / tribes / duels | `screens/village` | CTAs + gamification APIs |
| 6 | Feed / community / X | `screens/feed` | Post/thread APIs; errors |
| 7 | Chat / WA / Snap / calls | `screens/chat`, `screens/wa`, `screens/snap` | Real-time contracts |
| 8 | Classroom | `screens/classroom` | Session lifecycle |
| 9 | AI / Polie / tutor | `screens/ai_chat`, `screens/tutor` | Orchestrator + hybrid-polie |
| 10 | Magazine / heritage / media / UGC | `screens/magazine`, `screens/heritage`, … | Content APIs |

Each epic closes when:

- All primary screens in the folder pass [`LIVE_READINESS_CHECKLIST.md`](./LIVE_READINESS_CHECKLIST.md).
- Matrix rows updated for touched files.

**Program status:** Inventory is fixed at **245** screen files (see [`SCREEN_FILE_INVENTORY.txt`](./SCREEN_FILE_INVENTORY.txt)). Remaining domains are closed incrementally via vertical-slice PRs; use the matrix **Pass / Won’t fix** column rather than blocking on a single mega-merge.

**Review queue:** Files with automated **Tier C** (no heuristic API signals) are listed in [`TIER_C_REVIEW_QUEUE.txt`](./TIER_C_REVIEW_QUEUE.txt). Many are still production-complete via child widgets or game loaders — see [`SCREEN_BACKEND_REGISTRY.md`](./SCREEN_BACKEND_REGISTRY.md).
