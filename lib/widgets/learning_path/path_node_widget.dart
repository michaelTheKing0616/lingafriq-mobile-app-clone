import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/screens/section_lessons_list.dart';

/// State of a lesson node in the learning path.
enum PathNodeState {
  locked,
  current,
  completed,
  crowned,
}

/// Circular node widget representing a lesson in the learning path.
/// 
/// States:
/// - locked: Grayed out with lock icon
/// - current: Pulsing glow, primary color
/// - completed: Green with checkmark
/// - crowned: Gold with crown (perfect score)
class PathNodeWidget extends ConsumerStatefulWidget {
  final Lesson lesson;
  final PathNodeState state;
  final int index;
  final VoidCallback? onTap;
  final double size;

  const PathNodeWidget({
    Key? key,
    required this.lesson,
    required this.state,
    required this.index,
    this.onTap,
    this.size = 64,
  }) : super(key: key);

  @override
  ConsumerState<PathNodeWidget> createState() => _PathNodeWidgetState();
}

class _PathNodeWidgetState extends ConsumerState<PathNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.state == PathNodeState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PathNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PathNodeState.current &&
        oldWidget.state != PathNodeState.current) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != PathNodeState.current &&
        oldWidget.state == PathNodeState.current) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.size.w;

    final stateLabel = _getStateLabel();
    return Semantics(
      label: 'Lesson ${widget.index + 1}: ${widget.lesson.name}. $stateLabel.',
      button: true,
      enabled: widget.state != PathNodeState.locked,
      child: GestureDetector(
        onTap: widget.state == PathNodeState.locked ? null : _handleTap,
        child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.state == PathNodeState.current
              ? _pulseAnimation.value
              : 1.0;

          final nodeContent = Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getBackgroundColor(context, isDark),
              border: Border.all(
                color: _getBorderColor(context, isDark),
                width: widget.state == PathNodeState.current ? 3.w : 2.w,
              ),
              boxShadow: widget.state == PathNodeState.current
                  ? [
                      BoxShadow(
                        color: _getBorderColor(context, isDark)
                            .withOpacity(0.4),
                        blurRadius: 16.w,
                        spreadRadius: 4.w,
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

  String _getStateLabel() {
    switch (widget.state) {
      case PathNodeState.locked:
        return 'Locked';
      case PathNodeState.current:
        return 'Current lesson. Tap to start';
      case PathNodeState.completed:
        return 'Completed';
      case PathNodeState.crowned:
        return 'Completed with perfect score';
    }
  }

  Color _getBackgroundColor(BuildContext context, bool isDark) {
    switch (widget.state) {
      case PathNodeState.locked:
        return isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.neutralLightest;
      case PathNodeState.current:
        return PanAfricanColors.primary;
      case PathNodeState.completed:
        return PanAfricanColors.success;
      case PathNodeState.crowned:
        return PanAfricanColors.secondary;
    }
  }

  Color _getBorderColor(BuildContext context, bool isDark) {
    switch (widget.state) {
      case PathNodeState.locked:
        return PanAfricanColors.neutralMedium.withOpacity(0.3);
      case PathNodeState.current:
        return PanAfricanColors.primaryLight;
      case PathNodeState.completed:
        return PanAfricanColors.success;
      case PathNodeState.crowned:
        return PanAfricanColors.secondaryDark;
    }
  }

  Widget _buildContent(BuildContext context, bool isDark, double size) {
    switch (widget.state) {
      case PathNodeState.locked:
        return Icon(
          Icons.lock_rounded,
          color: PanAfricanColors.neutralMedium.withOpacity(0.5),
          size: size * 0.4,
        );
      case PathNodeState.current:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.index + 1}',
              style: PanAfricanTypography.titleMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Icon(
              Icons.play_circle_filled_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: size * 0.3,
            ),
          ],
        );
      case PathNodeState.completed:
        return Icon(
          Icons.check_circle_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: size * 0.6,
        );
      case PathNodeState.crowned:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: size * 0.6,
            ),
            Positioned(
              top: size * 0.15,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: PanAfricanColors.secondaryDark,
                size: size * 0.35,
              ),
            ),
          ],
        );
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    ref.read(navigationProvider).navigateTo(
          LessonSectionsListScreen(lesson: widget.lesson),
        );
  }
}
