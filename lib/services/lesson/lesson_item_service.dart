/// Lesson Item Service
/// Manages lesson items with caching and offline support
/// 
/// Features:
/// - Fetch lesson items with caching
/// - Offline support
/// - Filtering and searching
/// - Progress tracking

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../models/lesson_item_model.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../../utils/simple_cache.dart';
import '../../core/network/api_client_with_recovery.dart';
import '../../services/offline/offline_handler.dart';
import 'dart:convert';

/// Lesson Item Service
class LessonItemService {
  final Dio _dio;
  final SimpleCache _cache = SimpleCache();
  final OfflineHandler _offlineHandler = OfflineHandler();
  static const Duration _cacheTTL = Duration(hours: 24);

  LessonItemService(this._dio);

  /// Get lesson items with filters
  Future<List<LessonItem>> getLessonItems({
    String? languageCode,
    String? level,
    List<String>? categories,
    String? category,
    String? searchQuery,
    int? limit,
    int? offset,
    bool useCache = true,
  }) async {
    final cacheKey = _buildCacheKey(
      languageCode: languageCode,
      level: level,
      category: category ?? categories?.join(','),
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );

    if (useCache) {
      final cached = _cache.get<List<LessonItem>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final client = ApiClientWithRecovery(_dio);
      final response = await client.get<Map<String, dynamic>>(
        ApiContract.url(ApiContract.lessonItems.list),
        queryParameters: {
          if (languageCode != null) 'language_code': languageCode,
          if (level != null) 'level': level,
          if (categories != null && categories.isNotEmpty) 'categories': categories.join(','),
          if (category != null) 'category': category,
          if (searchQuery != null) 'search': searchQuery,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = (response.data!['data'] as List)
            .map((json) => LessonItem.fromJson(json as Map<String, dynamic>))
            .toList();

        _cache.set(cacheKey, items, ttl: _cacheTTL);
        return items;
      } else {
        throw Exception('Failed to fetch lesson items');
      }
    } catch (e) {
      debugPrint('Error fetching lesson items: $e');
      
      if (!_offlineHandler.isOnline) {
        final cached = _cache.get<List<LessonItem>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      rethrow;
    }
  }

  /// Get single lesson item by ID
  Future<LessonItem?> getLessonItemById(String itemId, {bool useCache = true}) async {
    final cacheKey = 'lesson_item_$itemId';

    if (useCache) {
      final cached = _cache.get<LessonItem>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final client = ApiClientWithRecovery(_dio);
      final response = await client.get<Map<String, dynamic>>(
        ApiContract.url(ApiContract.lessonItems.item(itemId)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final item = LessonItem.fromJson(response.data!['data'] as Map<String, dynamic>);
        _cache.set(cacheKey, item, ttl: _cacheTTL);
        return item;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching lesson item: $e');
      
      if (!_offlineHandler.isOnline) {
        final cached = _cache.get<LessonItem>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      return null;
    }
  }

  /// Get lesson items by category
  Future<List<LessonItem>> getLessonItemsByCategory({
    required String languageCode,
    required String category,
    String? level,
    int? limit,
  }) async {
    return await getLessonItems(
      languageCode: languageCode,
      level: level,
      category: category,
      limit: limit,
    );
  }


  /// Search lesson items
  Future<List<LessonItem>> searchLessonItems({
    required String query,
    String? languageCode,
    String? level,
    int? limit = 50,
  }) async {
    return await getLessonItems(
      languageCode: languageCode,
      level: level,
      searchQuery: query,
      limit: limit,
    );
  }

  /// Get lesson item statistics
  Future<Map<String, dynamic>> getLessonItemStats({
    String? languageCode,
    String? level,
  }) async {
    try {
      final client = ApiClientWithRecovery(_dio);
      final response = await client.get<Map<String, dynamic>>(
        ApiContract.url(ApiContract.lessonItems.stats),
        queryParameters: {
          if (languageCode != null) 'language_code': languageCode,
          if (level != null) 'level': level,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['data'] as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching lesson item stats: $e');
      return {};
    }
  }

  /// Preload lesson items for offline use
  Future<void> preloadLessonItems({
    required String languageCode,
    List<String>? levels,
    List<String>? categories,
    Function(int current, int total)? onProgress,
  }) async {
    final levelsToLoad = levels ?? ['A0', 'A1', 'A2', 'B1', 'B2', 'C1'];
    int total = 0;
    int current = 0;

    for (final level in levelsToLoad) {
      final items = await getLessonItems(
        languageCode: languageCode,
        level: level,
        categories: categories,
        useCache: false,
      );
      total += items.length;
    }

    for (final level in levelsToLoad) {
      final items = await getLessonItems(
        languageCode: languageCode,
        level: level,
        categories: categories,
        useCache: false,
      );

      for (final item in items) {
        current++;
        onProgress?.call(current, total);
        await getLessonItemById(item.id, useCache: true);
      }
    }
  }

  String _buildCacheKey({
    String? languageCode,
    String? level,
    String? category,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    final parts = <String>[];
    if (languageCode != null) parts.add('lang_$languageCode');
    if (level != null) parts.add('level_$level');
    if (category != null) parts.add('cat_$category');
    if (searchQuery != null) parts.add('search_${searchQuery.hashCode}');
    if (limit != null) parts.add('limit_$limit');
    if (offset != null) parts.add('offset_$offset');
    return 'lesson_items_${parts.join("_")}';
  }

  void clearCache() {
    _cache.clear();
  }
}

