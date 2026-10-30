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
            showCaption: false,
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
String _bidi(BuildContext context, String text) {
  final locale = Localizations.maybeLocaleOf(context);
  final ar = locale?.languageCode == 'ar' ? _arCopy[text] : null;
  if (ar != null) return ar;
  return Directionality.of(context) == TextDirection.rtl &&
          !_rtlChars.hasMatch(text)
      ? '\u2066$text\u2069'
      : text;
}

/// Copy with a runtime value: Arabic built from [ar] for `ar`, else [en].
String _tr(BuildContext context, String en, String ar) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'ar'
    ? ar
    : _bidi(context, en);

/// Fade cue height; the body is inset by the same amount so the last line
/// always scrolls fully clear of the cue and the footer.
const double _scrollCueHeight = 64;

class _StepScaffold extends HookConsumerWidget {
  const _StepScaffold({
    required this.child,
    this.bottom,
    this.header,
    this.showOfflineNotice = true,
  });

  /// Off where the step shows its own offline error (one Retry only).
  final bool showOfflineNotice;

  final Widget child;

  /// Pinned above the scroll body so the question never scrolls away.
  final Widget? header;
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        showOfflineNotice && ref.watch(onboardingOnlineProvider).value == false;
    // At large text a pinned header starves the body: scroll it with the
    // body instead, and pin a one-line question once it scrolls away.
    final pinHeader = MediaQuery.textScalerOf(context).scale(1) < 1.5;
    final question = switch (header) {
      final _QuestionHeader h => h.question,
      _ => null,
    };
    final moreBelow = useState(false);
    final headerGone = useState(false);
    bool onMetrics(ScrollNotification n) {
      final m = n.metrics;
      if (n.depth != 0 || m.axis != Axis.vertical) return false;
      moreBelow.value = m.extentAfter > 1;
      headerGone.value = !pinHeader && m.pixels > 48;
      return false;
    }

    // Question steps at large text scroll the notice with the header and body.
    final scrollNotice = offline && !pinHeader;
    final notice = _OfflineNotice(
      key: const ValueKey('step-offline-notice'),
      onRetry: () => ref.invalidate(onboardingOnlineProvider),
    );
    return Container(
      color: ModernGriotColors.surface,
      child: ResponsiveSafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => Column(
            children: [
              SizedBox(height: ModernGriotSpacing.xxl.h),
              // At large text the notice scrolls with the body (below) so it
              // cannot starve the body and push the CTA off screen.
              if (offline && !scrollNotice) notice,
              if (header != null && pinHeader)
                ConstrainedBox(
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
              // The slot is reserved up front so the body never jumps when
              // the one-line question appears.
              if (question != null && !pinHeader)
                SizedBox(
                  height:
                      MediaQuery.textScalerOf(context).scale(16.sp) * 1.5 +
                      ModernGriotSpacing.xs.h * 2,
                  child: headerGone.value
                      ? _CompactQuestion(question: question)
                      : null,
                ),
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (n) {
                    final m = n.metrics;
                    if (n.depth == 0 && m.axis == Axis.vertical) {
                      moreBelow.value = m.extentAfter > 1;
                    }
                    return false;
                  },
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: onMetrics,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bottomInset = bottom == null
                                  ? 0.0
                                  : _scrollCueHeight.h;
                              return SingleChildScrollView(
                                key: const ValueKey('step-body'),
                                // Bottom inset = the fade height, so the last
                                // line always scrolls clear of the cue/footer.
                                padding: EdgeInsets.fromLTRB(
                                  ModernGriotSpacing.lg.w,
                                  0,
                                  ModernGriotSpacing.lg.w,
                                  bottomInset,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: math.max(
                                      0,
                                      constraints.maxHeight - bottomInset,
                                    ),
                                  ),
                                  child:
                                      (header != null && !pinHeader) ||
                                          scrollNotice
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (scrollNotice) notice,
                                            ?header,
                                            child,
                                          ],
                                        )
                                      : child,
                                ),
                              );
                            },
                          ),
                        ),
                        // Scroll cue: only when content continues below.
                        if (bottom != null && moreBelow.value)
                          PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 0,
                            height: _scrollCueHeight.h,
                            child: const IgnorePointer(
                              key: ValueKey('step-scroll-fade'),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x00FEF6E7),
                                      ModernGriotColors.surface,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (bottom != null)
                DecoratedBox(
                  key: const ValueKey('step-bottom'),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surface,
                    boxShadow: moreBelow.value
                        ? [
                            BoxShadow(
                              color: ModernGriotColors.onSurface.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, -4),
                            ),
                          ]
                        : const [],
                  ),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line question pinned at large text once the full header scrolls off.
class _CompactQuestion extends StatelessWidget {
  const _CompactQuestion({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('step-compact-question'),
      padding: EdgeInsets.symmetric(
        horizontal: ModernGriotSpacing.lg.w,
        vertical: ModernGriotSpacing.xs.h,
      ),
      child: Semantics(
        header: true,
        child: Text(
          _bidi(context, question),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ModernGriotTypography.titleMedium(
            context: context,
            color: ModernGriotColors.onSurface,
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
    this.busy = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  /// In-button progress while the step saves (no full-screen scrim).
  final bool busy;
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: math.max(
            ModernGriotLayout.minTouchTarget.h,
            ModernGriotLayout.minTouchTarget.toDouble(),
          ),
        ),
        child: FilledButton(
          onPressed: enabled && !busy
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed?.call();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: ModernGriotColors.surfaceContainerHighest,
            disabledForegroundColor: _captionInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
            textStyle: ModernGriotTypography.titleMedium(context: context),
          ),
          child: busy
              ? _BusyLabel(label: _bidi(context, 'Saving…'))
              : Text(_bidi(context, label), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _BusyLabel extends StatelessWidget {
  const _BusyLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: DefaultTextStyle.of(context).style.color,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(_bidi(context, label))),
      ],
    ),
  );
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
                    ? ModernGriotColors.primary
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
                    color: ModernGriotColors.primary,
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
              color: _captionInk,
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
  const _OfflineNotice({super.key, required this.onRetry});

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
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          border: Border.all(color: ModernGriotColors.outline),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ModernGriotColors.onSurface,
            ),
            SizedBox(width: ModernGriotSpacing.sm.w),
            Expanded(
              child: Text(
                _bidi(context, message),
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: ModernGriotColors.onSurface,
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
                _bidi(context, 'Retry'),
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
