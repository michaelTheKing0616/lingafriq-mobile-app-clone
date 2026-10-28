import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/learning_path/path_motion.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Sticky 56px path chrome: language chip · streak · cowries (never hearts).
///
/// Background fades in after [PathLayout.headerFadeScrollPx] of scroll.
/// Finch kindness: a broken streak reads "Welcome" and never shames.
class PathStickyHeader extends StatelessWidget {
  const PathStickyHeader({
    super.key,
    required this.languageName,
    required this.streakCount,
    required this.cowriesCount,
    required this.scrollPixels,
    required this.onBack,
    required this.onLanguageTap,
    required this.onStreakTap,
    required this.onCowriesTap,
    this.onDialectTap,
    this.onToggleListView,
    this.listViewActive = false,
    this.isOffline = false,
    this.welcomeBack = false,
    this.freezeAvailable = true,
    this.reducedMotion = false,
    this.playDayOneFlameBurst = false,
  });

  final String languageName;
  final int streakCount;
  final int cowriesCount;
  final double scrollPixels;
  final VoidCallback onBack;
  final VoidCallback onLanguageTap;
  final VoidCallback onStreakTap;
  final VoidCallback onCowriesTap;
  final VoidCallback? onDialectTap;
  final VoidCallback? onToggleListView;
  final bool listViewActive;
  final bool isOffline;
  final bool welcomeBack;
  final bool freezeAvailable;
  final bool reducedMotion;

  /// Day's first lesson: flame burst 600 ms + week dots (recipe).
  final bool playDayOneFlameBurst;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fadeT = (scrollPixels / PathLayout.headerFadeScrollPx).clamp(0.0, 1.0);
    final bg = Color.lerp(
      cs.surface.withValues(alpha: 0),
      cs.surface.withValues(alpha: isDark ? 0.96 : 0.94),
      fadeT,
    )!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon =
        isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    final flag = pathLanguageFlagEmoji(languageName);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = textScale >= 1.35;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: bg,
        child: SizedBox(
          height: PathLayout.stickyHeaderHeight.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _HeaderIconButton(
                  tooltip: 'Back',
                  semanticsLabel: 'Back',
                  icon: backIcon,
                  onTap: onBack,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatChip(
                          semanticsLabel: '$languageName course',
                          onTap: onLanguageTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(flag, style: TextStyle(fontSize: 16.sp)),
                              if (!compact) ...[
                                SizedBox(width: 4.w),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 72.w),
                                  child: Text(
                                    languageName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ModernGriotTypography.labelLarge(
                                      context: context,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        _StatChip(
                          semanticsLabel: welcomeBack
                              ? 'Welcome back. Streak freeze available'
                              : 'Streak $streakCount days',
                          onTap: onStreakTap,
                          accent: welcomeBack
                              ? PathBrandColors.gold.withValues(alpha: 0.35)
                              : null,
                          child: PathStreakFlameBurst(
                            play: playDayOneFlameBurst && !welcomeBack,
                            reducedMotion: reducedMotion,
                            streakCount: streakCount,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StreakFlameIcon(
                                  welcomeBack: welcomeBack,
                                  streakCount: streakCount,
                                  reducedMotion: reducedMotion,
                                  idleColor: streakCount > 0
                                      ? PathBrandColors.coral
                                      : cs.onSurfaceVariant,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  welcomeBack && streakCount == 0
                                      ? 'Welcome'
                                      : '$streakCount',
                                  maxLines: 1,
                                  style: ModernGriotTypography.labelLarge(
                                    context: context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: welcomeBack
                                        ? cs.onSurface
                                        : (streakCount > 0
                                            ? PathBrandColors.coral
                                            : cs.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        _StatChip(
                          semanticsLabel: '$cowriesCount cowries',
                          onTap: onCowriesTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                size: 16.sp,
                                color: PathBrandColors.gold,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                _compactCount(cowriesCount),
                                maxLines: 1,
                                style: ModernGriotTypography.labelLarge(
                                  context: context,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        if (isOffline) ...[
                          SizedBox(width: 4.w),
                          Semantics(
                            label: 'Offline — showing your last saved progress',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 6.w : 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                'Offline',
                                style: ModernGriotTypography.labelSmall(
                                  context: context,
                                ).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurfaceVariant,
                                  fontSize: compact ? 9.sp : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onToggleListView != null)
                  _HeaderIconButton(
                    tooltip: listViewActive ? 'Path view' : 'List view',
                    semanticsLabel:
                        listViewActive ? 'Show winding path' : 'Show list view',
                    icon: listViewActive
                        ? Icons.map_rounded
                        : Icons.view_list_rounded,
                    onTap: onToggleListView!,
                  ),
                if (onDialectTap != null)
                  _HeaderIconButton(
                    tooltip: 'Dialect mode',
                    semanticsLabel: 'Dialect mode',
                    icon: Icons.tune_rounded,
                    onTap: onDialectTap!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _compactCount(int n) {
    if (n >= 10000) return '${(n / 1000).floor()}k';
    return '$n';
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: PathLayout.minTapTarget.w,
            height: PathLayout.minTapTarget.w,
            child: Icon(icon, size: 22.sp, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.child,
    required this.onTap,
    required this.semanticsLabel,
    this.accent,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = accent ??
        (isDark
            ? cs.surfaceContainerHigh.withValues(alpha: 0.7)
            : PathBrandColors.parchment.withValues(alpha: 0.7));
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: PathLayout.minTapTarget.h,
              minWidth: PathLayout.minTapTarget.w,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Align(
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resting streak flicker (~2s). Reduce Motion keeps a static flame.
class _StreakFlameIcon extends StatefulWidget {
  const _StreakFlameIcon({
    required this.welcomeBack,
    required this.streakCount,
    required this.reducedMotion,
    required this.idleColor,
  });

  final bool welcomeBack;
  final int streakCount;
  final bool reducedMotion;
  final Color idleColor;

  @override
  State<_StreakFlameIcon> createState() => _StreakFlameIconState();
}

class _StreakFlameIconState extends State<_StreakFlameIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _flicker;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _StreakFlameIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.welcomeBack != widget.welcomeBack ||
        oldWidget.streakCount != widget.streakCount) {
      _sync();
    }
  }

  void _sync() {
    final shouldFlicker = !widget.reducedMotion &&
        !widget.welcomeBack &&
        widget.streakCount > 0;
    if (!shouldFlicker) {
      _flicker?.dispose();
      _flicker = null;
      return;
    }
    _flicker ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.welcomeBack) {
      return Icon(
        Icons.ac_unit_rounded,
        size: 16.sp,
        color: PathBrandColors.gold,
      );
    }
    final icon = Icon(
      Icons.local_fire_department_rounded,
      size: 16.sp,
      color: widget.idleColor,
    );
    final controller = _flicker;
    if (controller == null) return icon;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        return Transform.scale(
          scale: 0.92 + (t * 0.16),
          child: Opacity(
            opacity: 0.82 + (t * 0.18),
            child: child,
          ),
        );
      },
      child: icon,
    );
  }
}
