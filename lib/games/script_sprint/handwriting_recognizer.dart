/// On-device stroke recognition for Script Sprint (P8-927). No network egress.
library;

import 'package:flutter/material.dart';
import 'package:lingafriq/lessons/handwriting_practice.dart';
import 'package:lingafriq/lessons/stroke_order_view.dart';

/// Default match threshold for flight rounds (re-tunable via tests).
const double kScriptSprintMatchThreshold = 0.48;

class ScriptSprintRecognition {
  const ScriptSprintRecognition({
    required this.state,
    required this.confidence,
  });

  final HandwritingUiState state;
  final double confidence;

  bool get isRecognized => state == HandwritingUiState.recognized;
  bool get isUnsure => state == HandwritingUiState.unsure;
}

ScriptSprintRecognition recognizeScriptSprintStroke({
  required List<Offset> points,
  required String character,
  required StrokeCatalog catalog,
  double matchThreshold = kScriptSprintMatchThreshold,
}) {
  final result = recognizeHandwriting(
    attempt: HandwritingAttempt(points: points),
    character: character,
    catalog: catalog,
    matchThreshold: matchThreshold,
  );
  final confidence = _confidenceFromResult(result, points.length);
  return ScriptSprintRecognition(state: result.state, confidence: confidence);
}

double _confidenceFromResult(
  HandwritingRecognitionResult result,
  int pointCount,
) {
  switch (result.state) {
    case HandwritingUiState.recognized:
      return 0.92;
    case HandwritingUiState.mismatch:
      return 0.35;
    case HandwritingUiState.unsure:
      return pointCount < 8 ? 0.2 : 0.45;
    case HandwritingUiState.unavailable:
      return 0;
    case HandwritingUiState.drawing:
      return 0;
  }
}

bool scriptSprintConfidenceAccepts(ScriptSprintRecognition recognition) {
  return recognition.isRecognized &&
      recognition.confidence >= kScriptSprintMatchThreshold;
}
