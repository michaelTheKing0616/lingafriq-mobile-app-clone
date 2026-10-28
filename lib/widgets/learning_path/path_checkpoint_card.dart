import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Busuu-style chapter checkpoint callout every 5th lesson.
///
/// Expands beyond a plain node so hierarchy reads "test gate", not another
/// Duo circle with a gold ring.
class PathCheckpointCard extends StatelessWidget {
  const PathCheckpointCard({
    super.key,
    required this.lessonTitle,
    required this.nodeNumber,
    required this.state,
    required this.onTap,
    this.savedOffline = false,
  });

  final String lessonTitle;
  final int nodeNumber;
  final PathNodeVisualState state;
  final VoidCallback? onTap;
  final bool savedOffline;

  @override
  Widget build(BuildContext context) {
    final locked = state == PathNodeVisualState.locked;
    final done = state == PathNodeVisualState.done ||
        state == PathNodeVisualState.reviewDue;
    final current = state == PathNodeVisualState.current;
    final cs = Theme.of(context).colorScheme;

    final bg = locked
        ? PathBrandColors.locked.withValues(alpha: 0.55)
        : (done
            ? PathBrandColors.gold.withValues(alpha: 0.28)
            : PathBrandColors.parchment);
    final border = locked
        ? PathBrandColors.lockedLip
        : (current ? PathBrandColors.coral : PathBrandColors.gold);

    return Semantics(
      button: true,
      enabled: !locked,
      label:
          'Checkpoint $nodeNumber: $lessonTitle. ${locked ? 'Locked' : (done ? 'Completed' : 'Current checkpoint')}.',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Material(
          color: bg,
          elevation: current ? 3 : 0,
          shadowColor: PathBrandColors.coral.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: locked
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: border, width: current ? 2.5 : 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: locked
                          ? PathBrandColors.lockedLip
                          : (done
                              ? PathBrandColors.gold
                              : PathBrandColors.coral),
                      boxShadow: current
                          ? [
                              BoxShadow(
                                color: PathBrandColors.coral
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      locked
                          ? Icons.lock_rounded
                          : (done
                              ? Icons.flag_rounded
                              : Icons.flag_circle_rounded),
                      color: locked
                          ? PathBrandColors.lockedLabel
                          : (done ? const Color(0xFF3A1500) : Colors.white),
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checkpoint',
                          style: ModernGriotTypography.titleSmall(
                            context: context,
                          ).copyWith(
                            fontWeight: FontWeight.w900,
                            color: locked
                                ? PathBrandColors.lockedLabel
                                : cs.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          locked
                              ? 'Finish earlier lessons to unlock this gate.'
                              : (done
                                  ? 'Skills checked — keep journeying.'
                                  : 'Test your skills to open the next stretch.'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                          ).copyWith(
                            color: locked
                                ? PathBrandColors.lockedLabel
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (savedOffline)
                    Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18.sp,
                        color: PathBrandColors.done,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
