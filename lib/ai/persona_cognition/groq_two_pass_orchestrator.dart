// Pass result types only — LLM orchestration runs on the gateway (P6-018).

import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';

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
