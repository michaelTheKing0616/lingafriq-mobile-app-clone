// Conversation Analytics Service
// Tracks conversation metrics, fluency, and provides topic suggestions
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_analytics_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';

final conversationAnalyticsServiceProvider = Provider<ConversationAnalyticsService>((ref) {
  return ConversationAnalyticsService(ref);
});

class ConversationAnalyticsService {
  final Ref _ref;
  ConversationAnalytics? _cachedAnalytics;

  ConversationAnalyticsService(this._ref);

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
      await prefs.setString('conversation_analytics_${analytics.language}', analytics.toJsonString());
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
    final updatedSessions = [session, ...analytics.sessions].take(50).toList(); // Keep last 50
    
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

  /// Calculate fluency score from session
  double calculateFluencyScore(ConversationSession session) {
    if (session.messageCount == 0) return 0.0;
    
    // Base score from error rate
    final errorRate = session.errorCount / session.messageCount;
    final errorScore = (1.0 - errorRate.clamp(0.0, 1.0)) * 100.0;
    
    // Bonus for vocabulary diversity
    final vocabDiversity = session.vocabularyUsed.length / session.wordCount.clamp(1, 100);
    final vocabScore = vocabDiversity.clamp(0.0, 1.0) * 20.0;
    
    // Bonus for conversation length (longer = more fluent)
    final lengthScore = (session.messageCount / 20.0).clamp(0.0, 1.0) * 10.0;
    
    return (errorScore * 0.7 + vocabScore * 0.2 + lengthScore * 0.1).clamp(0.0, 100.0);
  }

  /// Sync analytics to backend
  Future<void> _syncToBackend(ConversationAnalytics analytics) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress,
        data: {
          'user_id': user.id.toString(),
          'type': 'conversation_analytics',
          'language': analytics.language,
          'analytics': analytics.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing conversation analytics: $e');
    }
  }

  /// Clear cached analytics
  void clearCache() {
    _cachedAnalytics = null;
  }
}

