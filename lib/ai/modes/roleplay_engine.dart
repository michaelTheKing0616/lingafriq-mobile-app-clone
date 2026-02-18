import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:lingafriq/ai/validation/response_validator.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';

/// Hierarchical state machine for roleplay conversations.
///
/// Roleplay is NOT free chat. It is a branching conversation tree
/// where:
/// - Each node has an expected response pattern
/// - Branches are selected based on learner response quality
/// - Errors trigger corrective feedback before continuing
/// - The learner model is updated at every turn
/// - Personality profiles are maintained throughout
class RoleplayEngine {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;

  RoleplayEngine({
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

  /// Active roleplay sessions indexed by learnerId.
  final Map<String, RoleplaySession> _activeSessions = {};

  /// Starts a new roleplay scenario.
  Future<RoleplayTurn> startScenario({
    required String learnerId,
    required String languageCode,
    required RoleplayScenario scenario,
  }) async {
    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: scenario.targetSkillIds.first,
    );

    final session = RoleplaySession(
      learnerId: learnerId,
      languageCode: languageCode,
      scenario: scenario,
      turns: [],
      currentNodeId: 'start',
    );

    _activeSessions[learnerId] = session;

    // Generate opening turn from AI
    final openingTurn = await _generateTurn(
      session: session,
      state: state,
      isOpening: true,
    );

    session.turns.add(openingTurn);
    return openingTurn;
  }

  /// Processes a learner response and advances the roleplay.
  Future<RoleplayTurn> processResponse({
    required String learnerId,
    required String learnerResponse,
    double responseTimeSeconds = 0,
  }) async {
    final session = _activeSessions[learnerId];
    if (session == null) {
      throw StateError('No active roleplay session for learner $learnerId');
    }

    final skillId = session.scenario.targetSkillIds.isNotEmpty
        ? session.scenario.targetSkillIds.first
        : 'general_conversation';

    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    // Evaluate response via AI
    final evaluation = await _evaluateResponse(
      session: session,
      state: state,
      learnerResponse: learnerResponse,
    );

    // Update learner model
    if (skillId != 'general_conversation') {
      await _learnerModel.recordAttempt(
        learnerId: learnerId,
        skillId: skillId,
        wasCorrect: evaluation.detectedErrors.isEmpty,
        errorTypeIds: evaluation.detectedErrors,
        responseTimeSeconds: responseTimeSeconds,
      );
    }

    // Determine branching
    final nextNode = _determineBranch(session, evaluation);
    session.currentNodeId = nextNode;

    // Generate next turn
    final nextTurn = await _generateTurn(
      session: session,
      state: state,
      isOpening: false,
      previousResponse: learnerResponse,
      evaluation: evaluation,
    );

    session.turns.add(nextTurn);

    // Check if scenario is complete
    if (evaluation.scenarioComplete || session.turns.length > 20) {
      _activeSessions.remove(learnerId);
    }

    return nextTurn;
  }

  /// Gets the current session summary.
  RoleplaySessionSummary? getSessionSummary(String learnerId) {
    final session = _activeSessions[learnerId];
    if (session == null) return null;

    return RoleplaySessionSummary(
      scenario: session.scenario,
      turnsCompleted: session.turns.length,
      errorsDetected: session.turns
          .expand((t) => t.detectedErrors)
          .toSet()
          .toList(),
      isComplete: !_activeSessions.containsKey(learnerId),
    );
  }

  /// Ends a session early.
  void endSession(String learnerId) {
    _activeSessions.remove(learnerId);
  }

  // ─── Private ───────────────────────────────────────────────────────

  Future<RoleplayTurn> _generateTurn({
    required RoleplaySession session,
    required LearnerSkillState state,
    required bool isOpening,
    String? previousResponse,
    _RoleplayEvaluation? evaluation,
  }) async {
    final scenario = session.scenario;
    final history = session.turns.map((t) => t.dialogue).join('\n');

    final prompt = isOpening
        ? _buildOpeningPrompt(scenario, state)
        : _buildContinuationPrompt(
            scenario, state, history, previousResponse!, evaluation!);

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': prompt,
          'temperature': 0.4,
          'max_tokens': 400,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final parsed = ResponseValidator.validateRoleplayResponse(content);

      return RoleplayTurn(
        dialogue: parsed['dialogue'] as String,
        nextPrompt: parsed['nextPrompt'] as String? ?? '',
        correction: parsed['correction'] as String?,
        branchReason: parsed['branchReason'] as String?,
        detectedErrors: (parsed['detectedErrors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        scenarioComplete: parsed['scenarioComplete'] as bool? ?? false,
        nodeId: session.currentNodeId,
      );
    } catch (e) {
      return RoleplayTurn(
        dialogue: isOpening
            ? scenario.openingLine
            : 'Let me rephrase. ${scenario.openingLine}',
        nextPrompt: 'Please try responding.',
        correction: evaluation?.correction,
        detectedErrors: evaluation?.detectedErrors ?? [],
        scenarioComplete: false,
        nodeId: session.currentNodeId,
      );
    }
  }

  Future<_RoleplayEvaluation> _evaluateResponse({
    required RoleplaySession session,
    required LearnerSkillState state,
    required String learnerResponse,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You evaluate learner responses in a roleplay scenario.
Respond with JSON only:
{
  "isAppropriate": bool,
  "detectedErrors": [string],
  "correction": string or null,
  "shouldBranch": string ("continue" | "correct" | "simplify" | "advance"),
  "scenarioComplete": bool
}'''
            },
            {
              'role': 'user',
              'content': 'Scenario: ${session.scenario.description}\n'
                  'Expected response pattern: ${session.scenario.expectedPatterns.join(", ")}\n'
                  'Learner mastery: ${(state.mastery * 100).toStringAsFixed(0)}%\n'
                  'Learner response: "$learnerResponse"'
            },
          ],
          'temperature': 0.1,
          'max_tokens': 200,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      return _RoleplayEvaluation(
        isAppropriate: parsed['isAppropriate'] as bool? ?? true,
        detectedErrors: (parsed['detectedErrors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        correction: parsed['correction'] as String?,
        branchDirection: parsed['shouldBranch'] as String? ?? 'continue',
        scenarioComplete: parsed['scenarioComplete'] as bool? ?? false,
      );
    } catch (e) {
      return _RoleplayEvaluation(
        isAppropriate: true,
        detectedErrors: [],
        branchDirection: 'continue',
        scenarioComplete: false,
      );
    }
  }

  String _determineBranch(RoleplaySession session, _RoleplayEvaluation eval) {
    switch (eval.branchDirection) {
      case 'correct':
        return '${session.currentNodeId}_correction';
      case 'simplify':
        return '${session.currentNodeId}_simplified';
      case 'advance':
        return '${session.currentNodeId}_advanced';
      default:
        final turnNum = session.turns.length + 1;
        return 'turn_$turnNum';
    }
  }

  List<Map<String, String>> _buildOpeningPrompt(
    RoleplayScenario scenario,
    LearnerSkillState state,
  ) {
    return [
      {
        'role': 'system',
        'content': '''You are ${scenario.personaName}, ${scenario.personaDescription}.
Language: ${scenario.targetLanguage}.
Learner mastery: ${(state.mastery * 100).toStringAsFixed(0)}%.

RULES:
- Stay in character throughout.
- Force the learner to produce language, not just listen.
- Branch based on learner response quality.
- Never exceed 3 sentences per turn.
- Respond with JSON only:
{
  "dialogue": string (your character's line),
  "nextPrompt": string (what you want the learner to say/do),
  "correction": null,
  "branchReason": null,
  "detectedErrors": [],
  "scenarioComplete": false
}'''
      },
      {
        'role': 'user',
        'content': 'Start the scenario: ${scenario.description}'
      },
    ];
  }

  List<Map<String, String>> _buildContinuationPrompt(
    RoleplayScenario scenario,
    LearnerSkillState state,
    String history,
    String learnerResponse,
    _RoleplayEvaluation evaluation,
  ) {
    final correctionContext = evaluation.correction != null
        ? '\nCorrection needed: ${evaluation.correction}'
        : '';

    return [
      {
        'role': 'system',
        'content': '''You are ${scenario.personaName}, ${scenario.personaDescription}.
Continue the roleplay. Learner mastery: ${(state.mastery * 100).toStringAsFixed(0)}%.
$correctionContext

RULES:
- If correction is needed, address it briefly then continue the story.
- Force production from the learner.
- Branch: ${evaluation.branchDirection}.
- JSON only response (same schema as before).'''
      },
      {'role': 'user', 'content': 'History:\n$history\n\nLearner said: "$learnerResponse"'},
    ];
  }
}

/// A roleplay scenario definition.
class RoleplayScenario {
  final String id;
  final String title;
  final String description;
  final String personaName;
  final String personaDescription;
  final String targetLanguage;
  final List<String> targetSkillIds;
  final List<String> expectedPatterns;
  final String openingLine;
  final double difficulty;

  const RoleplayScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.personaName,
    required this.personaDescription,
    required this.targetLanguage,
    required this.targetSkillIds,
    this.expectedPatterns = const [],
    required this.openingLine,
    this.difficulty = 0.5,
  });
}

/// A single turn in a roleplay conversation.
class RoleplayTurn {
  final String dialogue;
  final String nextPrompt;
  final String? correction;
  final String? branchReason;
  final List<String> detectedErrors;
  final bool scenarioComplete;
  final String nodeId;

  const RoleplayTurn({
    required this.dialogue,
    required this.nextPrompt,
    this.correction,
    this.branchReason,
    required this.detectedErrors,
    required this.scenarioComplete,
    required this.nodeId,
  });
}

class RoleplaySession {
  final String learnerId;
  final String languageCode;
  final RoleplayScenario scenario;
  final List<RoleplayTurn> turns;
  String currentNodeId;

  RoleplaySession({
    required this.learnerId,
    required this.languageCode,
    required this.scenario,
    required this.turns,
    required this.currentNodeId,
  });
}

class RoleplaySessionSummary {
  final RoleplayScenario scenario;
  final int turnsCompleted;
  final List<String> errorsDetected;
  final bool isComplete;

  const RoleplaySessionSummary({
    required this.scenario,
    required this.turnsCompleted,
    required this.errorsDetected,
    required this.isComplete,
  });
}

class _RoleplayEvaluation {
  final bool isAppropriate;
  final List<String> detectedErrors;
  final String? correction;
  final String branchDirection;
  final bool scenarioComplete;

  const _RoleplayEvaluation({
    required this.isAppropriate,
    required this.detectedErrors,
    this.correction,
    required this.branchDirection,
    required this.scenarioComplete,
  });
}
