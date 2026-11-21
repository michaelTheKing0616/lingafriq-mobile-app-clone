part of '../unified_onboarding_screen.dart';

class _LearningStyleStep extends HookConsumerWidget {
  const _LearningStyleStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static _styles(BuildContext context) => [
    {
      'id': 'audio',
      'icon': Icons.headphones_rounded,
      'title': l10nOf(context).onboardingListening,
      'desc': l10nOf(context).onboardingLearnByEar,
    },
    {
      'id': 'visual',
      'icon': Icons.visibility_rounded,
      'title': l10nOf(context).onboardingVisual,
      'desc': l10nOf(context).onboardingSeeToRemember,
    },
    {
      'id': 'stories',
      'icon': Icons.auto_stories_rounded,
      'title': l10nOf(context).onboardingStories,
      'desc': l10nOf(context).onboardingNarrativeLearning,
    },
    {
      'id': 'drills',
      'icon': Icons.repeat_rounded,
      'title': l10nOf(context).onboardingPractice,
      'desc': l10nOf(context).onboardingRepetitionDrills,
    },
    {
      'id': 'conversation',
      'icon': Icons.chat_rounded,
      'title': l10nOf(context).onboardingConversation,
      'desc': l10nOf(context).onboardingTalkToLearn,
    },
    {
      'id': 'mixed',
      'icon': Icons.shuffle_rounded,
      'title': l10nOf(context).onboardingMixed,
      'desc': l10nOf(context).onboardingVarietyOfMethods,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value != null,
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('learning_style', selected.value!);
          } catch (e) {
            logger.error('Error saving learning style', error: e);
          }
          onNext({'learning_style': selected.value});
        },
      ),
      header: _QuestionHeader(
        question: l10nOf(context).onboardingHowDoYouLearnBest,
        hint: l10nOf(context).onboardingPickTheStyleThatFeelsMost,
        step: OnboardingStep.learningStyle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final style in _styles(context))
            _SelectRow(
              label: style['title'] as String,
              subtitle: style['desc'] as String,
              isSelected: selected.value == style['id'],
              leading: Icon(
                style['icon'] as IconData,
                color: ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                selected.value = style['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. First win — Speak/Finch celebration after micro-lesson
// =============================================================================
