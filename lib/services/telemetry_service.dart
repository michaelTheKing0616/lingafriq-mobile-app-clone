import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/user_provider.dart';
import 'dart:async';

/// Comprehensive Telemetry Service
/// Tracks user engagement, Polie performance, and app analytics
class TelemetryService {
  final Ref _ref;
  final Map<String, DateTime> _sessionStartTimes = {};
  final Map<String, int> _interactionCounts = {};
  final List<Map<String, dynamic>> _pendingEvents = [];
  Timer? _flushTimer;

  TelemetryService(this._ref) {
    // Flush events every 30 seconds
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flushEvents());
    // Provider lifecycle cleanup
    _ref.onDispose(() {
      _flushTimer?.cancel();
    });
  }

  void dispose() {
    _flushTimer?.cancel();
  }

  /// Track user engagement event
  Future<void> trackEngagement({
    required String eventType,
    required String feature,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _ref.read(userProvider);
      // Track telemetry even when user is not logged in (pre-onboarding flow).
      final userId = user?.global_id ?? user?.id.toString() ?? 'anonymous';

      final event = {
        'event_type': eventType,
        'feature': feature,
        // Prefer globalId when available so telemetry is stable across services.
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      };

      _pendingEvents.add(event);
      _interactionCounts[feature] = (_interactionCounts[feature] ?? 0) + 1;

      // Flush immediately for critical events
      if (eventType == 'error' || eventType == 'purchase' || eventType == 'achievement') {
        await _flushEvents();
      }
    } catch (e) {
      debugPrint('Error tracking engagement: $e');
    }
  }

  /// Track Polie / Hybrid Polie performance (powers admin telemetry dashboards).
  Future<void> trackPoliePerformance({
    required String mode,
    required String language,
    required int responseTimeMs,
    required int tokenCount,
    bool? diacriticsCorrected,
    String? modelUsed,
    double? confidence,
    bool needsNativeReview = false,
  }) async {
    try {
      await trackEngagement(
        eventType: 'polie_performance',
        feature: 'hybrid_polie',
        metadata: {
          'mode': mode,
          'language': language,
          'response_time_ms': responseTimeMs,
          'token_count': tokenCount,
          'diacritics_corrected': diacriticsCorrected ?? false,
          'model_used': modelUsed ?? 'fallback',
          'confidence': confidence,
          'needs_native_review': needsNativeReview,
        },
      );
      if (diacriticsCorrected == true) {
        await _flushEvents();
      }
    } catch (e) {
      debugPrint('Error tracking Polie performance: $e');
    }
  }

  /// After [HybridPolieOrchestrator] completes — same schema as trackPoliePerformance.
  Future<void> trackHybridPolieResponse({
    required String mode,
    required String language,
    required String modelUsed,
    required int responseTimeMs,
    required double confidence,
    required bool diacriticsCorrected,
    bool needsNativeReview = false,
  }) {
    return trackPoliePerformance(
      mode: mode,
      language: language,
      responseTimeMs: responseTimeMs,
      tokenCount: 0,
      diacriticsCorrected: diacriticsCorrected,
      modelUsed: modelUsed,
      confidence: confidence,
      needsNativeReview: needsNativeReview,
    );
  }

  /// Track game session metrics
  Future<void> trackGameSession({
    required String gameType,
    required String language,
    required int durationMs,
    required double accuracy,
    required int score,
    required int turns,
  }) async {
    try {
      await trackEngagement(
        eventType: 'game_session',
        feature: 'games',
        metadata: {
          'game_type': gameType,
          'language': language,
          'duration_ms': durationMs,
          'accuracy': accuracy,
          'score': score,
          'turns': turns,
        },
      );
    } catch (e) {
      debugPrint('Error tracking game session: $e');
    }
  }

  /// Session/cards/network prevented the game from starting ([BaseGameScreen] load path).
  Future<void> trackGameLoadFailed({
    required String gameType,
    required String language,
    required String reason,
  }) async {
    try {
      const maxLen = 500;
      final safe =
          reason.length > maxLen ? '${reason.substring(0, maxLen)}…' : reason;
      await trackEngagement(
        eventType: 'error',
        feature: 'games',
        metadata: {
          'subtype': 'game_load_failed',
          'game_type': gameType,
          'language': language,
          'reason': safe,
        },
      );
    } catch (e) {
      debugPrint('Error tracking game load failure: $e');
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await trackEngagement(
        eventType: 'feature_usage',
        feature: featureName,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error tracking feature usage: $e');
    }
  }

  /// Track user session
  void startSession(String sessionId) {
    _sessionStartTimes[sessionId] = DateTime.now();
  }

  void endSession(String sessionId) {
    final startTime = _sessionStartTimes[sessionId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      trackEngagement(
        eventType: 'session_end',
        feature: 'app',
        metadata: {
          'session_id': sessionId,
          'duration_seconds': duration.inSeconds,
        },
      );
      _sessionStartTimes.remove(sessionId);
    }
  }

  /// Get engagement statistics
  Map<String, dynamic> getEngagementStats() {
    return {
      'interaction_counts': Map<String, int>.from(_interactionCounts),
      'active_sessions': _sessionStartTimes.length,
      'pending_events': _pendingEvents.length,
    };
  }

  /// Flush pending events to backend
  Future<void> _flushEvents() async {
    if (_pendingEvents.isEmpty) return;

    final eventsToSend = List<Map<String, dynamic>>.from(_pendingEvents);
    _pendingEvents.clear();

    try {
      final api = _ref.read(apiProvider.notifier);
      await api.sendTelemetry(eventsToSend);
      
      debugPrint('✅ Flushed ${eventsToSend.length} telemetry events');
    } catch (e) {
      debugPrint('Error flushing telemetry events: $e');
      // Re-add events to pending if flush failed
      _pendingEvents.addAll(eventsToSend);
    }
  }

  /// Force flush events (call on app close)
  Future<void> flush() async {
    await _flushEvents();
    _flushTimer?.cancel();
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  final svc = TelemetryService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});

