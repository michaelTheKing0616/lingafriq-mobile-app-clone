# Build Errors Fix Plan

## Summary
The build has **2000+ compilation errors** across multiple categories. This document outlines the systematic approach to fix them.

## Critical Blocking Issues (Must Fix First)

### 1. ✅ FIXED: Missing Packages
- Added `record: ^5.1.2`
- Added `audioplayers: ^6.1.0`
- Added `socket_io_client: ^2.0.3+1`

### 2. ✅ FIXED: Missing Files
- Created `lib/config/app_config.dart` with API endpoints
- Created `lib/widgets/animations/smooth_transitions.dart` with SmoothPageRoute

### 3. ⚠️ PENDING: Workmanager Kotlin Compilation Error
**Error:** `Unresolved reference: shim`, `ShimPluginRegistry`, `PluginRegistrantCallback`, `Registrar`

**Root Cause:** Workmanager 0.5.2 uses old Flutter embedding v1 APIs that are incompatible with current Flutter/Kotlin setup.

**Solution Options:**
- **Option A (Recommended):** Upgrade workmanager from 0.5.2 to 0.9.0+3 (requires code migration)
- **Option B:** Downgrade Flutter embedding (not recommended, breaks other things)
- **Option C:** Remove workmanager temporarily if not critical

**Action Required:** Upgrade workmanager and update code accordingly.

## Major Error Categories

### Category 1: Syntax Errors (High Priority)
- `dialog_provider.dart` - Multiple syntax errors in showPlatformDialogue function
- `import_media_dialogs.dart` - Missing braces/parentheses, class definition errors
- Multiple files with mismatched parentheses/braces

### Category 2: Missing Type Definitions
- `CredentialStorageService` - Missing class
- `BiometricAuthService` - Missing class  
- `ConflictResolutionService` - Missing class
- `SelectiveSyncService` - Missing class
- `CacheCompressionService` - Missing class
- `CacheEncryptionService` - Missing class
- `OfflineAnalyticsService` - Missing class
- `ProfileModel` - Missing fields (username, email, level, learningLanguage, etc.)
- `AppColors` - Missing properties (stitchPrimary, success, surfaceDark, surfaceLight, etc.)
- `ConversationFlow` enum - Must be moved out of class

### Category 3: API Changes
- `connectivity_plus` - Changed from `List<ConnectivityResult>` to `ConnectivityResult`
- `sentry_flutter` 7.20.2 API changes:
  - `ISentryTransaction` type changes
  - `SentryLevel.values` removed (use enum directly)
  - `UserFeedback` API changes
  - `Sentry.close(timeout:)` parameter removed

### Category 4: Duplicate Declarations
- `ai_chat_provider_groq.dart` - Duplicate getters for `targetLanguage` and `sourceLanguage`

### Category 5: Missing Methods/Properties
- `ApiProvider` - Missing many methods (awardXP, getUserXP, getGamification, etc.)
- `DialogProvider` - Missing `showSuccessSnackBar` method
- `BaseProviderState` - Missing properties (username, email, goals, etc.)
- `StateNotifier` usage - Incorrect implementation in xp_gain_overlay.dart

### Category 6: Flutter API Changes
- `CardTheme` vs `CardThemeData` type mismatch
- `LoadingOverlay` - API changes (opacity parameter removed)
- `OptimizedListView.builder` - Method doesn't exist
- `OfflineIndicator` - Required `child` parameter
- `HapticFeedback` - Import missing
- `TextDirection.rtl`/`.ltr` - Use `TextDirection.rtl` and `TextDirection.ltr`

## Recommended Fix Order

1. ✅ Fix missing packages (DONE)
2. ✅ Fix missing files (DONE)
3. ⚠️ Fix workmanager Kotlin error (IN PROGRESS)
4. Fix syntax errors in dialog_provider.dart and import_media_dialogs.dart
5. Fix duplicate declarations in ai_chat_provider_groq.dart
6. Move ConversationFlow enum out of class
7. Update connectivity_plus API usage
8. Update sentry_flutter API usage
9. Create missing service classes (stubs or full implementations)
10. Fix ProfileModel and AppColors missing properties
11. Fix StateNotifier usage
12. Update API provider with missing methods
13. Fix remaining Flutter API changes

## Notes

- Many errors are cascading - fixing one category may resolve others
- Some errors require architectural decisions (e.g., what should missing services do?)
- Consider creating stub implementations first, then implementing properly
- Test incrementally after each major category is fixed

