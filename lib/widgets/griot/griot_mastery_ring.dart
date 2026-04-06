import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Donut-chart mastery ring for game results.
///
/// Renders a percentage ring using [CustomPainter] with the signature
/// gradient (primary → primaryContainer) and a centered value display.
///
/// ```dart
/// GriotMasteryRing(
///   value: 0.85,
///   size: 120,
///   label: 'Mastery',
/// )
/// ```
class GriotMasteryRing extends StatelessWidget {
  const GriotMasteryRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 10,
    this.label,
    this.animate = true,
  });

  /// Progress value from 0.0 to 1.0.
  final double value;

  /// Outer diameter.
  final double size;

  /// Ring stroke width.
  final double strokeWidth;

  /// Optional label beneath the percentage text.
  final String? label;

  /// Whether to animate the ring on build.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringSize = size.r;
    final clampedValue = value.clamp(0.0, 1.0);
    final percent = (clampedValue * 100).round();

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (animate)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: clampedValue),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) => CustomPaint(
                size: Size(ringSize, ringSize),
                painter: _MasteryRingPainter(
                  value: animValue,
                  strokeWidth: strokeWidth.r,
                  trackColor: cs.surfaceContainerHighest,
                  gradientColors: [cs.primary, cs.primaryContainer],
                ),
              ),
            )
          else
            CustomPaint(
              size: Size(ringSize, ringSize),
              painter: _MasteryRingPainter(
                value: clampedValue,
                strokeWidth: strokeWidth.r,
                trackColor: cs.surfaceContainerHighest,
                gradientColors: [cs.primary, cs.primaryContainer],
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: (size * 0.22).sp,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: (size * 0.1).sp,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteryRingPainter extends CustomPainter {
  _MasteryRingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientColors,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0) return;

    final sweepAngle = 2 * math.pi * value;
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: gradientColors,
        tileMode: TileMode.clamp,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_MasteryRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor;
}
