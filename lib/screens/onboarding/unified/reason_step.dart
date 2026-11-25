part of '../unified_onboarding_screen.dart';

/// Step 3 — why are you learning (Duolingo web 20, Finch 06). One question.
class _ReasonStep extends HookConsumerWidget {
  const _ReasonStep({required this.onNext, required this.learningLanguage});

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  static _reasons(BuildContext context) => [
    (
      id: 'family',
      icon: Icons.favorite_rounded,
      title: l10nOf(context).onboardingTalkToFamily,
      subtitle: l10nOf(context).onboardingGreetEldersAndKeepUpAt,
      reason: 'family',
    ),
    (
      id: 'heritage',
      icon: Icons.diversity_3_rounded,
      title: l10nOf(context).onboardingHeritageAndCulture,
      subtitle: l10nOf(context).onboardingProverbsNamesMusicAndStories,
      reason: 'heritage',
    ),
    (
      id: 'travel',
      icon: Icons.flight_rounded,
      title: 'Travel',
      subtitle: l10nOf(context).onboardingMarketsDirectionsAndSmallTalk,
      reason: 'travel',
    ),
    (
      id: 'work',
      icon: Icons.work_rounded,
      title: 'Work',
      subtitle: l10nOf(context).onboardingColleaguesClientsAndCommunity,
      reason: 'business',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<List<String>>(const []);
    final languageName = _lessonCopyFor(learningLanguage).name;

    Future<void> submit() async {
      final List<String> reasons = [
        for (final id in selected.value)
          _reasons(context).firstWhere((r) => r.id == id).reason,
      ];
      final primary = selected.value.first;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('primary_goal', primary);
        await prefs.setStringList('learning_reasons', reasons);
      } catch (e) {
        logger.error('Error saving learning reasons', error: e);
      }
      onNext({'primary_goal': primary, 'learning_reasons': reasons});
    }

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value.isNotEmpty,
        onPressed: submit,
      ),
      header: _QuestionHeader(
        step: OnboardingStep.goals,
        question: l10nOf(context).onboardingWhyAreYouLearningLanguagename(languageName.toString()),
        hint: l10nOf(context).onboardingPickAllThatFitYourFirst,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in _reasons(context))
            _SelectRow(
              height: ModernGriotLayout.selectRowComfortable,
              label: r.title,
              subtitle: r.subtitle,
              isSelected: selected.value.contains(r.id),
              leading: Icon(
                r.icon,
                color: selected.value.contains(r.id)
                    ? ModernGriotColors.primary
                    : ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = [...selected.value];
                next.contains(r.id) ? next.remove(r.id) : next.add(r.id);
                selected.value = next;
              },
            ),
        ],
      ),
    );
  }
}
