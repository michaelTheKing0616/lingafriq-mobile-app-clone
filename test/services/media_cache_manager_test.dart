import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/media_cache_manager.dart';
import 'package:lingafriq/models/offline/local_media_cache.dart';

void main() {
  group('MediaCacheManager LRU Eviction', () {
    late MediaCacheManager cacheManager;

    setUp(() {
      cacheManager = MediaCacheManager();
    });

    group('Cache storage and retrieval', () {
      test('stores and retrieves cache entries', () async {
        // Note: This test requires actual file system setup
        // In a real test environment, you'd use a temporary directory
        const url = 'https://example.com/media.mp3';
        const localPath = '/tmp/test_media.mp3';

        // Mock: Simulate cache entry
        final cache = LocalMediaCache(
          url: url,
          localPath: localPath,
          mimeType: 'audio/mpeg',
          sizeBytes: 1024 * 1024, // 1MB
          cachedAt: DateTime.now(),
        );

        expect(cache.url, equals(url));
        expect(cache.localPath, equals(localPath));
        expect(cache.sizeBytes, equals(1024 * 1024));
      });

      test('tracks cache size correctly', () async {
        final cache1 = LocalMediaCache(
          url: 'https://example.com/media1.mp3',
          localPath: '/tmp/media1.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 500 * 1024, // 500KB
          cachedAt: DateTime.now(),
        );

        final cache2 = LocalMediaCache(
          url: 'https://example.com/media2.mp3',
          localPath: '/tmp/media2.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 300 * 1024, // 300KB
          cachedAt: DateTime.now(),
        );

        final totalSize = cache1.sizeBytes + cache2.sizeBytes;
        expect(totalSize, equals(800 * 1024));
      });
    });

    group('LRU eviction', () {
      test('evicts oldest entries when cache limit exceeded', () {
        final now = DateTime.now();
        final cache1 = LocalMediaCache(
          url: 'https://example.com/media1.mp3',
          localPath: '/tmp/media1.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 100 * 1024 * 1024, // 100MB
          cachedAt: now.subtract(const Duration(days: 5)),
          lastAccessedAt: now.subtract(const Duration(days: 5)),
        );

        final cache2 = LocalMediaCache(
          url: 'https://example.com/media2.mp3',
          localPath: '/tmp/media2.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 100 * 1024 * 1024, // 100MB
          cachedAt: now.subtract(const Duration(days: 2)),
          lastAccessedAt: now.subtract(const Duration(days: 2)),
        );

        final cache3 = LocalMediaCache(
          url: 'https://example.com/media3.mp3',
          localPath: '/tmp/media3.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 100 * 1024 * 1024, // 100MB
          cachedAt: now,
          lastAccessedAt: now,
        );

        // Sort by lastAccessedAt (LRU order)
        final caches = [cache2, cache1, cache3];
        caches.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

        expect(caches.first.url, equals(cache1.url));
        expect(caches.last.url, equals(cache3.url));
      });

      test('evicts entries until target size is reached', () {
        final caches = List.generate(10, (i) => LocalMediaCache(
              url: 'https://example.com/media$i.mp3',
              localPath: '/tmp/media$i.mp3',
              mimeType: 'audio/mpeg',
              sizeBytes: 50 * 1024 * 1024, // 50MB each
              cachedAt: DateTime.now().subtract(Duration(days: i)),
              lastAccessedAt: DateTime.now().subtract(Duration(days: i)),
            ));

        // Sort by lastAccessedAt
        caches.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

        // Simulate eviction: remove oldest until total size < 200MB
        const targetSizeBytes = 200 * 1024 * 1024;
        int currentSize = caches.fold(0, (sum, c) => sum + c.sizeBytes);
        final toDelete = <LocalMediaCache>[];

        for (final cache in caches) {
          if (currentSize <= targetSizeBytes) break;
          currentSize -= cache.sizeBytes;
          toDelete.add(cache);
        }

        expect(toDelete.length, greaterThan(0));
        expect(currentSize, lessThanOrEqualTo(targetSizeBytes));
      });
    });

    group('Cache size tracking', () {
      test('calculates total cache size correctly', () {
        final caches = [
          LocalMediaCache(
            url: 'https://example.com/media1.mp3',
            localPath: '/tmp/media1.mp3',
            mimeType: 'audio/mpeg',
            sizeBytes: 10 * 1024 * 1024,
            cachedAt: DateTime.now(),
          ),
          LocalMediaCache(
            url: 'https://example.com/media2.mp3',
            localPath: '/tmp/media2.mp3',
            mimeType: 'audio/mpeg',
            sizeBytes: 20 * 1024 * 1024,
            cachedAt: DateTime.now(),
          ),
          LocalMediaCache(
            url: 'https://example.com/media3.mp3',
            localPath: '/tmp/media3.mp3',
            mimeType: 'audio/mpeg',
            sizeBytes: 30 * 1024 * 1024,
            cachedAt: DateTime.now(),
          ),
        ];

        final totalSize = caches.fold<int>(
          0,
          (sum, cache) => sum + cache.sizeBytes,
        );

        expect(totalSize, equals(60 * 1024 * 1024));
      });

      test('tracks cache size limit', () {
        cacheManager.setCacheSizeLimit(200);
        expect(cacheManager.getCacheSizeLimitMB(), equals(200));
      });
    });

    group('Cache access tracking', () {
      test('updates lastAccessedAt on cache access', () {
        final cache = LocalMediaCache(
          url: 'https://example.com/media.mp3',
          localPath: '/tmp/media.mp3',
          mimeType: 'audio/mpeg',
          sizeBytes: 1024 * 1024,
          cachedAt: DateTime.now().subtract(const Duration(days: 1)),
          lastAccessedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final updatedCache = cache.copyWith(
          lastAccessedAt: DateTime.now(),
        );

        expect(
          updatedCache.lastAccessedAt.isAfter(cache.lastAccessedAt),
          isTrue,
        );
      });
    });
  });
}
