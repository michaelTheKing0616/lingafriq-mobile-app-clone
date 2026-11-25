import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// P10-933: on-device daily rollups for count/sum/duration metrics (privacy).
///
/// AC2 — events that must stay raw (per-event fields required downstream):
/// AC2: why these stay raw (see [LearningAnalyticsAggregator.shouldPassthroughRaw]).
const Map<String, String> rawAnalyticsEventReasons = {
  'content_report':
      'Content flags carry item_key and reason_code for review routing; daily sums would lose per-item signal.',
};

/// Metrics-only daily bucket (no text, audio, or account ids).
class DailyLearningRollup {
  DailyLearningRollup({required this.utcDayKey});

  final String utcDayKey;

  int sessionStartedCount = 0;
  int exerciseCount = 0;
  int exerciseCorrectCount = 0;
  int exerciseLatencyMsSum = 0;
  int exerciseHintsSum = 0;
  int speechCount = 0;
  int speechUnsureCount = 0;
  int speechPhonesOkCount = 0;
  int speechToneOkCount = 0;
  int aiTurnCount = 0;
  int aiTokensSum = 0;
  int aiLatencyMsSum = 0;
  int aiFallbackCount = 0;

  bool get isEmpty =>
      sessionStartedCount == 0 &&
      exerciseCount == 0 &&
      speechCount == 0 &&
      aiTurnCount == 0;

  void ingestEnvelope(Map<String, Object?> envelope) {
    final name = envelope['event_name'] as String?;
    final metrics = envelope['metrics'];
    if (metrics is! Map) return;
    final m = metrics.map((k, v) => MapEntry(k.toString(), v));

    switch (name) {
      case 'session_started':
        sessionStartedCount++;
      case 'exercise_answered':
        exerciseCount++;
        if (m['correct'] == true) exerciseCorrectCount++;
        exerciseLatencyMsSum += (m['latency_ms'] as int?) ?? 0;
        exerciseHintsSum += (m['hints'] as int?) ?? 0;
      case 'speech_attempt_scored':
        speechCount++;
        if (m['unsure'] == true) {
          speechUnsureCount++;
        } else {
          if (m['phones_ok'] == true) speechPhonesOkCount++;
          if (m['tone_ok'] == true) speechToneOkCount++;
        }
      case 'ai_turn':
        aiTurnCount++;
        aiTokensSum += (m['tokens'] as int?) ?? 0;
        aiLatencyMsSum += (m['latency_ms'] as int?) ?? 0;
        if (m['fallback_used'] == true) aiFallbackCount++;
    }
  }

  Map<String, Object?> toRollupMetrics() {
    return {
      'daily_rollup': true,
      'session_started_count': sessionStartedCount,
      'exercise_count': exerciseCount,
      'exercise_correct_count': exerciseCorrectCount,
      'exercise_latency_ms_sum': exerciseLatencyMsSum,
      'exercise_hints_sum': exerciseHintsSum,
      'speech_count': speechCount,
      'speech_unsure_count': speechUnsureCount,
      'speech_phones_ok_count': speechPhonesOkCount,
      'speech_tone_ok_count': speechToneOkCount,
      'ai_turn_count': aiTurnCount,
      'ai_tokens_sum': aiTokensSum,
      'ai_latency_ms_sum': aiLatencyMsSum,
      'ai_fallback_count': aiFallbackCount,
    };
  }

  Map<String, Object?> toJson() => {
        'utc_day_key': utcDayKey,
        'session_started_count': sessionStartedCount,
        'exercise_count': exerciseCount,
        'exercise_correct_count': exerciseCorrectCount,
        'exercise_latency_ms_sum': exerciseLatencyMsSum,
        'exercise_hints_sum': exerciseHintsSum,
        'speech_count': speechCount,
        'speech_unsure_count': speechUnsureCount,
        'speech_phones_ok_count': speechPhonesOkCount,
        'speech_tone_ok_count': speechToneOkCount,
        'ai_turn_count': aiTurnCount,
        'ai_tokens_sum': aiTokensSum,
        'ai_latency_ms_sum': aiLatencyMsSum,
        'ai_fallback_count': aiFallbackCount,
      };

  static DailyLearningRollup fromJson(Map<String, Object?> json) {
    final rollup = DailyLearningRollup(utcDayKey: json['utc_day_key'] as String);
    rollup.sessionStartedCount = (json['session_started_count'] as int?) ?? 0;
    rollup.exerciseCount = (json['exercise_count'] as int?) ?? 0;
    rollup.exerciseCorrectCount = (json['exercise_correct_count'] as int?) ?? 0;
    rollup.exerciseLatencyMsSum = (json['exercise_latency_ms_sum'] as int?) ?? 0;
    rollup.exerciseHintsSum = (json['exercise_hints_sum'] as int?) ?? 0;
    rollup.speechCount = (json['speech_count'] as int?) ?? 0;
    rollup.speechUnsureCount = (json['speech_unsure_count'] as int?) ?? 0;
    rollup.speechPhonesOkCount = (json['speech_phones_ok_count'] as int?) ?? 0;
    rollup.speechToneOkCount = (json['speech_tone_ok_count'] as int?) ?? 0;
    rollup.aiTurnCount = (json['ai_turn_count'] as int?) ?? 0;
    rollup.aiTokensSum = (json['ai_tokens_sum'] as int?) ?? 0;
    rollup.aiLatencyMsSum = (json['ai_latency_ms_sum'] as int?) ?? 0;
    rollup.aiFallbackCount = (json['ai_fallback_count'] as int?) ?? 0;
    return rollup;
  }
}

String utcDayKeyFrom(DateTime utc) {
  final d = utc.toUtc();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String rollupOccurredAtForDay(String utcDayKey) {
  return '${utcDayKey}T23:59:59';
}

typedef AggregatorPrefsLoader = Future<SharedPreferences> Function();

const String _prefsKey = 'learning_analytics_rollup_v1';

/// Buffers aggregatable v1 events per UTC day; emits one [offline_operation] rollup per closed day.
class LearningAnalyticsAggregator {
  LearningAnalyticsAggregator({
    AggregatorPrefsLoader? loadPrefs,
    DateTime Function()? now,
  })  : _loadPrefs = loadPrefs ?? SharedPreferences.getInstance,
        _now = now ?? DateTime.now;

  final AggregatorPrefsLoader _loadPrefs;
  final DateTime Function() _now;

  DailyLearningRollup? _openDay;

  bool shouldPassthroughRaw(Map<String, Object?> envelope) {
    final name = envelope['event_name'] as String?;
    if (name == 'offline_operation') {
      final metrics = envelope['metrics'];
      if (metrics is Map && metrics['content_report'] == true) {
        return true;
      }
    }
    return false;
  }

  bool shouldBuffer(Map<String, Object?> envelope) {
    if (shouldPassthroughRaw(envelope)) return false;
    const buffered = {
      'session_started',
      'exercise_answered',
      'speech_attempt_scored',
      'ai_turn',
    };
    return buffered.contains(envelope['event_name']);
  }

  /// Record an envelope. Returns a completed [DailyLearningRollup] when the UTC day rolled over.
  Future<DailyLearningRollup?> record(Map<String, Object?> envelope) async {
    if (!shouldBuffer(envelope)) return null;
    final dayKey = utcDayKeyFrom(_now());
    await _load();
    DailyLearningRollup? completed;
    if (_openDay != null && _openDay!.utcDayKey != dayKey) {
      if (!_openDay!.isEmpty) completed = _openDay;
      _openDay = null;
    }
    _openDay ??= DailyLearningRollup(utcDayKey: dayKey);
    _openDay!.ingestEnvelope(envelope);
    await _persist();
    return completed;
  }

  /// Force-close the current UTC day (end-of-day flush).
  Future<DailyLearningRollup?> closeCurrentDay() async {
    await _load();
    if (_openDay == null || _openDay!.isEmpty) return null;
    final completed = _openDay;
    _openDay = null;
    await _persist();
    return completed;
  }

  Map<String, Object?> rollupEnvelope({
    required DailyLearningRollup rollup,
    required String pseudonymousUserId,
    required Map<String, Object?> context,
  }) {
    return {
      'schema_version': '1',
      'event_name': 'offline_operation',
      'occurred_at': rollupOccurredAtForDay(rollup.utcDayKey),
      'pseudonymous_user_id': pseudonymousUserId,
      'context': context,
      'metrics': rollup.toRollupMetrics(),
    };
  }

  Future<void> _load() async {
    if (_openDay != null) return;
    final prefs = await _loadPrefs();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final day = decoded['open_day'];
    if (day is Map) {
      _openDay = DailyLearningRollup.fromJson(day.map((k, v) => MapEntry(k.toString(), v)));
    }
  }

  Future<void> _persist() async {
    final prefs = await _loadPrefs();
    if (_openDay == null) {
      await prefs.remove(_prefsKey);
      return;
    }
    await prefs.setString(_prefsKey, jsonEncode({'open_day': _openDay!.toJson()}));
  }

  Future<DailyLearningRollup?> loadedOpenDay() async {
    await _load();
    return _openDay;
  }
}
