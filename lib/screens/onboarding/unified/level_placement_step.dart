part of '../unified_onboarding_screen.dart';

class _LevelPlacementStep extends HookConsumerWidget {
  const _LevelPlacementStep({
    required this.onNext,
    required this.learningLanguage,
  });

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  static const _levels = [
    {'id': 'new', 'label': "I'm new", 'bars': 0},
    {'id': 'words', 'label': 'I know some common words', 'bars': 1},
    {'id': 'basic', 'label': 'I can have basic conversations', 'bars': 2},
    {'id': 'topics', 'label': 'I can talk about various topics', 'bars': 3},
    {'id': 'fluent', 'label': 'I can hold a conversation', 'bars': 4},
  ];

  String get _langName {
    switch (learningLanguage) {
      case 'yo':
        return 'Yoruba';
      case 'sw':
        return 'Swahili';
      case 'ha':
        return 'Hausa';
      case 'ig':
        return 'Igbo';
      case 'zu':
        return 'Zulu';
      case 'am':
        return 'Amharic';
      default:
        return 'this language';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String?>(null);
    final showQuickCheck = useState(false);
    final recognizedWords = useState<Set<String>>({});

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value != null,
        onPressed: () async {
          final level = selected.value!;
          // Map level loosely into a default learning style so reask keys
          // that expect learning_style still receive a value when style
          // step is skipped in reask flows that only ask level.
          final styleHint = level == 'new' || level == 'words'
              ? 'audio'
              : 'mixed';
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('self_reported_level', level);
            if (prefs.getString('learning_style') == null) {
              await prefs.setString('learning_style', styleHint);
            }
          } catch (e) {
            logger.error('Error saving level', error: e);
          }
          onNext({'self_reported_level': level, 'learning_style': styleHint});
        },
      ),
      header: _QuestionHeader(
        question: 'How much $_langName do you know?',
        step: OnboardingStep.goals,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ModernGriotSpacing.lg.h),
          for (final level in _levels)
            _SelectRow(
              label: level['label'] as String,
              isSelected: selected.value == level['id'],
              leading: _SignalBars(filled: level['bars'] as int),
              onTap: () {
                HapticFeedback.selectionClick();
                selected.value = level['id'] as String;
              },
            ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                ModernGriotLayout.minTouchTarget,
              ),
              alignment: AlignmentDirectional.centerStart,
            ),
            onPressed: () {
              showQuickCheck.value = !showQuickCheck.value;
              if (!showQuickCheck.value) {
                recognizedWords.value = {};
                return;
              }
              selected.value = 'unsure';
            },
            // Non-breaking hyphen: "1-" never dangles at the end of a line.
            child: Text(
              _bidi(context, 'Not sure? Take a 1\u2011minute check'),
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: ModernGriotColors.primary,
              ),
            ),
          ),
          if (showQuickCheck.value) ...[
            SizedBox(height: ModernGriotSpacing.xs.h),
            Text(
              'Quick check: tap each word you recognize.',
              style: ModernGriotTypography.bodyMedium(
                context: context,
                color: ModernGriotColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            Wrap(
              spacing: ModernGriotSpacing.xs.w,
              children: [
                for (final word in _quickCheckWords(learningLanguage))
                  FilterChip(
                    label: Text(word),
                    selected: recognizedWords.value.contains(word),
                    onSelected: (isOn) {
                      HapticFeedback.selectionClick();
                      final next = Set<String>.from(recognizedWords.value);
                      if (isOn) {
                        next.add(word);
                      } else {
                        next.remove(word);
                      }
                      recognizedWords.value = next;
                      if (next.isEmpty) {
                        selected.value = 'unsure';
                      } else if (next.length >= 2) {
                        selected.value = 'words';
                      } else {
                        selected.value = 'new';
                      }
                    },
                  ),
              ],
            ),
          ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

List<String> _quickCheckWords(String code) {
  final copy = _lessonCopyFor(code);
  switch (code) {
    case 'ha':
      return [copy.hear, 'Na gode', 'Ina kwana'];
    case 'ig':
      return [copy.hear, 'Kedu', 'Daalụ'];
    case 'sw':
      return [copy.hear, 'Asante', 'Jambo'];
    case 'am':
      return [copy.hear, 'አመሰግናለሁ', 'እንደምን'];
    case 'zu':
      return [copy.hear, 'Ngiyabonga', 'Unjani'];
    default:
      return [copy.hear, 'Ẹ káàárọ̀', 'Oúnjẹ'];
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ModernGriotSpacing.xl.w,
      height: ModernGriotSpacing.lg.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final on = i < filled;
          return Padding(
            padding: EdgeInsetsDirectional.only(
              end: i == 3 ? 0 : ModernGriotSpacing.xxs.w,
            ),
            child: Container(
              width: ModernGriotSpacing.xxs.w,
              height: (ModernGriotSpacing.xs + i * ModernGriotSpacing.xxs).h,
              decoration: BoxDecoration(
                color: on
                    ? ModernGriotColors.primary
                    : ModernGriotColors.outlineVariant.withValues(
                        alpha: _GriotAlpha.signalEmpty,
                      ),
                borderRadius: BorderRadius.circular(ModernGriotRadius.xs / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Learning style (preserved feature)
// =============================================================================
