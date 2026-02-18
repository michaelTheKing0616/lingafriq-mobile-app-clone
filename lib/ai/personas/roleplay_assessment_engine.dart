import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

/// Weights for final score: language 50%, historical 30%, opinion 20%.
const double kWeightLanguage = 0.50;
const double kWeightHistorical = 0.30;
const double kWeightOpinion = 0.20;

/// Structured report from post-session assessment.
///
/// Four dimensions (0–1 each): languageAccuracy (50% weight),
/// historicalAccuracy (30%), culturalPragmatics (part of language),
/// opinionJustification (20%).
class RoleplayAssessmentReport {
  final double finalScore;
  final Map<String, double> dimensionScores;
  final List<String> strengths;
  final List<String> improvementAreas;
  final String? suggestedNextPersona;
  final Map<String, double> skillUpdates;

  const RoleplayAssessmentReport({
    required this.finalScore,
    required this.dimensionScores,
    this.strengths = const [],
    this.improvementAreas = const [],
    this.suggestedNextPersona,
    this.skillUpdates = const {},
  });

  /// Backward compatibility: language accuracy from dimensionScores.
  double get languageAccuracy =>
      dimensionScores['languageAccuracy'] ?? 0.0;

  /// Historical accuracy from dimensionScores.
  double get historicalAccuracy =>
      dimensionScores['historicalAccuracy'] ?? 0.0;

  /// Cultural pragmatics from dimensionScores.
  double get culturalPragmatics =>
      dimensionScores['culturalPragmatics'] ?? 0.0;

  /// Opinion justification from dimensionScores.
  double get opinionJustification =>
      dimensionScores['opinionJustification'] ?? 0.0;
}

/// Post-session assessment engine: uses LLM to evaluate the full conversation
/// transcript, scores four dimensions, and produces [RoleplayAssessmentReport].
class RoleplayAssessmentEngine {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;

  RoleplayAssessmentEngine({
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

  /// Produces an assessment report from a completed session.
  /// Uses an LLM call to evaluate the full conversation transcript.
  Future<RoleplayAssessmentReport> generateReport(
    HistoricalRoleplayReport session,
  ) async {
    final transcript = _buildTranscript(session);
    Map<String, double> rawScores;
    List<String> strengths = [];
    List<String> improvementAreas = [];
    String? suggestedNextPersona;

    try {
      final result = await _evaluateWithLlm(
        transcript: transcript,
        personaId: session.personaId,
        languageCode: session.languageCode,
      );
      rawScores = result.scores;
      strengths = result.strengths;
      improvementAreas = result.improvementAreas;
      suggestedNextPersona = result.suggestedNextPersona;
    } catch (_) {
      rawScores = _inferScoresFromTurns(session.turns, session.contextMemory);
      improvementAreas = _defaultImprovementAreas(rawScores);
    }

    final language = rawScores['languageAccuracy'] ?? 0.5;
    final historical = rawScores['historicalAccuracy'] ?? 0.5;
    final cultural = rawScores['culturalPragmatics'] ?? 0.5;
    final opinion = rawScores['opinionJustification'] ?? 0.5;

    final finalScore = (language * kWeightLanguage +
            historical * kWeightHistorical +
            opinion * kWeightOpinion)
        .clamp(0.0, 1.0);

    final dimensionScores = <String, double>{
      'languageAccuracy': language,
      'historicalAccuracy': historical,
      'culturalPragmatics': cultural,
      'opinionJustification': opinion,
    };

    final skillId = 'historical_roleplay_${session.languageCode}';
    await _learnerModel.recordAttempt(
      learnerId: session.learnerId,
      skillId: skillId,
      wasCorrect: finalScore >= 0.6,
      errorTypeIds: finalScore < 0.6 ? ['roleplay_accuracy'] : [],
      responseTimeSeconds: 0,
    );

    final skillUpdates = <String, double>{
      skillId: finalScore,
    };

    return RoleplayAssessmentReport(
      finalScore: finalScore,
      dimensionScores: dimensionScores,
      strengths: strengths,
      improvementAreas: improvementAreas,
      suggestedNextPersona: suggestedNextPersona,
      skillUpdates: skillUpdates,
    );
  }

  String _buildTranscript(HistoricalRoleplayReport session) {
    final lines = <String>[];
    for (var i = 0; i < session.turns.length; i++) {
      final t = session.turns[i];
      lines.add('Persona: ${t.speechText}');
      if (t.teachingPoints.isNotEmpty) {
        lines.add('  [Teaching: ${t.teachingPoints.map((p) => p.content).join("; ")}]');
      }
    }
    if (session.contextMemory.isNotEmpty) {
      lines.add('Learner statements (context): ${session.contextMemory.join("; ")}');
    }
    return lines.join('\n');
  }

  Future<_LlmAssessmentResult> _evaluateWithLlm({
    required String transcript,
    required String personaId,
    required String languageCode,
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    final personaName = persona?.displayName ?? personaId;

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
            'content': '''You evaluate a historical roleplay conversation transcript.
Score the learner on four dimensions (0.0 to 1.0 each):
- languageAccuracy: grammar, vocabulary, fluency in the target language.
- historicalAccuracy: engagement with historically accurate facts and persona knowledge.
- culturalPragmatics: use of appropriate register, politeness, cultural norms.
- opinionJustification: when debating opinions, how well the learner justified with persona values.

Also return:
- strengths: list of 1-3 short strengths.
- improvementAreas: list of 1-3 short improvement areas.
- suggestedNextPersona: one persona id from the same region/language for next practice, or empty string.

Respond with JSON only:
{
  "languageAccuracy": number,
  "historicalAccuracy": number,
  "culturalPragmatics": number,
  "opinionJustification": number,
  "strengths": ["string"],
  "improvementAreas": ["string"],
  "suggestedNextPersona": "string"
}'''
          },
          {
            'role': 'user',
            'content': 'Persona: $personaName. Language: $languageCode.\n\nTranscript:\n$transcript'
          },
        ],
        'temperature': 0.2,
        'max_tokens': 400,
        'response_format': {'type': 'json_object'},
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    final json = _parseJson(content);
    if (json.isEmpty) throw Exception('Empty LLM assessment response');

    final scores = <String, double>{
      'languageAccuracy': _toScore(json['languageAccuracy']),
      'historicalAccuracy': _toScore(json['historicalAccuracy']),
      'culturalPragmatics': _toScore(json['culturalPragmatics']),
      'opinionJustification': _toScore(json['opinionJustification']),
    };
    final strengthsList = (json['strengths'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final improvementList = (json['improvementAreas'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final nextPersona = json['suggestedNextPersona'] as String?;
    final nextPersonaTrimmed =
        (nextPersona != null && nextPersona.trim().isNotEmpty)
            ? nextPersona.trim()
            : null;

    return _LlmAssessmentResult(
      scores: scores,
      strengths: strengthsList,
      improvementAreas: improvementList,
      suggestedNextPersona: nextPersonaTrimmed,
    );
  }

  double _toScore(dynamic v) {
    if (v == null) return 0.5;
    if (v is num) return (v.toDouble()).clamp(0.0, 1.0);
    if (v is String) return (double.tryParse(v) ?? 0.5).clamp(0.0, 1.0);
    return 0.5;
  }

  Map<String, dynamic> _parseJson(String raw) {
    final trimmed = raw.trim();
    try {
      final out = jsonDecode(trimmed);
      if (out is Map<String, dynamic>) return out;
    } catch (_) {}
    final braceStart = trimmed.indexOf('{');
    final braceEnd = trimmed.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      try {
        final out = jsonDecode(trimmed.substring(braceStart, braceEnd + 1));
        if (out is Map<String, dynamic>) return out;
      } catch (_) {}
    }
    return {};
  }

  Map<String, double> _inferScoresFromTurns(
    List<HistoricalRoleplayTurn> turns,
    List<String> contextMemory,
  ) {
    if (turns.isEmpty) {
      return {
        'languageAccuracy': 0.5,
        'historicalAccuracy': 0.5,
        'culturalPragmatics': 0.5,
        'opinionJustification': 0.5,
      };
    }
    final language = _inferLanguageAccuracy(turns);
    final historical = _inferHistoricalAccuracy(turns);
    final cultural = _inferCulturalPragmatics(turns);
    final opinion = _inferOpinionJustification(turns, contextMemory);
    return {
      'languageAccuracy': language,
      'historicalAccuracy': historical,
      'culturalPragmatics': cultural,
      'opinionJustification': opinion,
    };
  }

  double _inferLanguageAccuracy(List<HistoricalRoleplayTurn> turns) {
    final total = turns.length;
    if (total == 0) return 0.5;
    final errorTurns = turns.where((t) => t.detectedErrors.isNotEmpty).length;
    final withTeaching = turns.where((t) => t.teachingPoints.isNotEmpty).length;
    final accuracy = 1.0 - (errorTurns / total) * 0.5;
    final bonus = (withTeaching / total) * 0.2;
    return (accuracy + bonus).clamp(0.0, 1.0);
  }

  double _inferHistoricalAccuracy(List<HistoricalRoleplayTurn> turns) {
    final total = turns.length;
    if (total == 0) return 0.5;
    final withCitations =
        turns.where((t) => t.historicalCitations.isNotEmpty).length;
    return (0.5 + 0.5 * (withCitations / total)).clamp(0.0, 1.0);
  }

  double _inferCulturalPragmatics(List<HistoricalRoleplayTurn> turns) {
    final total = turns.length;
    if (total == 0) return 0.5;
    final withPragmatics = turns
        .where((t) => t.teachingPoints.any((p) => p.type == 'pragmatics'))
        .length;
    return (0.4 + 0.6 * (withPragmatics / total)).clamp(0.0, 1.0);
  }

  double _inferOpinionJustification(
    List<HistoricalRoleplayTurn> turns,
    List<String> contextMemory,
  ) {
    if (turns.isEmpty) return 0.5;
    return (0.5 + 0.1 * turns.length.clamp(0, 5)).clamp(0.0, 1.0);
  }

  List<String> _defaultImprovementAreas(Map<String, double> scores) {
    final areas = <String>[];
    if ((scores['languageAccuracy'] ?? 0.5) < 0.7) {
      areas.add('Practice grammar and vocabulary in short dialogues.');
    }
    if ((scores['historicalAccuracy'] ?? 0.5) < 0.7) {
      areas.add('Review the persona\'s timeline and documented positions.');
    }
    if ((scores['culturalPragmatics'] ?? 0.5) < 0.7) {
      areas.add('Use more culturally appropriate phrasing and register.');
    }
    if ((scores['opinionJustification'] ?? 0.5) < 0.7) {
      areas.add('Justify opinions with the persona\'s documented values.');
    }
    return areas;
  }
}

class _LlmAssessmentResult {
  final Map<String, double> scores;
  final List<String> strengths;
  final List<String> improvementAreas;
  final String? suggestedNextPersona;

  _LlmAssessmentResult({
    required this.scores,
    required this.strengths,
    required this.improvementAreas,
    this.suggestedNextPersona,
  });
}
