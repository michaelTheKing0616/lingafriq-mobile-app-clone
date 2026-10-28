import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'path_node_state.dart';

/// Circular node widget representing a lesson in the learning path.
class PathNodeWidget extends ConsumerStatefulWidget {
  /// Default bubble diameter (logical px, before `.w` scaling). Exposed so
  /// callers that lay the node out inside a parent-sized box (e.g. the
  /// learning path screen's per-row `SizedBox`) can size that box to match
  /// without duplicating the literal.
  static const double defaultSize = 64;

  final Lesson lesson;
  final PathNodeVisualState state;
  final int index;
  final VoidCallback? onTap;
  final double size;
  final String? studyLanguageKey;
  final bool reducedMotion;
  final String reviewDueLabel;
  final String playNowFallback;

  /// Total lessons on this path, used only to enrich the Semantics label
  /// (e.g. "Lesson 3 of 12"). Optional so existing call sites keep working.
  final int? totalLessons;

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
  });

  @override
  ConsumerState<PathNodeWidget> createState() => _PathNodeWidgetState();
}

class _PathNodeWidgetState extends ConsumerState<PathNodeWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
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
    final shouldPulse = widget.state == PathNodeVisualState.current &&
        !widget.reducedMotion;
    if (!shouldPulse) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
      return;
    }
    if (_pulseController == null) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minSize = kPathNodeMinTapTargetDp.w;
    final size = widget.size.w < minSize ? minSize : widget.size.w;

    final semanticsLabel = pathNodeSemanticsLabel(
      nodeNumber: widget.index + 1,
      title: widget.lesson.name,
      state: widget.state,
      reviewDueLabel: widget.reviewDueLabel,
      totalLessons: widget.totalLessons,
    );

    final tappable = widget.state != PathNodeVisualState.locked;

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: tappable,
      // Without this, the bubble's icon (`Icon(..., semanticLabel: 'Completed')`
      // etc.) merges its own text into this node's announcement, so a screen
      // reader would read "...Greetings. Completed.\nCompleted" — the state
      // said twice. `semanticsLabel` above already fully describes the icon,
      // so the icon's own label is redundant and excluded here.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: tappable ? _handleTap : null,
        child: AnimatedBuilder(
          animation: _pulseAnimation ?? kAlwaysCompleteAnimation,
          builder: (context, child) {
            final scale = widget.state == PathNodeVisualState.current &&
                    !widget.reducedMotion
                ? (_pulseAnimation?.value ?? 1.0)
                : 1.0;

            final nodeContent = Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _backgroundColor(context),
                border: Border.all(
                  color: _borderColor(context),
                  width: widget.state == PathNodeVisualState.current ? 3.w : 2.w,
                ),
                boxShadow: widget.state == PathNodeVisualState.current &&
                        !widget.reducedMotion
                    ? [
                        BoxShadow(
                          color: _borderColor(context).withValues(alpha: 0.35),
                          blurRadius: 12.w,
                          spreadRadius: 2.w,
                        ),
                      ]
                    : null,
              ),
              child: _buildContent(context, size),
            );
            return Transform.scale(
              scale: scale,
              child: Hero(
                tag: 'path_node_${widget.lesson.id}',
                child: nodeContent,
              ),
            );
          },
        ),
      ),
    );
  }

  // Every fill/icon pair below is drawn from the SAME `ColorScheme` role pair
  // (e.g. `secondary`/`onSecondary`), which is how Material 3 themes
  // guarantee the two were designed together for contrast — rather than
  // mixing an unrelated palette's fill with this theme's `onPrimary` icon,
  // which previously paired colors that were never designed against each
  // other (measured as low as ~2.0:1, well under the 3:1 non-text minimum).
  // Verified against the live `ModernGriotColorScheme` light + dark values:
  // every pair below is >=4.9:1 in light mode and >=7.1:1 in dark mode.
  Color _backgroundColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return cs.surfaceContainerHigh;
      case PathNodeVisualState.current:
        return cs.primary;
      case PathNodeVisualState.done:
        return cs.secondary;
      case PathNodeVisualState.reviewDue:
        return cs.tertiary;
      case PathNodeVisualState.skipped:
        return cs.surfaceContainerHighest;
    }
  }

  Color _borderColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return cs.outlineVariant;
      case PathNodeVisualState.current:
        return cs.primary;
      case PathNodeVisualState.done:
        return cs.secondary;
      case PathNodeVisualState.reviewDue:
        return cs.tertiary;
      case PathNodeVisualState.skipped:
        return cs.outlineVariant;
    }
  }

  Widget _buildContent(BuildContext context, double size) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.state) {
      case PathNodeVisualState.locked:
        // Full-opacity `onSurfaceVariant` (not a low-alpha wash, which
        // measured well under the 3:1 WCAG non-text contrast minimum
        // against the fill) so the lock glyph stays legible for low-vision
        // learners.
        return Icon(
          Icons.lock_rounded,
          color: cs.onSurfaceVariant,
          size: size * 0.4,
          semanticLabel: 'Locked',
        );
      case PathNodeVisualState.current:
        return Icon(
          Icons.play_arrow_rounded,
          color: cs.onPrimary,
          size: size * 0.45,
          semanticLabel: widget.playNowFallback,
        );
      case PathNodeVisualState.done:
        return Icon(
          Icons.check_rounded,
          color: cs.onSecondary,
          size: size * 0.55,
          semanticLabel: 'Completed',
        );
      case PathNodeVisualState.reviewDue:
        return Icon(
          Icons.schedule_rounded,
          color: cs.onTertiary,
          size: size * 0.45,
          semanticLabel: widget.reviewDueLabel,
        );
      case PathNodeVisualState.skipped:
        return Icon(
          Icons.fast_forward_rounded,
          color: cs.onSurfaceVariant,
          size: size * 0.4,
          semanticLabel: 'Skipped',
        );
    }
  }

  void _handleTap() {
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
