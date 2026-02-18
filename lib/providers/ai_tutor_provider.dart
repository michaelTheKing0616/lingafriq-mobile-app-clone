import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/ai/pedagogy/ai_tutor_controller.dart';
import 'package:lingafriq/ai/pedagogy/tutor_turn.dart';
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';

/// Provides the AI Tutor Controller via Riverpod.
///
/// Requires Dio and API key to be available.
final aiTutorControllerProvider = Provider<AiTutorController>((ref) {
  final dio = ref.watch(_tutorDioProvider);

  return AiTutorController(
    dio: dio,
    apiKey: EnvConfig.groqApiKey,
    apiUrl: UrlConstants.groqChatCompletions,
  );
});

/// Stateful notifier for managing AI tutor sessions.
class AiTutorNotifier extends Notifier<AiTutorState> {
  @override
  AiTutorState build() {
    return const AiTutorState();
  }

  /// Starts a new tutor session.
  Future<void> startSession({
    required String learnerId,
    required String languageCode,
    String? focusSkillId,
  }) async {
    state = state.copyWith(
      isActive: true,
      isProcessing: true,
      learnerId: learnerId,
      languageCode: languageCode,
      focusSkillId: focusSkillId,
      turns: [],
      error: null,
    );

    try {
      final controller = ref.read(aiTutorControllerProvider);
      final turn = await controller.generateNextTurn(
        learnerId: learnerId,
        languageCode: languageCode,
        specificSkillId: focusSkillId,
      );

      state = state.copyWith(
        isProcessing: false,
        currentTurn: turn,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to generate first turn: $e',
      );
    }
  }

  /// Submits a response to the current turn and gets the next one.
  Future<TutorEvaluationResult?> submitResponse({
    required String response,
    double responseTimeSeconds = 0,
  }) async {
    final currentTurn = state.currentTurn;
    final learnerId = state.learnerId;
    if (currentTurn == null || learnerId == null) return null;

    state = state.copyWith(isProcessing: true);

    try {
      final controller = ref.read(aiTutorControllerProvider);

      // Evaluate response
      final result = await controller.evaluateResponse(
        learnerId: learnerId,
        turn: currentTurn,
        learnerResponse: response,
        responseTimeSeconds: responseTimeSeconds,
      );

      // Add to session history
      final turns = [...state.turns, TutorTurnRecord(
        turn: currentTurn,
        response: response,
        result: result,
        responseTimeSeconds: responseTimeSeconds,
      )];

      // Check if session should end
      if (result.feedback.nextAction == NextAction.endSession ||
          turns.length >= 10) {
        state = state.copyWith(
          isProcessing: false,
          isActive: false,
          turns: turns,
          currentTurn: null,
          lastResult: result,
        );
        return result;
      }

      // Generate next turn based on feedback
      String? nextSkillId;
      if (result.feedback.nextAction == NextAction.practicePrerequisite) {
        // The controller handles prerequisite selection internally
        nextSkillId = null;
      } else if (result.feedback.nextAction == NextAction.retrySameItem ||
          result.feedback.nextAction == NextAction.nextItemSameDifficulty) {
        nextSkillId = currentTurn.goalSkillId;
      }

      final nextTurn = await controller.generateNextTurn(
        learnerId: learnerId,
        languageCode: state.languageCode!,
        specificSkillId: nextSkillId ?? state.focusSkillId,
      );

      state = state.copyWith(
        isProcessing: false,
        turns: turns,
        currentTurn: nextTurn,
        lastResult: result,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process response: $e',
      );
      return null;
    }
  }

  /// Ends the current session.
  void endSession() {
    state = state.copyWith(
      isActive: false,
      currentTurn: null,
    );
  }

  /// Gets the session summary.
  TutorSessionSummary? getSessionSummary() {
    if (state.turns.isEmpty || state.learnerId == null) return null;

    return TutorSessionSummary(
      learnerId: state.learnerId!,
      languageCode: state.languageCode ?? '',
      turns: state.turns,
      startedAt: state.turns.first.result.updatedState.lastPractice,
    );
  }
}

/// State for the AI tutor session.
class AiTutorState {
  final bool isActive;
  final bool isProcessing;
  final String? learnerId;
  final String? languageCode;
  final String? focusSkillId;
  final TutorTurn? currentTurn;
  final List<TutorTurnRecord> turns;
  final TutorEvaluationResult? lastResult;
  final String? error;

  const AiTutorState({
    this.isActive = false,
    this.isProcessing = false,
    this.learnerId,
    this.languageCode,
    this.focusSkillId,
    this.currentTurn,
    this.turns = const [],
    this.lastResult,
    this.error,
  });

  AiTutorState copyWith({
    bool? isActive,
    bool? isProcessing,
    String? learnerId,
    String? languageCode,
    String? focusSkillId,
    TutorTurn? currentTurn,
    List<TutorTurnRecord>? turns,
    TutorEvaluationResult? lastResult,
    String? error,
  }) {
    return AiTutorState(
      isActive: isActive ?? this.isActive,
      isProcessing: isProcessing ?? this.isProcessing,
      learnerId: learnerId ?? this.learnerId,
      languageCode: languageCode ?? this.languageCode,
      focusSkillId: focusSkillId ?? this.focusSkillId,
      currentTurn: currentTurn ?? this.currentTurn,
      turns: turns ?? this.turns,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }

  /// Session accuracy so far.
  double get sessionAccuracy =>
      turns.isEmpty ? 0 : turns.where((t) => t.result.feedback.wasCorrect).length / turns.length;

  /// Number of turns completed.
  int get turnsCompleted => turns.length;
}

/// Provider for the AI Tutor Notifier.
final aiTutorProvider = NotifierProvider<AiTutorNotifier, AiTutorState>(
  AiTutorNotifier.new,
);

// ─── Internal providers ──────────────────────────────────────────────

/// Dio instance for tutor API calls.
final _tutorDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

