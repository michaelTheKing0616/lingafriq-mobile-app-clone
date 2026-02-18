// Two-pass LLM orchestration: Pass 1 = hidden reasoning, Pass 2 = user-facing response.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';

class Pass1Result {
  final EpistemicStatus epistemicStatus;
  final String reasoningNotes;
  final double confidence;
  final List<String> personaAlignmentIssues;

  const Pass1Result({
    required this.epistemicStatus,
    required this.reasoningNotes,
    required this.confidence,
    this.personaAlignmentIssues = const [],
  });

  factory Pass1Result.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['epistemic_status'] as String? ?? 'uncertain')
        .toLowerCase()
        .replaceAll('_', '');
    EpistemicStatus status = EpistemicStatus.uncertain;
    for (final e in EpistemicStatus.values) {
      if (e.name.toLowerCase().replaceAll('_', '') == statusStr) {
        status = e;
        break;
      }
    }
    final issues = (json['persona_alignment_issues'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return Pass1Result(
      epistemicStatus: status,
      reasoningNotes: json['reasoning_notes'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      personaAlignmentIssues: issues,
    );
  }
}

class GroqTwoPassOrchestrator {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;

  GroqTwoPassOrchestrator({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model;

  /// Pass 1: Hidden internal reasoning (NOT shown to user).
  Future<Pass1Result> runPass1({
    required String userInput,
    required HistoricalPersona persona,
    required EpistemicClassification epistemic,
    required IntentClassification intent,
  }) async {
    final coreEventsStr = persona.coreEvents
        .take(10)
        .map((e) => '${e.year}: ${e.event}')
        .join('; ');
    final positionsStr = persona.documentedPositions.entries
        .take(10)
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
    final matrixStr = persona.opinionInferenceMatrix.entries
        .map((e) =>
            '${e.key}: basis ${e.value.inferenceBasis.join(", ")} (confidence ${e.value.confidence})')
        .join('; ');

    const systemContent = '''You are an internal reasoning engine for a historical persona. Your output is NEVER shown to the user.

Your job:
1. Reason about the user's input from a global perspective.
2. Filter that reasoning through what this specific historical persona can plausibly know (documented positions, inferred opinions, era).
3. Output strict JSON only.

Use epistemic_status: documented | inferred | uncertain | anachronistic | outOfScope.
Set confidence (0.0-1.0). List any persona_alignment_issues (e.g. anachronism, topic outside knowledge).''';

    final userContent = '''Persona: ${persona.displayName} (${persona.startYear}-${persona.endYear}).
Core events: $coreEventsStr
Documented positions: $positionsStr
Opinion inference matrix: $matrixStr

Epistemic classification: ${epistemic.status.name} (${epistemic.reasoning})
User intent: ${intent.domain.name} / ${intent.type.name}
User input: "$userInput"

Output JSON:
{
  "epistemic_status": "documented|inferred|uncertain|anachronistic|outOfScope",
  "reasoning_notes": "brief internal notes",
  "confidence": 0.0-1.0,
  "persona_alignment_issues": ["issue1", "issue2"]
}''';

    final response = await _dio.post(
      _apiUrl,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemContent},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.2,
        'max_tokens': 500,
        'response_format': {'type': 'json_object'},
      },
    );

    final content = response.data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) {
      return Pass1Result(
        epistemicStatus: epistemic.status,
        reasoningNotes: epistemic.reasoning,
        confidence: epistemic.confidence,
        personaAlignmentIssues: [],
      );
    }

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Pass1Result.fromJson(json);
    } catch (_) {
      return Pass1Result(
        epistemicStatus: epistemic.status,
        reasoningNotes: epistemic.reasoning,
        confidence: epistemic.confidence,
        personaAlignmentIssues: [],
      );
    }
  }

  /// Pass 2: User-facing persona response.
  Future<Map<String, dynamic>> runPass2({
    required String userInput,
    required HistoricalPersona persona,
    required Pass1Result pass1,
    required double learnerMastery,
    List<String> conversationHistory = const [],
  }) async {
    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : 'English';
    final behaviorProfile =
        'openness ${persona.openness}, formality ${persona.formality}, humor ${persona.humorLevel}. '
        'Voice: ${persona.voiceStyle}, pace ${persona.pace}, tone ${persona.tone}. '
        'Emotion range: ${persona.emotionRange.join(", ")}.';
    final coreEventsStr = persona.coreEvents
        .take(10)
        .map((e) => '${e.year}: ${e.event}')
        .join('; ');
    final positionsStr = persona.documentedPositions.entries
        .take(10)
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');

    final systemContent = '''You are roleplaying as ${persona.displayName} in a historical language-learning context.

Bio: ${persona.shortBio}
BEHAVIOR AND TONE: $behaviorProfile
CORE EVENTS YOU KNOW: $coreEventsStr
DOCUMENTED POSITIONS (stay consistent): $positionsStr

INTERNAL REASONING (from Pass 1 - use to stay consistent, do not expose verbatim):
Epistemic status: ${pass1.epistemicStatus.name}
Reasoning notes: ${pass1.reasoningNotes}
Persona alignment issues: ${pass1.personaAlignmentIssues.join("; ")}

Target language: $language. Learner mastery: ${(learnerMastery * 100).toStringAsFixed(0)}%.

RULES:
- Stay in character. Do not reference being an AI.
- When epistemic status is inferred/uncertain/anachronistic, use uncertainty language (e.g. "I would have thought...", "In my time we did not...").
- Include at least one teaching_points entry (vocabulary, grammar, or pragmatics).
- Respond with JSON only. Schema:
{
  "persona_reply": "your in-character response in $language",
  "epistemic_status": "documented|inferred|uncertain|anachronistic|outOfScope",
  "confidence": 0.0-1.0,
  "language_feedback": [{"type": "grammar|vocabulary|pragmatics", "note": "brief teaching note"}],
  "cultural_note": "optional one sentence",
  "historical_citations": [{"source": "string", "relevance": "string"}],
  "emotion_tone": "string"
}''';

    final historyBlock = conversationHistory.isEmpty
        ? ''
        : 'Conversation so far:\n${conversationHistory.join("\n")}\n\n';
    final userContent = '${historyBlock}Learner said: "$userInput"';

    final response = await _dio.post(
      _apiUrl,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemContent},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.35,
        'max_tokens': 500,
        'response_format': {'type': 'json_object'},
      },
    );

    final content = response.data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) {
      return {
        'persona_reply': '${persona.displayName} nods thoughtfully. (Response unavailable.)',
        'epistemic_status': pass1.epistemicStatus.name,
        'confidence': pass1.confidence,
        'language_feedback': <Map<String, dynamic>>[],
        'cultural_note': null,
        'historical_citations': <Map<String, dynamic>>[],
        'emotion_tone': 'calm',
      };
    }

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json;
    } catch (_) {
      return {
        'persona_reply': '${persona.displayName} responds with warmth. (Parse error.)',
        'epistemic_status': pass1.epistemicStatus.name,
        'confidence': pass1.confidence,
        'language_feedback': <Map<String, dynamic>>[],
        'cultural_note': null,
        'historical_citations': <Map<String, dynamic>>[],
        'emotion_tone': 'calm',
      };
    }
  }
}
