# Batch Integration Guide

## Quick Integration Using Helpers

This guide shows how to quickly integrate ErrorHandler and performance utilities across all screens using the new `integration_helpers.dart` utilities.

## 1. ErrorHandler Integration

### Before:
```dart
Future<void> loadData() async {
  try {
    final data = await apiService.getData();
    setState(() => this.data = data);
  } catch (e) {
    // Error handling missing or incomplete
  }
}
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

Future<void> loadData() async {
  await safeAsync(
    context: context,
    operation: () async {
      final data = await apiService.getData();
      setState(() => this.data = data);
    },
    errorContext: 'loadData',
  );
}
```

### Manual Integration (If Needed):
```dart
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

Future<void> loadData() async {
  try {
    final data = await apiService.getData();
    setState(() => this.data = data);
  } catch (e, stackTrace) {
    SentryService().captureException(e, stackTrace: stackTrace);
    if (context.mounted) {
      ErrorHandler.showError(context, e);
    }
  }
}
```

## 2. Search Debouncing

### Before:
```dart
TextField(
  onChanged: (query) {
    searchUsers(query); // Called on every keystroke!
  },
)
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

final searchDebouncer = createSearchDebouncer(
  onSearch: (query) async {
    final results = await searchUsers(query);
    setState(() => searchResults = results);
  },
);

TextField(
  onChanged: searchDebouncer,
)
```

## 3. ListView Optimization

### Before:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

optimizedList(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

## 4. Image Loading Optimization

### Before:
```dart
Image.network(
  user.avatarUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
)
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

lazyImage(
  imageUrl: user.avatarUrl,
  placeholder: CircularProgressIndicator(),
)
```

## 5. Data Caching

### Before:
```dart
Future<User> getUser(String id) async {
  return await apiService.getUser(id); // Always fetches from API
}
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

final userCache = createDataCache<User>(
  fetcher: (id) => apiService.getUser(id),
  ttl: Duration(minutes: 5),
);

// Usage:
final user = await userCache.get('user_123');
```

## 6. Batch Operations

### Before:
```dart
Future<void> loadAllData() async {
  try {
    final user = await fetchUser();
    final settings = await fetchSettings();
    final notifications = await fetchNotifications();
  } catch (e) {
    // Error handling
  }
}
```

### After (Using Helper):
```dart
import 'package:lingafriq/utils/integration_helpers.dart';

final results = await batchSafeAsync(
  context: context,
  operations: [
    () => fetchUser(),
    () => fetchSettings(),
    () => fetchNotifications(),
  ],
  errorContext: 'loadAllData',
);

final user = results[0] as User?;
final settings = results[1] as Settings?;
final notifications = results[2] as List<Notification>?;
```

## Integration Checklist

For each screen, check:

- [ ] All async operations wrapped in `safeAsync` or try-catch with `ErrorHandler`
- [ ] Search operations use `createSearchDebouncer`
- [ ] ListView replaced with `optimizedList` or `OptimizedListView`
- [ ] Image.network replaced with `lazyImage` or `LazyImage`
- [ ] Frequently accessed data uses `createDataCache`
- [ ] Batch operations use `batchSafeAsync`
- [ ] Navigation wrapped in `safeNavigate` if needed

## Priority Screens

### High Priority (Do First):
1. `auth\world_class_signup_screen.dart` - Registration
2. `dashboard\modern_dashboard_screen.dart` - Main dashboard
3. `chat\private_chat_screen.dart` - Private messaging
4. `chat\global_chat_screen.dart` - Global chat
5. `tutor\*.dart` - All tutor screens
6. `profile\*.dart` - All profile screens

### Medium Priority:
7. `games\*.dart` - Game screens
8. `settings\settings_screen.dart` - Settings
9. `onboarding\*.dart` - Onboarding flows
10. `social\*.dart` - Social features

### Low Priority:
11. Help screens
12. Info screens
13. Static content screens

## Automated Integration Script

For bulk integration, you can use find-and-replace:

### Find:
```dart
try {
  await someOperation();
} catch (e) {
  // Error handling
}
```

### Replace:
```dart
await safeAsync(
  context: context,
  operation: () async => someOperation(),
  errorContext: 'someOperation',
);
```

## Testing After Integration

1. Test error scenarios (network errors, API errors, etc.)
2. Verify error messages are user-friendly
3. Check Sentry for error tracking
4. Test performance improvements (debouncing, caching)
5. Verify list scrolling performance
6. Check image loading performance

## Notes

- Always use `context.mounted` check before showing errors
- Provide meaningful `errorContext` for debugging
- Set appropriate TTL for cached data
- Use debouncing for all search operations (300ms default)
- Replace all ListView with OptimizedListView for better performance

