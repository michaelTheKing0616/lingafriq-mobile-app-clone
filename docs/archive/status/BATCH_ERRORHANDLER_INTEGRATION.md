# Batch ErrorHandler Integration Guide

## Quick Integration Pattern

For screens with async operations that need ErrorHandler, use this pattern:

### Pattern 1: Using safeAsync Helper (Recommended)

```dart
// Add imports at top
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

// Replace existing try-catch blocks:
// BEFORE:
try {
  final result = await apiCall();
  setState(() => data = result);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}

// AFTER:
await safeAsync(
  context: context,
  operation: () async {
    final result = await apiCall();
    setState(() => data = result);
  },
  errorContext: 'operationName',
);
```

### Pattern 2: Manual ErrorHandler (When needed)

```dart
// Add import
import 'package:lingafriq/utils/error_handler.dart';

// Wrap async operations:
try {
  await operation();
} catch (e) {
  if (context.mounted) {
    ErrorHandler.showError(context, e);
  }
}
```

### Pattern 3: Socket Operations

```dart
// For socket.sendMessage, socket.connect, etc.
try {
  socket.sendMessage(roomId, message);
} catch (e) {
  if (mounted) {
    ErrorHandler.showError(context, e);
  }
}
```

## Remaining Screens to Integrate

### Tutor Screens (4 remaining)
- [ ] tutor_translation_mode_screen.dart
- [ ] tutor_dashboard_screen.dart
- [ ] listening_quiz_screen.dart
- [ ] shadowing_exercise_screen.dart
- [ ] curriculum_viewer_screen.dart

### Profile & Settings (3 screens)
- [ ] user_profile_screen.dart (has ErrorBoundary, needs ErrorHandler for async)
- [ ] profile_edit_screen.dart
- [ ] change_password_screen.dart
- [ ] settings_screen.dart (has ErrorBoundary, needs ErrorHandler for async)

### Games & Social (~10 screens)
- [ ] games_screen.dart
- [ ] language_games_screen.dart
- [ ] base_game_screen.dart
- [ ] global_people_search_screen.dart
- [ ] user_connections_screen.dart
- [ ] social_gifting_screen.dart
- [ ] tribe_vs_tribe_screen.dart
- [ ] language_villages_screen.dart
- [ ] ancestral_tree_screen.dart

### AI Chat & Content (~5 screens)
- [ ] ai_chat_screen.dart
- [ ] ai_chat_select_screen.dart
- [ ] ai_chat_language_setup_screen.dart
- [ ] polie_mode_selection_screen.dart
- [ ] culture_magazine_screen.dart

### Onboarding & Progress (~6 screens)
- [ ] enhanced_onboarding_flow_screen.dart
- [ ] onboarding_screen.dart
- [ ] modern_onboarding_screen.dart
- [ ] placement_test_screen.dart
- [ ] progress_dashboard_screen.dart
- [ ] global_progress_screen.dart

### UGC & Content Creation (~5 screens)
- [ ] ugc_hub_screen.dart
- [ ] create_lesson_screen.dart
- [ ] create_quiz_screen.dart
- [ ] create_story_screen.dart
- [ ] ugc_validation_feedback_screen.dart

### Chat Screens (remaining)
- [ ] tribe_chat_screen.dart
- [ ] community_chat_screen.dart
- [ ] private_chat_screen_material3.dart
- [ ] global_chat_screen_material3.dart
- [ ] classroom_chat_livekit_screen.dart
- [ ] moderation_tools_screen.dart

### Other Screens (~30 screens)
- All remaining screens in tabs_view, help, contribute, etc.

## Integration Checklist Per Screen

1. [ ] Add ErrorHandler import
2. [ ] Add Integration Helpers import (if using safeAsync)
3. [ ] Find all async operations (Future, async, await)
4. [ ] Wrap in safeAsync() or try-catch with ErrorHandler.showError()
5. [ ] Test error scenarios
6. [ ] Verify no linter errors
7. [ ] Mark as complete

## Total Progress

- **Completed**: 22 screens (25%)
- **Remaining**: ~66 screens (75%)
- **Target**: 100% (88 screens)

