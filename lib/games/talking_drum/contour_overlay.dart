import 'package:flutter/material.dart';

import '../../utils/pan_african_design_system.dart';

/// Native drum contour with optional learner F0 overlay (P8-920 AC3).
class TalkingDrumContourOverlay extends StatelessWidget {
  const TalkingDrumContourOverlay({
    super.key,
    required this.nativeContour,
    this.learnerContour,
    this.unsure = false,
    this.height = 120,
  });

  final List<double> nativeContour;
  final List<double>? learnerContour;
  final bool unsure;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nativeColor = PanAfricanColors.primary;
    final learnerColor = cs.secondary;
    return Semantics(
      label: unsure
          ? 'Pitch comparison unavailable'
          : 'Talking drum contour with your pitch line',
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _ContourOverlayPainter(
            native: nativeContour,
            learner: learnerContour,
            nativeColor: nativeColor,
            learnerColor: learnerColor,
            unsure: unsure,
          ),
        ),
      ),
    );
  }
}

class _ContourOverlayPainter extends CustomPainter {
  _ContourOverlayPainter({
    required this.native,
    this.learner,
    required this.nativeColor,
    required this.learnerColor,
    required this.unsure,
  });

  final List<double> native;
  final List<double>? learner;
  final Color nativeColor;
  final Color learnerColor;
  final bool unsure;

  @override
  void paint(Canvas canvas, Size size) {
    if (native.isEmpty) return;
    _drawLine(canvas, size, native, nativeColor, strokeWidth: 3);
    if (learner != null && learner!.isNotEmpty && !unsure) {
      _drawLine(canvas, size, learner!, learnerColor, strokeWidth: 2, dashed: true);
    }
    if (unsure) {
      final paint = Paint()
        ..color = nativeColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color, {
    required double strokeWidth,
    bool dashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final n = values.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : (i / (n - 1)) * size.width;
      final y = size.height * (1 - values[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (dashed) {
      paint.shader = null;
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final len = 6.0;
          final extract = metric.extractPath(distance, distance + len);
          canvas.drawPath(extract, paint);
          distance += len + 4;
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourOverlayPainter oldDelegate) {
    return oldDelegate.native != native ||
        oldDelegate.learner != learner ||
        oldDelegate.unsure != unsure;
  }
}

/// Maps scorer syllable height hints (0–1) onto overlay space.
List<double> learnerContourFromSyllableHeights(List<double> heights) {
  if (heights.isEmpty) return const [];
  return heights.map((h) => h.clamp(0.0, 1.0)).toList(growable: false);
}
