import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/roleplay_progress_model.dart';
import 'package:lingafriq/services/roleplay_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/ai_chat/roleplay_scenario_selection_screen.dart';

/// Roleplay Progress Dashboard
/// Shows comprehensive progress tracking, statistics, and recommendations
class RoleplayProgressDashboardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const RoleplayProgressDashboardScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressService = ref.read(roleplayProgressServiceProvider);
    final progress = useState<RoleplayProgress?>(null);
    final isLoading = useState(true);
    final selectedCategory = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load progress
    useEffect(() {
      _loadProgress(progressService, progress, isLoading);
      return null;
    }, []);

    if (isLoading.value || progress.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Roleplay Progress')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = progress.value!;
    final scenarios = p.scenarios.values
        .where((s) => s.language == languageName)
        .where((s) => selectedCategory.value == null || s.category == selectedCategory.value)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Roleplay Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadProgress(progressService, progress, isLoading),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Stats
                _OverallStatsCard(progress: p, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Category Filter
                _CategoryFilter(
                  selectedCategory: selectedCategory.value,
                  onCategorySelected: (cat) => selectedCategory.value = cat,
                  isDark: isDark,
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.lg),

                // Difficulty Progress
                _DifficultyProgressCard(progress: p, isDark: isDark)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Scenarios List
                Text(
                  'Scenarios',
                  style: PanAfricanTypography.titleLarge(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.md),

                if (scenarios.isEmpty)
                  Card(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.xl),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 64.sp, color: PanAfricanColors.neutralMedium),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No scenarios completed yet',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  child: RoleplayScenarioSelectionScreen(
                                    language: language,
                                    languageName: languageName,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.play_arrow),
                            label: Text('Start Your First Scenario'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...scenarios.map((scenario) {
                    return _ScenarioProgressCard(
                      scenario: scenario,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            child: RoleplayScenarioSelectionScreen(
                              language: language,
                              languageName: languageName,
                            ),
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: 0.1);
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProgress(
    RoleplayProgressService service,
    ValueNotifier<RoleplayProgress?> progress,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final p = await service.loadProgress();
      progress.value = p;
    } catch (e) {
      debugPrint('Error loading progress: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _OverallStatsCard extends StatelessWidget {
  final RoleplayProgress progress;
  final bool isDark;

  const _OverallStatsCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          children: [
            Text(
              'Overall Progress',
              style: PanAfricanTypography.titleLarge(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Completed',
                  value: '${progress.totalScenariosCompleted}',
                  icon: Icons.check_circle,
                  color: PanAfricanColors.success,
                ),
                _StatItem(
                  label: 'Mastered',
                  value: '${progress.masteredScenarios.length}',
                  icon: Icons.star,
                  color: PanAfricanColors.accent,
                ),
                _StatItem(
                  label: 'Streak',
                  value: '${progress.currentStreak}',
                  icon: Icons.local_fire_department,
                  color: PanAfricanColors.error,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Accuracy',
                  value: '${(progress.averageAccuracy * 100).toStringAsFixed(0)}%',
                  icon: Icons.target,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Fluency',
                  value: '${(progress.averageFluency * 100).toStringAsFixed(0)}%',
                  icon: Icons.speed,
                  color: PanAfricanColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          value,
          style: PanAfricanTypography.titleMedium(context)?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context),
        ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool isDark;

  const _CategoryFilter({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Greetings', 'Shopping', 'Food', 'Travel', 'Health', 'Social', 'Business', 'Emergency'];
    
    return SizedBox(
      height: 50.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final isSelected = (cat == 'All' && selectedCategory == null) || cat == selectedCategory;
          return Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(cat == 'All' ? null : cat),
              selectedColor: PanAfricanColors.primary,
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DifficultyProgressCard extends StatelessWidget {
  final RoleplayProgress progress;
  final bool isDark;

  const _DifficultyProgressCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentDiff = progress.currentDifficulty;
    
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Progress',
              style: PanAfricanTypography.titleMedium(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...difficulties.map((diff) {
              final count = progress.difficultyProgress[diff] ?? 0;
              final isCurrent = diff == currentDiff;
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 60.w,
                      child: Text(
                        diff,
                        style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? PanAfricanColors.primary : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count > 0 ? (count / 10).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: PanAfricanColors.neutralLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCurrent ? PanAfricanColors.primary : PanAfricanColors.neutralMedium,
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      '$count',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScenarioProgressCard extends StatelessWidget {
  final ScenarioProgress scenario;
  final bool isDark;
  final VoidCallback onTap;

  const _ScenarioProgressCard({
    required this.scenario,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scenario.scenarioName,
                      style: PanAfricanTypography.titleMedium(context)?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (scenario.isMastered)
                    Icon(Icons.star, color: PanAfricanColors.accent, size: 24.sp),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Row(
                children: [
                  Chip(
                    label: Text(scenario.category),
                    backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                    labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                      color: PanAfricanColors.primary,
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Chip(
                    label: Text(scenario.difficulty),
                    backgroundColor: PanAfricanColors.secondary.withOpacity(0.1),
                    labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                      color: PanAfricanColors.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16.sp, color: PanAfricanColors.success),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    'Completed ${scenario.timesCompleted}x',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Icon(Icons.target, size: 16.sp, color: PanAfricanColors.primary),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    '${(scenario.averageAccuracy * 100).toStringAsFixed(0)}%',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
              ),
              if (scenario.streak > 0) ...[
                SizedBox(height: PanAfricanSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16.sp, color: PanAfricanColors.error),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Text(
                      '${scenario.streak} day streak',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

