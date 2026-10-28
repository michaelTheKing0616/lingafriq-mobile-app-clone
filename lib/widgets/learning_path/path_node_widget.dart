import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Clay path node — 72px soft token with lip depth (v3 sunlit-clay brief).
///
/// State is communicated by colour **and** shape/icon so colour is never the
/// sole cue. Checkpoints (every 5th) use Gold reward chrome.
class PathNodeWidget extends ConsumerStatefulWidget {
  /// Default bubble diameter (logical px, before `.w` scaling).
  static const double defaultSize = PathLayout.nodeSize;

  final Lesson lesson;
  final PathNodeVisualState state;
  final int index;
  final VoidCallback? onTap;
  final double size;
  final String? studyLanguageKey;
  final bool reducedMotion;
  final String reviewDueLabel;
  final String playNowFallback;
  final int? totalLessons;

  /// When true, shows a small offline-saved tick (Drift-cached progress).
  final bool savedOffline;

  /// Busuu-style checkpoint / treasure every 5 nodes.
  final bool isCheckpoint;

  const PathNodeWidget({
    super.key,
    required this.lesson,
    required this.state,
    required this.index,
    this.onTap,
    this.size = defaultSize,
    this.studyLanguageKey,
    this.reducedMotion = false,
    this.reviewDueLabel = 'Review due',
    this.playNowFallback = 'Play now',
    this.totalLessons,
    this.savedOffline = false,
    this.isCheckpoint = false,
  });

  @override
  ConsumerState<PathNodeWidget> createState() => _PathNodeWidgetState();
}

class _PathNodeWidgetState extends ConsumerState<PathNodeWidget>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: PathLayout.pressDuration,
      reverseDuration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1, end: PathLayout.pressScale).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(PathNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final shouldPulse =
        widget.state == PathNodeVisualState.current && !widget.reducedMotion;
    if (!shouldPulse) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
      return;
    }
    if (_pulseController == null) {
      _pulseController = AnimationController(
        duration: PathLayout.pulseDuration,
        vsync: this,
      );
      // Clay brief halo pulse 0.97–1.16 kept readable on low-end phones.
      _pulseAnimation = Tween<double>(begin: 0.97, end: 1.12).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minSize = kPathNodeMinTapTargetDp.w;
    final size = widget.size.w < minSize ? minSize : widget.size.w;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final semanticsLabel = pathNodeSemanticsLabel(
      nodeNumber: widget.index + 1,
      title: widget.lesson.name,
      state: widget.state,
      reviewDueLabel: widget.reviewDueLabel,
      totalLessons: widget.totalLessons,
    );

    final tappable = widget.state != PathNodeVisualState.locked;
    final fill = _fillColor(isDark);
    final lip = _lipColor(isDark);

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: tappable,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: tappable && !widget.reducedMotion
            ? (_) => _pressController.forward()
            : null,
        onTapUp: tappable
            ? (_) {
                _pressController.reverse();
                _handleTap();
              }
            : null,
        onTapCancel: () => _pressController.reverse(),
        onTap: tappable && widget.reducedMotion ? _handleTap : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pressScale,
            _pulseAnimation ?? kAlwaysCompleteAnimation,
          ]),
          builder: (context, child) {
            final pulse = widget.state == PathNodeVisualState.current &&
                    !widget.reducedMotion
                ? (_pulseAnimation?.value ?? 1.0)
                : 1.0;
            final scale = _pressScale.value * pulse;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: size + 8.w,
                height: size + 18.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (widget.state == PathNodeVisualState.current &&
                        !widget.reducedMotion)
                      Container(
                        width: size + 10.w,
                        height: size + 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: fill.withValues(alpha: 0.35),
                              blurRadius: 14.w,
                              spreadRadius: 1.w,
                            ),
                          ],
                        ),
                      ),
                    // Clay lip (depth)
                    Positioned(
                      top: 6.h,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lip,
                        ),
                      ),
                    ),
                    // Top face
                    Positioned(
                      top: 0,
                      child: Hero(
                        tag: 'path_node_${widget.lesson.id}',
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fill,
                            border: widget.isCheckpoint
                                ? Border.all(
                                    color: PathBrandColors.gold,
                                    width: 3.w,
                                  )
                                : null,
                          ),
                          child: _buildContent(context, size, isDark),
                        ),
                      ),
                    ),
                    if (widget.state == PathNodeVisualState.current)
                      Positioned(
                        bottom: -4.h,
                        child: _StartSpeechBubble(
                          label: widget.playNowFallback,
                          reducedMotion: widget.reducedMotion,
                        ),
                      ),
                    if (widget.savedOffline)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: PathBrandColors.savedOk,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 12.sp,
                            color: PathBrandColors.savedOk,
                          ),
                        ),
                      ),
                    if (widget.isCheckpoint &&
                        widget.state != PathNodeVisualState.locked)
                      Positioned(
                        top: -2.h,
                        left: 0,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 16.sp,
                          color: PathBrandColors.gold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _fillColor(bool isDark) {
    if (widget.isCheckpoint && widget.state == PathNodeVisualState.done) {
      return PathBrandColors.gold;
    }
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return isDark
            ? const Color(0xFF4A4338)
            : PathBrandColors.locked;
      case PathNodeVisualState.current:
        return PathBrandColors.current;
      case PathNodeVisualState.done:
        return PathBrandColors.done;
      case PathNodeVisualState.reviewDue:
        return PathBrandColors.reviewDue;
      case PathNodeVisualState.skipped:
        return isDark
            ? const Color(0xFF3A342C)
            : PathBrandColors.lockedLip;
    }
  }

  Color _lipColor(bool isDark) {
    if (widget.isCheckpoint && widget.state == PathNodeVisualState.done) {
      return PathBrandColors.currentLip;
    }
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return isDark
            ? const Color(0xFF2E2922)
            : PathBrandColors.lockedLip;
      case PathNodeVisualState.current:
        return PathBrandColors.currentLip;
      case PathNodeVisualState.done:
        return PathBrandColors.doneLip;
      case PathNodeVisualState.reviewDue:
        return PathBrandColors.reviewDueLip;
      case PathNodeVisualState.skipped:
        return isDark
            ? const Color(0xFF252018)
            : PathBrandColors.lockedLip;
    }
  }

  Color _glyphColor(bool isDark) {
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return isDark
            ? const Color(0xFFD4C4A8)
            : PathBrandColors.lockedLabel;
      case PathNodeVisualState.current:
      case PathNodeVisualState.done:
      case PathNodeVisualState.reviewDue:
        return Colors.white;
      case PathNodeVisualState.skipped:
        return isDark
            ? const Color(0xFFCABB9E)
            : PathBrandColors.lockedLabel;
    }
  }

  Widget _buildContent(BuildContext context, double size, bool isDark) {
    final glyph = _glyphColor(isDark);
    final nodeNumber = '${widget.index + 1}';

    switch (widget.state) {
      case PathNodeVisualState.locked:
        return Icon(
          Icons.lock_rounded,
          color: glyph,
          size: size * 0.38,
          semanticLabel: 'Locked',
        );
      case PathNodeVisualState.current:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nodeNumber,
              style: TextStyle(
                color: glyph,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.28,
                height: 1,
              ),
            ),
            Icon(
              Icons.play_arrow_rounded,
              color: glyph,
              size: size * 0.32,
              semanticLabel: widget.playNowFallback,
            ),
          ],
        );
      case PathNodeVisualState.done:
        return Icon(
          widget.isCheckpoint
              ? Icons.emoji_events_rounded
              : Icons.check_rounded,
          color: const Color(0xFF3A1500),
          size: size * 0.48,
          semanticLabel: 'Completed',
        );
      case PathNodeVisualState.reviewDue:
        return Icon(
          Icons.refresh_rounded,
          color: glyph,
          size: size * 0.42,
          semanticLabel: widget.reviewDueLabel,
        );
      case PathNodeVisualState.skipped:
        return Icon(
          Icons.fast_forward_rounded,
          color: glyph,
          size: size * 0.38,
          semanticLabel: 'Skipped',
        );
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    LearningExperienceNavigation.openLessonSections(
      context,
      lesson: widget.lesson,
      studyLanguageKey: widget.studyLanguageKey,
    );
  }
}

/// Speech-bubble CTA under the current node (recipe + clay BEGIN mass).
class _StartSpeechBubble extends StatelessWidget {
  const _StartSpeechBubble({
    required this.label,
    required this.reducedMotion,
  });

  final String label;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reducedMotion ? 1 : 0.85, end: 1),
      duration: reducedMotion
          ? PathLayout.reducedMotionCrossfade
          : PathLayout.popoverDuration,
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(10.w, 6.h),
            painter: _BubbleTailPainter(color: PathBrandColors.coral),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: PathBrandColors.coral,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: PathBrandColors.coral.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label.toUpperCase(),
              style: ModernGriotTypography.labelSmall(context: context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
