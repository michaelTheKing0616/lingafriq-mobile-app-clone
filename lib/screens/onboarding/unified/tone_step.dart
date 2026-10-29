part of '../unified_onboarding_screen.dart';

class _ToneStep extends HookConsumerWidget {
  const _ToneStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _tones = [
    {
      'id': 'playful',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'label': 'Playful',
      'desc': 'Fun & light',
    },
    {
      'id': 'encouraging',
      'icon': Icons.thumb_up_rounded,
      'label': 'Encouraging',
      'desc': 'Supportive',
    },
    {
      'id': 'serious',
      'icon': Icons.psychology_rounded,
      'label': 'Focused',
      'desc': 'Direct & efficient',
    },
    {
      'id': 'friendly',
      'icon': Icons.emoji_people_rounded,
      'label': 'Friendly',
      'desc': 'Warm & casual',
    },
  ];

  static const _gamificationLevels = [
    {'id': 'full', 'label': 'Full', 'desc': 'XP, badges, streaks'},
    {'id': 'moderate', 'label': 'Moderate', 'desc': 'Progress tracking'},
    {'id': 'minimal', 'label': 'Minimal', 'desc': 'Just learning'},
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How should Polie sound?',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'Pick the voice that feels like a good study buddy.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          for (final tone in _tones)
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
            'How much game feel?',
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          for (final level in _gamificationLevels)
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
