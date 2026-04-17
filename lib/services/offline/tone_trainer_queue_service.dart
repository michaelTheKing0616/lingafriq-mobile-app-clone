import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:uuid/uuid.dart';

/// Offline-first queue for Tone & Rhythm evaluations.
///
/// This exists because evaluations require uploading an audio file (multipart).
/// The sync-v2 outbox currently supports JSON-only operations.
class ToneTrainerQueueService {
  ToneTrainerQueueService._();
  static final ToneTrainerQueueService instance = ToneTrainerQueueService._();

  static const _boxName = 'lingafriq_tone_trainer_queue_v1';
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
  }) async {
    await ensureOpen();
    final id = _uuid.v4();
    final rec = <String, dynamic>{
      'id': id,
      'language': language.trim().toLowerCase(),
      'expectedText': expectedText.trim(),
      'audioPath': audioPath,
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
  Future<int> flushPending({int batchSize = 10}) async {
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

      if (audioPath.isEmpty || expectedText.isEmpty || language.isEmpty) {
        await _box!.delete(id);
        removed++;
        continue;
      }
      if (!await File(audioPath).exists()) {
        await _box!.delete(id);
        removed++;
        continue;
      }

      try {
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
        if (res.statusCode != 200) {
          throw Exception('tone_eval_http_${res.statusCode}');
        }
        await _box!.delete(id);
        removed++;
      } catch (e, st) {
        logger.error('ToneTrainer flush item failed', error: e, stackTrace: st, context: {
          'id': id,
          'attempts': rec['attempts'],
        });
        final attempts = (rec['attempts'] is num) ? (rec['attempts'] as num).toInt() : 0;
        rec['attempts'] = attempts + 1;
        rec['lastError'] = e.toString();
        await _box!.put(id, jsonEncode(rec));
        break;
      }
    }

    return removed;
  }
}

