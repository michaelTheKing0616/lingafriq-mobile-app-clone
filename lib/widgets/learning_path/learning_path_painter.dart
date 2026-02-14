import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Custom painter that draws a curved zigzag path connecting lesson nodes.
/// 
/// The path alternates left-right as it goes down, creating a serpentine pattern.
/// Completed sections are drawn in the primary color, upcoming sections are gray/dotted.
class LearningPathPainter extends CustomPainter {
  final List<PathNodePosition> nodePositions;
  final int currentIndex;
  final Color primaryColor;
  final Color inactiveColor;
  final double strokeWidth;

  LearningPathPainter({
    required this.nodePositions,
    required this.currentIndex,
    Color? primaryColor,
    Color? inactiveColor,
    double? strokeWidth,
  })  : primaryColor = primaryColor ?? PanAfricanColors.primary,
        inactiveColor = inactiveColor ?? PanAfricanColors.neutralMedium.withOpacity(0.3),
        strokeWidth = strokeWidth ?? 4.w;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];
      
      final isCompleted = i < currentIndex;
      final isCurrent = i == currentIndex - 1;
      
      paint.color = isCompleted || isCurrent
          ? primaryColor
          : inactiveColor;

      if (isCompleted || isCurrent) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = strokeWidth * 0.7;
      }

      _drawCurvedPath(canvas, paint, start, end, isCompleted || isCurrent);
    }

    _drawCurrentGlow(canvas, nodePositions, currentIndex);
  }

  void _drawCurvedPath(
    Canvas canvas,
    Paint paint,
    PathNodePosition start,
    PathNodePosition end,
    bool isActive,
  ) {
    final path = Path();
    
    path.moveTo(start.x, start.y);
    
    final midX = (start.x + end.x) / 2;
    
    final controlPointX = midX;
    final controlPointY = start.y + (end.y - start.y) * 0.3;
    
    path.quadraticBezierTo(
      controlPointX,
      controlPointY,
      end.x,
      end.y,
    );
    
    if (!isActive) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashWidth = 8.w;
    final dashSpace = 6.w;
    
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          (distance + dashWidth).clamp(0, pathMetric.length),
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawCurrentGlow(
    Canvas canvas,
    List<PathNodePosition> positions,
    int currentIndex,
  ) {
    if (currentIndex < 0 || currentIndex >= positions.length) return;
    
    final currentPos = positions[currentIndex];
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final glowRadius = 24.w;
    canvas.drawCircle(
      Offset(currentPos.x, currentPos.y),
      glowRadius,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(LearningPathPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

/// Represents the position of a node on the path.
class PathNodePosition {
  final double x;
  final double y;

  const PathNodePosition(this.x, this.y);
}
