import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/screens/curriculum/lesson_detail_screen.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/models/curriculum_model.dart';

/// Beautiful Material 3 Curriculum Screen
class CurriculumScreenMaterial3 extends HookConsumerWidget {
  const CurriculumScreenMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState('yoruba');
    final selectedLevel = useState('A1');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState(false);
    final error = useState<String?>(null);

    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu'];
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    // Load curriculum data from provider
    final curriculum = ref.watch(curriculumProvider.notifier).curriculum;
    final weeks = useState<List<Map<String, dynamic>>>([]);

    // Load lessons when language/level changes
    useEffect(() {
      safeAsync(
        context: context,
        operation: () async {
          isLoading.value = true;
          error.value = null;
          try {
            // Try to load from curriculum provider first
            if (curriculum != null) {
              final languageData = curriculum.languages[selectedLanguage.value];
              final levelData = languageData?[selectedLevel.value];
              if (levelData != null) {
                // Convert curriculum units to weeks format
                weeks.value = levelData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final unit = entry.value;
                  return {
                    'week': index + 1,
                    'title': unit.title,
                    'lessons': unit.lessons.map((lesson) {
                      // Check completion status from curriculum provider
                      final curriculumNotifier = ref.read(curriculumProvider.notifier);
                      final isCompleted = curriculumNotifier.isLessonCompleted(
                        selectedLanguage.value,
                        selectedLevel.value,
                        lesson.id,
                      );
                      return {
                      'id': lesson.id,
                      'title': lesson.title,
                      'completed': isCompleted,
                    };
                  }).toList(),
                };
              }).toList();
            }
          }
        } catch (e) {
          error.value = ErrorHandler.getUserFriendlyError(e);
        } finally {
          isLoading.value = false;
        }
        },
      );
      return null;
    }, [selectedLanguage.value, selectedLevel.value, curriculum]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Curriculum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Column(
          children: [
            // Language and Level Selectors
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Select language',
                      child: DropdownButtonFormField<String>(
                        value: selectedLanguage.value,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? PanAfricanColors.surfaceDark
                              : PanAfricanColors.surfaceLight,
                        ),
                        items: languages.map((lang) {
                          return DropdownMenuItem(
                            value: lang,
                            child: Text(lang.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) selectedLanguage.value = value;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Expanded(
                    child: Semantics(
                      label: 'Select level',
                      child: DropdownButtonFormField<String>(
                        value: selectedLevel.value,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? PanAfricanColors.surfaceDark
                              : PanAfricanColors.surfaceLight,
                        ),
                        items: levels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) selectedLevel.value = value;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Curriculum Content
            Expanded(
              child: isLoading.value
                  ? ListView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      itemCount: 5,
                      itemBuilder: (context, index) => const SkeletonListCard(),
                    )
                  : error.value != null
                      ? AppErrorState(
                          message: 'Failed to load curriculum',
                          onRetry: () {
                            safeAsync(
                              context: context,
                              operation: () async {
                                isLoading.value = true;
                                error.value = null;
                                await ref.read(curriculumProvider.notifier).loadCurriculumFromBundle();
                                isLoading.value = false;
                              },
                            );
                          },
                        )
                      : weeks.value.isEmpty
                          ? AppEmptyState(
                              icon: Icons.menu_book_rounded,
                              title: 'No lessons available',
                              subtitle: 'Check back soon for new content',
                            )
                          : OptimizedListView.builder(
                              padding: EdgeInsets.all(PanAfricanSpacing.lg),
                              itemCount: weeks.value.length,
                              itemBuilder: (context, index) {
                                final week = weeks.value[index];
                                return _WeekCard(
                                  week: week,
                                  isDark: isDark,
                                  onTap: () {
                                    // Navigate to week details
                                    if (week['lessons'] != null && (week['lessons'] as List).isNotEmpty) {
                                      final lessonData = (week['lessons'] as List)[0];
                                      final lesson = CurriculumLesson(
                                        id: lessonData['id']?.toString() ?? '',
                                        title: lessonData['title'] ?? 'Lesson',
                                        vocab: lessonData['vocab'] ?? [],
                                        exercises: (lessonData['exercises'] as List?)?.map((e) => CurriculumExercise.fromMap(e)).toList() ?? [],
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LessonDetailScreen(
                                            lesson: lesson,
                                            language: selectedLanguage.value,
                                            level: selectedLevel.value,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                )
                                    .animate(delay: (index * 50).ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.2);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final Map<String, dynamic> week;
  final bool isDark;
  final VoidCallback onTap;

  const _WeekCard({
    required this.week,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lessons = week['lessons'] as List? ?? [];
    final completedLessons = lessons.where((l) => l['completed'] == true).length;
    final progress = lessons.isNotEmpty ? completedLessons / lessons.length : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Semantics(
        label: '${week['title'] ?? 'Week ${week['week']}'}. Progress: $completedLessons out of ${lessons.length} lessons',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    week['title'] ?? 'Week ${week['week']}',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  Chip(
                    label: Text('$completedLessons/${lessons.length}'),
                    backgroundColor: PanAfricanColors.primaryContainer.withOpacity(0.3),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                week['description'] ?? '',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Semantics(
                label: 'Progress',
                value: '$completedLessons out of ${lessons.length} lessons completed',
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: PanAfricanColors.neutralLight,
                  valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                  minHeight: 8.h,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Wrap(
                spacing: PanAfricanSpacing.sm,
                children: lessons.take(3).map((lesson) {
                  return Chip(
                    label: Text(
                      lesson['title'] ?? 'Lesson',
                      style: PanAfricanTypography.labelSmall(context),
                    ),
                    backgroundColor: lesson['completed'] == true
                        ? PanAfricanColors.success.withOpacity(0.2)
                        : PanAfricanColors.neutralLight.withOpacity(0.3),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

