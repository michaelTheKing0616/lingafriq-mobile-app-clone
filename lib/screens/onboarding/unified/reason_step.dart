part of '../unified_onboarding_screen.dart';

/// Step 3 — why are you learning (Duolingo web 20, Finch 06). One question.
class _ReasonStep extends HookConsumerWidget {
  const _ReasonStep({required this.onNext, required this.learningLanguage});

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  static const _reasons = [
    (
      id: 'family',
      icon: Icons.favorite_rounded,
      title: 'Talk to family',
      subtitle: 'Greet elders and keep up at gatherings',
      reason: 'family',
    ),
    (
      id: 'heritage',
      icon: Icons.diversity_3_rounded,
      title: 'Heritage and culture',
      subtitle: 'Proverbs, names, music and stories',
      reason: 'heritage',
    ),
    (
      id: 'travel',
      icon: Icons.flight_rounded,
      title: 'Travel',
      subtitle: 'Markets, directions and small talk',
      reason: 'travel',
    ),
    (
      id: 'work',
      icon: Icons.work_rounded,
      title: 'Work',
      subtitle: 'Colleagues, clients and community',
      reason: 'business',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<List<String>>(const []);
    final languageName = _lessonCopyFor(learningLanguage).name;

    Future<void> submit() async {
      final reasons = [
        for (final id in selected.value)
          _reasons.firstWhere((r) => r.id == id).reason,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuestionHeader(
            step: OnboardingStep.goals,
            question: 'Why are you learning $languageName?',
            hint: 'Pick all that fit. Your first lessons follow your answer.',
          ),
          for (final r in _reasons)
            _SelectRow(
              height: ModernGriotLayout.selectRowComfortable,
              label: r.title,
              subtitle: r.subtitle,
              isSelected: selected.value.contains(r.id),
              leading: Icon(
                r.icon,
                color: selected.value.contains(r.id)
                    ? ModernGriotColors.brandCoral
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
