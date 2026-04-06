import 'package:flutter/material.dart';

/// Configurable SVG-like pattern background using [CustomPainter].
///
/// Renders decorative patterns at very low opacity (3–5%) for subtle texture.
/// Available patterns: triangles, diamonds, dots, kente.
///
/// ```dart
/// GriotSvgPatternBackground(
///   pattern: GriotPattern.kente,
///   child: YourContent(),
/// )
/// ```
class GriotSvgPatternBackground extends StatelessWidget {
  const GriotSvgPatternBackground({
    super.key,
    required this.child,
    this.pattern = GriotPattern.dots,
    this.opacity = 0.04,
    this.color,
    this.cellSize = 32,
  });

  final Widget child;
  final GriotPattern pattern;

  /// Pattern opacity. Design system recommends 0.03–0.05.
  final double opacity;

  /// Pattern color. Defaults to onSurface.
  final Color? color;

  /// Size of each repeating cell.
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final patternColor =
        color ?? Theme.of(context).colorScheme.onSurface;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PatternPainter(
              pattern: pattern,
              color: patternColor.withAlpha((opacity * 255).round()),
              cellSize: cellSize,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Available background pattern types.
enum GriotPattern { triangles, diamonds, dots, kente }

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.pattern,
    required this.color,
    required this.cellSize,
  });

  final GriotPattern pattern;
  final Color color;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    switch (pattern) {
      case GriotPattern.dots:
        _paintDots(canvas, cols, rows, fillPaint);
      case GriotPattern.triangles:
        _paintTriangles(canvas, cols, rows, paint);
      case GriotPattern.diamonds:
        _paintDiamonds(canvas, cols, rows, paint);
      case GriotPattern.kente:
        _paintKente(canvas, cols, rows, paint);
    }
  }

  void _paintDots(Canvas canvas, int cols, int rows, Paint paint) {
    final radius = cellSize * 0.08;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cellSize + cellSize / 2;
        final cy = r * cellSize + cellSize / 2;
        canvas.drawCircle(Offset(cx, cy), radius, paint);
      }
    }
  }

  void _paintTriangles(Canvas canvas, int cols, int rows, Paint paint) {
    final half = cellSize / 2;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * cellSize;
        final y = r * cellSize;
        final path = Path()
          ..moveTo(x + half, y + cellSize * 0.2)
          ..lineTo(x + cellSize * 0.8, y + cellSize * 0.8)
          ..lineTo(x + cellSize * 0.2, y + cellSize * 0.8)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintDiamonds(Canvas canvas, int cols, int rows, Paint paint) {
    final half = cellSize / 2;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cellSize + half;
        final cy = r * cellSize + half;
        final s = cellSize * 0.3;
        final path = Path()
          ..moveTo(cx, cy - s)
          ..lineTo(cx + s, cy)
          ..lineTo(cx, cy + s)
          ..lineTo(cx - s, cy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintKente(Canvas canvas, int cols, int rows, Paint paint) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * cellSize;
        final y = r * cellSize;
        final q = cellSize / 4;

        // Horizontal zigzag
        canvas.drawLine(
          Offset(x, y + q),
          Offset(x + q, y),
          paint,
        );
        canvas.drawLine(
          Offset(x + q, y),
          Offset(x + q * 2, y + q),
          paint,
        );
        canvas.drawLine(
          Offset(x + q * 2, y + q),
          Offset(x + q * 3, y),
          paint,
        );
        canvas.drawLine(
          Offset(x + q * 3, y),
          Offset(x + cellSize, y + q),
          paint,
        );

        // Vertical zigzag (offset)
        canvas.drawLine(
          Offset(x + q, y + q * 2),
          Offset(x, y + q * 3),
          paint,
        );
        canvas.drawLine(
          Offset(x + q, y + q * 2),
          Offset(x + q * 2, y + q * 3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern ||
      oldDelegate.color != color ||
      oldDelegate.cellSize != cellSize;
}
