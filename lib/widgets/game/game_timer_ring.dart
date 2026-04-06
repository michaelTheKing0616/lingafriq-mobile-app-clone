import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Circular countdown timer with a gradient ring drawn via [CustomPainter].
///
/// Displays [remainingSeconds] in the center. The ring uses the app's
/// signature gradient. When remaining time drops below 5 seconds, a
/// pulsing scale animation emphasizes urgency.
class GameTimerRing extends StatefulWidget {
  /// Total duration of the timer in seconds.
  final int totalSeconds;

  /// Current remaining seconds. The ring fills proportionally.
  final int remainingSeconds;

  /// Called when remaining time reaches zero.
  final VoidCallback? onTimeUp;

  /// Outer diameter of the ring widget.
  final double size;

  const GameTimerRing({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.onTimeUp,
    this.size = 72,
  });

  @override
  State<GameTimerRing> createState() => _GameTimerRingState();
}

class _GameTimerRingState extends State<GameTimerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _timeUpFired = false;

  static const int _lowTimeThreshold = 5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncPulse();
  }

  @override
  void didUpdateWidget(GameTimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();

    if (widget.remainingSeconds <= 0 && !_timeUpFired) {
      _timeUpFired = true;
      widget.onTimeUp?.call();
    }
    if (widget.remainingSeconds > 0) {
      _timeUpFired = false;
    }
  }

  void _syncPulse() {
    if (widget.remainingSeconds > 0 &&
        widget.remainingSeconds <= _lowTimeThreshold) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLow =
        widget.remainingSeconds > 0 && widget.remainingSeconds <= _lowTimeThreshold;
    final fraction = widget.totalSeconds > 0
        ? (widget.remainingSeconds / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    final displayMinutes = widget.remainingSeconds ~/ 60;
    final displaySeconds = widget.remainingSeconds % 60;
    final timeText = displayMinutes > 0
        ? '$displayMinutes:${displaySeconds.toString().padLeft(2, '0')}'
        : '${widget.remainingSeconds}';

    final ringColor = isLow ? PanAfricanColors.error : null;

    Widget ring = SizedBox(
      width: widget.size.w,
      height: widget.size.w,
      child: CustomPaint(
        painter: _TimerRingPainter(
          fraction: fraction,
          trackColor: cs.surfaceContainerHighest,
          ringGradientColors: ringColor != null
              ? [ringColor, ringColor.withOpacity(0.7)]
              : [PanAfricanColors.primary, PanAfricanColors.tertiary],
          strokeWidth: 5.w,
        ),
        child: Center(
          child: Text(
            timeText,
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: isLow ? PanAfricanColors.error : cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: widget.size > 60 ? 22.sp : 16.sp,
            ),
          ),
        ),
      ),
    );

    if (isLow) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: ring,
      );
    }

    return ring;
  }
}

class _TimerRingPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final List<Color> ringGradientColors;
  final double strokeWidth;

  _TimerRingPainter({
    required this.fraction,
    required this.trackColor,
    required this.ringGradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final sweepAngle = 2 * math.pi * fraction;
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: ringGradientColors,
        tileMode: TileMode.clamp,
      );

      final ringPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
