import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/screens/curriculum/lesson_detail_screen.dart';
import 'package:lingafriq/services/deep_link_service.dart';

class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({super.key});

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurriculum();
    });
  }

  Future<void> _loadCurriculum() async {
    try {
      await ref.read(curriculumProvider.notifier).loadCurriculumFromBundle();
      
      // Check for pending deep link lesson after curriculum loads
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final pendingLessonId = DeepLinkService.consumePendingLessonId();
          if (pendingLessonId != null) {
            _navigateToDeepLinkedLesson(pendingLessonId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load curriculum. Please check your connection and try again.',
      onRetry: () {
        _loadCurriculum();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final curriculum = ref.watch(curriculumProvider.notifier).curriculum;
    final selectedLanguage = ref.watch(curriculumProvider.notifier).selectedLanguage;
    final isLoading = ref.watch(curriculumProvider.select((state) => state.isLoading));
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Comprehensive Curriculum'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
        foregroundColor: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final offlineState = ref.watch(offlineDownloadProvider);
              final offlineNotifier = ref.read(offlineDownloadProvider.notifier);
              final selectedLanguage = ref.watch(curriculumProvider.notifier).selectedLanguage;
              
              return IconButton(
                icon: offlineState.isDownloading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.cloud_download,
                        color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                      ),
                onPressed: selectedLanguage != null && !offlineState.isDownloading
                    ? () async {
                        try {
                          await offlineNotifier.downloadAllLessonsForLanguage(selectedLanguage);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('All lessons for $selectedLanguage downloaded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to download lessons: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                tooltip: selectedLanguage != null
                    ? 'Download All for Offline'
                    : 'Select a language first',
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface),
            onPressed: _loadCurriculum,
            tooltip: 'Reload Curriculum',
          ),
          IconButton(
            icon: Icon(Icons.menu, color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          ),
        ],
      ),
      body: isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonListCard(),
            )
          : ref.watch(curriculumProvider).hasError
              ? AppErrorState(
                  message: 'Failed to load curriculum',
                  onRetry: () => ref.invalidate(curriculumProvider),
                )
              : curriculum == null
                  ? AppEmptyState(
                      icon: Icons.menu_book_rounded,
                      title: 'No lessons available',
                      subtitle: 'Check back soon for new content',
                      actionLabel: 'Load Curriculum',
                      onAction: _loadCurriculum,
                    )
                  : _buildCurriculumContent(context, curriculum, selectedLanguage, isDark),
    );
  }

  Widget _buildCurriculumContent(
    BuildContext context,
    Curriculum curriculum,
    String? selectedLanguage,
    bool isDark,
  ) {
    return Column(
      children: [
        // Language Selection
        Container(
          padding: EdgeInsets.all(16.sp),
          color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12.sp),
              Wrap(
                spacing: 8.sp,
                runSpacing: 8.sp,
                children: curriculum.meta.languages.map((lang) {
                  final isSelected = selectedLanguage == lang;
                  return Semantics(
                    label: 'Language filter: ${lang.toUpperCase()}',
                    selected: isSelected,
                    button: true,
                    child: FilterChip(
                      label: Text(lang.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(curriculumProvider.notifier).setSelectedLanguage(lang);
                      },
                      selectedColor: PanAfricanColors.primary,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : (isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[200],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Levels and Units
        if (selectedLanguage != null)
          Expanded(
            child: _buildLevelsView(context, selectedLanguage, isDark),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'Select a language to view curriculum',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelsView(BuildContext context, String language, bool isDark) {
    final levels = ref.read(curriculumProvider.notifier).getLevelsForLanguage(language);

    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        return _buildLevelCard(context, level, language, isDark);
      },
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    CurriculumLevel level,
    String language,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
        childrenPadding: EdgeInsets.all(16.sp),
        leading: Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: PanAfricanColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            level.level,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: PanAfricanColors.primary,
            ),
          ),
        ),
        title: Text(
          'Level ${level.level}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.sp),
            Semantics(
              label: 'Progress: ${(level.calculatedProgress * 100).toInt()}% complete',
              value: '${(level.calculatedProgress * 100).toInt()}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: level.calculatedProgress,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                ),
              ),
            ),
            SizedBox(height: 4.sp),
            Semantics(
              label: 'Level ${level.level}: ${(level.calculatedProgress * 100).toInt()}% complete, ${level.units.length} units',
              child: Text(
                '${(level.calculatedProgress * 100).toInt()}% complete • ${level.units.length} units',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        children: level.units.map((unit) {
          return _buildUnitCard(context, unit, language, level.level, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    CurriculumUnit unit,
    String language,
    String level,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A4A35) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A5A45) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Unit ${unit.unit}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 8.sp),
              if (unit.isCompleted)
                Icon(Icons.check_circle, color: PanAfricanColors.primary, size: 20.sp),
            ],
          ),
          SizedBox(height: 4.sp),
          Text(
            unit.title,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.sp),
          Semantics(
            label: 'Unit ${unit.unit} progress: ${(unit.calculatedProgress * 100).toInt()}%',
            value: '${(unit.calculatedProgress * 100).toInt()}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: unit.calculatedProgress,
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF3A5A45) : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
              ),
            ),
          ),
          SizedBox(height: 12.sp),
          ...unit.lessons.map((lesson) {
            return _buildLessonTile(context, lesson, language, level, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    CurriculumLesson lesson,
    String language,
    String level,
    bool isDark,
  ) {
    final heroTag = 'lesson_icon_${lesson.id}';
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      leading: Hero(
        tag: heroTag,
        child: Container(
          width: 40.sp,
          height: 40.sp,
          decoration: BoxDecoration(
            color: lesson.isCompleted
                ? PanAfricanColors.primary.withOpacity(0.2)
                : (isDark ? const Color(0xFF3A5A45) : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: lesson.isCompleted
                ? Icon(Icons.check, color: PanAfricanColors.primary, size: 20.sp)
                : Text(
                    '${lesson.vocab.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              lesson.title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (lesson.grammar != null && lesson.grammar!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(left: 8.sp),
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
              decoration: BoxDecoration(
                color: PanAfricanColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PanAfricanColors.secondary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 12.sp,
                    color: PanAfricanColors.secondary,
                  ),
                  SizedBox(width: 4.sp),
                  Text(
                    'Tips',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: PanAfricanColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${lesson.vocab.length} words • ${lesson.exercises.length} exercises',
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Semantics(
        label: lesson.isCompleted ? 'Replay lesson: ${lesson.title}' : 'Start lesson: ${lesson.title}',
        button: true,
        child: IconButton(
          icon: Icon(
            lesson.isCompleted ? Icons.undo : Icons.play_circle_outline,
            color: lesson.isCompleted
                ? PanAfricanColors.primary
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          onPressed: () {
            // Navigate to lesson detail screen
            Navigator.push(
              context,
              SmoothPageRoute(
                child: LessonDetailScreen(
                  lesson: lesson,
                  language: language,
                  level: level,
                ),
              ),
            ).then((completed) {
              // Mark lesson as complete if user completed it
              if (completed == true && !lesson.isCompleted) {
                ref.read(curriculumProvider.notifier).markLessonComplete(
                      language,
                      level,
                      lesson.id,
                    );
              }
            });
          },
        ),
      ),
    );
  }

  /// Find a lesson by ID across all languages and levels
  ({CurriculumLesson lesson, String language, String level})? _findLessonById(String lessonId) {
    final curriculum = ref.read(curriculumProvider.notifier).curriculum;
    if (curriculum == null) return null;

    for (final languageEntry in curriculum.languages.entries) {
      final language = languageEntry.key;
      final levelsMap = languageEntry.value;

      for (final levelEntry in levelsMap.entries) {
        final level = levelEntry.key;
        final units = levelEntry.value;

        for (final unit in units) {
          for (final lesson in unit.lessons) {
            if (lesson.id == lessonId) {
              return (
                lesson: lesson,
                language: language,
                level: level,
              );
            }
          }
        }
      }
    }

    return null;
  }

  /// Navigate to a lesson from deep link
  void _navigateToDeepLinkedLesson(String lessonId) {
    final result = _findLessonById(lessonId);
    
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lesson not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        SmoothPageRoute(
          child: LessonDetailScreen(
            lesson: result.lesson,
            language: result.language,
            level: result.level,
          ),
        ),
      ).then((completed) {
        // Mark lesson as complete if user completed it
        if (completed == true && !result.lesson.isCompleted) {
          ref.read(curriculumProvider.notifier).markLessonComplete(
                result.language,
                result.level,
                result.lesson.id,
              );
        }
      });
    }
  }
}


