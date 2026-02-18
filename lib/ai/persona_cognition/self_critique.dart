/// Self-critique loop for persona response quality assurance.
/// Single LLM call: evaluate and optionally rewrite in one pass.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';

class SelfCritiqueResult {
  final bool passedCritique;
  final String? revisedReply;
  final List<String> issues;

  const SelfCritiqueResult({
    required this.passedCritique,
    this.revisedReply,
    this.issues = const [],
  });
}

class SelfCritique {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;

  SelfCritique({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model;

  /// Evaluates [personaReply] for persona consistency, historical plausibility,
  /// epistemic honesty, and safety. If issues found, returns revised reply.
  Future<SelfCritiqueResult> critique({
    required String personaReply,
    required HistoricalPersona persona,
    required EpistemicStatus epistemicStatus,
  }) async {
    final systemContent = '''You are a quality checker for historical persona responses. Single call only.

Evaluate the persona reply for:
1. Persona consistency (voice, values, documented positions)
2. Historical plausibility (no anachronisms, era-appropriate)
3. Epistemic honesty (if status is inferred/uncertain/anachronistic, reply must use uncertainty language)
4. Safety (no harmful content, no breaking character)

If ALL criteria pass: set "passed_critique" true, leave "revised_reply" null, put empty "issues" list.
If ANY criterion fails: set "passed_critique" false, list "issues", and provide "revised_reply" (corrected response).

Output strict JSON only:
{
  "passed_critique": true|false,
  "issues": ["issue1", "issue2"],
  "revised_reply": "corrected reply or null if passed"
}''';

    final userContent = '''Persona: ${persona.displayName} (${persona.startYear}-${persona.endYear}).
Documented positions (keys): ${persona.documentedPositions.keys.join(", ")}

Epistemic status for this turn: $epistemicStatus

Persona reply to evaluate:
"$personaReply"

Output JSON with passed_critique, issues, revised_reply.''';

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
            {'role': 'system', 'content': systemContent},
            {'role': 'user', 'content': userContent},
          ],
          'temperature': 0.2,
          'max_tokens': 600,
          'response_format': {'type': 'json_object'},
        },
      );

      final content =
          response.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        return const SelfCritiqueResult(passedCritique: true, issues: []);
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final passed = json['passed_critique'] as bool? ?? true;
      final issuesList = json['issues'] as List<dynamic>?;
      final issues =
          issuesList?.map((e) => e.toString()).toList() ?? <String>[];
      final revised = json['revised_reply'] as String?;

      return SelfCritiqueResult(
        passedCritique: passed,
        revisedReply: revised?.isNotEmpty == true ? revised : null,
        issues: issues,
      );
    } catch (_) {
      return const SelfCritiqueResult(passedCritique: true, issues: []);
    }
  }
}
