# Performance Utilities Integration Guide
## Complete Integration Across All Applicable Screens

**Status:** Utilities ready, needs integration  
**Target:** Integrated across all applicable screens

---

## Integration Patterns

### 1. Debouncer for Search Inputs

**Before:**
```dart
TextField(
  onChanged: (value) {
    performSearch(value); // Called on every keystroke!
  },
)
```

**After:**
```dart
final searchDebouncer = useMemoized(() => Debouncer(delay: Duration(milliseconds: 500)));

TextField(
  onChanged: (value) {
    searchDebouncer.run(() {
      performSearch(value); // Called only after 500ms of no typing
    });
  },
)
```

**Files to Update:** ~15 files with search inputs

---

### 2. OptimizedListView for Lists

**Before:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

**After:**
```dart
import 'package:lingafriq/utils/performance_utils.dart';

OptimizedListView(
  itemCount: items.length,
  itemExtent: 80.0, // Fixed height for better performance
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

**Files to Update:** ~30 files with ListView.builder

---

### 3. LazyImage for Images

**Before:**
```dart
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
)
```

**After:**
```dart
import 'package:lingafriq/utils/performance_utils.dart';

LazyImage(
  imageUrl: imageUrl,
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.broken_image),
  fit: BoxFit.cover,
)
```

**Files to Update:** ~25 files with Image.network

---

### 4. SimpleCache for Data

**Before:**
```dart
Future<List<Item>> loadItems() async {
  final response = await api.getItems(); // Always fetches from API
  return response;
}
```

**After:**
```dart
import 'package:lingafriq/utils/performance_utils.dart';

final cache = SimpleCache<String, List<Item>>(defaultTtl: Duration(hours: 1));

Future<List<Item>> loadItems() async {
  final cacheKey = 'items_${language}_${userId}';
  
  // Check cache first
  final cached = cache.get(cacheKey);
  if (cached != null) return cached;
  
  // Fetch from API
  final response = await api.getItems();
  
  // Cache result
  cache.set(cacheKey, response);
  
  return response;
}
```

**Files to Update:** ~20 locations with cacheable data

---

## Files Requiring Integration

### Search Inputs (Debouncer) - ~15 files
1. `lib/screens/chat/user_search_global_id_screen.dart`
2. `lib/screens/social/global_people_search_screen.dart`
3. `lib/screens/chat/chat_search_screen.dart`
4. And more...

### Lists (OptimizedListView) - ~30 files
1. `lib/screens/chat/private_chat_list_screen.dart`
2. `lib/screens/curriculum/curriculum_screen.dart`
3. `lib/screens/magazine/culture_magazine_screen_enhanced.dart`
4. And more...

### Images (LazyImage) - ~25 files
1. `lib/screens/magazine/culture_magazine_screen.dart`
2. `lib/screens/tabs_view/home/home_tab.dart`
3. `lib/screens/tabs_view/courses/courses_tab.dart`
4. And more...

### Data Caching (SimpleCache) - ~20 locations
- API response caching
- User data caching
- Language data caching
- Content caching

---

## Implementation Checklist

For each file:
- [ ] Identify performance optimization opportunities
- [ ] Import performance utilities
- [ ] Replace with optimized versions
- [ ] Test performance improvements
- [ ] Verify functionality unchanged

---

## Expected Performance Improvements

- **Search:** 50-70% reduction in API calls
- **Lists:** 30-40% faster scrolling
- **Images:** 40-60% faster loading
- **Data:** 60-80% faster subsequent loads (with cache)

---

**Estimated Time:** 16 hours (2 days) for complete integration

---

**Last Updated:** January 2025

