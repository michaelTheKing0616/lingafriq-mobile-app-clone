part of '../unified_onboarding_screen.dart';

class _NotificationsStep extends HookConsumerWidget {
  const _NotificationsStep({
    required this.onNext,
    required this.dailyMinutes,
    required this.learningLanguage,
  });

  final Function(Map<String, dynamic>) onNext;
  final int dailyMinutes;
  final String learningLanguage;

  static List<Map<String, String>> _times(BuildContext context) =>
      <Map<String, String>>[
    {'id': 'sunrise', 'label': l10nOf(context).onboardingSunrise, 'time': l10nOf(context).onboardingText69Am},
    {'id': 'midday', 'label': l10nOf(context).onboardingMidday, 'time': l10nOf(context).onboardingText122Pm},
    {'id': 'sunset', 'label': l10nOf(context).onboardingSunset, 'time': l10nOf(context).onboardingText57Pm},
    {'id': 'night', 'label': l10nOf(context).onboardingNight, 'time': l10nOf(context).onboardingText810Pm},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTime = useState<String?>('sunrise');
    final lesson = _lessonCopyFor(learningLanguage);
    final reminderLine = lesson.reminder.replaceFirst(
      l10nOf(context).onboardingText5Minutes,
      l10nOf(context).onboardingDailyminutesMinutes(dailyMinutes.toString()),
    );

    Future<void> finish({required bool enable}) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('daily_duration', dailyMinutes);
        await prefs.setString(
          'preferred_time',
          selectedTime.value ?? 'sunrise',
        );
        await prefs.setBool('reminders_enabled', enable);
        if (enable) {
          try {
            await ref
                .read(firebaseMessagingProvider)
                .messaging
                .requestPermission();
          } catch (e) {
            logger.warn('Notification permission request failed', error: e);
          }
        }
      } catch (e) {
        logger.error('Error saving reminders', error: e);
      }
      onNext({
        'daily_duration_minutes': dailyMinutes,
        'preferred_time_of_day': selectedTime.value ?? 'sunrise',
        'reminders_enabled': enable,
      });
    }

    return _StepScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryCta(
            label: l10nOf(context).onboardingTurnOnReminders,
            enabled: selectedTime.value != null,
            onPressed: () => finish(enable: true),
          ),
          TextButton(
            onPressed: () => finish(enable: false),
            style: TextButton.styleFrom(
              minimumSize: const Size(
                ModernGriotLayout.minTouchTarget,
                ModernGriotLayout.minTouchTarget,
              ),
            ),
            child: Text(
              _bidi(context, l10nOf(context).onboardingNotNow),
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: _captionInk,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
        ],
      ),
      header: _QuestionHeader(
        question: l10nOf(context).onboardingASoftNudgeWhenItMatters,
        hint:
            l10nOf(context).onboardingSeeTheReminderBelowTurnIt,
        step: OnboardingStep.schedule,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ModernGriotSpacing.lg.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ModernGriotSpacing.md.w),
            decoration: BoxDecoration(
              color: ModernGriotColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              border: Border.all(
                color: ModernGriotColors.brandGold.withValues(
                  alpha: _GriotAlpha.goldBorder,
                ),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PolieBadge(
                      step: OnboardingStep.schedule,
                      size: ModernGriotLayout.selectRowMin.w,
                    ),
                    SizedBox(width: ModernGriotSpacing.sm.w),
                    Expanded(
                      child: Text(
                        _bidi(context, reminderLine),
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ModernGriotSpacing.sm.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ModernGriotSpacing.sm.w,
                    vertical: ModernGriotSpacing.xxs.h,
                  ),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.chipSelected,
                    ),
                    borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
                  ),
                  child: Text(
                    _bidi(
                      context,
                      () {
                        final List<Map<String, String>> times = _times(
                          context,
                        );
                        return times.firstWhere(
                          (Map<String, String> slot) =>
                              slot['id'] == selectedTime.value,
                          orElse: () => times.first,
                        )['time']!;
                      }(),
                    ),
                    style: ModernGriotTypography.labelLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Text(
            _bidi(context, l10nOf(context).onboardingBestTime),
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          for (final t in _times(context))
            _SelectRow(
              label: t['label'] as String,
              subtitle: t['time'] as String,
              isSelected: selectedTime.value == t['id'],
              onTap: () {
                HapticFeedback.selectionClick();
                selectedTime.value = t['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// Tone + gamification (preserved)
// =============================================================================
