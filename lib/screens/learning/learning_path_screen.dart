import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class LearningPathScreen extends ConsumerStatefulWidget {
  final dynamic language;

  const LearningPathScreen({super.key, required this.language});

  @override
  ConsumerState<LearningPathScreen> createState() =>
      _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  static const _lessons = [
    _LessonNode('Greetings', _NodeState.completed, false),
    _LessonNode('Numbers 1-10', _NodeState.completed, false),
    _LessonNode('Family Words', _NodeState.completed, false),
    _LessonNode('Basic Phrases', _NodeState.active, false),
    _LessonNode('Checkpoint 1', _NodeState.checkpoint, true),
    _LessonNode('Food & Drink', _NodeState.locked, false),
    _LessonNode('At the Market', _NodeState.locked, false),
    _LessonNode('Directions', _NodeState.locked, false),
    _LessonNode('Checkpoint 2', _NodeState.locked, true),
    _LessonNode('Past Tense', _NodeState.locked, false),
    _LessonNode('Future Plans', _NodeState.locked, false),
    _LessonNode('Final Mastery', _NodeState.locked, true),
  ];

  static const _activeIndex = 3;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const nodeSpacing = 110.0;
    final totalHeight = _lessons.length * nodeSpacing + 200;
    final completedCount =
        _lessons.where((l) => l.state == _NodeState.completed).length;

    return GriotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Learning Path',
                            style: ModernGriotTypography.titleLarge()),
                        Text(
                            '$completedCount of ${_lessons.length} completed',
                            style: ModernGriotTypography.bodySmall()),
                      ],
                    ),
                  ),
                  GriotBadgePill(
                    label:
                        '${(completedCount / _lessons.length * 100).round()}%',
                    icon: Icons.trending_up_rounded,
                    color: cs.secondaryContainer,
                    textColor: cs.onSecondaryContainer,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: SizedBox(
                  height: totalHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WindingPathPainter(
                            nodeCount: _lessons.length,
                            nodeSpacing: nodeSpacing,
                            activeIndex: _activeIndex,
                            color: cs.primary,
                            trackColor: cs.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16.w,
                        top: 50.h,
                        child: Opacity(
                          opacity: 0.06,
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: 140.sp,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      ...List.generate(_lessons.length, (i) {
                        final lesson = _lessons[i];
                        final xOffset = _nodeX(i, nodeSpacing);
                        final yOffset = i * nodeSpacing + 40.0;
                        return Positioned(
                          left: xOffset,
                          top: yOffset,
                          child: _buildNode(context, lesson, i),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _nodeX(int index, double spacing) {
    final screenW = MediaQuery.of(context).size.width;
    final amplitude = screenW * 0.22;
    final center = screenW / 2 - 32.r;
    return center + sin(index * 0.8) * amplitude;
  }

  Widget _buildNode(BuildContext context, _LessonNode lesson, int index) {
    final cs = Theme.of(context).colorScheme;
    final size = lesson.isCheckpoint ? 72.r : 56.r;

    Widget nodeCircle;
    switch (lesson.state) {
      case _NodeState.completed:
        nodeCircle = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: ModernGriotColors.secondary,
            shape: BoxShape.circle,
            boxShadow: ModernGriotShadows.glow(ModernGriotColors.secondary),
          ),
          child: Icon(Icons.check_rounded,
              size: 24.sp, color: ModernGriotColors.onSecondary),
        );
      case _NodeState.active:
        nodeCircle = AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              shape: BoxShape.circle,
              boxShadow: ModernGriotShadows.glow(cs.primary),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded,
                    size: 20.sp, color: cs.onPrimary),
                Text('START',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimary,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
        );
      case _NodeState.checkpoint:
        final isLocked = index > _activeIndex;
        nodeCircle = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLocked
                ? cs.surfaceContainerHighest.withAlpha(180)
                : cs.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(
                color: isLocked
                    ? cs.outlineVariant.withAlpha(60)
                    : cs.primary.withAlpha(80),
                width: 2),
          ),
          child: Icon(
            isLocked ? Icons.lock_rounded : Icons.emoji_events_rounded,
            size: 28.sp,
            color: isLocked ? cs.onSurfaceVariant.withAlpha(120) : cs.primary,
          ),
        );
      case _NodeState.locked:
        nodeCircle = ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(180),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded,
                  size: 18.sp, color: cs.onSurfaceVariant.withAlpha(120)),
            ),
          ),
        );
    }

    return GestureDetector(
      onTap: lesson.state == _NodeState.locked
          ? null
          : () => HapticFeedback.lightImpact(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          nodeCircle,
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(220),
              borderRadius: ModernGriotRadius.borderPill,
              boxShadow: ModernGriotShadows.sm,
            ),
            child: Text(
              lesson.title,
              style: ModernGriotTypography.labelSmall(
                color: lesson.state == _NodeState.locked
                    ? cs.onSurfaceVariant.withAlpha(120)
                    : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { completed, active, checkpoint, locked }

class _LessonNode {
  const _LessonNode(this.title, this.state, this.isCheckpoint);
  final String title;
  final _NodeState state;
  final bool isCheckpoint;
}

class _WindingPathPainter extends CustomPainter {
  _WindingPathPainter({
    required this.nodeCount,
    required this.nodeSpacing,
    required this.activeIndex,
    required this.color,
    required this.trackColor,
  });

  final int nodeCount;
  final double nodeSpacing;
  final int activeIndex;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final amplitude = size.width * 0.22;
    final centerX = size.width / 2;
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodeCount - 1; i++) {
      final y1 = i * nodeSpacing + 40 + 28;
      final y2 = (i + 1) * nodeSpacing + 40 + 28;
      final x1 = centerX + sin(i * 0.8) * amplitude;
      final x2 = centerX + sin((i + 1) * 0.8) * amplitude;

      final path = Path()
        ..moveTo(x1, y1)
        ..cubicTo(
            x1, y1 + nodeSpacing * 0.4, x2, y2 - nodeSpacing * 0.4, x2, y2);

      dashPaint.color =
          i < activeIndex ? color.withAlpha(180) : trackColor;

      _drawDashedPath(canvas, path, dashPaint, 8, 6);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen,
      double gapLen) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLen).clamp(0, metric.length).toDouble();
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_WindingPathPainter old) =>
      old.activeIndex != activeIndex || old.nodeCount != nodeCount;
}
