import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/services/offline/offline_progress_service.dart';
import 'package:lingafriq/services/offline/vocabulary_store.dart';
import 'package:lingafriq/services/offline/media_cache_manager.dart';
import 'package:lingafriq/models/offline/local_vocabulary.dart';

void main() {
  group('Offline Flow Integration Test', () {
    late OfflineProgressService progressService;
    late VocabularyStore vocabularyStore;
    late MediaCacheManager cacheManager;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock path_provider for unit tests
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      });

      await LocalDatabaseService().init();
    });

    setUp(() async {
      progressService = OfflineProgressService();
      vocabularyStore = VocabularyStore();
      cacheManager = MediaCacheManager();
      await LocalDatabaseService().clearAll();
    });

    tearDownAll(() async {
      await LocalDatabaseService().close();
    });

    test('download -> offline access -> sync flow', () async {
      // Step 1: Download content (simulate offline mode preparation)
      final vocab = LocalVocabulary(
        id: 'test-vocab-1',
        word: 'hello',
        translation: 'bonjour',
        language: 'french',
      );

      await vocabularyStore.addWord(vocab);
      expect(vocabularyStore.getVocabulary('test-vocab-1'), isNotNull);

      // Step 2: Record progress offline
      final progressId = await progressService.recordProgress(
        type: 'lesson',
        language: 'french',
        xp: 50,
        score: 85,
        completionPercentage: 100.0,
        timeSpentSeconds: 300,
      );

      expect(progressId, isNotEmpty);

      // Step 3: Verify offline access works
      final unsyncedProgress = progressService.getUnsyncedProgress();
      expect(unsyncedProgress.length, greaterThan(0));

      final wordsDue = vocabularyStore.getWordsDueForReview('french');
      expect(wordsDue, isA<List<LocalVocabulary>>());

      // Step 4: Simulate sync (mark as synced)
      await progressService.markAsSynced([progressId]);

      final syncedProgress = progressService.getUnsyncedProgress();
      final syncedIds = syncedProgress.map((p) => p.id).toList();
      expect(syncedIds.contains(progressId), isFalse);
    });

    test('vocabulary review updates SRS metadata', () async {
      // Add vocabulary
      final vocab = LocalVocabulary(
        id: 'test-vocab-2',
        word: 'world',
        translation: 'monde',
        language: 'french',
        easeFactor: 2.5,
        interval: 0,
        repetitions: 0,
      );

      await vocabularyStore.addWord(vocab);

      // Review with quality 3 (pass)
      await vocabularyStore.reviewWord('test-vocab-2', 3);

      final updated = vocabularyStore.getVocabulary('test-vocab-2');
      expect(updated, isNotNull);
      expect(updated!.repetitions, equals(1));
      expect(updated.interval, equals(1));
      expect(updated.nextReviewDate, isNotNull);

      // Review again with quality 4 (good)
      await vocabularyStore.reviewWord('test-vocab-2', 4);

      final updated2 = vocabularyStore.getVocabulary('test-vocab-2');
      expect(updated2, isNotNull);
      expect(updated2!.repetitions, equals(2));
      expect(updated2.interval, equals(6));
      expect(updated2.easeFactor, greaterThan(2.5));
    });

    test('progress sync preserves data integrity', () async {
      // Record multiple progress events
      final id1 = await progressService.recordProgress(
        type: 'lesson',
        language: 'french',
        xp: 50,
      );
      final id2 = await progressService.recordProgress(
        type: 'quiz',
        language: 'french',
        xp: 30,
      );
      final id3 = await progressService.recordProgress(
        type: 'story',
        language: 'french',
        xp: 20,
      );

      // Verify all are unsynced
      final unsynced = progressService.getUnsyncedProgress();
      expect(unsynced.length, greaterThanOrEqualTo(3));

      // Sync first two
      await progressService.markAsSynced([id1, id2]);

      // Verify only third is unsynced
      final remainingUnsynced = progressService.getUnsyncedProgress();
      final remainingIds = remainingUnsynced.map((p) => p.id).toList();
      expect(remainingIds.contains(id1), isFalse);
      expect(remainingIds.contains(id2), isFalse);
      expect(remainingIds.contains(id3), isTrue);

      // Verify total XP is correct
      final totalXP = progressService.getTotalXP();
      expect(totalXP, greaterThanOrEqualTo(100));
    });

    test('cache management works with offline content', () async {
      // Set cache limit
      cacheManager.setCacheSizeLimit(100); // 100MB

      expect(cacheManager.getCacheSizeLimitMB(), equals(100));

      // Note: Actual cache operations require file system
      // In a real integration test, you'd:
      // 1. Cache media files
      // 2. Verify cache size tracking
      // 3. Trigger LRU eviction
      // 4. Verify oldest entries are removed
    });
  });
}
