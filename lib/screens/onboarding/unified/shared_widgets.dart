part of '../unified_onboarding_screen.dart';

/// Clips Polie to a fixed square so the avatar's internal column cannot
/// overflow speech-bubble rows on phone-sized layouts.
class _PolieBadge extends StatelessWidget {
  const _PolieBadge({required this.step, this.size});

  final OnboardingStep step;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final side = size ?? ModernGriotSpacing.xxxl.w;
    return SizedBox(
      width: side,
      height: side,
      child: ClipRect(
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: OnboardingAvatarWidget(
            step: step,
            size: side,
            animate: true,
            showDialogue: false,
          ),
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernGriotColors.surface,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            SizedBox(height: ModernGriotSpacing.xxl.h),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ModernGriotSpacing.lg.w,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.color = ModernGriotColors.brandGold,
    this.foreground = ModernGriotColors.onBrandGold,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ModernGriotSpacing.lg.w,
        ModernGriotSpacing.xs.h,
        ModernGriotSpacing.lg.w,
        ModernGriotSpacing.md.h,
      ),
      child: SizedBox(
        width: double.infinity,
        height: math.max(
          ModernGriotLayout.minTouchTarget.h,
          ModernGriotLayout.minTouchTarget.toDouble(),
        ),
        child: FilledButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed?.call();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: ModernGriotColors.surfaceContainerHighest,
            disabledForegroundColor: ModernGriotColors.onSurfaceVariant
                .withValues(alpha: _GriotAlpha.disabledLabel),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
            textStyle: ModernGriotTypography.titleMedium(context: context),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.height = ModernGriotLayout.selectRowMin,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: isSelected ? '$label, selected' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          child: AnimatedContainer(
            duration: _motionDuration(context, 180.ms),
            constraints: BoxConstraints(
              minHeight: math.max(
                height.h,
                ModernGriotLayout.minTouchTarget.toDouble(),
              ),
            ),
            margin: EdgeInsets.only(bottom: ModernGriotSpacing.sm.h),
            padding: EdgeInsets.symmetric(
              horizontal: ModernGriotSpacing.md.w,
              vertical: ModernGriotSpacing.sm.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.softSelected,
                    )
                  : ModernGriotColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              border: Border.all(
                color: isSelected
                    ? ModernGriotColors.brandCoral
                    : ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.ghostBorder,
                      ),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: ModernGriotSpacing.sm.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                            color: ModernGriotColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: ModernGriotColors.brandCoral,
                    size: ModernGriotSpacing.lg.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. Welcome — Finch mascot + Speak promise (Polie ~55%)
// =============================================================================
