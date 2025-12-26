# Performance Utilities Quick Reference

## Cache Usage

### SimpleCache (Singleton)
```dart
import 'package:lingafriq/utils/simple_cache.dart';

// Get singleton instance
final cache = SimpleCache();

// Set value with default TTL (1 hour)
cache.set<String>('user_name', 'John');

// Set value with custom TTL
cache.set<List<String>>('recent_searches', ['search1', 'search2'], 
  ttl: Duration(minutes: 30));

// Get value
final userName = cache.get<String>('user_name');

// Get or compute (lazy loading)
final data = await cache.getOrCompute<List<Item>>(
  'items',
  () => fetchItemsFromAPI(),
  ttl: Duration(hours: 2),
);

// Check if key exists
if (cache.contains('user_name')) {
  // Key exists and not expired
}

// Remove key
cache.remove('user_name');

// Clear all cache
cache.clear();

// Get cache statistics
final stats = cache.getStats();
print('Active entries: ${stats['active']}');
print('Total entries: ${stats['total']}');
```

---

## Widget Usage

### OptimizedListView
```dart
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';

OptimizedListView(
  itemCount: items.length,
  itemExtent: 80.0, // Fixed height for better performance
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].title),
    );
  },
  controller: scrollController,
  padding: EdgeInsets.all(16),
)
```

### LazyImage
```dart
import 'package:lingafriq/widgets/performance/lazy_image.dart';

LazyImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.broken_image),
)
```

---

## Debouncer
```dart
import 'package:lingafriq/utils/debouncer.dart';

final debouncer = Debouncer(delay: Duration(milliseconds: 500));

// In search field
onChanged: (value) {
  debouncer.run(() {
    performSearch(value);
  });
}

// Cleanup
@override
void dispose() {
  debouncer.dispose();
  super.dispose();
}
```

---

## Throttler
```dart
import 'package:lingafriq/utils/performance_utils_consolidated.dart';

final throttler = Throttler(delay: Duration(seconds: 1));

// Throttle button clicks
onPressed: () {
  throttler.run(() {
    handleButtonClick();
  });
}
```

---

## Batch Processor
```dart
import 'package:lingafriq/utils/performance_utils_consolidated.dart';

final processor = BatchProcessor<Item>(
  batchSize: 10,
  processor: (batch) async {
    await uploadBatch(batch);
  },
);

await processor.processAll(allItems);
```

---

## Image Cache Management
```dart
import 'package:lingafriq/utils/performance_utils_consolidated.dart';

// Configure cache size (default: 100MB)
ImageCacheManager.configureCache();

// Clear all cached images
ImageCacheManager.clearCache();
```

---

## Migration Checklist

- [ ] Replace `SimpleCache<K, V>()` with `SimpleCache()` singleton
- [ ] Convert keys to String if needed
- [ ] Update imports from `performance_utils.dart` to dedicated files
- [ ] Use `get<T>()` and `set<T>()` with type parameters
- [ ] Test cache eviction and TTL behavior
- [ ] Verify widget performance improvements

