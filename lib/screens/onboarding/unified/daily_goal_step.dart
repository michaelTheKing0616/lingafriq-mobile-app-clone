part of '../unified_onboarding_screen.dart';

/// Step 5 — daily goal (Duolingo web 24, Headspace 07). One question; the
/// plain word next to each time means colour is never the only signal.
class _DailyGoalStep extends HookConsumerWidget {
  const _DailyGoalStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static _goals(BuildContext context) => [
    (min: 5, label: 'Casual', note: l10nOf(context).onboardingAGreetingADay),
    (min: 10, label: 'Steady', note: l10nOf(context).onboardingAGoodDailyStart),
    (min: 15, label: 'Serious', note: l10nOf(context).onboardingHoldAShortChatInWeeks),
    (min: 20, label: 'Intense', note: l10nOf(context).onboardingForATripOrABig),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = useState<int?>(null);

    Future<void> submit() async {
      final value = minutes.value!;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('daily_duration', value);
      } catch (e) {
        logger.error('Error saving daily goal', error: e);
      }
      onNext({'daily_duration_minutes': value});
    }

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: minutes.value != null,
        onPressed: submit,
      ),
      header: _QuestionHeader(
        step: OnboardingStep.schedule,
        question: l10nOf(context).onboardingHowMuchTimeADayFeels,
        hint: l10nOf(context).onboardingYouCanChangeThisAnyTime,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in _goals(context))
            _SelectRow(
              label: g.label,
              subtitle: g.note,
              isSelected: minutes.value == g.min,
              leading: _MinutesBadge(
                minutes: g.min,
                selected: minutes.value == g.min,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                minutes.value = g.min;
              },
            ),
        ],
      ),
    );
  }
}

class _MinutesBadge extends StatelessWidget {
  const _MinutesBadge({required this.minutes, required this.selected});

  final int minutes;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: ModernGriotSpacing.xxxl.w),
      padding: EdgeInsets.symmetric(
        horizontal: ModernGriotSpacing.xs.w,
        vertical: ModernGriotSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: selected
            ? ModernGriotColors.brandGold
            : ModernGriotColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
      ),
      child: Text(
        _bidi(context, l10nOf(context).onboardingMinutesMin(minutes.toString())),
        textAlign: TextAlign.center,
        style: ModernGriotTypography.labelLarge(
          context: context,
          color: selected
              ? ModernGriotColors.onBrandGold
              : ModernGriotColors.onSurface,
        ),
      ),
    );
  }
}
