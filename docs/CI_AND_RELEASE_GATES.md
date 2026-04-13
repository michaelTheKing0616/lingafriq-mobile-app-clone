# CI and release gates (Phase E)

## Policy

- **Flutter:** Rely on **GitHub Actions** for `flutter analyze` and tests on push/PR (local analyze optional for velocity).
- **Node (intermediary):** Run `npm run build` before push; run targeted `npm test` when touching auth, lexicon, or hybrid-polie.

## Backend release scripts

From `node-backend-safe-push/package.json`:

- `gates:validate`, `resilience:validate`, `chaos:validate` — use for major releases.
- `security:secrets-hygiene` — run in CI or before prod deploy.

## Lexicon / admin

- Admin import: restrict to `requireSignin` + `requireAdmin`; cap upload size (multer); scan path logged; no execution of uploaded content.

## Push workflow

- Flutter: **`mobile-app-safe-push-michael`** → remote `michael` / `main` (per project rules).
- Node: **`node-backend-safe-push`** → `origin` / `main`.

Do not push from `Downloads/*` copies unless emergency, then sync back to intermediary.
