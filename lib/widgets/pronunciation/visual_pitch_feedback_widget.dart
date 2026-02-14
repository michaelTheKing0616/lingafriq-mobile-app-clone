import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
/// World-class Visual Pitch Feedback Widget
/// Displays native vs user pitch comparison with error highlighting
/// Key differentiator for tonal language learning
/// 
/// Features:
/// - Real-time pitch visualization
/// - Native vs user comparison
/// - Error highlighting
/// - Tone pattern visualization
/// - Interactive feedback

class VisualPitchFeedbackWidget extends StatelessWidget {
  /// Native speaker pitch contour (ground truth)
  final List<PitchPoint> nativePitch;
  
  /// User's pitch contour
  final List<PitchPoint> userPitch;
  
  /// Time points for both contours
  final List<double> timePoints;
  
  /// Error regions (where pitch differs significantly)
  final List<ErrorRegion>? errorRegions;
  
  /// Overall tone accuracy score
  final double? toneAccuracy;
  
  /// Feedback message
  final String? feedback;
  
  /// Whether to show real-time updates
  final bool isRealTime;
  
  /// Height of the widget
  final double height;

  const VisualPitchFeedbackWidget({
    super.key,
    required this.nativePitch,
    required this.userPitch,
    required this.timePoints,
    this.errorRegions,
    this.toneAccuracy,
    this.feedback,
    this.isRealTime = false,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          _buildHeader(context, isDark),
          
          // Pitch visualization
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: CustomPaint(
                painter: PitchContourPainter(
                  nativePitch: nativePitch,
                  userPitch: userPitch,
                  timePoints: timePoints,
                  errorRegions: errorRegions ?? [],
                  isDark: isDark,
                ),
                child: Container(),
              ),
            ),
          ),
          
          // Feedback text
          if (feedback != null && feedback!.isNotEmpty)
            _buildFeedback(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Native pitch indicator
              _buildLegendItem(
                'Native',
                Colors.green,
                isDark,
              ),
              SizedBox(width: 16.w),
              // User pitch indicator
              _buildLegendItem(
                'Your Pitch',
                Colors.blue,
                isDark,
              ),
              if (errorRegions != null && errorRegions!.isNotEmpty) ...[
                SizedBox(width: 16.w),
                _buildLegendItem(
                  'Errors',
                  Colors.red,
                  isDark,
                ),
              ],
            ],
          ),
          if (toneAccuracy != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _getScoreColor(toneAccuracy!, isDark).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${(toneAccuracy! * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(toneAccuracy!, isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16.sp,
            color: Colors.blue,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              feedback!,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.blue[200] : Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score, bool isDark) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Pitch point data structure
class PitchPoint {
  final double time;
  final double pitch; // Hz
  final double? confidence;

  PitchPoint({
    required this.time,
    required this.pitch,
    this.confidence,
  });
}

/// Error region data structure
class ErrorRegion {
  final double startTime;
  final double endTime;
  final String type; // 'tone', 'timing', 'pitch'
  final String message;

  ErrorRegion({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.message,
  });
}

/// Custom painter for pitch contour visualization
class PitchContourPainter extends CustomPainter {
  final List<PitchPoint> nativePitch;
  final List<PitchPoint> userPitch;
  final List<double> timePoints;
  final List<ErrorRegion> errorRegions;
  final bool isDark;

  PitchContourPainter({
    required this.nativePitch,
    required this.userPitch,
    required this.timePoints,
    required this.errorRegions,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nativePitch.isEmpty && userPitch.isEmpty) return;

    // Calculate pitch range
    final allPitches = [
      ...nativePitch.map((p) => p.pitch),
      ...userPitch.map((p) => p.pitch),
    ];
    final minPitch = allPitches.reduce(math.min);
    final maxPitch = allPitches.reduce(math.max);
    final pitchRange = maxPitch - minPitch;
    final padding = pitchRange * 0.1;

    // Calculate time range
    final maxTime = timePoints.isNotEmpty 
        ? timePoints.reduce(math.max) 
        : 1.0;

    // Draw error regions first (background)
    for (final error in errorRegions) {
      final startX = (error.startTime / maxTime) * size.width;
      final endX = (error.endTime / maxTime) * size.width;
      
      final errorPaint = Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        errorPaint,
      );
    }

    // Draw grid lines
    _drawGrid(canvas, size, minPitch - padding, maxPitch + padding);

    // Draw native pitch contour (green)
    if (nativePitch.isNotEmpty) {
      _drawContour(
        canvas,
        size,
        nativePitch,
        timePoints,
        minPitch - padding,
        maxPitch + padding,
        maxTime,
        Colors.green,
        2.0,
      );
    }

    // Draw user pitch contour (blue)
    if (userPitch.isNotEmpty) {
      _drawContour(
        canvas,
        size,
        userPitch,
        timePoints,
        minPitch - padding,
        maxPitch + padding,
        maxTime,
        Colors.blue,
        2.0,
      );
    }

    // Draw error markers
    for (final error in errorRegions) {
      final centerX = ((error.startTime + error.endTime) / 2 / maxTime) * size.width;
      final errorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(centerX, size.height / 2),
        4,
        errorPaint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double minPitch, double maxPitch) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.grey[800] : Colors.grey[300])!
      ..strokeWidth = 0.5;

    // Horizontal grid lines (pitch levels)
    for (int i = 0; i <= 4; i++) {
      final pitch = minPitch + (maxPitch - minPitch) * (i / 4);
      final y = size.height - ((pitch - minPitch) / (maxPitch - minPitch)) * size.height;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawContour(
    Canvas canvas,
    Size size,
    List<PitchPoint> points,
    List<double> timePoints,
    double minPitch,
    double maxPitch,
    double maxTime,
    Color color,
    double strokeWidth,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final pitchRange = maxPitch - minPitch;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final time = i < timePoints.length ? timePoints[i] : point.time;
      final x = (time / maxTime) * size.width;
      final normalizedPitch = (point.pitch - minPitch) / pitchRange;
      final y = size.height - (normalizedPitch * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

