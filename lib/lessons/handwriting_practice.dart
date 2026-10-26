/// On-device handwriting practice for script characters (P5-084).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingafriq/lessons/stroke_order_view.dart';

enum HandwritingUiState { drawing, unsure, recognized, mismatch, unavailable }

abstract final class HandwritingCopyKeys {
  static const drawPrompt = 'Trace the character in the box below.';
  static const recognized = 'Nice — that matches the guide.';
  static const mismatch = 'Not quite — compare with stroke order and try again.';
  static const unsure =
      'We could not judge this attempt. Try again or skip for now.';
}

class HandwritingAttempt {
  const HandwritingAttempt({required this.points});

  final List<Offset> points;
}

class HandwritingRecognitionResult {
  const HandwritingRecognitionResult._(this.state);

  final HandwritingUiState state;

  static const recognized =
      HandwritingRecognitionResult._(HandwritingUiState.recognized);
  static const mismatch =
      HandwritingRecognitionResult._(HandwritingUiState.mismatch);
  static const unsure =
      HandwritingRecognitionResult._(HandwritingUiState.unsure);
  static const unavailable =
      HandwritingRecognitionResult._(HandwritingUiState.unavailable);
}

/// Compares learner trace to catalog strokes; no network, no stroke egress.
HandwritingRecognitionResult recognizeHandwriting({
  required HandwritingAttempt attempt,
  required String character,
  required StrokeCatalog catalog,
  double matchThreshold = 0.48,
  int minPoints = 8,
}) {
  final data = catalog.dataFor(character);
  if (data == null) {
    return HandwritingRecognitionResult.unavailable;
  }
  if (attempt.points.length < minPoints) {
    return HandwritingRecognitionResult.unsure;
  }
  final reference = _flattenReference(data.strokes);
  if (reference.length < 2) {
    return HandwritingRecognitionResult.unsure;
  }
  final learner = _normalizePoints(attempt.points);
  final refNorm = _normalizePoints(reference);
  final score = _frechetSimilarity(learner, refNorm);
  if (score >= matchThreshold) {
    return HandwritingRecognitionResult.recognized;
  }
  return HandwritingRecognitionResult.mismatch;
}

List<Offset> _flattenReference(List<StrokePolyline> strokes) {
  final out = <Offset>[];
  for (final stroke in strokes) {
    out.addAll(stroke.points);
  }
  return out;
}

List<Offset> _normalizePoints(List<Offset> points) {
  if (points.isEmpty) {
    return const [];
  }
  double minX = points.first.dx;
  double maxX = points.first.dx;
  double minY = points.first.dy;
  double maxY = points.first.dy;
  for (final p in points) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }
  final w = (maxX - minX).abs();
  final h = (maxY - minY).abs();
  final scale = 1 / math.max(math.max(w, h), 1e-6);
  return points
      .map(
        (p) => Offset(
          (p.dx - minX) * scale,
          (p.dy - minY) * scale,
        ),
      )
      .toList(growable: false);
}

double _frechetSimilarity(List<Offset> a, List<Offset> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  var total = 0.0;
  for (final p in a) {
    var best = double.infinity;
    for (final q in b) {
      best = math.min(best, (p - q).distance);
    }
    total += best;
  }
  final meanDist = total / a.length;
  return math.exp(-meanDist * 4);
}

String handwritingFeedbackFor(HandwritingUiState state) {
  switch (state) {
    case HandwritingUiState.recognized:
      return HandwritingCopyKeys.recognized;
    case HandwritingUiState.mismatch:
      return HandwritingCopyKeys.mismatch;
    case HandwritingUiState.unsure:
      return HandwritingCopyKeys.unsure;
    case HandwritingUiState.unavailable:
      return StrokeOrderCopyKeys.unavailable;
    case HandwritingUiState.drawing:
      return HandwritingCopyKeys.drawPrompt;
  }
}

class HandwritingPracticePanel extends StatefulWidget {
  const HandwritingPracticePanel({
    super.key,
    required this.character,
    this.catalog = kDefaultStrokeCatalog,
    this.onRecognized,
  });

  final String character;
  final StrokeCatalog catalog;
  final VoidCallback? onRecognized;

  @override
  State<HandwritingPracticePanel> createState() =>
      _HandwritingPracticePanelState();
}

class _HandwritingPracticePanelState extends State<HandwritingPracticePanel> {
  final List<Offset> _points = [];
  HandwritingUiState _state = HandwritingUiState.drawing;

  @override
  void didUpdateWidget(covariant HandwritingPracticePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _clear();
    }
  }

  void _clear() {
    _points.clear();
    _state = widget.catalog.dataFor(widget.character) == null
        ? HandwritingUiState.unavailable
        : HandwritingUiState.drawing;
  }

  void _finishStroke() {
    if (_state == HandwritingUiState.unavailable) {
      return;
    }
    final result = recognizeHandwriting(
      attempt: HandwritingAttempt(points: List<Offset>.from(_points)),
      character: widget.character,
      catalog: widget.catalog,
    );
    setState(() => _state = result.state);
    if (result.state == HandwritingUiState.recognized) {
      widget.onRecognized?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.catalog.dataFor(widget.character);
    if (data == null) {
      return Semantics(
        label: handwritingFeedbackFor(HandwritingUiState.unavailable),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(handwritingFeedbackFor(HandwritingUiState.unavailable)),
        ),
      );
    }

    final feedback = handwritingFeedbackFor(_state);
    return Semantics(
      label: '${widget.character}. $feedback',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(feedback, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Semantics(
            label: HandwritingCopyKeys.drawPrompt,
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _state = HandwritingUiState.drawing;
                  _points.add(d.localPosition);
                });
              },
              onPanUpdate: (d) {
                setState(() => _points.add(d.localPosition));
              },
              onPanEnd: (_) => _finishStroke(),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _TracePainter(points: _points),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clear,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
