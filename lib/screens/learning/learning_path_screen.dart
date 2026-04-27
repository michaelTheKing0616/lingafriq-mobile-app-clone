import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/lessons/screens/section_lessons_list.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/griot/griot_widgets.dart';
import 'package:lingafriq/screens/learning/dialect_variant_picker.dart';

/// Winding learning path driven by real [Lesson] rows from the API (same as [LessonsListScreen]).
class LearningPathScreen extends ConsumerStatefulWidget {
  final Language language;

  const LearningPathScreen({super.key, required this.language});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  static const _nodeSpacing = 110.0;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  /// Matches sequential unlock in [LessonsListScreen] (`_LessonItem` / `isEnabled`).
  bool _sectionUnlocked(int index, List<Lesson> lessons) {
    if (index <= 0) return true;
    final prev = lessons[index - 1];
    return prev.count == prev.completed;
  }

  bool _sectionCompleted(Lesson lesson) =>
      lesson.count > 0 && lesson.completed >= lesson.count;

  /// First incomplete, unlocked lesson index — matches sequential unlock in [LessonsListScreen].
  int? _activeIndex(List<Lesson> lessons) {
    for (var i = 0; i < lessons.length; i++) {
      if (!_sectionUnlocked(i, lessons)) return null;
      if (!_sectionCompleted(lessons[i])) return i;
    }
    return null;
  }

  _NodeState _stateFor(int index, List<Lesson> lessons, int? activeIndex) {
    if (!_sectionUnlocked(index, lessons)) return _NodeState.locked;
    final lesson = lessons[index];
    if (_sectionCompleted(lesson)) return _NodeState.completed;
    if (activeIndex == index) return _NodeState.active;
    return _NodeState.locked;
  }

  void _openLesson(Lesson lesson) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      SmoothPageRoute.platform(child: LessonSectionsListScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsListProvider(widget.language.id));

    return lessonsAsync.when(
      data: (lessonResponse) {
        final lessons = lessonResponse.results
            .where((e) => e.lessons_language == widget.language.id)
            .toList();
        if (lessons.isEmpty) {
          return GriotScaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 48.sp),
                    SizedBox(height: 16.h),
                    Text(
                      'No lesson sections yet for ${widget.language.name}.',
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.titleSmall(),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Try again later or open the full lesson list.',
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodySmall(),
                    ),
                    SizedBox(height: 24.h),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          SmoothPageRoute.platform(
                            child: LessonsListScreen(language: widget.language),
                          ),
                        );
                      },
                      child: const Text('Open lesson list'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final active = _activeIndex(lessons);
        final completedCount = lessons
            .where((l) => _sectionCompleted(l))
            .length;
        // When all sections are done, paint the full path as "past" the last index.
        final pathActiveIndex = active ?? lessons.length;

        final totalHeight = lessons.length * _nodeSpacing + 200;

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
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
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
                            Text(
                              'Learning Path',
                              style: ModernGriotTypography.titleLarge(),
                            ),
                            Text(
                              '$completedCount of ${lessons.length} sections completed',
                              style: ModernGriotTypography.bodySmall(),
                            ),
                          ],
                        ),
                      ),
                      GriotBadgePill(
                        label:
                            '${(completedCount / lessons.length * 100).round()}%',
                        icon: Icons.trending_up_rounded,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      SizedBox(width: 10.w),
                      IconButton(
                        tooltip: 'Dialect mode (Common vs Local)',
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => DialectVariantPicker(
                              umbrellaLanguage: widget.language.name
                                  .toLowerCase(),
                            ),
                          );
                        },
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
                                nodeCount: lessons.length,
                                nodeSpacing: _nodeSpacing,
                                activeIndex: pathActiveIndex,
                                color: Theme.of(context).colorScheme.primary,
                                trackColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...List.generate(lessons.length, (i) {
                            final lesson = lessons[i];
                            final state = _stateFor(i, lessons, active);
                            final xOffset = _nodeX(i, _nodeSpacing);
                            final yOffset = i * _nodeSpacing + 40.0;
                            return Positioned(
                              left: xOffset,
                              top: yOffset,
                              child: _buildNode(
                                context,
                                lesson: lesson,
                                displayTitle: lesson.name.isNotEmpty
                                    ? lesson.name
                                    : 'Section ${i + 1}',
                                state: state,
                              ),
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
      },
      loading: () =>
          GriotScaffold(body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => GriotScaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Could not load lessons',
                  style: ModernGriotTypography.titleSmall(),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.bodySmall(),
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(lessonsListProvider(widget.language.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
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

  Widget _buildNode(
    BuildContext context, {
    required Lesson lesson,
    required String displayTitle,
    required _NodeState state,
  }) {
    final cs = Theme.of(context).colorScheme;
    const size = 56.0;
    final nodeSize = size.r;

    Widget nodeCircle;
    switch (state) {
      case _NodeState.completed:
        nodeCircle = Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            color: ModernGriotColors.secondary,
            shape: BoxShape.circle,
            boxShadow: ModernGriotShadows.glow(ModernGriotColors.secondary),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 24.sp,
            color: ModernGriotColors.onSecondary,
          ),
        );
      case _NodeState.active:
        nodeCircle = AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              shape: BoxShape.circle,
              boxShadow: ModernGriotShadows.glow(cs.primary),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 20.sp,
                  color: cs.onPrimary,
                ),
                Text(
                  'START',
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      case _NodeState.locked:
        nodeCircle = ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(180),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 18.sp,
                color: cs.onSurfaceVariant.withAlpha(120),
              ),
            ),
          ),
        );
    }

    void onTap() {
      if (state == _NodeState.locked) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete the previous section first.')),
        );
        return;
      }
      _openLesson(lesson);
    }

    return GestureDetector(
      onTap: onTap,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 160.w),
              child: Text(
                displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ModernGriotTypography.labelSmall(
                  color: state == _NodeState.locked
                      ? cs.onSurfaceVariant.withAlpha(120)
                      : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { completed, active, locked }

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
          x1,
          y1 + nodeSpacing * 0.4,
          x2,
          y2 - nodeSpacing * 0.4,
          x2,
          y2,
        );

      dashPaint.color = i < activeIndex ? color.withAlpha(180) : trackColor;

      _drawDashedPath(canvas, path, dashPaint, 8, 6);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashLen,
    double gapLen,
  ) {
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
