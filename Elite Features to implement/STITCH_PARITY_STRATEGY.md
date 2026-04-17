# Stitch mockups vs shipped app — strategy

## Is screen-for-screen, full visual parity advisable?

**Usually no** for a production codebase of this size.

- Stitch folders are **exploratory HTML** (many overlapping patterns, duplicate navigation, non–production states).
- Rebuilding **every** mock as a dedicated Flutter route would **fragment** navigation, duplicate logic, and slow iteration.
- **Better:** **feature parity** (same data, same user goals, same backend contracts) on **consolidated screens** (e.g. one Games hub + `GameType` registry, one Import/Studio flow, one WA-style inbox). The app already exposes a **feature map** at `StitchNavigationHubScreen` (`/stitch-hub`) linking named routes.

## When to mirror a mock more closely

- The mock represents a **distinct user journey** that cannot fold into an existing shell without UX loss.
- The mock introduces **new backend capabilities** (not just layout).

## What we optimize instead

- **Rich culture articles** from the backend scraper (long text, gallery, audio/video, highlights, attribution).
- **Stable localization** (`DynamicLocalizationService` + ARB) and incremental string migration.
- **Single design system** (Pan African / Modern Griot) over duplicating one-off Stitch CSS.

This document aligns product expectations with **maintainable** delivery; treat Stitch as **reference**, not a page checklist.
