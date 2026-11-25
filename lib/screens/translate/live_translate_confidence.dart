/// P6-030: confidence mapping for live translate (mirrors gateway liveTranslate.ts).
library;

const double liveTranslateLowConfidenceThreshold = 0.62;
const double liveTranslateHighConfidenceThreshold = 0.82;

enum LiveTranslateConfidenceBand { high, medium, low }

enum LiveTranslateInputKind { voice, camera }

class LiveTranslateConfidenceView {
  const LiveTranslateConfidenceView({
    required this.score,
    required this.band,
    required this.labelKey,
  });

  final double score;
  final LiveTranslateConfidenceBand band;
  final String labelKey;
}

LiveTranslateConfidenceView mapLiveTranslateConfidence({
  double? sttConfidence,
  required String sourceText,
  required bool isFinal,
  LiveTranslateInputKind inputKind = LiveTranslateInputKind.voice,
}) {
  final trimmed = sourceText.trim();
  double score = (sttConfidence != null && sttConfidence.isFinite)
      ? sttConfidence.clamp(0.0, 1.0)
      : (inputKind == LiveTranslateInputKind.camera ? 0.58 : 0.5);

  if (trimmed.length < 2) {
    score = score < 0.35 ? score : 0.35;
  } else if (trimmed.length < 6) {
    score = score < 0.55 ? score : 0.55;
  }

  if (!isFinal) {
    score = score < liveTranslateHighConfidenceThreshold - 0.05
        ? score
        : liveTranslateHighConfidenceThreshold - 0.05;
  }

  final band = confidenceBandForScore(score);
  return LiveTranslateConfidenceView(
    score: score,
    band: band,
    labelKey: confidenceLabelKey(band),
  );
}

LiveTranslateConfidenceBand confidenceBandForScore(double score) {
  final s = score.clamp(0.0, 1.0);
  if (s < liveTranslateLowConfidenceThreshold) {
    return LiveTranslateConfidenceBand.low;
  }
  if (s >= liveTranslateHighConfidenceThreshold) {
    return LiveTranslateConfidenceBand.high;
  }
  return LiveTranslateConfidenceBand.medium;
}

String confidenceLabelKey(LiveTranslateConfidenceBand band) {
  switch (band) {
    case LiveTranslateConfidenceBand.high:
      return 'live.confidence_high';
    case LiveTranslateConfidenceBand.medium:
      return 'live.confidence_medium';
    case LiveTranslateConfidenceBand.low:
      return 'live.confidence_low';
  }
}

String confidenceDisplayLabel(LiveTranslateConfidenceBand band) {
  switch (band) {
    case LiveTranslateConfidenceBand.high:
      return 'High confidence';
    case LiveTranslateConfidenceBand.medium:
      return 'Medium confidence';
    case LiveTranslateConfidenceBand.low:
      return 'Low confidence — double-check this translation';
  }
}
