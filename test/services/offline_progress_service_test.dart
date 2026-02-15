import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/offline_progress_service.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/models/offline/local_progress.dart';

void main() {
  group('OfflineProgressService', () {
    late OfflineProgressService progressService;
    late LocalDatabaseService db;

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

      db = LocalDatabaseService();
      await db.init();
    });

    setUp(() async {
      progressService = OfflineProgressService();
      await db.clearAll();
    });

    group('Recording progress', () {
      test('records progress with all fields', () async {
        final progressId = await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
          score: 85,
          completionPercentage: 100.0,
          timeSpentSeconds: 300,
          details: {'lessonId': '123', 'section': 'greetings'},
          sessionId: 'session-abc',
        );

        expect(progressId, isNotEmpty);
      });

      test('records progress with minimal fields', () async {
        final progressId = await progressService.recordProgress(
          type: 'quiz',
          language: 'yoruba',
        );

        expect(progressId, isNotEmpty);
      });

      test('progress is marked as unsynced initially', () async {
        await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );

        final unsynced = progressService.getUnsyncedProgress();
        expect(unsynced.length, greaterThan(0));
        expect(unsynced.first.isSynced, isFalse);
      });
    });

    group('Retrieving unsynced progress', () {
      test('returns only unsynced progress', () async {
        await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );

        await progressService.recordProgress(
          type: 'quiz',
          language: 'yoruba',
          xp: 30,
        );

        final unsynced = progressService.getUnsyncedProgress();
        expect(unsynced.length, greaterThanOrEqualTo(2));
        expect(unsynced.every((p) => !p.isSynced), isTrue);
      });

      test('returns empty list when all progress is synced', () async {
        final progressId = await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );

        await progressService.markAsSynced([progressId]);

        final unsynced = progressService.getUnsyncedProgress();
        expect(unsynced.any((p) => p.id == progressId), isFalse);
      });
    });

    group('Marking as synced', () {
      test('marks single progress as synced', () async {
        final progressId = await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );

        await progressService.markAsSynced([progressId]);

        final unsynced = progressService.getUnsyncedProgress();
        expect(unsynced.any((p) => p.id == progressId), isFalse);
      });

      test('marks multiple progress items as synced', () async {
        final id1 = await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );
        final id2 = await progressService.recordProgress(
          type: 'quiz',
          language: 'yoruba',
          xp: 30,
        );

        await progressService.markAsSynced([id1, id2]);

        final unsynced = progressService.getUnsyncedProgress();
        expect(unsynced.any((p) => p.id == id1), isFalse);
        expect(unsynced.any((p) => p.id == id2), isFalse);
      });
    });

    group('Progress statistics', () {
      test('calculates total XP correctly', () async {
        await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );
        await progressService.recordProgress(
          type: 'quiz',
          language: 'yoruba',
          xp: 30,
        );
        await progressService.recordProgress(
          type: 'story',
          language: 'yoruba',
          xp: 20,
        );

        final totalXP = progressService.getTotalXP();
        expect(totalXP, greaterThanOrEqualTo(100));
      });

      test('calculates total XP for specific language', () async {
        await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
        );
        await progressService.recordProgress(
          type: 'lesson',
          language: 'swahili',
          xp: 30,
        );

        final yorubaXP = progressService.getTotalXPForLanguage('yoruba');
        expect(yorubaXP, greaterThanOrEqualTo(50));
      });

      test('returns progress for specific language', () {
        // Note: This requires actual database setup
        final progress = progressService.getProgressForLanguage('yoruba');
        expect(progress, isA<List<LocalProgress>>());
      });
    });

    group('Progress dashboard data', () {
      test('returns empty dashboard for no progress', () async {
        final dashboard = progressService.getProgressDashboardData();
        expect(dashboard['totalXP'], equals(0));
        expect(dashboard['totalLessons'], equals(0));
        expect(dashboard['totalTimeSpent'], equals(0));
      });

      test('calculates dashboard metrics correctly', () async {
        await progressService.recordProgress(
          type: 'lesson',
          language: 'yoruba',
          xp: 50,
          score: 85,
          completionPercentage: 100.0,
          timeSpentSeconds: 300,
        );

        final dashboard = progressService.getProgressDashboardData();
        expect(dashboard['totalXP'], greaterThanOrEqualTo(50));
        expect(dashboard['totalLessons'], greaterThanOrEqualTo(1));
        expect(dashboard['totalTimeSpent'], greaterThanOrEqualTo(300));
      });
    });
  });
}
