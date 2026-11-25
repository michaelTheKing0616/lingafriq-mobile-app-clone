charter: v2

# Marketing claims freeze (P1-029, P0-16)

Every public lesson-count and language-count claim found in the repository is **frozen until content is verified**.
Do not repeat these numbers in store listings, ads, onboarding, in-app copy or partner material until native-speaker
sign-off exists for the content behind them. Unverified languages show a coming-soon state, not placeholder lessons.

| Claim | Frozen value | Where it appears | Why frozen |
| --- | --- | --- | --- |
| Lessons per language (full track) | 30 lessons | `assets/data/lingafriq_authentic_curriculum_*.json` meta `lessons_per_language_full_track` | Editorial content only; no native reviewer sign-off |
| Languages shipped with curriculum and games | 14 languages | `tools/llm_authoring/reviewer_recruitment.md`; `lib/screens/curriculum/authentic_curriculum_entry_screen.dart` (user-facing: "Bundled lessons for 14 African languages — levels A1 through C2.") | Per-language content is not reviewer-verified |
| Public language-count claim: "2000+ languages" | 2000+ languages | `lib/screens/onboarding/onboarding_screen.dart`, `lib/screens/onboarding/modern_onboarding_screen.dart` | Public language-count claim, not a verified catalogue; no content behind it |
| Languages listed in bundled curriculum meta | 15 languages | `assets/data/lingafriq_authentic_curriculum_*.json` meta `languages` | `pidgin` and `nigerian_pidgin` are both listed; count is not a verified-content count |
| Languages supported by all features | 12 languages | `ALL_LANGUAGES_SUPPORT_IMPLEMENTATION.md`, `IMPLEMENTATION_COMPLETE_FINAL.md` | Infrastructure claim, not verified content |
| Future language catalogue | 50+ African languages | `FEATURES_COMPLETE.md` | Roadmap claim with no content behind it |
| Languages in legacy FINAL curriculum index | 7 languages | `lingafriq_FINAL_curriculum/master_index.json` | Template bundle; removed from the release asset list |

## Bundles pulled from the release build

Removed from `flutter: assets:` in `pubspec.yaml`: `curriculum_bundle/`, `lingafriq_FINAL_curriculum/`,
`lingafriq_full_curriculum_bundle/` (legacy template curriculum). `CurriculumService` already falls back to
`assets/data/` when these are absent.

## Unfreezing a claim

A row is unfrozen only when the content it describes passes `scripts/ci/placeholder_linter.py` and has native-speaker
sign-off recorded for each language counted.
