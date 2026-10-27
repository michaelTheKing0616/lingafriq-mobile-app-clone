import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/services/voice/voice_api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:uuid/uuid.dart';

/// Offline-first queue for "Point & Say" evaluations.
///
/// Why this exists (instead of the persisted outbox):
/// - evaluations require uploading audio files (multipart),
/// - persisted outbox currently pushes JSON-only operations.
class PointAndSayQueueService {
  PointAndSayQueueService._();
  static final PointAndSayQueueService instance = PointAndSayQueueService._();

  static const _uuid = Uuid();

  Future<void> ensureOpen() async {
    await LocalDatabaseService().init();
  }

  int get pendingCount => LocalDatabaseService().pointAndSayCount;

  Future<String> enqueue({
    required String language,
    required String expectedText,
    required String audioPath,
    required bool evaluateTone,
    Map<String, dynamic>? context,
  }) async {
    await ensureOpen();
    final id = _uuid.v4();
    final rec = <String, dynamic>{
      'id': id,
      'language': language.trim().toLowerCase(),
      'expectedText': expectedText.trim(),
      'audioPath': audioPath,
      'evaluateTone': evaluateTone,
      'context': context ?? const <String, dynamic>{},
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
      'lastError': null,
    };
    await LocalDatabaseService().savePointAndSay(rec);
    return id;
  }

  List<Map<String, dynamic>> _pendingRecords() {
    if (!LocalDatabaseService().isInitialized) return [];
    return LocalDatabaseService().pointAndSayRecords();
  }

  /// Attempts to flush up to [batchSize] queued evaluations.
  /// Returns number of removed (successful) records.
  Future<int> flushPending({
    required VoiceApiService voiceApi,
    Dio? scoringDio,
    LensScoringClient? scoringClient,
    int batchSize = 10,
  }) async {
    final scorer = scoringClient ?? const LensScoringClient();
    await ensureOpen();
    final pending = _pendingRecords();
    if (pending.isEmpty) return 0;

    var removed = 0;
    for (final rec in pending.take(batchSize)) {
      final id = rec['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final audioPath = rec['audioPath']?.toString() ?? '';
      final expectedText = rec['expectedText']?.toString() ?? '';
      final language = rec['language']?.toString() ?? '';
      final evaluateTone = rec['evaluateTone'] == true;

      if (audioPath.isEmpty || expectedText.isEmpty || language.isEmpty) {
        await LocalDatabaseService().deletePointAndSay(id);
        removed++;
        continue;
      }
      if (!await File(audioPath).exists()) {
        await LocalDatabaseService().deletePointAndSay(id);
        removed++;
        continue;
      }

      try {
        if (evaluateTone) {
          if (scoringDio == null) {
            throw Exception('scorer_dio_missing');
          }
          final outcome = await scorer.scoreUtterance(
            post: (path, data) => scoringDio.post(path, data: data),
            audioPath: audioPath,
            expectedText: expectedText,
            language: language,
          );
          if (outcome.retryable && outcome.phase == ToneOverlayStatus.error) {
            throw Exception('scorer_unavailable');
          }
          if (outcome.phase == ToneOverlayStatus.error) {
            throw Exception('scorer_failed');
          }
        } else {
          final quick = await voiceApi.quickPronunciationCheck(
            audioPath: audioPath,
            expectedText: expectedText,
            language: language,
          );
          if (quick == null) {
            throw Exception('quick_check_failed');
          }
        }

        await LocalDatabaseService().deletePointAndSay(id);
        removed++;
      } catch (e, st) {
        logger.error('PointAndSay flush item failed', error: e, stackTrace: st, context: {
          'id': id,
          'attempts': rec['attempts'],
        });
        final attempts = (rec['attempts'] is num) ? (rec['attempts'] as num).toInt() : 0;
        rec['attempts'] = attempts + 1;
        rec['lastError'] = e.toString();
        await LocalDatabaseService().savePointAndSay(rec);
        // Stop early on first failure to avoid thrashing when connectivity is flaky.
        break;
      }
    }
    return removed;
  }
}

