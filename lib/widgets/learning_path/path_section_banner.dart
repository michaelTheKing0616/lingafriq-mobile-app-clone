import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/learning_path/path_motion.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// L10n keys (resolved in ARB): [kPathUnitBannerKey], [kPathPreviewSheetKey].
const String kPathUnitBannerKey = 'learn.f_007.unit';

/// Full-width unit ribbon — Mimo-clean chapter chrome + Duo sticky swap only.
///
/// Shows "Unit N · Title", one-line goal, optional n/N progress, and Guide.
class PathSectionBanner extends StatelessWidget {
  const PathSectionBanner({
    super.key,
    required this.unitName,
    required this.cefrLevel,
    required this.canDoStatement,
    this.unitOrdinal = 0,
    this.completedInUnit = 0,
    this.totalInUnit = 0,
    this.showSceneArt = false,
    this.languageKey,
    this.unitIndex = 0,
    this.sceneDimmed = false,
    this.bundleLicensed = true,
    this.sticky = false,
    this.locked = false,
    this.onGuideTap,
    this.reducedMotion = false,
    this.parallaxOffset = 0,
  });

  final String unitName;
  final String cefrLevel;
  final String canDoStatement;
  final int unitOrdinal;
  final int completedInUnit;
  final int totalInUnit;

  /// When true, renders a [PathSceneArtSlot] strip (inline section only).
  final bool showSceneArt;
  final String? languageKey;
  final int unitIndex;
  final bool sceneDimmed;
  final bool bundleLicensed;

  /// Compact sticky chrome (no scene strip, full-bleed edge).
  final bool sticky;
  final bool locked;
  final VoidCallback? onGuideTap;
  final bool reducedMotion;
  final double parallaxOffset;

  @override
  Widget build(BuildContext context) {
    final ribbon = pathUnitRibbonColor(unitOrdinal);
    final place = PathLayout.placeThemeForUnit(unitOrdinal);
    final title = unitName.trim().isEmpty ? 'Unit ${unitOrdinal + 1}' : unitName;
    // Avoid "Unit 1 · Unit 3" when unitName already carries the chapter label.
    final headline = RegExp(r'^unit\s+\d+', caseSensitive: false).hasMatch(title)
        ? title
        : 'Unit ${unitOrdinal + 1} · $title';
    final subtitle = canDoStatement.trim().isNotEmpty
        ? canDoStatement.trim()
        : (cefrLevel.isNotEmpty ? cefrLevel : 'Keep going');
    final progressLabel = totalInUnit > 0
        ? '$completedInUnit/$totalInUnit'
        : '';
    final label =
        '$headline. $subtitle${locked ? '. Locked' : ''}'
        '${progressLabel.isNotEmpty ? '. $progressLabel complete' : ''}';

    final banner = Material(
      color: ribbon,
      elevation: sticky ? 2 : 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: sticky ? PathLayout.stickyBannerMinHeight.h * 0.85 : 0,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: sticky ? 10.h : 12.h,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: label,
                  header: true,
                  child: InkWell(
                    onTap: onGuideTap == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onGuideTap!();
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ModernGriotTypography.titleSmall(
                            context: context,
                          ).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                          ).copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        if (!sticky) ...[
                          SizedBox(height: 4.h),
                          Text(
                            pathPlaceThemeLabel(place),
                            style: ModernGriotTypography.labelSmall(
                              context: context,
                            ).copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (progressLabel.isNotEmpty) ...[
                SizedBox(width: 8.w),
                _UnitProgressRing(
                  completed: completedInUnit,
                  total: totalInUnit,
                  label: progressLabel,
                ),
              ],
              if (cefrLevel.isNotEmpty && !sticky && progressLabel.isEmpty) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    cefrLevel,
                    style: ModernGriotTypography.labelMedium(
                      context: context,
                    ).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              SizedBox(width: 8.w),
              _GuideButton(onTap: onGuideTap),
            ],
          ),
        ),
      ),
    );

    if (sticky) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
        child: banner,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSceneArt)
            SizedBox(
              height: 88.h,
              width: double.infinity,
              child: Transform.translate(
                offset: Offset(0, -parallaxOffset * PathLayout.sceneryParallax),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: ColoredBox(
                    color: pathPlaceWashColor(
                      place,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    child: PathSceneArtSlot(
                      languageKey: languageKey,
                      unitIndex: unitIndex,
                      dimmed: sceneDimmed || locked,
                      bundleLicensed: bundleLicensed,
                      reducedMotion: reducedMotion,
                    ),
                  ),
                ),
              ),
            ),
          if (showSceneArt) SizedBox(height: 8.h),
          banner,
        ],
      ),
    );
  }
}

/// Sticky unit banner with 250ms ease-out swap + optional unlock shine (~700ms).
class PathStickyUnitBanner extends StatelessWidget {
  const PathStickyUnitBanner({
    super.key,
    required this.unitName,
    required this.cefrLevel,
    required this.canDoStatement,
    required this.unitOrdinal,
    required this.reducedMotion,
    this.completedInUnit = 0,
    this.totalInUnit = 0,
    this.locked = false,
    this.playUnlockShine = false,
    this.onGuideTap,
    this.onUnlockShineCompleted,
  });

  final String unitName;
  final String cefrLevel;
  final String canDoStatement;
  final int unitOrdinal;
  final bool reducedMotion;
  final int completedInUnit;
  final int totalInUnit;
  final bool locked;
  final bool playUnlockShine;
  final VoidCallback? onGuideTap;
  final VoidCallback? onUnlockShineCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reducedMotion
          ? PathLayout.reducedMotionCrossfade
          : PathLayout.bannerSwapDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        if (reducedMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.35),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: PathUnitUnlockShine(
        key: ValueKey('unit-shine-$unitOrdinal-$playUnlockShine'),
        play: playUnlockShine,
        reducedMotion: reducedMotion,
        onCompleted: onUnlockShineCompleted,
        child: PathSectionBanner(
          key: ValueKey('unit-$unitOrdinal-$unitName'),
          unitName: unitName,
          cefrLevel: cefrLevel,
          canDoStatement: canDoStatement,
          unitOrdinal: unitOrdinal,
          completedInUnit: completedInUnit,
          totalInUnit: totalInUnit,
          sticky: true,
          locked: locked,
          onGuideTap: onGuideTap,
          reducedMotion: reducedMotion,
        ),
      ),
    );
  }
}

class _UnitProgressRing extends StatelessWidget {
  const _UnitProgressRing({
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$label lessons complete in this unit',
      child: SizedBox(
        width: 44.w,
        height: 44.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: t,
              strokeWidth: 3.5,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              color: PathBrandColors.gold,
            ),
            Text(
              label,
              style: ModernGriotTypography.labelSmall(context: context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideButton extends StatelessWidget {
  const _GuideButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Guide',
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: PathLayout.minTapTarget.w,
            height: PathLayout.minTapTarget.w,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }
}
