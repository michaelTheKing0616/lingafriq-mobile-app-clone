import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/models/progress_metrics_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final progressTrackingProvider = NotifierProvider<ProgressTrackingProvider, BaseProviderState>(() {
  return ProgressTrackingProvider();
});

class ProgressTrackingProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  ProgressMetrics _metrics = ProgressMetrics(
    wordsLearned: 0,
    listeningHours: 0.0,
    speakingHours: 0.0,
    readingWords: 0.0,
    writtenWords: 0,
    knownWords: 0,
    timeSpentMinutes: 0.0,
    lastUpdated: DateTime.now(),
  );

  final List<ProgressMetrics> _history = []; // Daily history for charts

  ProgressMetrics get metrics => _metrics;
  List<ProgressMetrics> get history => List.unmodifiable(_history);

  @override
  BaseProviderState build() {
    _loadMetrics();
    _loadHistory();
    _syncWithBackend();
    ref.onDispose(() {
      _outboxMergeTimer?.cancel();
      if (_pendingOutboxMerge.isNotEmpty) {
        unawaited(_flushPendingOutboxMerge());
      }
    });
    return BaseProviderState();
  }

  Future<void> _syncWithBackend() async {
    try {
      final backendMetrics = await ref.read(apiProvider.notifier).getProgressMetrics();
      if (backendMetrics.isNotEmpty) {
        _metrics = ProgressMetrics.fromMap(backendMetrics);
        await _saveMetrics();
        state = state.copyWith();
      }
    } catch (e) {
      logger.error('Error syncing progress metrics with backend', tag: 'progress-tracking', error: e);
      // Silently fail - local state is primary
    }
  }

  void recordWordsLearned(int count, {String? language}) {
    _metrics = _metrics.copyWith(
      wordsLearned: _metrics.wordsLearned + count,
      knownWords: _metrics.knownWords + count,
      lastUpdated: DateTime.now(),
      wordsByLanguage: {
        ..._metrics.wordsByLanguage,
        if (language != null)
          language: (_metrics.wordsByLanguage[language] ?? 0) + count,
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    _scheduleDebouncedProgressOutbox({
      'words_learned': count,
      'known_words': count,
      if (language != null) 'words_by_language': {language: count},
    });
    state = state.copyWith();
  }

  void recordListeningTime(double minutes) {
    _metrics = _metrics.copyWith(
      listeningHours: _metrics.listeningHours + (minutes / 60.0),
      timeSpentMinutes: _metrics.timeSpentMinutes + minutes,
      lastUpdated: DateTime.now(),
      timeByActivity: {
        ..._metrics.timeByActivity,
        'listening': (_metrics.timeByActivity['listening'] ?? 0.0) + (minutes / 60.0),
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    final lh = minutes / 60.0;
    _scheduleDebouncedProgressOutbox({
      'listening_hours': lh,
      'time_spent_minutes': minutes,
      'time_by_activity': {'listening': lh},
    });
    state = state.copyWith();
  }

  void recordSpeakingTime(double minutes) {
    _metrics = _metrics.copyWith(
      speakingHours: _metrics.speakingHours + (minutes / 60.0),
      timeSpentMinutes: _metrics.timeSpentMinutes + minutes,
      lastUpdated: DateTime.now(),
      timeByActivity: {
        ..._metrics.timeByActivity,
        'speaking': (_metrics.timeByActivity['speaking'] ?? 0.0) + (minutes / 60.0),
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    final sh = minutes / 60.0;
    _scheduleDebouncedProgressOutbox({
      'speaking_hours': sh,
      'time_spent_minutes': minutes,
      'time_by_activity': {'speaking': sh},
    });
    state = state.copyWith();
  }

  void recordReadingWords(int count) {
    _metrics = _metrics.copyWith(
      readingWords: _metrics.readingWords + count,
      timeSpentMinutes: _metrics.timeSpentMinutes + (count / 200.0), // Estimate: 200 words/min
      lastUpdated: DateTime.now(),
      timeByActivity: {
        ..._metrics.timeByActivity,
        'reading': (_metrics.timeByActivity['reading'] ?? 0.0) + (count / 200.0 / 60.0),
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    final readAct = count / 200.0 / 60.0;
    _scheduleDebouncedProgressOutbox({
      'reading_words': count,
      'time_spent_minutes': count / 200.0,
      'time_by_activity': {'reading': readAct},
    });
    state = state.copyWith();
  }

  void recordWrittenWords(int count) {
    _metrics = _metrics.copyWith(
      writtenWords: _metrics.writtenWords + count,
      timeSpentMinutes: _metrics.timeSpentMinutes + (count / 50.0), // Estimate: 50 words/min
      lastUpdated: DateTime.now(),
      timeByActivity: {
        ..._metrics.timeByActivity,
        'writing': (_metrics.timeByActivity['writing'] ?? 0.0) + (count / 50.0 / 60.0),
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    final wAct = count / 50.0 / 60.0;
    _scheduleDebouncedProgressOutbox({
      'written_words': count,
      'time_spent_minutes': count / 50.0,
      'time_by_activity': {'writing': wAct},
    });
    state = state.copyWith();
  }

  void recordActivityTime(String activity, double minutes) {
    _metrics = _metrics.copyWith(
      timeSpentMinutes: _metrics.timeSpentMinutes + minutes,
      lastUpdated: DateTime.now(),
      timeByActivity: {
        ..._metrics.timeByActivity,
        activity: (_metrics.timeByActivity[activity] ?? 0.0) + (minutes / 60.0),
      },
    );
    _saveMetrics();
    _updateDailyHistory();
    final actHours = minutes / 60.0;
    _scheduleDebouncedProgressOutbox({
      'time_spent_minutes': minutes,
      'time_by_activity': {activity: actHours},
    });
    state = state.copyWith();
  }

  /// Pending incremental payload for `POST /api/v2/sync/outbox/push` (`progress_metrics_merge`).
  final Map<String, dynamic> _pendingOutboxMerge = {};
  Timer? _outboxMergeTimer;

  static const Duration _outboxMergeDebounce = Duration(seconds: 5);

  void _scheduleDebouncedProgressOutbox(Map<String, dynamic> delta) {
    _mergeIntoPendingOutbox(delta);
    _outboxMergeTimer?.cancel();
    _outboxMergeTimer = Timer(_outboxMergeDebounce, () {
      unawaited(_flushPendingOutboxMerge());
    });
  }

  void _mergeIntoPendingOutbox(Map<String, dynamic> delta) {
    for (final e in delta.entries) {
      final k = e.key;
      final v = e.value;
      if (k == 'words_by_language' && v is Map) {
        final cur = Map<String, dynamic>.from(
          (_pendingOutboxMerge['words_by_language'] as Map?)?.cast<String, dynamic>() ?? {},
        );
        v.forEach((lang, n) {
          if (n is num) {
            cur[lang.toString()] = (cur[lang.toString()] as num? ?? 0) + n;
          }
        });
        _pendingOutboxMerge['words_by_language'] = cur;
      } else if (k == 'time_by_activity' && v is Map) {
        final cur = Map<String, dynamic>.from(
          (_pendingOutboxMerge['time_by_activity'] as Map?)?.cast<String, dynamic>() ?? {},
        );
        v.forEach((act, n) {
          if (n is num) {
            cur[act.toString()] = (cur[act.toString()] as num? ?? 0) + n;
          }
        });
        _pendingOutboxMerge['time_by_activity'] = cur;
      } else if (v is num) {
        _pendingOutboxMerge[k] = (_pendingOutboxMerge[k] as num? ?? 0) + v;
      }
    }
  }

  Future<void> _flushPendingOutboxMerge() async {
    if (_pendingOutboxMerge.isEmpty) return;
    final user = ref.read(userProvider);
    if (user == null) {
      _pendingOutboxMerge.clear();
      return;
    }

    final payload = Map<String, dynamic>.from(_pendingOutboxMerge);
    _pendingOutboxMerge.clear();

    try {
      await PersistedOutboxService.instance.ensureOpen();
      await PersistedOutboxService.instance.enqueue(
        type: 'progress_metrics_merge',
        payload: payload,
      );
    } catch (e) {
      logger.error('Error enqueueing progress_metrics_merge', tag: 'progress-tracking', error: e);
    }
  }

  void _updateDailyHistory() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    // Remove today's entry if exists
    _history.removeWhere((m) {
      final mDate = m.lastUpdated;
      final mStr = '${mDate.year}-${mDate.month}-${mDate.day}';
      return mStr == todayStr;
    });

    // Add today's metrics
    _history.add(_metrics);
    
    // Keep only last 30 days
    if (_history.length > 30) {
      _history.removeRange(0, _history.length - 30);
    }

    _saveHistory();
  }

  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('progress_metrics', _metrics.toJson());
    } catch (e) {
      logger.error('Error saving progress metrics', tag: 'progress-tracking', error: e);
    }
  }

  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString('progress_metrics');
      if (metricsJson != null) {
        _metrics = ProgressMetrics.fromJson(metricsJson);
      }
    } catch (e) {
      logger.error('Error loading progress metrics', tag: 'progress-tracking', error: e);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _history.map((m) => m.toJson()).toList();
      await prefs.setStringList('progress_history', historyJson);
    } catch (e) {
      logger.error('Error saving progress history', tag: 'progress-tracking', error: e);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('progress_history') ?? [];
      _history.clear();
      _history.addAll(historyJson.map((json) => ProgressMetrics.fromJson(json)));
    } catch (e) {
      logger.error('Error loading progress history', tag: 'progress-tracking', error: e);
    }
  }
}

