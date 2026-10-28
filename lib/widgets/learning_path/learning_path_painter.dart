import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Decorative connector joining consecutive path nodes.
///
/// Supports legacy lane signs (`fromLane`/`toLane`) and absolute sine offsets
/// (`fromOffsetX`/`toOffsetX`). With [clayRoad], paints a Candy Crush-style
/// parchment ribbon under a coral travelled centre line.
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

      if (traveled) {
        final centre = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.w
          ..color = travelledColor;
        canvas.drawPath(path, centre);
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
        oldDelegate.fromOffsetX != fromOffsetX ||
        oldDelegate.toOffsetX != toOffsetX ||
        oldDelegate.traveled != traveled ||
        oldDelegate.travelledColor != travelledColor ||
        oldDelegate.untravelledColor != untravelledColor ||
        oldDelegate.clayRoad != clayRoad;
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
  });

  final double fromLane;
  final double toLane;
  final bool traveled;
  final double? fromOffsetX;
  final double? toOffsetX;
  final bool clayRoad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final travelled = isDark ? PathBrandColors.gold : PathBrandColors.coral;
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
        ),
        size: Size.infinite,
      ),
    );
  }
}
