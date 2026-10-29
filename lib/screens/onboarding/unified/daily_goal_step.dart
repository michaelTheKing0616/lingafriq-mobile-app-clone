part of '../unified_onboarding_screen.dart';

/// Step 5 — daily goal (Duolingo web 24, Headspace 07). One question; the
/// plain word next to each time means colour is never the only signal.
class _DailyGoalStep extends HookConsumerWidget {
  const _DailyGoalStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _goals = [
    (min: 5, label: 'Casual', note: 'A greeting a day'),
    (min: 10, label: 'Steady', note: 'Most learners start here'),
    (min: 15, label: 'Serious', note: 'Hold a short chat in weeks'),
    (min: 20, label: 'Intense', note: 'For a trip or a big day soon'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _QuestionHeader(
            step: OnboardingStep.schedule,
            question: 'How much time a day feels right?',
            hint: 'You can change this any time in Settings.',
          ),
          for (final g in _goals)
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
        '$minutes min',
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
