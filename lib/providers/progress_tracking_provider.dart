import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/models/progress_metrics_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'base_provider.dart';

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
      debugPrint('Error syncing progress metrics with backend: $e');
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
    _syncToBackend(); // Sync to backend after update
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
    _syncToBackend(); // Sync to backend after update
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
    _syncToBackend(); // Sync to backend after update
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
    _syncToBackend(); // Sync to backend after update
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
    _syncToBackend(); // Sync to backend after update
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
    _syncToBackend(); // Sync to backend after update
    state = state.copyWith();
  }

  /// Sync progress metrics to backend (debounced to avoid too many calls)
  Future<void> _syncToBackend() async {
    try {
      // Debounce: only sync if last sync was more than 5 seconds ago
      final now = DateTime.now();
      if (_lastBackendSync != null && now.difference(_lastBackendSync!).inSeconds < 5) {
        return; // Skip if synced recently
      }
      _lastBackendSync = now;
      
      final success = await ref.read(apiProvider.notifier).updateProgressMetrics(_metrics.toMap());
      if (success) {
        debugPrint('Progress metrics synced to backend');
      }
    } catch (e) {
      debugPrint('Error syncing progress metrics to backend: $e');
    }
  }

  DateTime? _lastBackendSync;

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
      debugPrint('Error saving progress metrics: $e');
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
      debugPrint('Error loading progress metrics: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _history.map((m) => m.toJson()).toList();
      await prefs.setStringList('progress_history', historyJson);
    } catch (e) {
      debugPrint('Error saving progress history: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('progress_history') ?? [];
      _history.clear();
      _history.addAll(historyJson.map((json) => ProgressMetrics.fromJson(json)));
    } catch (e) {
      debugPrint('Error loading progress history: $e');
    }
  }
}

