import 'package:lingafriq/content/lingafriq_ux_voice.dart';

/// Shared Polie correction payload (blueprint §99).
class CorrectionResult {
  final String tier;
  final bool hasCorrection;
  final bool wasCorrect;
  final String? correction;
  final String note;

  const CorrectionResult({
    required this.tier,
    required this.hasCorrection,
    required this.wasCorrect,
    this.correction,
    this.note = '',
  });

  factory CorrectionResult.fromJson(Map<String, dynamic> json) {
    final tier = (json['tier'] as String?)?.trim().toLowerCase();
    final wasCorrect = json['was_correct'] as bool? ?? true;
    final resolvedTier = tier?.isNotEmpty == true
        ? tier!
        : (wasCorrect ? 'correct' : 'incorrect');
    return CorrectionResult(
      tier: resolvedTier,
      hasCorrection: json['has_correction'] as bool? ?? false,
      wasCorrect: wasCorrect,
      correction: (json['correction'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['correction'] as String?,
      note: (json['note'] as String?) ?? '',
    );
  }

  String uxFeedbackLine() {
    switch (tier) {
      case 'close':
        return LingAfriqUxVoice.quizFeedback(isCorrect: false, nearMiss: true);
      case 'incorrect':
        return LingAfriqUxVoice.quizFeedback(isCorrect: false, nearMiss: false);
      case 'correct':
      default:
        return LingAfriqUxVoice.quizFeedback(isCorrect: true);
    }
  }
}
