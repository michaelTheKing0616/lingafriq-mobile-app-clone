import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../../models/offline/local_media_cache.dart';
import '../../utils/api_service.dart';
import '../../utils/structured_logger.dart';
import 'local_database_service.dart';

/// Media Cache Manager
/// Implements LRU eviction and prefetching for media files
class MediaCacheManager {
  static final MediaCacheManager _instance = MediaCacheManager._internal();
  factory MediaCacheManager() => _instance;
  MediaCacheManager._internal();

  final LocalDatabaseService _db = LocalDatabaseService();
  final Dio _dio = Dio();
  
  static const int _defaultCacheSizeLimitMB = 200;
  int _cacheSizeLimitBytes = _defaultCacheSizeLimitMB * 1024 * 1024;
  
  Directory? _cacheDirectory;

  /// Initialize the cache manager
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/media_cache');
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  /// Set cache size limit in MB
  void setCacheSizeLimit(int limitMB) {
    _cacheSizeLimitBytes = limitMB * 1024 * 1024;
  }

  /// Get cache size limit in MB
  int getCacheSizeLimitMB() => _cacheSizeLimitBytes ~/ (1024 * 1024);

  /// Cache media file
  /// Downloads and stores media file, updates metadata
  Future<String> cacheMedia({
    required String url,
    String? localPath,
    Map<String, dynamic>? metadata,
    String? language,
    String? lessonId,
  }) async {
    await init();
    
    final existingCache = _db.getMediaCache(url);
    if (existingCache != null) {
      await _db.updateMediaCacheAccess(url);
      return existingCache.localPath;
    }

    final fileName = _getFileNameFromUrl(url);
    final finalLocalPath = localPath ?? '${_cacheDirectory!.path}/$fileName';
    final file = File(finalLocalPath);
    
    if (await file.exists()) {
      final size = await file.length();
      final cache = LocalMediaCache(
        url: url,
        localPath: finalLocalPath,
        mimeType: metadata?['mimeType'] as String? ?? 'application/octet-stream',
        sizeBytes: size,
        cachedAt: DateTime.now(),
        language: language,
        lessonId: lessonId,
      );
      await _db.saveMediaCache(cache);
      return finalLocalPath;
    }

    await file.parent.create(recursive: true);

    try {
      await _dio.download(url, finalLocalPath);
      
      final size = await file.length();
      
      final cache = LocalMediaCache(
        url: url,
        localPath: finalLocalPath,
        mimeType: metadata?['mimeType'] as String? ?? _getMimeTypeFromUrl(url),
        sizeBytes: size,
        cachedAt: DateTime.now(),
        language: language,
        lessonId: lessonId,
      );

      await _db.saveMediaCache(cache);
      
      final currentSize = await getCacheSizeBytes();
      if (currentSize > _cacheSizeLimitBytes) {
        await evictLRU(_cacheSizeLimitBytes);
      }
      
      return finalLocalPath;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      logger.error('Failed to cache media: $url', error: e);
      rethrow;
    }
  }

  /// Get cached path for a URL
  /// Returns null if not cached
  String? getCachedPath(String url) {
    final cache = _db.getMediaCache(url);
    if (cache != null) {
      final file = File(cache.localPath);
      if (file.existsSync()) {
        _db.updateMediaCacheAccess(url);
        return cache.localPath;
      } else {
        _db.deleteMediaCache(url);
      }
    }
    return null;
  }

  /// Evict least recently used entries until cache size is below target
  Future<void> evictLRU(int targetSizeBytes) async {
    final allCache = _db.getAllMediaCache();
    
    if (allCache.isEmpty) return;

    allCache.sort((a, b) {
      final aAccess = a.lastAccessedAt;
      final bAccess = b.lastAccessedAt;
      return aAccess.compareTo(bAccess);
    });

    int currentSize = await getCacheSizeBytes();
    final toDelete = <LocalMediaCache>[];

    for (final cache in allCache) {
      if (currentSize <= targetSizeBytes) {
        break;
      }

      final file = File(cache.localPath);
      if (await file.exists()) {
        currentSize -= cache.sizeBytes;
        toDelete.add(cache);
      } else {
        await _db.deleteMediaCache(cache.url);
      }
    }

    for (final cache in toDelete) {
      try {
        final file = File(cache.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await _db.deleteMediaCache(cache.url);
        logger.debug('Evicted cache entry: ${cache.url}');
      } catch (e) {
        logger.error('Failed to evict cache entry: ${cache.url}', error: e);
      }
    }
  }

  /// Prefetch media for a lesson
  Future<void> prefetchForLesson(String lessonId) async {
    await init();
    
    try {
      await ApiService.initialize();
      final response = await ApiService.get(ApiContract.content.lesson(lessonId));
      if (response.statusCode != 200) {
        return;
      }

      final lessonData = response.data as Map<String, dynamic>;
      final audioUrls = (lessonData['audio_urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final imageUrls = (lessonData['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final language = lessonData['language'] as String? ?? 'unknown';

      final urlsToPrefetch = <String>[];
      urlsToPrefetch.addAll(audioUrls);
      urlsToPrefetch.addAll(imageUrls);

      for (final url in urlsToPrefetch) {
        if (url.isEmpty) continue;
        
        try {
          await cacheMedia(
            url: url,
            language: language,
            lessonId: lessonId,
          );
        } catch (e) {
          logger.debug('Failed to prefetch media: $url', error: e);
        }
      }
    } catch (e) {
      logger.error('Failed to prefetch media for lesson: $lessonId', error: e);
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSizeBytes() async {
    await init();
    
    int totalSize = 0;
    
    final allCache = _db.getAllMediaCache();
    for (final cache in allCache) {
      final file = File(cache.localPath);
      if (await file.exists()) {
        totalSize += await file.length();
      } else {
        await _db.deleteMediaCache(cache.url);
      }
    }
    
    return totalSize;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await init();
    
    final allCache = _db.getAllMediaCache();
    
    for (final cache in allCache) {
      try {
        final file = File(cache.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        logger.error('Failed to delete cache file: ${cache.localPath}', error: e);
      }
    }
    
    await _db.deleteMediaCacheBatch(
      allCache.map((c) => c.url).toList(),
    );
  }

  /// Get oldest cache entries
  List<LocalMediaCache> getOldestEntries(int count) {
    final allCache = _db.getAllMediaCache();
    
    allCache.sort((a, b) {
      return a.lastAccessedAt.compareTo(b.lastAccessedAt);
    });
    
    return allCache.take(count).toList();
  }

  /// Get cache entries by language
  List<LocalMediaCache> getCacheByLanguage(String language) {
    return _db.getMediaCacheByLanguage(language);
  }

  /// Get cache entries by lesson
  List<LocalMediaCache> getCacheByLesson(String lessonId) {
    return _db.getMediaCacheByLesson(lessonId);
  }

  /// Get expired cache entries
  List<LocalMediaCache> getExpiredCache() {
    return _db.getExpiredMediaCache();
  }

  /// Clean up expired cache entries
  Future<void> cleanupExpiredCache() async {
    final expired = getExpiredCache();
    
    for (final cache in expired) {
      try {
        final file = File(cache.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await _db.deleteMediaCache(cache.url);
      } catch (e) {
        logger.error('Failed to delete expired cache: ${cache.url}', error: e);
      }
    }
  }

  /// Extract filename from URL
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return 'media_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'media_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get MIME type from URL
  String _getMimeTypeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      
      if (path.endsWith('.mp3') || path.endsWith('.m4a') || path.endsWith('.wav')) {
        return 'audio/mpeg';
      } else if (path.endsWith('.mp4') || path.endsWith('.mov')) {
        return 'video/mp4';
      } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'image/jpeg';
      } else if (path.endsWith('.png')) {
        return 'image/png';
      } else if (path.endsWith('.gif')) {
        return 'image/gif';
      } else if (path.endsWith('.webp')) {
        return 'image/webp';
      }
      
      return 'application/octet-stream';
    } catch (e) {
      return 'application/octet-stream';
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final allCache = _db.getAllMediaCache();
    final totalSize = await getCacheSizeBytes();
    
    final byLanguage = <String, int>{};
    final byLesson = <String, int>{};
    
    for (final cache in allCache) {
      if (cache.language != null) {
        byLanguage[cache.language!] = (byLanguage[cache.language] ?? 0) + cache.sizeBytes;
      }
      if (cache.lessonId != null) {
        byLesson[cache.lessonId!] = (byLesson[cache.lessonId] ?? 0) + cache.sizeBytes;
      }
    }
    
    return {
      'totalEntries': allCache.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'limitBytes': _cacheSizeLimitBytes,
      'limitMB': (_cacheSizeLimitBytes / (1024 * 1024)).toStringAsFixed(2),
      'usagePercentage': (totalSize / _cacheSizeLimitBytes * 100).clamp(0.0, 100.0),
      'byLanguage': byLanguage,
      'byLesson': byLesson,
    };
  }
}
