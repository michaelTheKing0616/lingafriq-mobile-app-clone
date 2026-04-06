import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class PracticeRoomSetupScreen extends ConsumerStatefulWidget {
  const PracticeRoomSetupScreen({super.key});

  @override
  ConsumerState<PracticeRoomSetupScreen> createState() =>
      _PracticeRoomSetupScreenState();
}

class _PracticeRoomSetupScreenState
    extends ConsumerState<PracticeRoomSetupScreen> {
  int _selectedLang = 0;
  int _selectedProficiency = 0;
  int _selectedGoal = 0;

  static const _languages = [
    _LangOption('Yoruba', Color(0xFF006B3E), Color(0xFFFFFFFF)),
    _LangOption('Zulu', Color(0xFF002395), Color(0xFFE03C31)),
    _LangOption('Swahili', Color(0xFF1EB53A), Color(0xFF006233)),
  ];

  static const _proficiencies = ['Beginner', 'Intermediate', 'Advanced'];

  static const _goals = [
    _GoalOption(
      'Pronunciation Lab',
      'Perfect your accent with AI-guided drills',
      Icons.record_voice_over_rounded,
    ),
    _GoalOption(
      'Vocab Drill',
      'Expand your word bank with spaced repetition',
      Icons.auto_stories_rounded,
    ),
    _GoalOption(
      'Casual Conversation',
      'Free-form practice with native speakers and fellow learners in a relaxed setting',
      Icons.forum_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.arrow_back_rounded,
                    size: 24.sp, color: cs.onSurface),
              ),
              SizedBox(height: 16.h),
              Text('Start Practice\nSession',
                  style:
                      ModernGriotTypography.headlineLarge(context: context)),
              SizedBox(height: 24.h),
              _buildLanguageCards(cs),
              SizedBox(height: 20.h),
              _buildProficiencyPills(cs),
              SizedBox(height: 24.h),
              Text('Session Goal',
                  style: ModernGriotTypography.titleMedium(
                      context: context)),
              SizedBox(height: 12.h),
              _buildGoalBento(cs),
              SizedBox(height: 16.h),
              _buildInfoNote(cs),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: GriotGradientButton(
                  label: 'Start Session',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pushNamed(
                      '/${VillageRouteNames.practiceSession}',
                    );
                  },
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCards(ColorScheme cs) {
    return Row(
      children: List.generate(_languages.length, (i) {
        final lang = _languages[i];
        final selected = _selectedLang == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4.w, right: i == 2 ? 0 : 4.w),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedLang = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.surfaceContainerLow,
                  borderRadius: ModernGriotRadius.borderXl,
                  border: selected
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                  boxShadow: selected
                      ? ModernGriotShadows.glow(cs.primary)
                      : ModernGriotShadows.sm,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36.r,
                      height: 6.h,
                      decoration: BoxDecoration(
                        borderRadius: ModernGriotRadius.borderPill,
                        gradient: LinearGradient(
                          colors: [lang.color1, lang.color2],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      lang.name,
                      style: ModernGriotTypography.labelLarge(
                        context: context,
                        color: selected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProficiencyPills(ColorScheme cs) {
    return Wrap(
      spacing: 8.w,
      children: List.generate(_proficiencies.length, (i) {
        return GriotChip(
          label: _proficiencies[i],
          selected: _selectedProficiency == i,
          onTap: () {
            setState(() => _selectedProficiency = i);
          },
        );
      }),
    );
  }

  Widget _buildGoalBento(ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _goalCard(0, cs)),
            SizedBox(width: 10.w),
            Expanded(child: _goalCard(1, cs)),
          ],
        ),
        SizedBox(height: 10.h),
        _goalCard(2, cs, fullWidth: true),
      ],
    );
  }

  Widget _goalCard(int index, ColorScheme cs, {bool fullWidth = false}) {
    final goal = _goals[index];
    final selected = _selectedGoal == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedGoal = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withAlpha(50)
              : cs.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderXl,
          border: selected
              ? Border.all(color: cs.primary, width: 1.5)
              : null,
          boxShadow: ModernGriotShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: (selected ? cs.primary : cs.onSurfaceVariant)
                    .withAlpha(20),
                borderRadius: ModernGriotRadius.borderMd,
              ),
              child: Icon(goal.icon,
                  size: 22.sp,
                  color: selected ? cs.primary : cs.onSurfaceVariant),
            ),
            SizedBox(height: 10.h),
            Text(goal.title,
                style: ModernGriotTypography.titleSmall(
                    context: context,
                    color: selected ? cs.primary : cs.onSurface)),
            SizedBox(height: 4.h),
            Text(goal.description,
                style: ModernGriotTypography.bodySmall(context: context),
                maxLines: fullWidth ? 3 : 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(ColorScheme cs) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.secondaryContainer.withAlpha(60),
        borderRadius: ModernGriotRadius.borderXl,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20.sp, color: cs.secondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Sessions are matched with learners at your level. '
              'You can switch goals mid-session anytime.',
              style: ModernGriotTypography.bodySmall(
                  context: context, color: cs.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption {
  const _LangOption(this.name, this.color1, this.color2);
  final String name;
  final Color color1;
  final Color color2;
}

class _GoalOption {
  const _GoalOption(this.title, this.description, this.icon);
  final String title;
  final String description;
  final IconData icon;
}
