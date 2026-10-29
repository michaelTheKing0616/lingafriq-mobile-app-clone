part of '../unified_onboarding_screen.dart';

class _LearningStyleStep extends HookConsumerWidget {
  const _LearningStyleStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _styles = [
    {
      'id': 'audio',
      'icon': Icons.headphones_rounded,
      'title': 'Listening',
      'desc': 'Learn by ear',
    },
    {
      'id': 'visual',
      'icon': Icons.visibility_rounded,
      'title': 'Visual',
      'desc': 'See to remember',
    },
    {
      'id': 'stories',
      'icon': Icons.auto_stories_rounded,
      'title': 'Stories',
      'desc': 'Narrative learning',
    },
    {
      'id': 'drills',
      'icon': Icons.repeat_rounded,
      'title': 'Practice',
      'desc': 'Repetition & drills',
    },
    {
      'id': 'conversation',
      'icon': Icons.chat_rounded,
      'title': 'Conversation',
      'desc': 'Talk to learn',
    },
    {
      'id': 'mixed',
      'icon': Icons.shuffle_rounded,
      'title': 'Mixed',
      'desc': 'Variety of methods',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you learn best?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick the style that feels most natural.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final style in _styles)
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
