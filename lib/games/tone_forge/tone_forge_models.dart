/// ToneForge game models
class ToneForgeContent {
  final String text;
  final List<double> targetPitchContour;
  final String? audioUrl;
  final String? ipa;
  final double pitchTolerance;
  final double timingTolerance;
  final String? culturalContext;
  final String contentId;

  ToneForgeContent({
    required this.text,
    required this.targetPitchContour,
    this.audioUrl,
    this.ipa,
    required this.pitchTolerance,
    required this.timingTolerance,
    this.culturalContext,
    required this.contentId,
  });

  factory ToneForgeContent.fromPolieContent(Map<String, dynamic> polieData) {
    return ToneForgeContent(
      text: polieData['text'] as String? ?? '',
      targetPitchContour: polieData['tones'] != null
          ? List<double>.from(polieData['tones'] as List)
          : [],
      audioUrl: polieData['audio_url'] as String?,
      ipa: polieData['ipa'] as String?,
      pitchTolerance: (polieData['scoring_rules']?['pitch_tolerance'] as num?)?.toDouble() ?? 0.15,
      timingTolerance: (polieData['scoring_rules']?['timing_tolerance'] as num?)?.toDouble() ?? 0.2,
      culturalContext: polieData['cultural_context'] as String?,
      contentId: polieData['content_id'] as String? ?? '',
    );
  }
}

class ToneForgeInput {
  final List<double> userPitchContour;
  final List<double>? audioSamples;
  final int durationMs;

  ToneForgeInput({
    required this.userPitchContour,
    this.audioSamples,
    required this.durationMs,
  });
}

