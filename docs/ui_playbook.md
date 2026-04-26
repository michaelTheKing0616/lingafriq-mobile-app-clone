# LingAfriq Mobile UI playbook (wave-based)

This repository has a design system already. The goal is to enforce it consistently by shipping changes in waves, not by touching every screen at once.

## Non-negotiables for any touched screen

1. Use `LingafriqScaffold` for page structure and safe areas.
   - If the screen uses an `AppBar`, set `applyTopSafeArea: false` so the toolbar owns the top inset.
   - If the screen is inside a tab shell with a `bottomNavigationBar`, the shell usually sets `applyBottomSafeArea: false` on the body; the bottom bar can wrap itself with a safe area.
2. Use tokens from `lib/utils/pan_african_design_system.dart` (spacing, radius, typography, colors).
3. Avoid “magic numbers” for padding/margins unless there is no suitable token.
4. Always design for states: loading, empty, error, and success.

## Spacing & layout rules

- Prefer `PanAfricanSpacing.*` over raw `EdgeInsets(...)`.
- Keep touch targets at least 48 logical pixels high for primary actions (buttons, icon buttons).
- Avoid placing primary controls under the iOS home indicator / Android gesture bar. If in doubt, wrap the body with `LingafriqScaffold` (default safe areas).

## Wave rollout

Wave 1 (infrastructure + highest traffic)
- Shell / tabs view
- Ling Chat (community channels) + Ling Chat (AI)
- Lessons (lesson flow)
- Games (hub/catalog screen)

Wave 2 (first impression)
- Auth + onboarding

Wave 3 (high time-spend)
- Lessons detail screens + games sub-screens

Wave 4 (long tail)
- Settings, admin, and rarely used routes

