// Conversation Analytics Service
// Tracks conversation metrics and reads scores only from a real scorer.
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../games/gamekit/game_scoring.dart';
import '../models/conversation_analytics_model.dart';
import '../providers/user_provider.dart';

import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

/// What a Speak insights load is showing.
enum SpeakInsightStatus { loading, empty, error, offline, ready }

/// How a pronunciation or tone score may be painted.
enum ScorerReadoutKind { number, unsure, practice, hidden }

/// A scorer result the screen is allowed to paint.
///
/// [hidden] means the scorer was missing. [practice] means it was not the
/// real scorer. Neither carries a number.
class ScorerReadout {
  const ScorerReadout._(this.kind, this.percent);

  const ScorerReadout.number(int percent)
    : this._(ScorerReadoutKind.number, percent);

  const ScorerReadout.unsure() : this._(ScorerReadoutKind.unsure, null);

  const ScorerReadout.practice() : this._(ScorerReadoutKind.practice, null);

  const ScorerReadout.hidden() : this._(ScorerReadoutKind.hidden, null);

  final ScorerReadoutKind kind;
  final int? percent;
}

/// Metadata value that marks a score from [GameScoreSource.realScorer].
const String realScorerSource = 'real_scorer';

/// Storage failed, or the phone is offline. The screen drops what it showed.
class SpeakDataUnavailable implements Exception {
  const SpeakDataUnavailable({this.offline = false});

  final bool offline;
}

/// Percent from a real scorer result. Missing, unsure, unavailable, local,
/// and any other source return null so a screen cannot paint a stand-in.
int? shownScorerPercent(GameScore score) {
  if (score.source != GameScoreSource.realScorer) return null;
  if (score.isUnsure || score.honestPracticeMode) return null;
  final double accuracy = score.accuracy;
  if (!accuracy.isFinite || accuracy < 0 || accuracy > 1) return null;
  return (accuracy * 100).round();
}

/// Page readout for one scorer result. A null score is missing, so no number.
ScorerReadout scorerReadout(GameScore? score) {
  if (score == null) return const ScorerReadout.hidden();
  if (score.isUnsure) return const ScorerReadout.unsure();
  if (score.honestPracticeMode ||
      score.source == GameScoreSource.honestPractice ||
      score.source == GameScoreSource.scorerUnavailable ||
      score.source != GameScoreSource.realScorer) {
    return const ScorerReadout.practice();
  }
  final int? percent = shownScorerPercent(score);
  if (percent == null) return const ScorerReadout.practice();
  return ScorerReadout.number(percent);
}

/// Pronunciation or tone score stored on a session.
///
/// [kind] is `pronunciation` or `tone`. A fluency field with no real scorer
/// source is ignored, including when the stored number is 0, 80, or 100.
GameScore? scoreFromMetadata(Map<String, dynamic> metadata, String kind) {
  final String specific = metadata['${kind}_source']?.toString().trim() ?? '';
  final String shared = metadata['score_source']?.toString().trim() ?? '';
  final String source = specific.isNotEmpty ? specific : shared;
  if (source.isEmpty) return null;
  if (source == 'unsure') {
    return GameScore.unsure(message: 'unsure');
  }
  if (source == 'unavailable' || source == 'scorer_unavailable') {
    return GameScore.scorerError(message: 'unavailable');
  }
  if (source != realScorerSource) {
    return GameScore.honestPractice(message: 'not real');
  }
  final Object? raw = metadata['${kind}_accuracy'];
  if (raw is! num) return null;
  final double accuracy = raw.toDouble();
  if (!accuracy.isFinite || accuracy < 0 || accuracy > 1) return null;
  return GameScore(
    accuracy: accuracy,
    isPerfect: accuracy >= 1,
    isFail: accuracy < 0.4,
    countsForRewards: true,
    source: GameScoreSource.realScorer,
    scorerVersion: metadata['scorer_version']?.toString(),
  );
}

final conversationAnalyticsServiceProvider =
    Provider<ConversationAnalyticsService>((ref) {
      return ConversationAnalyticsService(ref);
    });

class ConversationAnalyticsService {
  final Ref _ref;
  ConversationAnalytics? _cachedAnalytics;

  ConversationAnalyticsService(this._ref);

  /// Saved analytics for [language]. Null means nothing is stored.
  ///
  /// Throws when storage cannot be read so the screen can show an error
  /// instead of a made-up count.
  Future<ConversationAnalytics?> readStored(String language) async {
    final String name = language.trim();
    if (name.isEmpty) return null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('conversation_analytics_$name');
    if (raw == null || raw.trim().isEmpty) return null;
    final ConversationAnalytics parsed = ConversationAnalytics.fromJsonString(
      raw,
    );
    _cachedAnalytics = parsed;
    if (parsed.sessions.isEmpty) return null;
    final String storedLanguage = parsed.language.trim();
    if (storedLanguage.isNotEmpty && storedLanguage != name) return null;
    return parsed;
  }

  /// Load conversation analytics from local storage
  Future<ConversationAnalytics> loadAnalytics(String language) async {
    if (_cachedAnalytics != null && _cachedAnalytics!.language == language) {
      return _cachedAnalytics!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString('conversation_analytics_$language');

      if (analyticsJson != null && analyticsJson.isNotEmpty) {
        _cachedAnalytics = ConversationAnalytics.fromJsonString(analyticsJson);
        if (_cachedAnalytics!.language == language) {
          return _cachedAnalytics!;
        }
      }
    } catch (e) {
      debugPrint('Error loading conversation analytics: $e');
    }

    _cachedAnalytics = ConversationAnalytics(language: language);
    return _cachedAnalytics!;
  }

  /// Save conversation analytics to local storage
  Future<void> saveAnalytics(ConversationAnalytics analytics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'conversation_analytics_${analytics.language}',
        analytics.toJsonString(),
      );
      _cachedAnalytics = analytics;

      // Sync to backend
      await _syncToBackend(analytics);
    } catch (e) {
      debugPrint('Error saving conversation analytics: $e');
    }
  }

  /// Record a conversation session
  Future<void> recordSession(ConversationSession session) async {
    final analytics = await loadAnalytics(session.language);

    // Add session
    final updatedSessions = [
      session,
      ...analytics.sessions,
    ].take(50).toList(); // Keep last 50

    // Recalculate analytics
    final updatedAnalytics = ConversationAnalytics.fromJson({
      'language': analytics.language,
      'sessions': updatedSessions.map((s) => s.toJson()).toList(),
      'last_activity': DateTime.now().toIso8601String(),
    });

    await saveAnalytics(updatedAnalytics);
  }

  /// Get topic suggestions based on conversation history
  Future<List<String>> getTopicSuggestions(String language) async {
    final analytics = await loadAnalytics(language);

    // Get topics that haven't been covered much
    final allCommonTopics = [
      'Greetings',
      'Weather',
      'Food',
      'Travel',
      'Hobbies',
      'Family',
      'Work',
      'Shopping',
      'Health',
      'Education',
      'Entertainment',
      'Sports',
      'Technology',
      'Culture',
      'History',
    ];

    // Find topics with low frequency
    final suggestions = <String>[];
    for (final topic in allCommonTopics) {
      final frequency = analytics.topicFrequency[topic] ?? 0;
      if (frequency < 3) {
        suggestions.add(topic);
      }
    }

    // If all topics are covered, suggest new ones
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Future Plans',
        'Opinions',
        'Comparisons',
        'Hypotheticals',
        'Stories',
      ]);
    }

    return suggestions.take(5).toList();
  }

  /// Sync analytics to backend
  Future<void> _syncToBackend(ConversationAnalytics analytics) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      await PersistedOutboxService.instance.enqueue(
        type: 'progress_sync',
        data: {
          'user_id': user.id.toString(),
          'type': 'conversation_analytics',
          'language': analytics.language,
          'analytics': analytics.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error syncing conversation analytics: $e');
    }
  }

  /// Clear cached analytics
  void clearCache() {
    _cachedAnalytics = null;
  }
}
