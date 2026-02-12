import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

/// Tutor Progress Dashboard
/// Shows CEFR progress, skill levels, and adaptive recommendations
class TutorProgressDashboardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const TutorProgressDashboardScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressService = ref.read(tutorProgressServiceProvider);
    final progress = useState<TutorProgress?>(null);
    final isLoading = useState(true);
    final adaptiveSettings = useState<Map<String, dynamic>?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load progress
    useEffect(() {
      _loadProgress(progressService, progress, adaptiveSettings, isLoading);
      return null;
    }, []);

    if (isLoading.value || progress.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Tutor Progress')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = progress.value!;
    final settings = adaptiveSettings.value ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadProgress(progressService, progress, adaptiveSettings, isLoading),
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
                // CEFR Progress Card
                _CefrProgressCard(progress: p, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Skill Levels
                _SkillLevelsCard(progress: p, isDark: isDark)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Adaptive Recommendations
                if (settings.isNotEmpty)
                  _AdaptiveRecommendationsCard(
                    settings: settings,
                    progress: p,
                    isDark: isDark,
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1),

                SizedBox(height: PanAfricanSpacing.lg),

                // Statistics
                _StatisticsCard(progress: p, isDark: isDark)
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProgress(
    TutorProgressService service,
    ValueNotifier<TutorProgress?> progress,
    ValueNotifier<Map<String, dynamic>?> adaptiveSettings,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final p = await service.loadProgress(progress.value?.language ?? 'Yoruba');
      final settings = await service.getAdaptiveSettings(p.language);
      progress.value = p;
      adaptiveSettings.value = settings;
    } catch (e) {
      debugPrint('Error loading tutor progress: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _CefrProgressCard extends StatelessWidget {
  final TutorProgress progress;
  final bool isDark;

  const _CefrProgressCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(progress.currentCefrLevel);
    final nextLevel = progress.getRecommendedNextLevel();
    final canAdvance = nextLevel != progress.currentCefrLevel;

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
              'CEFR Progress',
              style: PanAfricanTypography.titleLarge(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // CEFR Level Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: levels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;
                final isCurrent = level == progress.currentCefrLevel;
                final isCompleted = index < currentIndex;
                final isNext = level == nextLevel && canAdvance;

                return Column(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? PanAfricanColors.primary
                            : isCompleted
                                ? PanAfricanColors.success
                                : isNext
                                    ? PanAfricanColors.accent
                                    : PanAfricanColors.neutralLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          level,
                          style: PanAfricanTypography.labelMedium(context)?.copyWith(
                            color: isCurrent || isCompleted || isNext
                                ? Theme.of(context).colorScheme.onPrimary
                                : PanAfricanColors.neutralMedium,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        '${progress.cefrScore.toStringAsFixed(0)}%',
                        style: PanAfricanTypography.bodySmall(context)?.copyWith(
                          color: PanAfricanColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Progress Bar
            LinearProgressIndicator(
              value: progress.cefrScore / 100.0,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
              minHeight: 8.h,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              '${progress.cefrScore.toStringAsFixed(1)}% to next level',
              style: PanAfricanTypography.bodySmall(context),
            ),
            if (canAdvance) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: PanAfricanColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: PanAfricanColors.accent),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      'Ready for $nextLevel!',
                      style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                        color: PanAfricanColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillLevelsCard extends StatelessWidget {
  final TutorProgress progress;
  final bool isDark;

  const _SkillLevelsCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final skills = [
      {'name': 'Grammar', 'score': progress.skillLevels['grammar'] ?? 0.0, 'icon': Icons.menu_book, 'color': PanAfricanColors.primary},
      {'name': 'Pronunciation', 'score': progress.skillLevels['pronunciation'] ?? 0.0, 'icon': Icons.record_voice_over, 'color': PanAfricanColors.secondary},
      {'name': 'Vocabulary', 'score': progress.skillLevels['vocabulary'] ?? 0.0, 'icon': Icons.book, 'color': PanAfricanColors.accent},
      {'name': 'Comprehension', 'score': progress.skillLevels['comprehension'] ?? 0.0, 'icon': Icons.hearing, 'color': PanAfricanColors.tertiary},
    ];

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill Levels',
              style: PanAfricanTypography.titleMedium(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...skills.map((skill) {
              final score = skill['score'] as double;
              final color = skill['color'] as Color;
              final isWeak = score < 60.0;
              
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(skill['icon'] as IconData, size: 20.sp, color: color),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Expanded(
                          child: Text(
                            skill['name'] as String,
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                        ),
                        if (isWeak)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: PanAfricanColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                            ),
                            child: Text(
                              'Needs Practice',
                              style: PanAfricanTypography.labelSmall(context)?.copyWith(
                                color: PanAfricanColors.error,
                              ),
                            ),
                          ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Text(
                          '${score.toStringAsFixed(0)}%',
                          style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    LinearProgressIndicator(
                      value: score / 100.0,
                      backgroundColor: PanAfricanColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6.h,
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

class _AdaptiveRecommendationsCard extends StatelessWidget {
  final Map<String, dynamic> settings;
  final TutorProgress progress;
  final bool isDark;

  const _AdaptiveRecommendationsCard({
    required this.settings,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final weakAreas = progress.getWeakAreas();
    final recommendedTopics = (settings['recommended_topics'] as List?)?.cast<String>() ?? [];

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: PanAfricanColors.accent),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Adaptive Recommendations',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            if (weakAreas.isNotEmpty) ...[
              Text(
                'Focus Areas:',
                style: PanAfricanTypography.labelLarge(context)?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Wrap(
                spacing: PanAfricanSpacing.sm,
                runSpacing: PanAfricanSpacing.sm,
                children: weakAreas.map((area) {
                  return Chip(
                    label: Text(area),
                    backgroundColor: PanAfricanColors.error.withOpacity(0.1),
                    labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                      color: PanAfricanColors.error,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: PanAfricanSpacing.md),
            ],
            if (recommendedTopics.isNotEmpty) ...[
              Text(
                'Recommended Topics:',
                style: PanAfricanTypography.labelLarge(context)?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Wrap(
                spacing: PanAfricanSpacing.sm,
                runSpacing: PanAfricanSpacing.sm,
                children: recommendedTopics.map((topic) {
                  return Chip(
                    label: Text(topic),
                    backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                    labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                      color: PanAfricanColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final TutorProgress progress;
  final bool isDark;

  const _StatisticsCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: PanAfricanTypography.titleMedium(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Sessions',
                  value: '${progress.totalSessions}',
                  icon: Icons.school,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Avg Score',
                  value: '${progress.averageScore.toStringAsFixed(0)}%',
                  icon: Icons.star,
                  color: PanAfricanColors.accent,
                ),
                _StatItem(
                  label: 'Time',
                  value: '${(progress.totalTimeSpent / 3600).toStringAsFixed(1)}h',
                  icon: Icons.timer,
                  color: PanAfricanColors.secondary,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Vocab',
                  value: '${progress.vocabularyMastered.length}',
                  icon: Icons.book,
                  color: PanAfricanColors.tertiary,
                ),
                _StatItem(
                  label: 'Grammar',
                  value: '${progress.grammarPointsMastered.length}',
                  icon: Icons.menu_book,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Topics',
                  value: '${progress.topicsMastered.length}',
                  icon: Icons.topic,
                  color: PanAfricanColors.accent,
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

