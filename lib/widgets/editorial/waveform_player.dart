import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Audio waveform visualiser with color-progressive bars.
///
/// Bars to the left of the [progress] position use a saturated primary
/// color ("played"), while bars to the right use a faded variant
/// ("unplayed"). Tap-to-seek is supported via [onSeek], which reports
/// the normalised position (0.0 – 1.0).
class WaveformPlayer extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final ValueChanged<double>? onSeek;
  final double height;

  const WaveformPlayer({
    super.key,
    required this.amplitudes,
    this.progress = 0.0,
    this.onSeek,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (details) => _handleSeek(details, context),
      onHorizontalDragUpdate: (details) => _handleDrag(details, context),
      child: CustomPaint(
        size: Size(double.infinity, height.h),
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          progress: progress.clamp(0.0, 1.0),
          playedColor: colors.primary,
          unplayedColor: colors.onSurface.withOpacity(0.15),
        ),
      ),
    );
  }

  void _handleSeek(TapDownDetails details, BuildContext context) {
    HapticFeedback.selectionClick();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = details.localPosition.dx;
    final fraction = (localX / box.size.width).clamp(0.0, 1.0);
    onSeek?.call(fraction);
  }

  void _handleDrag(DragUpdateDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = details.localPosition.dx;
    final fraction = (localX / box.size.width).clamp(0.0, 1.0);
    onSeek?.call(fraction);
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  static const double _barWidthRatio = 0.6;
  static const double _minBarFraction = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barCount = amplitudes.length;
    final slotWidth = size.width / barCount;
    final barWidth = slotWidth * _barWidthRatio;
    final midY = size.height / 2;
    final playedPaint = Paint()..color = playedColor;
    final unplayedPaint = Paint()..color = unplayedColor;

    for (var i = 0; i < barCount; i++) {
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final barHeight =
          (amp * (1 - _minBarFraction) + _minBarFraction) * size.height;
      final halfBar = barHeight / 2;

      final x = i * slotWidth + (slotWidth - barWidth) / 2;
      final fraction = barCount > 1 ? i / (barCount - 1) : 0.0;
      final paint = fraction <= progress ? playedPaint : unplayedPaint;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, midY - halfBar, x + barWidth, midY + halfBar),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.amplitudes != amplitudes ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}
