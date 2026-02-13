/// AI Chat Integration Service
/// Integrates all progress tracking services with the AI chat provider
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/roleplay_progress_model.dart';
import '../models/tutor_progress_model.dart';
import '../models/conversation_analytics_model.dart';
import '../models/review_progress_model.dart';
import '../models/translation_history_model.dart';
import 'roleplay_progress_service.dart';
import 'tutor_progress_service.dart';
import 'conversation_analytics_service.dart';
import 'vocabulary_progress_service.dart';
import 'review_progress_service.dart';
import 'translation_history_service.dart';

final aiChatIntegrationServiceProvider = Provider<AiChatIntegrationService>((ref) {
  return AiChatIntegrationService(ref);
});

class AiChatIntegrationService {
  final Ref _ref;

  AiChatIntegrationService(this._ref);

  /// Record a roleplay session completion
  Future<void> recordRoleplaySession({
    required String scenarioId,
    required String language,
    required int turnCount,
    required double accuracy,
    required double fluency,
    required int score,
    required List<String> branchesTaken,
    required List<String> vocabularyLearned,
    required List<String> grammarPoints,
    required List<String> corrections,
    required int timeSpent,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final progressService = _ref.read(roleplayProgressServiceProvider);
      
      final result = RoleplaySessionResult(
        scenarioId: scenarioId,
        language: language,
        turnCount: turnCount,
        accuracy: accuracy,
        fluency: fluency,
        score: score,
        branchesTaken: branchesTaken,
        vocabularyLearned: vocabularyLearned,
        grammarPoints: grammarPoints,
        corrections: corrections,
        timeSpent: timeSpent,
        completedAt: DateTime.now(),
        metadata: metadata,
      );

      await progressService.recordSession(result);
    } catch (e) {
      debugPrint('Error recording roleplay session: $e');
    }
  }

  /// Record a tutor session
  Future<void> recordTutorSession({
    required String sessionId,
    required String language,
    required String cefrLevel,
    required List<TutorInteraction> interactions,
    required double overallScore,
    required Map<String, double> skillScores,
    required List<String> topicsCovered,
    required List<String> vocabularyLearned,
    required List<String> grammarPoints,
    required int timeSpent,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final progressService = _ref.read(tutorProgressServiceProvider);
      
      final result = TutorSessionResult(
        sessionId: sessionId,
        language: language,
        cefrLevel: cefrLevel,
        interactions: interactions,
        overallScore: overallScore,
        skillScores: skillScores,
        topicsCovered: topicsCovered,
        vocabularyLearned: vocabularyLearned,
        grammarPoints: grammarPoints,
        timeSpent: timeSpent,
        completedAt: DateTime.now(),
        metadata: metadata,
      );

      await progressService.recordSession(result);
    } catch (e) {
      debugPrint('Error recording tutor session: $e');
    }
  }

  /// Record a conversation session
  Future<void> recordConversationSession({
    required String sessionId,
    required String language,
    required DateTime startTime,
    required int messageCount,
    required int wordCount,
    required List<String> topics,
    required double fluencyScore,
    required int errorCount,
    required List<String> corrections,
    required Map<String, int> vocabularyUsed,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final analyticsService = _ref.read(conversationAnalyticsServiceProvider);
      
      final session = ConversationSession(
        sessionId: sessionId,
        language: language,
        startTime: startTime,
        endTime: DateTime.now(),
        messageCount: messageCount,
        wordCount: wordCount,
        topics: topics,
        fluencyScore: fluencyScore,
        errorCount: errorCount,
        corrections: corrections,
        vocabularyUsed: vocabularyUsed,
        metadata: metadata,
      );

      await analyticsService.recordSession(session);
    } catch (e) {
      debugPrint('Error recording conversation session: $e');
    }
  }

  /// Record vocabulary word review
  Future<void> recordVocabularyReview({
    required String word,
    required String language,
    required bool isCorrect,
  }) async {
    try {
      final vocabService = _ref.read(vocabularyProgressServiceProvider);
      await vocabService.recordReview(word, language, isCorrect);
    } catch (e) {
      debugPrint('Error recording vocabulary review: $e');
    }
  }

  /// Record review session
  Future<void> recordReviewSession({
    required String sessionId,
    required String language,
    required List<ReviewItem> itemsReviewed,
    required int totalItems,
    required int correctCount,
    required int incorrectCount,
    required double accuracy,
    required int timeSpent,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final reviewService = _ref.read(reviewProgressServiceProvider);
      
      final result = ReviewSessionResult(
        sessionId: sessionId,
        language: language,
        itemsReviewed: itemsReviewed,
        totalItems: totalItems,
        correctCount: correctCount,
        incorrectCount: incorrectCount,
        accuracy: accuracy,
        timeSpent: timeSpent,
        completedAt: DateTime.now(),
        metadata: metadata,
      );

      await reviewService.recordSession(result);
    } catch (e) {
      debugPrint('Error recording review session: $e');
    }
  }

  /// Save translation to history
  Future<void> saveTranslation({
    required String sourceText,
    required String sourceLanguage,
    required String targetLanguage,
    required String primaryTranslation,
    List<TranslationAlternative>? alternatives,
    List<GrammarBreakdown>? grammarBreakdown,
    CulturalContext? culturalContext,
  }) async {
    try {
      final historyService = _ref.read(translationHistoryServiceProvider);
      
      final entry = TranslationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceText: sourceText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        primaryTranslation: primaryTranslation,
        alternatives: alternatives ?? [],
        grammarBreakdown: grammarBreakdown ?? [],
        culturalContext: culturalContext,
        timestamp: DateTime.now(),
      );

      await historyService.addTranslation(entry);
    } catch (e) {
      debugPrint('Error saving translation: $e');
    }
  }

  /// Calculate roleplay session metrics from chat messages
  Map<String, dynamic> calculateRoleplayMetrics({
    required List<dynamic> messages,
    required DateTime startTime,
    required String scenarioId,
  }) {
    final now = DateTime.now();
    final timeSpent = now.difference(startTime).inSeconds;
    final turnCount = messages.length;
    
    // Calculate accuracy from message analysis
    final corrections = <String>[];
    int totalUserMessages = 0;
    int errorCount = 0;
    final vocabularyLearned = <String>[];
    final grammarPoints = <String>[];
    final branchesTaken = <String>[];
    
    // Analyze messages for accuracy indicators
    for (final msg in messages) {
      final msgText = msg.toString().toLowerCase();
      if (msgText.contains('user:') || msgText.contains('student:')) {
        totalUserMessages++;
        // Check for common error indicators in AI responses
        if (msgText.contains('correction:') || 
            msgText.contains('suggest:') ||
            msgText.contains('better:') ||
            msgText.contains('grammar note:')) {
          errorCount++;
        }
      }
      // Extract vocabulary mentions
      if (msgText.contains('vocabulary:') || msgText.contains('word:')) {
        final words = msgText.split(RegExp(r'vocabulary:|word:'));
        if (words.length > 1) {
          vocabularyLearned.add(words[1].trim().split(' ').first);
        }
      }
      // Extract grammar points
      if (msgText.contains('grammar:') || msgText.contains('grammar point:')) {
        final grammar = msgText.split(RegExp(r'grammar:|grammar point:'));
        if (grammar.length > 1) {
          grammarPoints.add(grammar[1].trim().split('.').first);
        }
      }
      // Extract branches
      if (msgText.contains('branch:') || msgText.contains('path:')) {
        final branch = msgText.split(RegExp(r'branch:|path:'));
        if (branch.length > 1) {
          branchesTaken.add(branch[1].trim().split('.').first);
        }
      }
    }
    
    // Calculate accuracy: base score minus error rate
    final errorRate = totalUserMessages > 0 
        ? (errorCount / totalUserMessages).clamp(0.0, 1.0)
        : 0.0;
    double accuracy = (1.0 - errorRate * 0.5).clamp(0.5, 1.0);
    
    // Calculate fluency: based on message flow and turn count
    final avgWordsPerMessage = turnCount > 0 
        ? (messages.join(' ').split(' ').length / turnCount).clamp(5.0, 50.0)
        : 10.0;
    final fluencyBase = (avgWordsPerMessage / 30.0).clamp(0.0, 1.0);
    final fluencyBonus = (turnCount / 15.0).clamp(0.0, 0.2);
    double fluency = (fluencyBase + fluencyBonus).clamp(0.6, 1.0);
    
    // Calculate score
    final score = ((accuracy * 0.4 + fluency * 0.3 + (turnCount / 10.0).clamp(0.0, 0.3) * 0.3) * 100).round();

    return {
      'scenario_id': scenarioId,
      'turn_count': turnCount,
      'accuracy': accuracy,
      'fluency': fluency,
      'score': score,
      'branches_taken': branchesTaken,
      'vocabulary_learned': vocabularyLearned,
      'grammar_points': grammarPoints,
      'corrections': corrections,
      'time_spent': timeSpent,
    };
  }

  /// Calculate conversation fluency score
  double calculateConversationFluency({
    required int messageCount,
    required int wordCount,
    required int errorCount,
    required Map<String, int> vocabularyUsed,
  }) {
    if (messageCount == 0) return 0.0;
    
    // Base score from error rate
    final errorRate = errorCount / messageCount;
    final errorScore = (1.0 - errorRate.clamp(0.0, 1.0)) * 100.0;
    
    // Bonus for vocabulary diversity
    final vocabDiversity = vocabularyUsed.length / wordCount.clamp(1, 100);
    final vocabScore = vocabDiversity.clamp(0.0, 1.0) * 20.0;
    
    // Bonus for conversation length
    final lengthScore = (messageCount / 20.0).clamp(0.0, 1.0) * 10.0;
    
    return (errorScore * 0.7 + vocabScore * 0.2 + lengthScore * 0.1).clamp(0.0, 100.0);
  }
}

