import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Design tokens (P6-039): colour-blind-safe native vs learner pair.
abstract final class PitchContourColors {
  static const Color pitchNative = Color(0xFF0077BB);
  static const Color pitchLearner = Color(0xFFEE7733);
  static const Color axisGrid = Color(0x33000000);
  static const Color unsureHatch = Color(0x66999999);
}

/// One syllable slice on the shared semitone axis.
class SyllableContourSegment {
  const SyllableContourSegment({
    required this.label,
    required this.nativeSemitones,
    required this.learnerSemitones,
    required this.unsure,
  });

  final String label;
  final List<double> nativeSemitones;
  final List<double> learnerSemitones;
  final bool unsure;
}

/// Maps semitone values into vertical canvas coordinates (higher pitch = lower y).
List<Offset> mapContourToPoints({
  required List<double> semitones,
  required double minSemitone,
  required double maxSemitone,
  required double xStart,
  required double xEnd,
  required double height,
}) {
  if (semitones.isEmpty || maxSemitone <= minSemitone) return const [];
  final range = maxSemitone - minSemitone;
  final step = semitones.length <= 1
      ? 0.0
      : (xEnd - xStart) / (semitones.length - 1);
  final out = <Offset>[];
  for (var i = 0; i < semitones.length; i++) {
    final st = semitones[i];
    final t = ((st - minSemitone) / range).clamp(0.0, 1.0);
    final x = xStart + step * i;
    final y = height * (1 - t);
    out.add(Offset(x, y));
  }
  return out;
}

/// Shared min/max semitone range across native and learner contours.
({double min, double max}) semitoneAxisBounds(Iterable<SyllableContourSegment> segments) {
  final values = <double>[];
  for (final seg in segments) {
    values.addAll(seg.nativeSemitones);
    values.addAll(seg.learnerSemitones);
  }
  if (values.isEmpty) {
    return (min: 0.0, max: 1.0);
  }
  var minV = values.reduce(math.min);
  var maxV = values.reduce(math.max);
  if (maxV - minV < 1e-6) {
    minV -= 0.5;
    maxV += 0.5;
  } else {
    final pad = (maxV - minV) * 0.08;
    minV -= pad;
    maxV += pad;
  }
  return (min: minV, max: maxV);
}

class PitchContourPainter extends CustomPainter {
  PitchContourPainter({
    required this.segments,
    this.nativeColor = PitchContourColors.pitchNative,
    this.learnerColor = PitchContourColors.pitchLearner,
  });

  final List<SyllableContourSegment> segments;
  final Color nativeColor;
  final Color learnerColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final bounds = semitoneAxisBounds(segments);
    final minSt = bounds.min;
    final maxSt = bounds.max;

    _drawAxisGrid(canvas, size, minSt, maxSt);

    final slotWidth = size.width / segments.length;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final x0 = slotWidth * i;
      final x1 = slotWidth * (i + 1);

      if (seg.unsure) {
        _drawUnsureHatch(canvas, Rect.fromLTRB(x0, 0, x1, size.height));
      }

      _drawContourLine(
        canvas,
        size.height,
        mapContourToPoints(
          semitones: seg.nativeSemitones,
          minSemitone: minSt,
          maxSemitone: maxSt,
          xStart: x0 + 4,
          xEnd: x1 - 4,
          height: size.height,
        ),
        nativeColor,
        dashed: false,
      );
      _drawContourLine(
        canvas,
        size.height,
        mapContourToPoints(
          semitones: seg.learnerSemitones,
          minSemitone: minSt,
          maxSemitone: maxSt,
          xStart: x0 + 4,
          xEnd: x1 - 4,
          height: size.height,
        ),
        learnerColor,
        dashed: true,
      );
    }
  }

  void _drawAxisGrid(Canvas canvas, Size size, double minSt, double maxSt) {
    final paint = Paint()
      ..color = PitchContourColors.axisGrid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Semitone axis is shared; grid lines imply equal semitone steps between min and max.
    assert(maxSt > minSt);
  }

  void _drawUnsureHatch(Canvas canvas, Rect rect) {
    final fill = Paint()..color = PitchContourColors.unsureHatch.withValues(alpha: 0.25);
    canvas.drawRect(rect, fill);
    final hatch = Paint()
      ..color = PitchContourColors.unsureHatch
      ..strokeWidth = 1.2;
    const spacing = 8.0;
    for (var x = rect.left - rect.height; x < rect.right; x += spacing) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        hatch,
      );
    }
  }

  void _drawContourLine(
    Canvas canvas,
    double height,
    List<Offset> points,
    Color color,
    {required bool dashed}
  ) {
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, 3, Paint()..color = color);
      }
      return;
    }
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      const dash = 6.0;
      const gap = 4.0;
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PitchContourPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.nativeColor != nativeColor ||
        oldDelegate.learnerColor != learnerColor;
  }
}
