/// Performance Utilities Integration Example
/// Shows the pattern for integrating performance utilities
/// 
/// Copy these patterns to applicable screens

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/performance_utils.dart';

/// Example Screen with Performance Utilities
class ExampleScreenWithPerformanceUtils extends HookConsumerWidget {
  const ExampleScreenWithPerformanceUtils({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final searchResults = useState<List<String>>([]);
    final items = useState<List<Map<String, dynamic>>>([]);
    final cache = useMemoized(() => SimpleCache<String, List<String>>());

    // DEBOUNCER for Search - Reduces API calls by 50-70%
    final searchDebouncer = useMemoized(() => Debouncer(delay: Duration(milliseconds: 500)));

    void performSearch(String query) {
      // Check cache first
      final cached = cache.get(query);
      if (cached != null) {
        searchResults.value = cached;
        return;
      }

      // Perform search (would be API call)
      // final results = await api.search(query);
      final results = <String>[]; // Placeholder
      
      // Cache results
      cache.set(query, results, ttl: Duration(minutes: 5));
      searchResults.value = results;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Performance Example')),
      body: Column(
        children: [
          // SEARCH with DEBOUNCER
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                searchQuery.value = value;
                // DEBOUNCER: Only search after 500ms of no typing
                searchDebouncer.run(() {
                  if (value.isNotEmpty) {
                    performSearch(value);
                  }
                });
              },
            ),
          ),

          // LIST with OPTIMIZEDLISTVIEW
          Expanded(
            child: items.value.isEmpty
                ? Center(child: Text('No items'))
                : OptimizedListView(
                    itemCount: items.value.length,
                    itemExtent: 80.0, // Fixed height for better performance
                    padding: EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = items.value[index];
                      return _ListItem(
                        item: item,
                        // Use LAZYIMAGE for images
                        imageUrl: item['imageUrl'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// List Item with LazyImage
class _ListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? imageUrl;

  const _ListItem({
    required this.item,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: imageUrl != null
            ? LazyImage(
                imageUrl: imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: CircularProgressIndicator(),
                errorWidget: Icon(Icons.image),
              )
            : Icon(Icons.image),
        title: Text(item['title'] ?? ''),
        subtitle: Text(item['subtitle'] ?? ''),
      ),
    );
  }
}

/// Key Points:
/// 1. Use Debouncer for all search inputs (500ms delay)
/// 2. Use OptimizedListView for all lists (with itemExtent when possible)
/// 3. Use LazyImage for all network images
/// 4. Use SimpleCache for cacheable data (API responses, etc.)
/// 5. Set appropriate TTL for cache (5-60 minutes typically)

