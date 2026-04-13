# Backend gap notes (mobile ↔ Node)

Living checklist for **contract drift** and **intentional deferrals**. Authoritative API lists live in `lib/config/api_contract.dart` and `node-backend-safe-push/src/contracts/mobileApiContract.ts`.

## In sync (recent verification)

| Domain | Mobile | Node | Notes |
|--------|--------|------|------|
| Feed explore | `ApiContract.feed.trending`, `ApiContract.feed.search` | `GET /api/feed/explore/trending`, `GET /api/feed/explore/search` | Query `q`, `type` for search. |
| Feed core | `feed.posts`, notifications, lists, profile | `feed.route.ts` | Auth as required per handler. |
| Games cards prefetch | `ApiContract.games.cards` | Games routes + controller | Used by `LazyGameLoader`. |

## Watch list (review each release)

1. **Feed post by id** — `XPostDetailScreen` resolves a post from the in-memory timeline; deep links work only after the post appears in a loaded page. Add `GET` single-post (or extend explore) when product prioritizes cold-start detail URLs.
2. **Social connections** — `ApiContract.social.*` uses path prefixes; confirm every screen uses `ApiContract.url()` consistently (some legacy `/connections` vs `/api/...`).
3. **Classroom / live session** — REST + realtime contracts for lobby/notes/speaker queue are implemented in app + Node; keep WebSocket/session IDs aligned per deployment.
4. **Speed-round games** — Each `GameType` should have content + scoring persistence; gaps are **per-game** (see `GAME_UI_MIGRATION_MATRIX.md`, `GAMES_RELEASE_GATES.md`).
5. **Hybrid translate / Polie** — Documented in `BACKEND_HYBRID_TRANSLATE_CONTRACT.md`; backend env keys must match deployment.

## When to update this file

- After adding a route-backed screen that calls a **new** endpoint.
- After changing `mobileApiContract.ts` or `api_contract.dart`.
- When CI or manual testing shows **404** / **wrong path** for a mobile call.

## Related docs

- [`SCREEN_API_MATRIX.md`](./SCREEN_API_MATRIX.md) — Pass / owner tracking.
- [`SCREEN_BACKEND_REGISTRY.md`](./SCREEN_BACKEND_REGISTRY.md) — Inventory and tier heuristics.
- [`MOCKUP_TRACEABILITY.md`](./MOCKUP_TRACEABILITY.md) — Stitch HTML → Flutter mapping.
