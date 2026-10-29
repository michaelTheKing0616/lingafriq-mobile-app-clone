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

final _rtlChars = RegExp(r'[\u0590-\u08FF\uFB1D-\uFEFC]');

/// Onboarding copy is English today. In an RTL layout an English string must
/// still read LTR, or its punctuation flips ("?Not sure"). Wrap it in a
/// left-to-right isolate; real RTL strings pass through untouched.
String _bidi(BuildContext context, String text) =>
    Directionality.of(context) == TextDirection.rtl && !_rtlChars.hasMatch(text)
    ? '\u2066$text\u2069'
    : text;

class _StepScaffold extends ConsumerWidget {
  const _StepScaffold({required this.child, this.bottom, this.header});

  final Widget child;

  /// Pinned above the scroll body so the question never scrolls away.
  final Widget? header;
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(onboardingOnlineProvider).value == false;
    return Container(
      color: ModernGriotColors.surface,
      child: ResponsiveSafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => Column(
            children: [
              SizedBox(height: ModernGriotSpacing.xxl.h),
              if (offline)
                _OfflineNotice(
                  onRetry: () => ref.invalidate(onboardingOnlineProvider),
                ),
              if (header != null)
                ConstrainedBox(
                  // At 200% text the header may not starve the options.
                  constraints: BoxConstraints(
                    maxHeight: viewport.maxHeight * 0.35,
                  ),
                  child: SingleChildScrollView(
                    // Own position: must not share the body's primary
                    // controller, or scrolling options drags the header away.
                    primary: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: ModernGriotSpacing.lg.w,
                    ),
                    child: header,
                  ),
                ),
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
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  static const Color color = ModernGriotColors.brandGold;
  static const Color foreground = ModernGriotColors.onBrandGold;

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
            disabledForegroundColor: ModernGriotColors.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
            textStyle: ModernGriotTypography.titleMedium(context: context),
          ),
          child: Text(_bidi(context, label)),
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
      label: [label, if (subtitle != null) subtitle!].join(', '),
      hint: isSelected ? null : 'Double tap to choose',
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
                        _bidi(context, label),
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          _bidi(context, subtitle!),
                          style: ModernGriotTypography.bodyMedium(
                            context: context,
                            color: ModernGriotColors.onSurface,
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

/// Duolingo-pattern question header: Polie on the leading edge, the question
/// in a speech bubble pointing at her. One question per screen, always.
/// Uses directional insets so the tail flips for RTL (Arabic, Darija).
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.question,
    required this.step,
    this.hint,
  });

  final String question;
  final String? hint;
  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ExcludeSemantics(
              child: _PolieBadge(step: step, size: ModernGriotSpacing.xxxl.w),
            ),
            SizedBox(width: ModernGriotSpacing.xs.w),
            Expanded(
              child: Semantics(
                header: true,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ModernGriotSpacing.md.w,
                    vertical: ModernGriotSpacing.sm.h,
                  ),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerLowest,
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(ModernGriotRadius.xl),
                      topEnd: Radius.circular(ModernGriotRadius.xl),
                      bottomEnd: Radius.circular(ModernGriotRadius.xl),
                      bottomStart: Radius.circular(ModernGriotRadius.xs),
                    ).resolve(Directionality.of(context)),
                    border: Border.all(
                      color: ModernGriotColors.brandGold.withValues(
                        alpha: _GriotAlpha.goldBorder,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _bidi(context, question),
                    style: ModernGriotTypography.titleLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          SizedBox(height: ModernGriotSpacing.sm.h),
          Text(
            _bidi(context, hint!),
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: ModernGriotSpacing.lg.h),
      ],
    );
  }
}

/// In-flow offline notice. Answers are saved on the device either way, so
/// this is reassurance, not an error: no red, no blocking.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.onRetry});

  final VoidCallback onRetry;

  static const String message =
      "You're offline. Keep going: your answers are saved on this phone "
      'and sync when you reconnect.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          ModernGriotSpacing.lg.w,
          0,
          ModernGriotSpacing.lg.w,
          ModernGriotSpacing.sm.h,
        ),
        padding: EdgeInsetsDirectional.only(
          start: ModernGriotSpacing.md.w,
          end: ModernGriotSpacing.xxs.w,
          top: ModernGriotSpacing.xs.h,
          bottom: ModernGriotSpacing.xs.h,
        ),
        decoration: BoxDecoration(
          color: ModernGriotColors.secondaryContainer,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ModernGriotColors.onSecondaryContainer,
            ),
            SizedBox(width: ModernGriotSpacing.sm.w),
            Expanded(
              child: Text(
                message,
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: ModernGriotColors.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  ModernGriotLayout.minTouchTarget,
                  ModernGriotLayout.minTouchTarget,
                ),
              ),
              child: Text(
                'Retry',
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: ModernGriotColors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
