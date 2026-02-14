import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/coaching/feedback_engine.dart';

/// Visual pronunciation score display with animated ring
class PronunciationScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final String? label;
  
  const PronunciationScoreRing({
    Key? key,
    required this.score,
    this.size = 100,
    this.label,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final grade = _getGrade(score);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: Colors.grey.shade200,
            ),
          ),
          // Score ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  String _getGrade(double score) {
    if (score >= 0.9) return 'A+';
    if (score >= 0.8) return 'A';
    if (score >= 0.7) return 'B';
    if (score >= 0.6) return 'C';
    if (score >= 0.5) return 'D';
    return 'F';
  }
}

/// Score breakdown bars
class ScoreBreakdownBars extends StatelessWidget {
  final double phonemeScore;
  final double toneScore;
  final double fluencyScore;
  final double? confidenceScore;
  
  const ScoreBreakdownBars({
    Key? key,
    required this.phonemeScore,
    required this.toneScore,
    required this.fluencyScore,
    this.confidenceScore,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildScoreBar('Pronunciation', phonemeScore, Icons.record_voice_over),
        SizedBox(height: 12.h),
        _buildScoreBar('Tone', toneScore, Icons.music_note),
        SizedBox(height: 12.h),
        _buildScoreBar('Fluency', fluencyScore, Icons.speed),
        if (confidenceScore != null) ...[
          SizedBox(height: 12.h),
          _buildScoreBar('Confidence', confidenceScore!, Icons.psychology),
        ],
      ],
    );
  }
  
  Widget _buildScoreBar(String label, double score, IconData icon) {
    final color = _getBarColor(score);
    final percentage = (score * 100).round();
    
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey.shade600),
        SizedBox(width: 8.w),
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                children: [
                  // Background
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 40.w,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  Color _getBarColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Waveform visualization (simplified)
class WaveformVisualizer extends StatefulWidget {
  final List<double> amplitudes;
  final Color color;
  final double height;
  
  const WaveformVisualizer({
    Key? key,
    required this.amplitudes,
    this.color = Colors.blue,
    this.height = 60,
  }) : super(key: key);
  
  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: widget.amplitudes,
          color: widget.color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  
  _WaveformPainter({required this.amplitudes, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final barWidth = size.width / amplitudes.length;
    final centerY = size.height / 2;
    
    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = amplitude * size.height * 0.8;
      
      final x = i * barWidth + barWidth / 2;
      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;
      
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}

/// Pitch contour visualization for tone analysis
class PitchContourChart extends StatelessWidget {
  final List<double> learnerPitch;
  final List<double>? referencePitch;
  final double height;
  
  const PitchContourChart({
    Key? key,
    required this.learnerPitch,
    this.referencePitch,
    this.height = 100,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _PitchContourPainter(
          learnerPitch: learnerPitch,
          referencePitch: referencePitch,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PitchContourPainter extends CustomPainter {
  final List<double> learnerPitch;
  final List<double>? referencePitch;
  
  _PitchContourPainter({
    required this.learnerPitch,
    this.referencePitch,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw reference pitch (if available)
    if (referencePitch != null && referencePitch!.isNotEmpty) {
      _drawPitchLine(canvas, size, referencePitch!, Colors.green.withOpacity(0.5), 3);
    }
    
    // Draw learner pitch
    if (learnerPitch.isNotEmpty) {
      _drawPitchLine(canvas, size, learnerPitch, Colors.blue, 2);
    }
    
    // Draw tone markers (H, M, L)
    _drawToneMarkers(canvas, size);
  }
  
  void _drawPitchLine(Canvas canvas, Size size, List<double> pitch, Color color, double width) {
    if (pitch.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Normalize pitch values
    final minPitch = pitch.reduce(min);
    final maxPitch = pitch.reduce(max);
    final range = maxPitch - minPitch;
    
    final path = Path();
    final stepX = size.width / (pitch.length - 1);
    
    for (int i = 0; i < pitch.length; i++) {
      final normalized = range > 0 ? (pitch[i] - minPitch) / range : 0.5;
      final x = i * stepX;
      final y = size.height - (normalized * size.height * 0.8 + size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawToneMarkers(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final positions = [
      (0.1, 'H', Colors.green), // High
      (0.5, 'M', Colors.orange), // Mid
      (0.9, 'L', Colors.red),    // Low
    ];
    
    for (final (yRatio, label, color) in positions) {
      final y = size.height * yRatio;
      
      // Draw dashed line
      final linePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 1;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
      
      // Draw label
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-15, y - 6));
    }
  }
  
  @override
  bool shouldRepaint(covariant _PitchContourPainter oldDelegate) {
    return oldDelegate.learnerPitch != learnerPitch ||
           oldDelegate.referencePitch != referencePitch;
  }
}

/// Feedback card with coaching response
class FeedbackCard extends StatelessWidget {
  final CoachingResponse response;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;
  
  const FeedbackCard({
    Key? key,
    required this.response,
    this.onRetry,
    this.onContinue,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main message with score
            Row(
              children: [
                PronunciationScoreRing(
                  score: response.overallScore,
                  size: 60.sp,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.mainMessage,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (response.encouragement != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            response.encouragement!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Feedback items
            if (response.feedbackItems.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 16.h),
              ...response.feedbackItems.map((item) => _buildFeedbackItem(item)),
            ],
            
            // Next step
            if (response.nextStep != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        response.nextStep!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (response.shouldRetry && onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                SizedBox(width: 8.w),
                if (onContinue != null)
                  ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeedbackItem(FeedbackItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getIcon(item),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _getMessageColor(item.severity),
                  ),
                ),
                if (item.actionableTip != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      '💡 ${item.actionableTip}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getIcon(FeedbackItem item) {
    IconData icon;
    Color color;
    
    switch (item.severity) {
      case FeedbackSeverity.positive:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case FeedbackSeverity.neutral:
        icon = Icons.info;
        color = Colors.blue;
        break;
      case FeedbackSeverity.constructive:
        icon = Icons.tips_and_updates;
        color = Colors.orange;
        break;
      case FeedbackSeverity.critical:
        icon = Icons.warning;
        color = Colors.red;
        break;
    }
    
    return Icon(icon, color: color, size: 20.sp);
  }
  
  Color _getMessageColor(FeedbackSeverity severity) {
    switch (severity) {
      case FeedbackSeverity.positive:
        return Colors.green.shade700;
      case FeedbackSeverity.neutral:
        return Colors.grey.shade700;
      case FeedbackSeverity.constructive:
        return Colors.orange.shade700;
      case FeedbackSeverity.critical:
        return Colors.red.shade700;
    }
  }
}

/// Recording button with visual feedback
class RecordingButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;
  final Stream<double>? amplitudeStream;
  
  const RecordingButton({
    Key? key,
    required this.isRecording,
    required this.onPressed,
    this.amplitudeStream,
  }) : super(key: key);
  
  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentAmplitude = 0.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    widget.amplitudeStream?.listen((amplitude) {
      setState(() => _currentAmplitude = amplitude);
    });
  }
  
  @override
  void didUpdateWidget(RecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _animationController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _animationController.stop();
      _animationController.reset();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = widget.isRecording 
              ? 1.0 + (_currentAmplitude * 0.2)
              : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80.sp,
              height: 80.sp,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording ? Colors.red : Colors.blue)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: widget.isRecording ? 10 * _currentAmplitude : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 36.sp,
              ),
            ),
          );
        },
      ),
    );
  }
}

