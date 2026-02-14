// Integrated Screen Example
// Demonstrates how to use all performance utilities, error handling, and analytics together
// 
// This is a reference implementation showing best practices for:
// - Error handling with retry
// - Performance tracking
// - Caching
// - Debounced search
// - Optimized list rendering
// - Lazy image loading

import 'package:flutter/material.dart';
import '../utils/performance_exports.dart';
// import '../core/network/api_client_with_recovery.dart';
import '../widgets/global/error_recovery_widget.dart';

class IntegratedScreenExample extends StatefulWidget {
  const IntegratedScreenExample({super.key});

  @override
  State<IntegratedScreenExample> createState() => _IntegratedScreenExampleState();
}

class _IntegratedScreenExampleState extends State<IntegratedScreenExample>
    with ScreenPerformanceTracker {
  final SimpleCache _cache = SimpleCache();
  final TextEditingController _searchController = TextEditingController();
  DebouncedSearch? _debouncedSearch;
  List<String> _items = [];
  List<String> _filteredItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Initialize debounced search
    _debouncedSearch = DebouncedSearch(
      delay: const Duration(milliseconds: 500),
      onSearch: _performSearch,
    );

    // Load initial data
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncedSearch?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Start performance tracking
    startTimer('data_load');

    try {
      // Try to get from cache first
      final cached = _cache.get<List<String>>('example_items');
      if (cached != null) {
        setState(() {
          _items = cached;
          _filteredItems = cached;
          _isLoading = false;
        });
        trackMetric(
          type: MetricType.cacheHit,
          identifier: 'example_items',
          value: 1.0,
        );
        return;
      }

      // Load from API with error recovery
      final result = await safeAsyncOperation<List<String>>(
        operation: () async {
          // Simulate API call
          await Future.delayed(const Duration(seconds: 1));
          return List.generate(100, (i) => 'Item ${i + 1}');
        },
        cacheKey: 'example_items',
        cacheTTL: const Duration(minutes: 5),
        maxAttempts: 3,
      );

      if (result != null) {
        setState(() {
          _items = result;
          _filteredItems = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      stopTimer('data_load');
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _items;
      });
      return;
    }

    // Start search performance tracking
    startTimer('search');

    final filtered = _items
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _filteredItems = filtered;
    });

    stopTimer('search', metadata: {'query': query, 'results': filtered.length});
  }

  @override
  Widget build(BuildContext context) {
    return ErrorRecoveryWidget(
      errorMessage: _error,
      onRetry: _loadData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Integrated Screen Example'),
        ),
        body: Column(
          children: [
            // Search bar with debouncing
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _debouncedSearch?.search(value);
                },
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(_error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : PerformanceTrackedListView(
                          identifier: 'example_list',
                          itemCount: _filteredItems.length,
                          itemExtent: 60.0, // Fixed height for better performance
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: PerformanceTrackedImage(
                                  identifier: 'avatar_$index',
                                  imageUrl: 'https://via.placeholder.com/50',
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                              title: Text(item),
                              subtitle: Text('Subtitle for $item'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Handle item tap
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of using SafeFutureBuilder
class SafeFutureBuilderExample extends StatelessWidget {
  const SafeFutureBuilderExample({super.key});

  Future<List<String>> _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Item 1', 'Item 2', 'Item 3'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Future Builder Example'),
      ),
      body: SafeFutureBuilder<List<String>>(
        future: _loadData(),
        cacheKey: 'example_data',
        cacheTTL: const Duration(minutes: 5),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, retry) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        builder: (context, data) {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(data[index]),
              );
            },
          );
        },
      ),
    );
  }
}

