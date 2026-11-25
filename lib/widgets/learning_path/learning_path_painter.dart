import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/learning_path/path_motion.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Decorative connector joining consecutive path nodes.
///
/// Supports legacy lane signs (`fromLane`/`toLane`) and absolute sine offsets
/// (`fromOffsetX`/`toOffsetX`). With [clayRoad], paints a Candy Crush-style
/// parchment ribbon under a coral travelled centre line.
///
/// [drawProgress] (0→1) animates the travelled centre line / dotted reveal
/// during completion choreography (recipe: 400 ms trail draw).
class PathRowConnectorPainter extends CustomPainter {
  PathRowConnectorPainter({
    this.fromLane = 0,
    this.toLane = 0,
    required this.traveled,
    Color? travelledColor,
    Color? untravelledColor,
    this.fromOffsetX,
    this.toOffsetX,
    this.clayRoad = false,
    this.drawProgress = 1.0,
    double? strokeWidth,
  })  : travelledColor = travelledColor ?? PathBrandColors.coral,
        untravelledColor = untravelledColor ?? PathBrandColors.lockedLip,
        strokeWidth = strokeWidth ?? (clayRoad ? PathLayout.roadWidth.w : 4.w);

  final double fromLane;
  final double toLane;
  final bool traveled;
  final Color travelledColor;
  final Color untravelledColor;
  final double? fromOffsetX;
  final double? toOffsetX;
  final bool clayRoad;
  final double strokeWidth;

  /// 0 = empty trail, 1 = fully drawn. Used for completion motion.
  final double drawProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;

    final laneInset = size.width * 0.26;
    final fromX = size.width / 2 +
        (fromOffsetX ?? (fromLane * laneInset));
    final toX = size.width / 2 + (toOffsetX ?? (toLane * laneInset));

    final path = Path()
      ..moveTo(fromX, size.height)
      ..cubicTo(
        fromX,
        size.height * 0.65,
        toX,
        size.height * 0.35,
        toX,
        0,
      );

    final progress = drawProgress.clamp(0.0, 1.0);

    if (clayRoad) {
      final road = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..color = traveled ? PathBrandColors.road : PathBrandColors.roadLip;
      final lip = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 6.w
        ..color = PathBrandColors.roadLip.withValues(alpha: 0.35);
      canvas.drawPath(path, lip);
      canvas.drawPath(path, road);

      if (traveled || progress > 0) {
        final centre = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.w
          ..color = travelledColor;
        _drawProgressed(canvas, path, centre, progress);
        if (progress < 1) {
          final remaining = Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.w
            ..color = untravelledColor;
          _drawDashedFrom(canvas, path, remaining, progress);
        }
      } else {
        final dashed = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.w
          ..color = untravelledColor;
        _drawDashed(canvas, path, dashed);
      }
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = traveled ? strokeWidth : strokeWidth * 0.7
      ..color = traveled ? travelledColor : untravelledColor;

    if (traveled) {
      _drawProgressed(canvas, path, paint, progress);
    } else {
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawProgressed(Canvas canvas, Path path, Paint paint, double progress) {
    for (final metric in path.computeMetrics()) {
      final end = metric.length * progress;
      if (end <= 0) continue;
      canvas.drawPath(metric.extractPath(0, end), paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    _drawDashedFrom(canvas, path, paint, 0);
  }

  void _drawDashedFrom(
    Canvas canvas,
    Path path,
    Paint paint,
    double fromProgress,
  ) {
    final dashWidth = 8.w;
    final dashSpace = 6.w;
    for (final metric in path.computeMetrics()) {
      var distance = metric.length * fromProgress;
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
        oldDelegate.fromOffsetX != fromOffsetX ||
        oldDelegate.toOffsetX != toOffsetX ||
        oldDelegate.traveled != traveled ||
        oldDelegate.travelledColor != travelledColor ||
        oldDelegate.untravelledColor != untravelledColor ||
        oldDelegate.clayRoad != clayRoad ||
        oldDelegate.drawProgress != drawProgress;
  }
}

/// Legacy lane sign helper kept for existing connector tests.
double pathLaneSign({required bool isEndLane, required bool isRtl}) {
  if (isEndLane) {
    return isRtl ? -1.0 : 1.0;
  }
  return isRtl ? 1.0 : -1.0;
}

/// Thin wrapper that fills its parent and ignores hit-testing.
class PathRowConnector extends StatelessWidget {
  const PathRowConnector({
    super.key,
    required this.fromLane,
    required this.toLane,
    required this.traveled,
    this.fromOffsetX,
    this.toOffsetX,
    this.clayRoad = false,
    this.drawProgress,
  });

  final double fromLane;
  final double toLane;
  final bool traveled;
  final double? fromOffsetX;
  final double? toOffsetX;
  final bool clayRoad;

  /// When null, reads [pathTrailDrawProgressOf] if an ancestor provides it.
  final double? drawProgress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final travelled = isDark ? PathBrandColors.gold : PathBrandColors.coral;
    final progress = drawProgress ?? pathTrailDrawProgressOf(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: PathRowConnectorPainter(
          fromLane: fromLane,
          toLane: toLane,
          fromOffsetX: fromOffsetX,
          toOffsetX: toOffsetX,
          traveled: traveled,
          travelledColor: travelled,
          untravelledColor: cs.outlineVariant,
          clayRoad: clayRoad,
          drawProgress: progress,
        ),
        size: Size.infinite,
      ),
    );
  }
}
