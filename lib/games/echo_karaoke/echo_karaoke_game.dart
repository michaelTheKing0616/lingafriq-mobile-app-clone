/// Echo Karaoke round logic (P8-929).
library;

import 'dart:math';

import '../../learning/pronunciation/tone_models.dart';
import '../talking_drum/talking_drum_game.dart';
import 'song_catalog.dart';

class EchoRoundScores {
  const EchoRoundScores({
    required this.rhythm,
    required this.tone,
    required this.fluency,
    required this.practiceOnly,
  });

  final double rhythm;
  final double tone;
  final double fluency;
  final bool practiceOnly;
}

/// Target pitch contour (0–1) for the piece.
List<double> targetContourForPiece(
  EchoKaraokePiece piece,
  ToneLanguageModel model,
) {
  return drumContourFromTonePattern(piece.tonePattern, model);
}

/// Mean absolute error between two equal-length normalised contours.
double pitchAlignmentScore({
  required List<double> target,
  required List<double> learner,
}) {
  if (target.isEmpty || learner.isEmpty) return 0;
  final n = min(target.length, learner.length);
  if (n == 0) return 0;
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    sum += (target[i] - learner[i]).abs();
  }
  final mae = sum / n;
  return (1.0 - mae).clamp(0.0, 1.0);
}

/// Resample [learner] to [targetLength] by linear interpolation.
List<double> resampleContour(List<double> learner, int targetLength) {
  if (targetLength <= 0) return const [];
  if (learner.isEmpty) {
    return List<double>.filled(targetLength, 0.5, growable: false);
  }
  if (learner.length == targetLength) {
    return learner.map((v) => v.clamp(0.0, 1.0)).toList(growable: false);
  }
  final out = <double>[];
  for (var i = 0; i < targetLength; i++) {
    final t = targetLength == 1 ? 0.0 : i / (targetLength - 1);
    final src = t * (learner.length - 1);
    final lo = src.floor().clamp(0, learner.length - 1);
    final hi = src.ceil().clamp(0, learner.length - 1);
    final frac = src - lo;
    final v = learner[lo] * (1 - frac) + learner[hi] * frac;
    out.add(v.clamp(0.0, 1.0));
  }
  return out;
}

/// Maps gateway scorer accuracy into rhythm / tone / fluency display buckets (AC3).
EchoRoundScores scoresFromScorerAccuracy({
  required double accuracy,
  required bool practiceOnly,
}) {
  final a = accuracy.clamp(0.0, 1.0);
  final tone = a;
  final rhythm = (a * 0.92 + 0.04).clamp(0.0, 1.0);
  final fluency = (a * 0.88 + 0.06).clamp(0.0, 1.0);
  return EchoRoundScores(
    rhythm: rhythm,
    tone: tone,
    fluency: fluency,
    practiceOnly: practiceOnly,
  );
}

/// Append a live sample during capture (amplitude proxy until scorer returns F0).
List<double> appendLivePitchSample({
  required List<double> samples,
  required double normalisedAmplitude,
  required List<double> targetAtPlayhead,
  int maxSamples = 120,
}) {
  final anchor = targetAtPlayhead.isEmpty
      ? 0.5
      : targetAtPlayhead[targetAtPlayhead.length ~/ 2];
  final jitter = (normalisedAmplitude - 0.5) * 0.35;
  final next = (anchor + jitter).clamp(0.0, 1.0);
  final updated = [...samples, next];
  if (updated.length > maxSamples) {
    return updated.sublist(updated.length - maxSamples);
  }
  return updated;
}

int playheadIndexForProgress({
  required double progress,
  required int syllableCount,
}) {
  if (syllableCount <= 1) return 0;
  final p = progress.clamp(0.0, 1.0);
  return (p * (syllableCount - 1)).round().clamp(0, syllableCount - 1);
}
