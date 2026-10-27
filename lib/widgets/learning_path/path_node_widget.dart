import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'path_node_state.dart';

/// Circular node widget representing a lesson in the learning path.
class PathNodeWidget extends ConsumerStatefulWidget {
  final Lesson lesson;
  final PathNodeVisualState state;
  final int index;
  final VoidCallback? onTap;
  final double size;
  final String? studyLanguageKey;
  final bool reducedMotion;
  final String reviewDueLabel;
  final String playNowFallback;

  const PathNodeWidget({
    super.key,
    required this.lesson,
    required this.state,
    required this.index,
    this.onTap,
    this.size = 64,
    this.studyLanguageKey,
    this.reducedMotion = false,
    this.reviewDueLabel = 'Review due',
    this.playNowFallback = 'Play now',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minSize = kPathNodeMinTapTargetDp.w;
    final size = widget.size.w < minSize ? minSize : widget.size.w;

    final semanticsLabel = pathNodeSemanticsLabel(
      nodeNumber: widget.index + 1,
      title: widget.lesson.name,
      state: widget.state,
      reviewDueLabel: widget.reviewDueLabel,
    );

    final tappable = widget.state != PathNodeVisualState.locked;

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: tappable,
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
                color: _backgroundColor(isDark),
                border: Border.all(
                  color: _borderColor(isDark),
                  width: widget.state == PathNodeVisualState.current ? 3.w : 2.w,
                ),
                boxShadow: widget.state == PathNodeVisualState.current &&
                        !widget.reducedMotion
                    ? [
                        BoxShadow(
                          color: _borderColor(isDark).withOpacity(0.35),
                          blurRadius: 12.w,
                          spreadRadius: 2.w,
                        ),
                      ]
                    : null,
              ),
              child: _buildContent(context, isDark, size),
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

  Color _backgroundColor(bool isDark) {
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.neutralLightest;
      case PathNodeVisualState.current:
        return PanAfricanColors.primary;
      case PathNodeVisualState.done:
        return PanAfricanColors.success;
      case PathNodeVisualState.reviewDue:
        return PanAfricanColors.warning;
      case PathNodeVisualState.skipped:
        return PanAfricanColors.neutralMedium.withOpacity(0.25);
    }
  }

  Color _borderColor(bool isDark) {
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return PanAfricanColors.neutralMedium.withOpacity(0.3);
      case PathNodeVisualState.current:
        return PanAfricanColors.primaryLight;
      case PathNodeVisualState.done:
        return PanAfricanColors.success;
      case PathNodeVisualState.reviewDue:
        return PanAfricanColors.warning;
      case PathNodeVisualState.skipped:
        return PanAfricanColors.neutralMedium.withOpacity(0.5);
    }
  }

  Widget _buildContent(BuildContext context, bool isDark, double size) {
    switch (widget.state) {
      case PathNodeVisualState.locked:
        return Icon(
          Icons.lock_rounded,
          color: PanAfricanColors.neutralMedium.withOpacity(0.5),
          size: size * 0.4,
          semanticLabel: 'Locked',
        );
      case PathNodeVisualState.current:
        return Icon(
          Icons.play_arrow_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: size * 0.45,
          semanticLabel: widget.playNowFallback,
        );
      case PathNodeVisualState.done:
        return Icon(
          Icons.check_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: size * 0.55,
          semanticLabel: 'Completed',
        );
      case PathNodeVisualState.reviewDue:
        return Icon(
          Icons.schedule_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: size * 0.45,
          semanticLabel: widget.reviewDueLabel,
        );
      case PathNodeVisualState.skipped:
        return Icon(
          Icons.fast_forward_rounded,
          color: PanAfricanColors.neutralDark,
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
