import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Versioned learning analytics (P10-931). Payloads match `schemas/analytics/events.v1.json`.
const String learningAnalyticsApiPath = '/api/v1/analytics/offline/events';

const String _queuePrefsKey = 'learning_analytics_queue_v1';
const String _droppedPrefsKey = 'learning_analytics_dropped_v1';
const String _sessionStartedPrefsKey = 'learning_analytics_session_started_v1';

const Set<String> _forbiddenPayloadKeys = {
  'answer',
  'answer_text',
  'transcript',
  'audio',
  'reason',
  'free_text',
  'user_id',
  'account_id',
};

/// Stable reason codes for [LearningAnalyticsService.trackContentReported] (no free text).
enum ContentReportReasonCode {
  wrongMeaning(0),
  toneSpelling(1),
  audio(2),
  unnatural(3),
  offensive(4);

  const ContentReportReasonCode(this.code);
  final int code;
}

typedef AnalyticsBatchPost = Future<void> Function(List<Map<String, Object?>> events);

typedef AnalyticsPrefsLoader = Future<SharedPreferences> Function();

int stableItemKey(String itemId) {
  final digest = sha256.convert(utf8.encode('lingafriq:item:v1:$itemId')).bytes;
  return digest[0] << 24 | digest[1] << 16 | digest[2] << 8 | digest[3];
}

String pseudonymousIdFromAccountId(String accountId) {
  final digest = sha256.convert(utf8.encode('lingafriq:psn:v1:$accountId')).toString();
  return 'psn_${digest.substring(0, 32)}';
}

String newSessionId() {
  final digest = sha256.convert(utf8.encode('lingafriq:sess:v1:${DateTime.now().microsecondsSinceEpoch}')).toString();
  return 'sess_${digest.substring(0, 32)}';
}

/// Emits schema v1 learning events; queues offline and flushes in order.
class LearningAnalyticsService {
  LearningAnalyticsService({
    AnalyticsBatchPost? postBatch,
    AnalyticsPrefsLoader? loadPrefs,
    Future<bool> Function()? isOnline,
    String Function()? sessionIdFactory,
    DateTime Function()? now,
    int maxSendAttempts = 3,
  })  : _postBatch = postBatch ?? _defaultPostBatch,
        _loadPrefs = loadPrefs ?? SharedPreferences.getInstance,
        _isOnline = isOnline ?? (() async => true),
        _sessionIdFactory = sessionIdFactory ?? newSessionId,
        _now = now ?? DateTime.now,
        _maxSendAttempts = maxSendAttempts;

  final AnalyticsBatchPost _postBatch;
  final AnalyticsPrefsLoader _loadPrefs;
  final Future<bool> Function() _isOnline;
  final String Function() _sessionIdFactory;
  final DateTime Function() _now;
  final int _maxSendAttempts;

  String? _activeSessionId;
  bool _sessionStartedEmitted = false;
  String? _pseudonymousUserId;
  String? _languageCode;

  static final LearningAnalyticsService instance = LearningAnalyticsService();

  int droppedAfterRetries = 0;

  void configureLearner({
    required String accountId,
    String? languageCode,
  }) {
    _pseudonymousUserId = pseudonymousIdFromAccountId(accountId);
    _languageCode = languageCode;
  }

  void clearLearner() {
    _pseudonymousUserId = null;
    _languageCode = null;
    _activeSessionId = null;
    _sessionStartedEmitted = false;
  }

  /// AC1: one `session_started` per open session.
  Future<void> beginLearningSession({String? sessionId}) async {
    _activeSessionId = sessionId ?? _sessionIdFactory();
    if (_sessionStartedEmitted) return;
    _sessionStartedEmitted = true;
    await _enqueue(
      _envelope(
        eventName: 'session_started',
        metrics: const {},
      ),
    );
    final prefs = await _loadPrefs();
    await prefs.setString(_sessionStartedPrefsKey, _activeSessionId!);
  }

  /// Maps ELEVATION `item_answered` → schema `exercise_answered` (no answer text).
  Future<void> trackItemAnswered({
    required String itemId,
    required bool correct,
    required int latencyMs,
    required int hintsUsed,
  }) async {
    await _enqueue(
      _envelope(
        eventName: 'exercise_answered',
        metrics: {
          'item_key': stableItemKey(itemId),
          'correct': correct,
          'latency_ms': latencyMs,
          'hints': hintsUsed,
        },
      ),
    );
  }

  /// AC4: item id + reason code only (`offline_operation` + coded metrics).
  Future<void> trackContentReported({
    required String itemId,
    required ContentReportReasonCode reasonCode,
  }) async {
    await _enqueue(
      _envelope(
        eventName: 'offline_operation',
        metrics: {
          'content_report': true,
          'item_key': stableItemKey(itemId),
          'reason_code': reasonCode.code,
        },
      ),
    );
  }

  /// AC3: `cando_demonstrated` is emitted by the server after verification — not on device.
  void noteCandoDemonstratedServerSide() {}

  Future<int> pendingCount() async {
    final prefs = await _loadPrefs();
    return _readQueue(prefs).length;
  }

  Future<void> flush({bool forceWhileOffline = false}) async {
    if (!forceWhileOffline && !await _isOnline()) return;

    final prefs = await _loadPrefs();
    final queue = _readQueue(prefs);
    if (queue.isEmpty) return;

    final remaining = <Map<String, Object?>>[];
    for (final row in queue) {
      final attempts = (row['_attempts'] as int?) ?? 0;
      try {
        await _postBatch([_publicEnvelope(row)]);
        continue;
      } catch (e, st) {
        debugPrint('analytics flush failed: $e');
        if (kDebugMode) debugPrint('$st');
        final nextAttempts = attempts + 1;
        if (nextAttempts >= _maxSendAttempts) {
          droppedAfterRetries++;
          final dropped = prefs.getInt(_droppedPrefsKey) ?? 0;
          await prefs.setInt(_droppedPrefsKey, dropped + 1);
          continue;
        }
        remaining.add({...row, '_attempts': nextAttempts});
      }
    }
    await _writeQueue(prefs, remaining);
  }

  Map<String, Object?> _envelope({
    required String eventName,
    required Map<String, Object?> metrics,
  }) {
    final psn = _pseudonymousUserId;
    if (psn == null || !psn.startsWith('psn_')) {
      throw StateError('configureLearner before emitting analytics');
    }
    for (final key in metrics.keys) {
      if (_forbiddenPayloadKeys.contains(key)) {
        throw ArgumentError('forbidden analytics field: $key');
      }
      final value = metrics[key];
      if (value is String) {
        throw ArgumentError('analytics metrics must not carry free text');
      }
    }

    final occurred = _now().toUtc();
    final iso =
        '${occurred.year.toString().padLeft(4, '0')}-'
        '${occurred.month.toString().padLeft(2, '0')}-'
        '${occurred.day.toString().padLeft(2, '0')}T'
        '${occurred.hour.toString().padLeft(2, '0')}:'
        '${occurred.minute.toString().padLeft(2, '0')}:'
        '${occurred.second.toString().padLeft(2, '0')}';

    final context = <String, Object?>{
      'platform': _platformName(),
      if (_languageCode != null) 'language_code': _languageCode,
      if (_activeSessionId != null) 'session_id': _activeSessionId,
    };

    return {
      'schema_version': '1',
      'event_name': eventName,
      'occurred_at': iso,
      'pseudonymous_user_id': psn,
      'context': context,
      'metrics': metrics,
    };
  }

  Map<String, Object?> _publicEnvelope(Map<String, Object?> row) {
    final copy = Map<String, Object?>.from(row);
    copy.remove('_attempts');
    return copy;
  }

  Future<void> _enqueue(Map<String, Object?> envelope) async {
    final prefs = await _loadPrefs();
    final queue = _readQueue(prefs);
    queue.add(envelope);
    await _writeQueue(prefs, queue);
    if (await _isOnline()) {
      await flush();
    }
  }

  List<Map<String, Object?>> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queuePrefsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> _writeQueue(SharedPreferences prefs, List<Map<String, Object?>> queue) async {
    await prefs.setString(_queuePrefsKey, jsonEncode(queue));
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  static Future<void> _defaultPostBatch(List<Map<String, Object?>> events) async {
    await ApiService.initialize();
    await ApiService.post(learningAnalyticsApiPath, data: {'events': events});
  }
}
