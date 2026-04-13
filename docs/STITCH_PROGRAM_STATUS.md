# Stitch full-build program — status vs plan

This tracks [`stitch_mockups_full_build_216002e5.plan.md`](file:///C:/Users/HP/.cursor/plans/stitch_mockups_full_build_216002e5.plan.md) (Phase 0–4). **Definition of done** in that plan requires every mockup row shipped or explicitly deferred, audits passed, CI green.

## Honest scope answer

| Question | Answer |
|----------|--------|
| **Are there ~88 separate, pixel-perfect Flutter files—one per `code.html`?** | **No.** The program maps mockups to **canonical screens** (one Flutter surface per user journey; repaired HTML variants collapse to a single implementation). Many mockups share [`GamesScreenMaterial3`](file:///C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/lib/screens/games/games_screen_material3.dart), magazine, village, feed, etc. |
| **Are all production routes and hubs implemented?** | **Largely yes** for elite baseline + existing app: see [`MOCKUP_TRACEABILITY.md`](./MOCKUP_TRACEABILITY.md) and [`SCREEN_BACKEND_REGISTRY.md`](./SCREEN_BACKEND_REGISTRY.md). Gaps are **per-audit** (Stitch fidelity, classroom realtime), not “missing files for every HTML folder name.” |
| **Community explore / profile / search** | **Production-backed:** trending and search use Node `feed` APIs; no hardcoded trending lists. Stitch **community chrome** uses [`StitchCommunityChatTheme`](file:///C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/lib/theme/stitch_theme_extensions.dart) when the app theme registers it. |

## Phase checklist (from plan)

| Phase | Status | Notes |
|-------|--------|--------|
| **0a** Prior screen audit | **Ongoing** | Requires row-by-row HTML vs Flutter diff; use traceability matrix + [`SCREEN_API_MATRIX.md`](./SCREEN_API_MATRIX.md). |
| **0b** Catalogue + tokens + backend gap | **Partial** | [`MOCKUP_TRACEABILITY.md`](./MOCKUP_TRACEABILITY.md), [`BACKEND_GAP.md`](./BACKEND_GAP.md); token extensions exist (`FlbEditorialTheme`, `StitchArcadeTheme`, `StitchCommunityChatTheme`). |
| **1** FLB / magazine / import | **Baseline** | Elite phases 9–14; audit Stitch HTML vs [`CultureMagazineScreenEnhanced`](file:///C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/lib/screens/magazine/culture_magazine_screen_enhanced.dart), import, heritage. |
| **2** Private chat tree | **Partial** | Community feed surfaces hardened; chat/classroom may need realtime spike per plan risk. |
| **3** Speed-round games | **Partial** | [`game_router.dart`](file:///C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/lib/screens/games/game_router.dart) + per-game audit vs mockup. |
| **4** QA / CI / i18n | **Ongoing** | Run `flutter analyze` / tests from intermediary before push. |

## What “complete” means here

Completing the **program** means: traceability rows **Shipped** or **Deferred (signed off)** + no dead production CTAs + contract sync + CI green—not 88 independent full-screen rewrites unless product demands that granularity.

---

*Last updated to reflect: hub language word lists + Quiz Chef rounds for all games-hub slugs; classroom/live routes in [`MOCKUP_TRACEABILITY.md`](./MOCKUP_TRACEABILITY.md); legacy `post_detail_screen.dart` / `post_detail_clean_screen.dart` delegating to [`XPostDetailScreen`](file:///C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/lib/screens/feed/x_post_detail_screen.dart) (no mock thread).*

**Remaining high-value backend (not blocking hub games):** optional `GET /api/feed/posts/:id` (or equivalent) so post detail does not depend on the post already being in the loaded timeline slice.
