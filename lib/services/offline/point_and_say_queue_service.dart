import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/voice/voice_api_service.dart';
import 'package:lingafriq/utils/api_service.dart';
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

  static const _boxName = 'lingafriq_point_and_say_queue_v1';
  static const _uuid = Uuid();

  Box<String>? _box;

  Future<void> ensureOpen() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  int get pendingCount {
    if (_box == null || !_box!.isOpen) return 0;
    return _box!.length;
  }

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
    await _box!.put(id, jsonEncode(rec));
    return id;
  }

  List<Map<String, dynamic>> _pendingRecords() {
    if (_box == null || !_box!.isOpen) return [];
    final out = <Map<String, dynamic>>[];
    for (final key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        out.add(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    out.sort((a, b) => (a['createdAt']?.toString() ?? '').compareTo(b['createdAt']?.toString() ?? ''));
    return out;
  }

  /// Attempts to flush up to [batchSize] queued evaluations.
  /// Returns number of removed (successful) records.
  Future<int> flushPending({
    required VoiceApiService voiceApi,
    int batchSize = 10,
  }) async {
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
        await _box!.delete(id);
        removed++;
        continue;
      }
      if (!await File(audioPath).exists()) {
        // Cannot ever upload; drop.
        await _box!.delete(id);
        removed++;
        continue;
      }

      try {
        // Quick pronunciation check
        final quick = await voiceApi.quickPronunciationCheck(
          audioPath: audioPath,
          expectedText: expectedText,
          language: language,
        );
        if (quick == null) {
          throw Exception('quick_check_failed');
        }

        // Optional tone evaluation (uses learning v2 endpoint)
        Map<String, dynamic>? tone;
        if (evaluateTone) {
          await ApiService.initialize();
          final res = await ApiService.uploadFile(
            ApiContract.learningV2.toneTrainer,
            audioPath,
            fileFieldName: 'audio',
            additionalData: {
              'expectedText': expectedText,
              'language': language,
            },
          );
          if (res.statusCode == 200 && res.data is Map) {
            tone = (res.data as Map).cast<String, dynamic>();
          }
        }

        // Success: remove record. (Results are shown live in-screen when user initiates sync.)
        await _box!.delete(id);
        removed++;
      } catch (e, st) {
        logger.error('PointAndSay flush item failed', error: e, stackTrace: st, context: {
          'id': id,
          'attempts': rec['attempts'],
        });
        final attempts = (rec['attempts'] is num) ? (rec['attempts'] as num).toInt() : 0;
        rec['attempts'] = attempts + 1;
        rec['lastError'] = e.toString();
        await _box!.put(id, jsonEncode(rec));
        // Stop early on first failure to avoid thrashing when connectivity is flaky.
        break;
      }
    }
    return removed;
  }
}

