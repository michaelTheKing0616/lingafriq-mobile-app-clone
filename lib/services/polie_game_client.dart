import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

/// Exception thrown when game turn evaluation fails - allows callers to show
/// user-friendly message and let user retry the same turn.
class GameEvaluationException implements Exception {
  final String userMessage;

  GameEvaluationException(this.userMessage);

  @override
  String toString() => userMessage;
}

/// Polie backend client for game content generation and evaluation
/// This replaces random logic with real AI-driven evaluation
class PolieGameClient {
  final Dio _dio;
  final String _resolvedBaseUrl;

  PolieGameClient({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _resolvedBaseUrl =
            (baseUrl ?? EnvConfig.backendBaseUrl).replaceAll(RegExp(r'/$'), '');

  String _url(String path) => '$_resolvedBaseUrl$path';

  /// Generate game content from Polie backend (Game Master API)
  /// Polie acts as dungeon master, cultural referee, difficulty tuner, and feedback author
  Future<PolieGameContent> generateContent({
    required String gameId,
    required String language,
    required String difficulty,
    required String userId,
    required String sessionId,
    Map<String, dynamic>? previousPerformance,
    List<String>? learningGoals,
    Map<String, dynamic>? masteryProfile,
  }) async {
    try {
      final response = await _dio.post(
        _url(ApiContract.ai.polieGameContent),
        data: {
          'game_id': gameId,
          'language': language,
          'difficulty': difficulty,
          'user_id': userId,
          'session_id': sessionId,
          'learning_goals': learningGoals ?? [],
          'previous_performance': previousPerformance ?? {},
          'mastery_profile': masteryProfile ?? {},
          // Game Master fields
          'request_type': 'game_content',
          'include_distractors': true,
          'include_evaluation_rules': true,
          'include_animation_cues': true,
          'include_feedback_templates': true,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return PolieGameContent.fromJson(response.data);
    } catch (e) {
      debugPrint('Error generating game content: $e');
      // Return fallback content instead of throwing
      return PolieGameContent.fallback(gameId: gameId, language: language);
    }
  }

  /// Evaluate a game turn - this is the critical method that replaces random logic.
  /// Throws [GameEvaluationException] with user-friendly message on failure so
  /// callers can show it and allow user to retry the same turn.
  Future<PolieEvaluationResult> evaluateTurn({
    required String gameId,
    required String contentId,
    required String language,
    required Map<String, dynamic> userInput,
    required String difficulty,
    required Map<String, dynamic> sessionMetrics,
  }) async {
    try {
      final response = await _dio.post(
        _url(ApiContract.ai.polieEvaluateGameTurn),
        data: {
          'game_id': gameId,
          'content_id': contentId,
          'language': language,
          'user_input': userInput,
          'difficulty': difficulty,
          'session_metrics': sessionMetrics,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return PolieEvaluationResult.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Error evaluating game turn: $e');
      throw GameEvaluationException(
        TransportErrorPolicy.toUserMessage(e),
      );
    } catch (e) {
      if (e is GameEvaluationException) rethrow;
      debugPrint('Error evaluating game turn: $e');
      throw GameEvaluationException(
        ErrorHandler.getUserFriendlyError(e),
      );
    }
  }
}

/// Polie game content response
class PolieGameContent {
  final String contentId;
  final String gameId;
  final String language;
  final String text;
  final String? ipa;
  final List<double>? tones;
  final String? audioUrl;
  final String? culturalContext;
  final double difficultyScore;
  final Map<String, dynamic> scoringRules;
  final Map<String, dynamic> animationCues;
  final Map<String, dynamic>? metadata;

  PolieGameContent({
    required this.contentId,
    required this.gameId,
    required this.language,
    required this.text,
    this.ipa,
    this.tones,
    this.audioUrl,
    this.culturalContext,
    required this.difficultyScore,
    required this.scoringRules,
    required this.animationCues,
    this.metadata,
  });

  factory PolieGameContent.fromJson(Map<String, dynamic> json) {
    return PolieGameContent(
      contentId: json['content_id'] as String? ?? '',
      gameId: json['game_id'] as String? ?? '',
      language: json['language'] as String? ?? '',
      text: json['text'] as String? ?? '',
      ipa: json['ipa'] as String?,
      tones: json['tones'] != null
          ? List<double>.from(json['tones'] as List)
          : null,
      audioUrl: json['audio_url'] as String?,
      culturalContext: json['cultural_context'] as String?,
      difficultyScore: (json['difficulty_score'] as num?)?.toDouble() ?? 0.5,
      scoringRules: json['scoring_rules'] as Map<String, dynamic>? ?? {},
      animationCues: json['animation_cues'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  factory PolieGameContent.fallback({
    required String gameId,
    required String language,
  }) {
    return PolieGameContent(
      contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      gameId: gameId,
      language: language,
      text: 'Loading content...',
      difficultyScore: 0.5,
      scoringRules: {},
      animationCues: {},
    );
  }
}

/// Polie evaluation result - replaces random correctness
class PolieEvaluationResult {
  final bool correct;
  final double accuracy;
  final String feedback;
  final String animationEvent;
  final String difficultyAdjustment;
  final Map<String, dynamic> learningSignal;

  PolieEvaluationResult({
    required this.correct,
    required this.accuracy,
    required this.feedback,
    required this.animationEvent,
    required this.difficultyAdjustment,
    required this.learningSignal,
  });

  factory PolieEvaluationResult.fromJson(Map<String, dynamic> json) {
    return PolieEvaluationResult(
      correct: json['correct'] as bool? ?? false,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      feedback: json['feedback'] as String? ?? '',
      animationEvent: json['animation_event'] as String? ?? 'encouraging',
      difficultyAdjustment: json['difficulty_adjustment'] as String? ?? 'maintain',
      learningSignal: json['learning_signal'] as Map<String, dynamic>? ?? {},
    );
  }

  factory PolieEvaluationResult.neutral() {
    return PolieEvaluationResult(
      correct: false,
      accuracy: 0.5,
      feedback: 'Please try again',
      animationEvent: 'encouraging',
      difficultyAdjustment: 'maintain',
      learningSignal: {},
    );
  }
}

