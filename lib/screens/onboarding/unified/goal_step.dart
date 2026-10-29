part of '../unified_onboarding_screen.dart';

class _GoalStep extends HookConsumerWidget {
  const _GoalStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _goals = [
    {
      'id': 'family',
      'icon': Icons.favorite_rounded,
      'title': 'Talk to family',
      'reason': 'family',
    },
    {
      'id': 'travel',
      'icon': Icons.flight_rounded,
      'title': 'Travel',
      'reason': 'travel',
    },
    {
      'id': 'heritage',
      'icon': Icons.diversity_3_rounded,
      'title': 'Heritage and culture',
      'reason': 'heritage',
    },
    {
      'id': 'work',
      'icon': Icons.work_rounded,
      'title': 'Work',
      'reason': 'business',
    },
  ];

  static const _durations = [
    {'min': 5, 'label': 'Casual'},
    {'min': 10, 'label': 'Steady'},
    {'min': 15, 'label': 'Serious'},
    {'min': 20, 'label': 'Intense'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<Set<String>>({});
    final duration = useState(10);

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selected.value.isNotEmpty,
        onPressed: () async {
          final reasons = selected.value
              .map(
                (id) =>
                    _goals.firstWhere((g) => g['id'] == id)['reason'] as String,
              )
              .toList();
          final primary = selected.value.first;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('primary_goal', primary);
            await prefs.setStringList('learning_reasons', reasons);
            await prefs.setInt('daily_duration', duration.value);
          } catch (e) {
            logger.error('Error saving goals', error: e);
          }
          onNext({
            'primary_goal': primary,
            'learning_reasons': reasons,
            'daily_duration_minutes': duration.value,
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why are you learning?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick one or more. We will shape your first path around them.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final goal in _goals)
            _SelectRow(
              height: ModernGriotLayout.selectRowComfortable,
              label: goal['title'] as String,
              isSelected: selected.value.contains(goal['id']),
              leading: Icon(
                goal['icon'] as IconData,
                color: selected.value.contains(goal['id'])
                    ? ModernGriotColors.brandCoral
                    : ModernGriotColors.primary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = Set<String>.from(selected.value);
                final id = goal['id'] as String;
                if (next.contains(id)) {
                  next.remove(id);
                } else {
                  next.add(id);
                }
                selected.value = next;
              },
            ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          Text(
            'Daily time',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          Wrap(
            spacing: ModernGriotSpacing.xs.w,
            runSpacing: ModernGriotSpacing.xs.h,
            children: [
              for (final d in _durations)
                Semantics(
                  button: true,
                  selected: duration.value == d['min'],
                  label: '${d['min']} minutes, ${d['label']}',
                  child: ChoiceChip(
                    selected: duration.value == d['min'],
                    label: Text('${d['min']} min · ${d['label']}'),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      duration.value = d['min'] as int;
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                    selectedColor: ModernGriotColors.brandGold.withValues(
                      alpha: _GriotAlpha.chipSelected,
                    ),
                    labelStyle: ModernGriotTypography.labelLarge(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. Level placement — Duolingo signal bars
// =============================================================================
