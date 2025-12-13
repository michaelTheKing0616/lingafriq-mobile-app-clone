import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/polie_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Polie Cache Service Tests', () {
    setUp(() async {
      // Clear cache before each test
      SharedPreferences.setMockInitialValues({});
      await PolieCacheService.clearCache();
    });

    test('Cache content and retrieve', () async {
      final content = {
        'proverb': 'Test proverb',
        'meaning': 'Test meaning',
      };

      await PolieCacheService.cacheContent('proverb', 'Yoruba', content);

      final cached = await PolieCacheService.getCachedContent('proverb', 'Yoruba');
      expect(cached, isNotNull);
      expect(cached!['proverb'], 'Test proverb');
    });

    test('Cache expiration check', () async {
      final content = {'test': 'data'};
      
      await PolieCacheService.cacheContent(
        'test',
        'Yoruba',
        content,
        ttl: const Duration(seconds: 1),
      );

      // Should be cached immediately
      expect(
        await PolieCacheService.hasCachedContent('test', 'Yoruba'),
        true,
      );

      // Wait for expiration
      await Future.delayed(const Duration(seconds: 2));

      // Should be expired
      expect(
        await PolieCacheService.hasCachedContent('test', 'Yoruba'),
        false,
      );
    });

    test('Cache key generation', () async {
      final content1 = {'data': '1'};
      final content2 = {'data': '2'};

      await PolieCacheService.cacheContent('type', 'lang1', content1);
      await PolieCacheService.cacheContent('type', 'lang2', content2);

      final cached1 = await PolieCacheService.getCachedContent('type', 'lang1');
      final cached2 = await PolieCacheService.getCachedContent('type', 'lang2');

      expect(cached1!['data'], '1');
      expect(cached2!['data'], '2');
    });

    test('Cache statistics', () async {
      await PolieCacheService.cacheContent('type1', 'lang', {'data': '1'});
      await PolieCacheService.cacheContent('type2', 'lang', {'data': '2'});

      final stats = await PolieCacheService.getCacheStats();
      expect(stats['total_entries'], 2);
      expect(stats['valid_entries'], 2);
    });
  });
}

