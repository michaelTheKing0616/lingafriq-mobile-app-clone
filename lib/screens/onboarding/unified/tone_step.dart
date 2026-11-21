part of '../unified_onboarding_screen.dart';

class _ToneStep extends HookConsumerWidget {
  const _ToneStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static _tones(BuildContext context) => [
    {
      'id': 'playful',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'label': l10nOf(context).onboardingPlayful,
      'desc': l10nOf(context).onboardingFunLight,
    },
    {
      'id': 'encouraging',
      'icon': Icons.thumb_up_rounded,
      'label': l10nOf(context).onboardingEncouraging,
      'desc': l10nOf(context).onboardingSupportive,
    },
    {
      'id': 'serious',
      'icon': Icons.psychology_rounded,
      'label': l10nOf(context).onboardingFocused,
      'desc': l10nOf(context).onboardingDirectEfficient,
    },
    {
      'id': 'friendly',
      'icon': Icons.emoji_people_rounded,
      'label': l10nOf(context).onboardingFriendly,
      'desc': l10nOf(context).onboardingWarmCasual,
    },
  ];

  static _gamificationLevels(BuildContext context) => [
    {'id': 'full', 'label': l10nOf(context).onboardingFull, 'desc': l10nOf(context).onboardingXpBadgesStreaks},
    {'id': 'moderate', 'label': l10nOf(context).onboardingModerate, 'desc': l10nOf(context).onboardingProgressTracking},
    {'id': 'minimal', 'label': l10nOf(context).onboardingMinimal, 'desc': l10nOf(context).onboardingJustLearning},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTone = useState<String?>(null);
    final selectedGamification = useState<String?>('full');

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selectedTone.value != null,
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('app_tone', selectedTone.value!);
            await prefs.setString(
              'gamification_level',
              selectedGamification.value!,
            );
          } catch (e) {
            logger.error('Error saving tone/gamification', error: e);
          }
          onNext({
            'app_tone': selectedTone.value,
            'gamification_level': selectedGamification.value,
          });
        },
      ),
      header: _QuestionHeader(
        question: l10nOf(context).onboardingHowShouldPolieSound,
        hint: l10nOf(context).onboardingPickTheVoiceThatFeelsLike,
        step: OnboardingStep.story,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final tone in _tones(context))
            _SelectRow(
              label: tone['label'] as String,
              subtitle: tone['desc'] as String,
              isSelected: selectedTone.value == tone['id'],
              leading: Icon(
                tone['icon'] as IconData,
                color: ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                selectedTone.value = tone['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.md.h),
          Text(
            _bidi(context, l10nOf(context).onboardingHowMuchGameFeel),
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          for (final level in _gamificationLevels(context))
            _SelectRow(
              label: level['label'] as String,
              subtitle: level['desc'] as String,
              isSelected: selectedGamification.value == level['id'],
              onTap: () {
                HapticFeedback.selectionClick();
                selectedGamification.value = level['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// Profile / naming (preserved)
// =============================================================================
