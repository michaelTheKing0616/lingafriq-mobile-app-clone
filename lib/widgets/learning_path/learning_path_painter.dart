import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Decorative connector drawn behind a single row of a lesson list,
/// joining the lane the previous node sat in to the lane this node sits in
/// so a scrolling list of alternating lesson bubbles reads as one
/// continuous winding path (the Duolingo-style "serpentine" pattern),
/// rather than a plain vertical stack of circles.
///
/// This is intentionally a standalone, stateless [CustomPainter] (no
/// [AnimationController], no repeating ticker) so it is reduced-motion safe
/// by construction: it paints once per layout/state change and never
/// animates on its own.
///
/// [fromLane] and [toLane] are direction-aware: `-1` means the lesson's
/// *start* lane (left in LTR, right in RTL), `1` means the *end* lane, and
/// `0` is centered. Callers resolve the physical sign themselves (see
/// [pathLaneSign]) so this painter never has to know about [TextDirection].
class PathRowConnectorPainter extends CustomPainter {
  PathRowConnectorPainter({
    required this.fromLane,
    required this.toLane,
    required this.traveled,
    Color? travelledColor,
    Color? untravelledColor,
    double? strokeWidth,
  })  : travelledColor = travelledColor ?? ModernGriotColors.primary,
        untravelledColor = untravelledColor ??
            ModernGriotColors.outlineVariant,
        strokeWidth = strokeWidth ?? 4.w;

  final double fromLane;
  final double toLane;

  /// True once the learner has reached/unlocked this segment of the path.
  final bool traveled;
  final Color travelledColor;
  final Color untravelledColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = traveled ? strokeWidth : strokeWidth * 0.7
      ..color = traveled ? travelledColor : untravelledColor;

    final laneInset = size.width * 0.26;
    final fromX = size.width / 2 + fromLane * laneInset;
    final toX = size.width / 2 + toLane * laneInset;

    final path = Path()
      ..moveTo(fromX, size.height)
      ..quadraticBezierTo(size.width / 2, size.height / 2, toX, 0);

    if (traveled) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    final dashWidth = 8.w;
    final dashSpace = 6.w;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(
          distance,
          (distance + dashWidth).clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathRowConnectorPainter oldDelegate) {
    return oldDelegate.fromLane != fromLane ||
        oldDelegate.toLane != toLane ||
        oldDelegate.traveled != traveled ||
        oldDelegate.travelledColor != travelledColor ||
        oldDelegate.untravelledColor != untravelledColor;
  }
}

/// Resolves a direction-aware lane value (`-1`/`0`/`1`) to a physical sign
/// for canvas painting, which always operates in physical (non-mirrored)
/// pixels regardless of [TextDirection]. Keeps the "end lane always paints
/// on the correct physical side" logic in one tested place instead of
/// scattering RTL math across call sites.
double pathLaneSign({required bool isEndLane, required bool isRtl}) {
  if (isEndLane) {
    return isRtl ? -1.0 : 1.0;
  }
  return isRtl ? 1.0 : -1.0;
}

/// Thin wrapping widget around [PathRowConnectorPainter] that fills its
/// parent and ignores hit-testing, so it can sit behind a tappable lesson
/// node inside a `Stack` without stealing taps.
class PathRowConnector extends StatelessWidget {
  const PathRowConnector({
    super.key,
    required this.fromLane,
    required this.toLane,
    required this.traveled,
  });

  final double fromLane;
  final double toLane;
  final bool traveled;

  @override
  Widget build(BuildContext context) {
    // Resolved explicitly from the live theme (rather than relying on the
    // painter's own default fallback, which is a light-mode-only constant)
    // so the connector tracks dark mode correctly, matching the node bubbles
    // it visually joins.
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: CustomPaint(
        painter: PathRowConnectorPainter(
          fromLane: fromLane,
          toLane: toLane,
          traveled: traveled,
          travelledColor: cs.primary,
          untravelledColor: cs.outlineVariant,
        ),
        size: Size.infinite,
      ),
    );
  }
}
