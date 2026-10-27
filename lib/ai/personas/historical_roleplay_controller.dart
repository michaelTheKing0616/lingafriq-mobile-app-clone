import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/validation/response_validator.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';

/// Engagement type for historical roleplay sessions.
enum HistoricalEngagementType {
  storyMode,
  freeConversation,
  opinionDebate,
}

/// Teaching point in a historical roleplay turn.
class TeachingPoint {
  final String type; // vocabulary | grammar | pragmatics
  final String content;

  const TeachingPoint({required this.type, required this.content});

  factory TeachingPoint.fromJson(Map<String, dynamic> json) {
    return TeachingPoint(
      type: json['type'] as String? ?? 'vocabulary',
      content: json['content'] as String? ?? '',
    );
  }
}

/// Historical citation in a turn.
class HistoricalCitation {
  final String source;
  final String relevance;

  const HistoricalCitation({required this.source, required this.relevance});

  factory HistoricalCitation.fromJson(Map<String, dynamic> json) {
    return HistoricalCitation(
      source: json['source'] as String? ?? '',
      relevance: json['relevance'] as String? ?? '',
    );
  }
}

/// Extended turn with teaching points, citations, and emotion.
class HistoricalRoleplayTurn {
  final String speechText;
  final List<TeachingPoint> teachingPoints;
  final String emotionTone;
  final List<HistoricalCitation> historicalCitations;
  final String nextState;
  final List<String> closureOptions;
  final List<String> detectedErrors;

  const HistoricalRoleplayTurn({
    required this.speechText,
    this.teachingPoints = const [],
    this.emotionTone = 'calm',
    this.historicalCitations = const [],
    required this.nextState,
    this.closureOptions = const [],
    this.detectedErrors = const [],
  });
}

/// Session with context memory for continuity within the session.
class HistoricalRoleplaySession {
  final String sessionId;
  final String learnerId;
  final String languageCode;
  final String personaId;
  final HistoricalEngagementType engagementType;
  final List<HistoricalRoleplayTurn> turns;
  final List<String> contextMemory;
  String currentNodeId;

  HistoricalRoleplaySession({
    required this.sessionId,
    required this.learnerId,
    required this.languageCode,
    required this.personaId,
    required this.engagementType,
    List<HistoricalRoleplayTurn>? turns,
    List<String>? contextMemory,
    this.currentNodeId = 'start',
  })  : turns = turns ?? [],
        contextMemory = contextMemory ?? [];
}

/// Session report for assessment: summary of a completed or active session.
class HistoricalRoleplayReport {
  final String sessionId;
  final String learnerId;
  final String languageCode;
  final String personaId;
  final HistoricalEngagementType engagementType;
  final List<HistoricalRoleplayTurn> turns;
  final List<String> contextMemory;

  const HistoricalRoleplayReport({
    required this.sessionId,
    required this.learnerId,
    required this.languageCode,
    required this.personaId,
    required this.engagementType,
    required this.turns,
    required this.contextMemory,
  });
}

/// Main controller: bridges persona registry with roleplay engine.
///
/// Injects persona behavior, documented positions, and (for opinion_debate)
/// opinion inference matrix into prompts. Enforces JSON response schema
/// and updates learner model after each turn.
class HistoricalRoleplayController {
  final AiGatewayClient _gateway;
  final String _model;
  final LearnerModelService _learnerModel;

  final Map<String, HistoricalRoleplaySession> _sessions = {};

  static const int _maxContextStatements = 10;
  static const int _maxTurnsBeforeClosure = 25;

  HistoricalRoleplayController({
    required AiGatewayClient gateway,
    String model = 'llama-3.3-70b-versatile',
    LearnerModelService? learnerModel,
  })  : _gateway = gateway,
        _model = model,
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Starts a new historical roleplay session. Returns the opening turn.
  Future<HistoricalRoleplayTurn> startPersonaSession({
    required String learnerId,
    required String languageCode,
    required String personaId,
    required HistoricalEngagementType engagementType,
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) {
      throw StateError('Persona not found: $personaId');
    }

    final sessionId =
        '${learnerId}_${personaId}_${DateTime.now().millisecondsSinceEpoch}';
    final session = HistoricalRoleplaySession(
      sessionId: sessionId,
      learnerId: learnerId,
      languageCode: languageCode,
      personaId: personaId,
      engagementType: engagementType,
      turns: [],
      contextMemory: [],
      currentNodeId: 'start',
    );
    _sessions[learnerId] = session;

    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : languageCode;
    final skillId = 'historical_roleplay_$language';
    final state =
        _learnerModel.getState(learnerId: learnerId, skillId: skillId);

    final turn = await _generateTurn(
      session: session,
      persona: persona,
      state: state,
      isOpening: true,
      userMessage: null,
    );
    session.turns.add(turn);
    return turn;
  }

  /// Processes the learner's message and returns the next persona turn.
  /// Updates learner model via [LearnerModelService.recordAttempt].
  Future<HistoricalRoleplayTurn> processLearnerResponse({
    required String learnerId,
    required String response,
    double responseTimeSeconds = 0,
  }) async {
    final session = _sessions[learnerId];
    if (session == null) {
      throw StateError(
          'No active historical roleplay session for learner $learnerId');
    }

    final persona = HistoricalPersonaRegistry.findById(session.personaId);
    if (persona == null) {
      throw StateError('Persona not found: ${session.personaId}');
    }

    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : session.languageCode;
    final skillId = 'historical_roleplay_$language';
    final state =
        _learnerModel.getState(learnerId: learnerId, skillId: skillId);

    final turn = await _generateTurn(
      session: session,
      persona: persona,
      state: state,
      isOpening: false,
      userMessage: response,
    );
    _addToContextMemory(session, response);
    session.turns.add(turn);
    session.currentNodeId = turn.nextState;

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: turn.detectedErrors.isEmpty,
      errorTypeIds: turn.detectedErrors,
      responseTimeSeconds: responseTimeSeconds,
    );

    if (session.turns.length >= _maxTurnsBeforeClosure) {
      _sessions.remove(learnerId);
    }

    return turn;
  }

  /// Returns a report for the current session, or null if none.
  HistoricalRoleplayReport? getSessionReport(String learnerId) {
    final session = _sessions[learnerId];
    if (session == null) return null;
    return HistoricalRoleplayReport(
      sessionId: session.sessionId,
      learnerId: session.learnerId,
      languageCode: session.languageCode,
      personaId: session.personaId,
      engagementType: session.engagementType,
      turns: List.from(session.turns),
      contextMemory: List.from(session.contextMemory),
    );
  }

  /// Ends the session for the learner.
  void endSession(String learnerId) {
    _sessions.remove(learnerId);
  }

  void _addToContextMemory(HistoricalRoleplaySession session, String statement) {
    session.contextMemory.add(statement);
    while (session.contextMemory.length > _maxContextStatements) {
      session.contextMemory.removeAt(0);
    }
  }

  Future<HistoricalRoleplayTurn> _generateTurn({
    required HistoricalRoleplaySession session,
    required HistoricalPersona persona,
    required LearnerSkillState state,
    required bool isOpening,
    String? userMessage,
  }) async {
    final messages =
        _buildMessages(session, persona, state, isOpening, userMessage);

    final data = await _gateway.completeChat(
      messages: messages,
      mode: 'roleplay',
      temperature: 0.35,
      maxTokens: 500,
      model: _model,
    );
    final content = _gateway.extractContent(data);
    final parsed = ResponseValidator.validateHistoricalRoleplayResponse(content);

    final teachingRaw = parsed['language_teaching_points'] as List<dynamic>? ??
        parsed['teaching_points'] as List<dynamic>?;
    final teachingPoints = teachingRaw
            ?.map((e) => TeachingPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final citations = (parsed['historical_citations'] as List<dynamic>?)
            ?.map((e) => HistoricalCitation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final closureOptions = (parsed['closure_options'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final nextState = parsed['next_beat'] as String? ??
        parsed['next_state'] as String? ??
        parsed['conversation_state'] as String? ??
        'turn_${session.turns.length + 1}';

    final emotion = parsed['emotion'] as String? ??
        parsed['emotion_tone'] as String? ??
        'neutral';

    return HistoricalRoleplayTurn(
      speechText: parsed['speech_text'] as String,
      teachingPoints: teachingPoints,
      emotionTone: emotion,
      historicalCitations: citations,
      nextState: nextState,
      closureOptions: closureOptions,
      detectedErrors: _parseDetectedErrors(parsed),
    );
  }

  List<String> _parseDetectedErrors(Map<String, dynamic> parsed) {
    final list = parsed['detectedErrors'] ?? parsed['detected_errors'];
    if (list == null || list is! List) return [];
    return list.map((e) => e.toString()).toList();
  }

  List<Map<String, String>> _buildMessages(
    HistoricalRoleplaySession session,
    HistoricalPersona persona,
    LearnerSkillState state,
    bool isOpening,
    String? userMessage,
  ) {
    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : session.languageCode;
    final coreEventsStr = persona.coreEvents
        .take(10)
        .map((e) => '${e.year}: ${e.event}')
        .join('; ');
    final positionsStr = persona.documentedPositions.entries
        .take(10)
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
    final behaviorProfile =
        'openness ${persona.openness}, formality ${persona.formality}, humor ${persona.humorLevel}. '
        'Voice: ${persona.voiceStyle}, pace ${persona.pace}, tone ${persona.tone}. '
        'Emotion range: ${persona.emotionRange.join(", ")}.';

    String systemContent = '''You are ${persona.displayName} in a historical roleplay. Target language: $language.
Bio: ${persona.shortBio}

BEHAVIOR AND TONE: $behaviorProfile
CORE EVENTS YOU KNOW: $coreEventsStr
DOCUMENTED POSITIONS (stay consistent): $positionsStr

LANGUAGE TEACHING: Use vocabulary: ${persona.commonVocabulary.take(8).join(", ")}. Grammar patterns: ${persona.grammarPatterns.take(5).join("; ")}. Cultural pragmatics: ${persona.culturalPragmatics.take(5).join("; ")}.

Engagement mode: ${session.engagementType.name}.

RULES:
- Stay in character. Do not reference being an AI.
- When discussing topics not in your documented positions, indicate uncertainty where appropriate.
- TEACHING POINTS ARE MANDATORY: every response must include at least one teaching_points entry (vocabulary, grammar, or pragmatics).
- Respond with JSON only. Schema (P11-003):
{
  "speech_text": "your in-character response",
  "language_teaching_points": [{"type": "vocabulary|grammar|pragmatics", "content": "brief teaching note"}],
  "claims": [{"text": "factual claim", "support": "documented|inferred|legend", "source_ids": []}],
  "emotion": "neutral|happy|proud|curious|concerned|surprised|thinking|encouraging|playful|focused",
  "next_beat": "string"
}''';

    if (session.engagementType == HistoricalEngagementType.opinionDebate &&
        persona.opinionInferenceMatrix.isNotEmpty) {
      final matrixStr = persona.opinionInferenceMatrix.entries
          .map((e) =>
              '${e.key}: basis ${e.value.inferenceBasis.join(", ")} (confidence ${e.value.confidence})')
          .join('; ');
      systemContent += '\n\nOPINION DEBATE — infer only from documented positions. Opinion inference matrix (use confidence): $matrixStr';
    }

    final historyLines = <String>[];
    for (final t in session.turns) {
      historyLines.add('Persona: ${t.speechText}');
    }
    if (session.contextMemory.isNotEmpty) {
      historyLines
          .add('Learner earlier: ${session.contextMemory.take(10).join("; ")}');
    }
    final learnerMastery = (state.mastery * 100).toStringAsFixed(0);
    final errorSummary = state.dominantErrorType != null
        ? 'Dominant error type: ${state.dominantErrorType}'
        : '';

    final contextPrompt =
        'Learner mastery (this skill): $learnerMastery%. $errorSummary';

    final userContent = isOpening
        ? 'Start the ${session.engagementType.name} roleplay. Greet the learner and set the scene in $language. $contextPrompt'
        : 'Conversation so far:\n${historyLines.join("\n")}\n\n$contextPrompt\n\nLearner just said: "$userMessage"';

    return [
      {'role': 'system', 'content': systemContent},
      {'role': 'user', 'content': userContent},
    ];
  }
}
