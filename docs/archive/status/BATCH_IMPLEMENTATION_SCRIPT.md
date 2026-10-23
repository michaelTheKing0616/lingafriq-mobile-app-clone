# Batch Implementation Script

Due to file access timeouts, here's a systematic approach to complete all enhancements:

## Quick Implementation Pattern

For each file that needs ErrorHandler integration:

```dart
// 1. Add import at top
import 'package:lingafriq/utils/error_handler.dart';

// 2. Replace catch blocks:
// OLD:
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}

// NEW:
catch (e) {
  if (context.mounted) {
    ErrorHandler.showError(context, e);
  }
}
```

For Debouncer on search inputs:

```dart
// 1. Add import
import 'package:lingafriq/utils/performance_utils.dart';

// 2. Add field
late final Debouncer _searchDebouncer;

// 3. Initialize in initState
@override
void initState() {
  super.initState();
  _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
}

// 4. Dispose in dispose
@override
void dispose() {
  _searchDebouncer.dispose();
  super.dispose();
}

// 5. Use in TextField
TextField(
  onChanged: (value) {
    _searchDebouncer.run(() => _performSearch(value));
  },
)
```

For OptimizedListView:

```dart
// Replace ListView.builder with:
OptimizedListView(
  itemCount: items.length,
  itemExtent: 80.0, // Set approximate height for better performance
  itemBuilder: (context, index) => _buildItem(items[index]),
)
```

For LazyImage:

```dart
// Replace Image.network with:
LazyImage(
  imageUrl: url,
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
  fit: BoxFit.cover,
  width: width,
  height: height,
)
```

## Remaining Files Checklist

### ErrorHandler (13 remaining):
- [ ] chat/private_chat_screen_material3.dart
- [ ] chat/moderation_tools_screen.dart  
- [ ] chat/user_search_global_id_screen.dart
- [ ] chat/classroom_chat_livekit_screen.dart
- [ ] chat/chat_search_screen.dart
- [ ] onboarding/enhanced_onboarding_flow_screen.dart
- [ ] onboarding/placement_test_screen.dart
- [ ] ugc/create_lesson_screen_enhanced.dart
- [ ] curriculum/curriculum_screen.dart
- [ ] profile/user_profile_screen.dart
- [ ] games/games_screen.dart
- [ ] dashboard/dashboard_screen_material3.dart
- [ ] magazine/culture_magazine_enhanced_features.dart

### Debouncer (3 remaining):
- [ ] chat/private_chat_list_screen.dart
- [ ] onboarding/kijiji_onboarding_screen.dart
- [ ] magazine/culture_magazine_screen_enhanced.dart (if has search)

### OptimizedListView (7 remaining):
- [ ] chat/private_chat_list_screen.dart
- [ ] gamification/tribe_selection_screen.dart
- [ ] gamification/seasonal_events_screen.dart
- [ ] gamification/quest_screen.dart
- [ ] curriculum/curriculum_screen.dart
- [ ] dashboard/dashboard_screen_material3.dart

### LazyImage (10 remaining):
- [ ] profile/user_profile_screen.dart
- [ ] profile/profile_screen_material3.dart
- [ ] dashboard/modern_dashboard_screen.dart
- [ ] magazine/culture_magazine_screen.dart
- [ ] loading/dynamic_loading_screen.dart
- [ ] chat/user_search_global_id_screen.dart
- [ ] tabs_view/home/home_tab.dart
- [ ] tabs_view/courses/courses_tab.dart
- [ ] tabs_view/standings/standing_item.dart

