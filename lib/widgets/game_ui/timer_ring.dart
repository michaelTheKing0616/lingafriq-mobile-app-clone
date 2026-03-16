import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'game_ui_tokens.dart';

class TimerRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final double size;

  const TimerRing({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSeconds <= 0 ? 1 : totalSeconds;
    final progress = (secondsRemaining / safeTotal).clamp(0.0, 1.0);
    final isCritical = secondsRemaining <= 5;
    final isWarn = secondsRemaining <= 15;
    final color = isCritical
        ? GameUiTokens.danger(context)
        : (isWarn ? GameUiTokens.warning(context) : GameUiTokens.timer(context));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: color,
            ),
          ),
          Center(
            child: Text(
              '$secondsRemaining',
              style: PanAfricanTypography.labelMedium(context).copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withOpacity(0.2)
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2, false, bgPaint);
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2 * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
