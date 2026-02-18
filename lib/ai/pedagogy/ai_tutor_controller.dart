import 'dart:convert';
import 'package:dio/dio.dart';

import '../../learning/learner_model/learner_model_service.dart';
import '../../learning/learner_model/learner_skill_state.dart';
import '../../learning/skill_graph/skill_node.dart';
import '../../learning/skill_graph/skill_registry.dart';
import 'error_classifier.dart';
import 'prompt_templates.dart';
import 'tutor_turn.dart';

/// The AI Tutor Controller — the pedagogical brain.
///
/// This is NOT a chatbot. It is a deterministic pedagogue that:
/// - Never chats freely
/// - Operates only through structured tutor turns
/// - Produces strict JSON output
/// - Updates the learner model after every interaction
/// - Selects the next optimal task based on cognitive state
///
/// Every interaction follows this cycle:
/// 1. Select skill + generate turn (from learner model)
/// 2. Present task to learner
/// 3. Evaluate response (error classification + AI feedback)
/// 4. Update learner model
/// 5. Determine next action
class AiTutorController {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;

  AiTutorController({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
    LearnerModelService? learnerModel,
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model,
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Generates the next tutor turn for a learner.
  ///
  /// Uses the learner model to select the optimal skill and task type,
  /// then generates a specific practice item either from templates
  /// or via AI generation.
  Future<TutorTurn> generateNextTurn({
    required String learnerId,
    required String languageCode,
    String? specificSkillId,
  }) async {
    // 1. Select skill to practice
    final skillId = specificSkillId ??
        _selectOptimalSkill(learnerId, languageCode);

    if (skillId == null) {
      throw StateError('No skills available for practice in $languageCode');
    }

    final skill = SkillRegistry.instance.findSkill(skillId);
    if (skill == null) {
      throw StateError('Skill $skillId not found in registry');
    }

    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    // 2. Determine task type based on skill modality and mastery
    final taskType = _selectTaskType(skill, state);

    // 3. Determine difficulty
    final difficulty = _computeTargetDifficulty(state);

    // 4. Determine error focus
    final errorFocus = _determineErrorFocus(state);

    // 5. Generate the turn via AI
    final turn = await _generateTurnViaAI(
      skill: skill,
      state: state,
      taskType: taskType,
      difficulty: difficulty,
      errorFocus: errorFocus,
    );

    return turn;
  }

  /// Evaluates a learner's response to a tutor turn.
  ///
  /// This is the core evaluation loop:
  /// 1. Run local error classification
  /// 2. Get AI feedback (constrained to schema)
  /// 3. Update the learner model
  /// 4. Return structured feedback + updated state
  Future<TutorEvaluationResult> evaluateResponse({
    required String learnerId,
    required TutorTurn turn,
    required String learnerResponse,
    List<PhonemeResult>? phonemeResults,
    double responseTimeSeconds = 0,
  }) async {
    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: turn.goalSkillId,
    );

    // 1. Local error classification (fast, deterministic)
    final classification = _classifyLocally(turn, learnerResponse, phonemeResults);

    // 2. AI-powered feedback (constrained by prompt architecture)
    final aiFeedback = await _getAiFeedback(
      state: state,
      turn: turn,
      learnerResponse: learnerResponse,
      classification: classification,
    );

    // 3. Merge local classification with AI feedback
    final mergedFeedback = _mergeFeedback(classification, aiFeedback);

    // 4. Update the learner model
    final expectedTime = turn.timeLimitSeconds > 0
        ? turn.timeLimitSeconds.toDouble()
        : 5.0;

    final updatedState = await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: turn.goalSkillId,
      wasCorrect: mergedFeedback.wasCorrect,
      errorTypeIds: mergedFeedback.detectedErrors,
      responseTimeSeconds: responseTimeSeconds,
      expectedTimeSeconds: expectedTime,
    );

    return TutorEvaluationResult(
      feedback: mergedFeedback,
      updatedState: updatedState,
      classification: classification,
    );
  }

  /// Runs a complete tutor session: generates turns, evaluates responses,
  /// and tracks progress until the session goal is met or the learner stops.
  ///
  /// Returns the session summary.
  Future<TutorSessionSummary> runSession({
    required String learnerId,
    required String languageCode,
    required Future<String?> Function(TutorTurn turn) getResponse,
    int maxTurns = 10,
    String? focusSkillId,
  }) async {
    final turns = <TutorTurnRecord>[];
    String? currentSkillId = focusSkillId;

    for (int i = 0; i < maxTurns; i++) {
      // Generate turn
      final turn = await generateNextTurn(
        learnerId: learnerId,
        languageCode: languageCode,
        specificSkillId: currentSkillId,
      );

      // Get learner response
      final startTime = DateTime.now();
      final response = await getResponse(turn);
      if (response == null) break; // Learner ended session

      final responseTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;

      // Evaluate
      final result = await evaluateResponse(
        learnerId: learnerId,
        turn: turn,
        learnerResponse: response,
        responseTimeSeconds: responseTime,
      );

      turns.add(TutorTurnRecord(
        turn: turn,
        response: response,
        result: result,
        responseTimeSeconds: responseTime,
      ));

      // Determine next action
      switch (result.feedback.nextAction) {
        case NextAction.endSession:
          break;
        case NextAction.practicePrerequisite:
          // Switch to a prerequisite skill
          final skill = SkillRegistry.instance.findSkill(turn.goalSkillId);
          if (skill != null && skill.prerequisites.isNotEmpty) {
            currentSkillId = skill.prerequisites.first;
          }
          break;
        case NextAction.retrySameItem:
        case NextAction.nextItemSameDifficulty:
          currentSkillId = turn.goalSkillId;
          break;
        case NextAction.downgradeToEasier:
        case NextAction.upgradeToHarder:
          currentSkillId = null; // Let the engine select
          break;
      }

      if (result.feedback.nextAction == NextAction.endSession) break;
    }

    return TutorSessionSummary(
      learnerId: learnerId,
      languageCode: languageCode,
      turns: turns,
      startedAt: turns.isNotEmpty
          ? turns.first.result.updatedState.lastPractice
          : DateTime.now(),
    );
  }

  // ─── Private methods ───────────────────────────────────────────────

  String? _selectOptimalSkill(String learnerId, String languageCode) {
    final recommendations = _learnerModel.getRecommendations(
      learnerId: learnerId,
      languageCode: languageCode,
      count: 1,
    );

    return recommendations.isNotEmpty ? recommendations.first.skillId : null;
  }

  TaskType _selectTaskType(SkillNode skill, LearnerSkillState state) {
    // Low mastery → receptive tasks (recognition before production)
    if (state.mastery < 0.3) {
      return switch (skill.modality) {
        SkillModality.speaking => TaskType.listeningTranscription,
        SkillModality.writing => TaskType.multipleChoice,
        SkillModality.listening => TaskType.multipleChoice,
        SkillModality.reading => TaskType.multipleChoice,
        SkillModality.mixed => TaskType.cloze,
      };
    }

    // Medium mastery → guided production
    if (state.mastery < 0.7) {
      return switch (skill.modality) {
        SkillModality.speaking => TaskType.speaking,
        SkillModality.writing => TaskType.cloze,
        SkillModality.listening => TaskType.listeningTranscription,
        SkillModality.reading => TaskType.translation,
        SkillModality.mixed => TaskType.sentenceConstruction,
      };
    }

    // High mastery → free production under pressure
    return switch (skill.modality) {
      SkillModality.speaking => TaskType.minimalPairSpeaking,
      SkillModality.writing => TaskType.guidedProduction,
      SkillModality.listening => TaskType.listeningTranscription,
      SkillModality.reading => TaskType.reverseTranslation,
      SkillModality.mixed => TaskType.guidedProduction,
    };
  }

  double _computeTargetDifficulty(LearnerSkillState state) {
    // Target zone: where the learner succeeds ~70-80% of the time
    // (zone of proximal development)
    final baseFromMastery = state.mastery.clamp(0.2, 0.9);

    // Adjust based on recent performance
    if (state.accuracy > 0.85 && state.currentStreak >= 3) {
      return (baseFromMastery + 0.1).clamp(0.0, 1.0);
    }
    if (state.accuracy < 0.5) {
      return (baseFromMastery - 0.15).clamp(0.0, 1.0);
    }

    return baseFromMastery;
  }

  List<String> _determineErrorFocus(LearnerSkillState state) {
    final topErrors = state.errorDistribution.rates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return topErrors.take(3).map((e) => e.key).toList();
  }

  Future<TutorTurn> _generateTurnViaAI({
    required SkillNode skill,
    required LearnerSkillState state,
    required TaskType taskType,
    required double difficulty,
    required List<String> errorFocus,
  }) async {
    final messages = PromptTemplates.generateTurnCreationPrompt(
      state: state,
      skillName: skill.name,
      skillDescription: skill.description,
      preferredTaskType: taskType,
      targetDifficulty: difficulty,
    );

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.3,
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      return TutorTurn(
        goalSkillId: skill.id,
        taskType: taskType,
        prompt: parsed['prompt'] as String? ?? 'Practice this skill.',
        expected: ExpectedOutput.fromJson(
          parsed['expected'] as Map<String, dynamic>? ?? {},
        ),
        errorFocus: (parsed['errorFocus'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            errorFocus,
        difficulty: difficulty,
        timeLimitSeconds: parsed['timeLimitSeconds'] as int? ?? 0,
      );
    } catch (e) {
      // Fallback: generate a basic turn without AI
      return TutorTurn(
        goalSkillId: skill.id,
        taskType: taskType,
        prompt: 'Practice: ${skill.name}',
        expected: ExpectedOutput(
          text: skill.name,
          requiredElements: [skill.name],
        ),
        errorFocus: errorFocus,
        difficulty: difficulty,
      );
    }
  }

  ErrorClassificationResult _classifyLocally(
    TutorTurn turn,
    String learnerResponse,
    List<PhonemeResult>? phonemeResults,
  ) {
    // Phoneme-level classification for speaking tasks
    if (phonemeResults != null && turn.expected.phonemes != null) {
      return ErrorClassifier.classifyPhonemeErrors(
        expected: turn.expected.phonemes!
            .map((p) => PhonemeResult(phoneme: p, confidence: 1.0))
            .toList(),
        actual: phonemeResults,
      );
    }

    // Text-level classification for all other tasks
    if (turn.expected.text != null) {
      return ErrorClassifier.classifyTextErrors(
        expected: turn.expected.text!,
        actual: learnerResponse,
        requiredElements: turn.expected.requiredElements,
      );
    }

    // Fallback: compare raw strings
    final isCorrect = learnerResponse.trim().toLowerCase() ==
        (turn.expected.text ?? '').trim().toLowerCase();
    return ErrorClassificationResult(
      detectedErrors: [],
      partialCredit: isCorrect ? 1.0 : 0.0,
      isCorrect: isCorrect,
    );
  }

  Future<TutorFeedback> _getAiFeedback({
    required LearnerSkillState state,
    required TutorTurn turn,
    required String learnerResponse,
    required ErrorClassificationResult classification,
  }) async {
    final messages = PromptTemplates.generateFullPromptSequence(
      state: state,
      turn: turn,
      learnerResponse: learnerResponse,
    );

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.1,
          'max_tokens': 300,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      return TutorFeedback.fromJson(parsed);
    } catch (e) {
      // Fallback: generate feedback from local classification
      return _generateFallbackFeedback(classification, turn);
    }
  }

  TutorFeedback _mergeFeedback(
    ErrorClassificationResult classification,
    TutorFeedback aiFeedback,
  ) {
    // Trust local classification for correctness and errors.
    // Trust AI for diagnosis text and next action.
    final mergedErrors = <String>{
      ...classification.errorTypeIds,
      ...aiFeedback.detectedErrors,
    }.toList();

    return TutorFeedback(
      diagnosis: aiFeedback.diagnosis,
      microExplanation: aiFeedback.microExplanation,
      nextAction: aiFeedback.nextAction,
      diagnosisConfidence: aiFeedback.diagnosisConfidence,
      detectedErrors: mergedErrors,
      wasCorrect: classification.isCorrect,
      partialCredit: classification.partialCredit,
    );
  }

  TutorFeedback _generateFallbackFeedback(
    ErrorClassificationResult classification,
    TutorTurn turn,
  ) {
    if (classification.isCorrect) {
      return TutorFeedback(
        wasCorrect: true,
        partialCredit: 1.0,
        nextAction: NextAction.nextItemSameDifficulty,
        detectedErrors: [],
      );
    }

    final topError = classification.detectedErrors.isNotEmpty
        ? classification.detectedErrors.first
        : null;

    final diagnosis = topError != null
        ? 'Expected "${topError.expected}" but got "${topError.actual}".'
        : null;

    return TutorFeedback(
      wasCorrect: false,
      partialCredit: classification.partialCredit,
      diagnosis: diagnosis,
      nextAction: classification.partialCredit > 0.5
          ? NextAction.retrySameItem
          : NextAction.downgradeToEasier,
      detectedErrors: classification.errorTypeIds,
    );
  }
}

/// Complete result of evaluating a learner's response.
class TutorEvaluationResult {
  final TutorFeedback feedback;
  final LearnerSkillState updatedState;
  final ErrorClassificationResult classification;

  const TutorEvaluationResult({
    required this.feedback,
    required this.updatedState,
    required this.classification,
  });

  Map<String, dynamic> toJson() => {
        'feedback': feedback.toJson(),
        'updatedState': updatedState.toJson(),
        'classification': classification.toJson(),
      };
}

/// Record of a single turn in a tutor session.
class TutorTurnRecord {
  final TutorTurn turn;
  final String response;
  final TutorEvaluationResult result;
  final double responseTimeSeconds;

  const TutorTurnRecord({
    required this.turn,
    required this.response,
    required this.result,
    required this.responseTimeSeconds,
  });
}

/// Summary of a complete tutor session.
class TutorSessionSummary {
  final String learnerId;
  final String languageCode;
  final List<TutorTurnRecord> turns;
  final DateTime startedAt;

  const TutorSessionSummary({
    required this.learnerId,
    required this.languageCode,
    required this.turns,
    required this.startedAt,
  });

  int get totalTurns => turns.length;

  int get correctTurns =>
      turns.where((t) => t.result.feedback.wasCorrect).length;

  double get accuracy =>
      totalTurns > 0 ? correctTurns / totalTurns : 0.0;

  double get averagePartialCredit =>
      totalTurns > 0
          ? turns.fold<double>(
                0,
                (sum, t) => sum + t.result.feedback.partialCredit,
              ) /
              totalTurns
          : 0.0;

  Set<String> get allDetectedErrors =>
      turns.expand((t) => t.result.feedback.detectedErrors).toSet();

  double get averageResponseTime =>
      totalTurns > 0
          ? turns.fold<double>(0, (sum, t) => sum + t.responseTimeSeconds) /
              totalTurns
          : 0.0;

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'languageCode': languageCode,
        'totalTurns': totalTurns,
        'correctTurns': correctTurns,
        'accuracy': accuracy,
        'averagePartialCredit': averagePartialCredit,
        'averageResponseTime': averageResponseTime,
        'allDetectedErrors': allDetectedErrors.toList(),
        'startedAt': startedAt.toIso8601String(),
      };
}
