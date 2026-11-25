// Pass result types only — LLM orchestration runs on the gateway (P6-018 / P11-008).

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';

/// Typed failure from POST /api/ai/persona/historical-roleplay/turn (no silent fallback).
class PersonaTurnGatewayError implements Exception {
  const PersonaTurnGatewayError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  bool get retryable =>
      statusCode == null || statusCode! >= 500 || statusCode == 429;

  static PersonaTurnGatewayError fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String code = 'persona_gateway_unavailable';
    String message = 'The persona could not reply. Try again.';
    if (data is Map) {
      final err = data['error']?.toString();
      if (err != null && err.isNotEmpty) code = err;
      final reason = data['reason']?.toString();
      if (reason != null && reason.isNotEmpty) {
        message = reason;
      }
    }
    return PersonaTurnGatewayError(
      code: code,
      message: message,
      statusCode: status,
    );
  }

  static PersonaTurnGatewayError fromResponse(int? status, Map<String, dynamic>? data) {
    final code = data?['error']?.toString() ?? 'persona_gateway_failed';
    final reason = data?['reason']?.toString();
    return PersonaTurnGatewayError(
      code: code,
      message: reason ?? 'The persona could not reply. Try again.',
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}

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
