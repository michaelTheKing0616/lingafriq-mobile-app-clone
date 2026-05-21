import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/screens/curriculum/lesson_detail_screen.dart';
import 'package:lingafriq/screens/lesson/authentic_lesson_flow_screen.dart';
import 'package:lingafriq/screens/curriculum/level_certificate_screen.dart';
import 'package:lingafriq/screens/persona_missions/persona_missions_hub_screen.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/utils/curriculum_languages.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

class CurriculumScreenMaterial3 extends HookConsumerWidget {
  const CurriculumScreenMaterial3({
    super.key,
    this.initialLanguage,
    this.initialLevel,
  });

  final String? initialLanguage;
  final String? initialLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(curriculumProvider.notifier).curriculum;
    final providerState = ref.watch(curriculumProvider);

    final defaultLang = CurriculumService.normalizeLanguageKey(
      initialLanguage ?? 'yoruba',
    );
    final selectedLanguage = useState(defaultLang);
    final selectedLevel = useState(initialLevel ?? 'A1');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState(true);
    final error = useState<String?>(null);

    final languages = CurriculumLanguages.pickerKeys(fromMeta: curriculum?.meta.languages);
    const fallbackLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

    final levels = curriculum != null && curriculum.meta.levels.isNotEmpty
        ? curriculum.meta.levels
        : fallbackLevels;

    String resolveLangKey(String pickerValue) =>
        CurriculumService.normalizeLanguageKey(pickerValue);

    bool languageHasContent(String langKey) {
      if (curriculum == null) return true;
      final normalized = resolveLangKey(langKey);
      return curriculum.languages.containsKey(normalized) ||
          curriculum.languages.containsKey(langKey);
    }

    bool levelHasContent(String level) {
      if (curriculum == null) return true;
      final normalized = resolveLangKey(selectedLanguage.value);
      final langData =
          curriculum.languages[normalized] ?? curriculum.languages[selectedLanguage.value];
      if (langData == null) return false;
      final unitList = langData[level];
      return unitList != null && unitList.isNotEmpty;
    }

    // Load curriculum bundle on mount (mirrors old CurriculumScreen.initState)
    useEffect(() {
      Future<void> doLoad() async {
          isLoading.value = true;
          error.value = null;
          try {
          await ref.read(curriculumProvider.notifier).loadCurriculumFromBundle();
        } catch (e) {
          error.value = ErrorHandler.getUserFriendlyError(e);
        } finally {
          isLoading.value = false;
        }
      }

      doLoad();
      return null;
    }, const []);

    // Re-evaluate loading state when curriculum appears or language/level changes
    useEffect(() {
      if (curriculum != null) {
        isLoading.value = false;
      }
      return null;
    }, [curriculum, selectedLanguage.value, selectedLevel.value]);

    // Ensure selectedLevel is valid for the current level list
    final effectiveLevel = levels.contains(selectedLevel.value)
        ? selectedLevel.value
        : (levels.isNotEmpty ? levels.first : 'A1');

    useEffect(() {
      if (effectiveLevel != selectedLevel.value) {
        selectedLevel.value = effectiveLevel;
      }
      return null;
    }, [effectiveLevel]);

    // Extract units for selected language + level
    List<CurriculumUnit> units = [];
    if (curriculum != null) {
      final langKey = resolveLangKey(selectedLanguage.value);
      final languageData =
          curriculum.languages[langKey] ?? curriculum.languages[selectedLanguage.value];
      final levelData = languageData?[effectiveLevel];
      if (levelData != null) {
        units = levelData;
      }
    }

    final allLessons = units.expand((u) => u.lessons).toList();
    final completedLessons = allLessons
        .where((l) => ref.read(curriculumProvider.notifier).isLessonCompleted(
              selectedLanguage.value,
              effectiveLevel,
              l.id,
            ))
        .length;
    final levelComplete = allLessons.isNotEmpty && completedLessons == allLessons.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentic Path'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Persona missions',
            icon: const Icon(Icons.theater_comedy_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonaMissionsHubScreen(
                    initialLanguage: selectedLanguage.value,
                  ),
                ),
              );
            },
          ),
          if (levelComplete)
            IconButton(
              tooltip: 'Level certificate',
              icon: const Icon(Icons.workspace_premium_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelCertificateScreen(
                      language: selectedLanguage.value,
                      level: effectiveLevel,
                      lessonsCompleted: completedLessons,
                    ),
                  ),
                );
              },
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
                          final hasContent = languageHasContent(lang);
                          return DropdownMenuItem(
                            value: lang,
                            child: Row(
                              children: [
                                Text(CurriculumLanguages.displayName(lang)),
                                if (!hasContent) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'Soon',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                        value: effectiveLevel,
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
                          final hasContent = levelHasContent(level);
                          return DropdownMenuItem(
                            value: level,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(level),
                                if (!hasContent) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Soon',
                                      style: TextStyle(fontSize: 9.sp, color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
              child: RefreshIndicator(
                onRefresh: () async {
                  error.value = null;
                  await ref.read(curriculumProvider.notifier).loadCurriculumFromBundle();
                },
              child: isLoading.value
                  ? ListView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      itemCount: 5,
                      itemBuilder: (context, index) => const SkeletonListCard(),
                    )
                    : (error.value != null || providerState.hasError)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              AppErrorState(
                                message: error.value ??
                                    providerState.errorMessage ??
                                    'Failed to load curriculum',
                          onRetry: () {
                            safeAsync(
                              context: context,
                              operation: () async {
                                isLoading.value = true;
                                error.value = null;
                                      await ref
                                          .read(curriculumProvider.notifier)
                                          .loadCurriculumFromBundle();
                                isLoading.value = false;
                              },
                            );
                          },
                              ),
                            ],
                          )
                        : curriculum == null
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height * 0.15),
                                  AppErrorState(
                                    message:
                                        'Unable to load curriculum data. Please try again.',
                                    onRetry: () {
                                      safeAsync(
                                        context: context,
                                        operation: () async {
                                          isLoading.value = true;
                                          error.value = null;
                                          await ref
                                              .read(curriculumProvider.notifier)
                                              .loadCurriculumFromBundle();
                                          isLoading.value = false;
                                        },
                                      );
                                    },
                                  ),
                                ],
                              )
                            : units.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                          height:
                                              MediaQuery.of(context).size.height *
                                                  0.15),
                                      AppEmptyState(
                                        icon: Icons.upcoming_rounded,
                                        title: 'Coming Soon',
                                        subtitle:
                                            'Content for $effectiveLevel is coming soon!\nTry A1 or B1 to get started.',
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding:
                                        EdgeInsets.all(PanAfricanSpacing.lg),
                                    itemCount: units.length,
                                    itemBuilder: (context, unitIndex) {
                                      final unit = units[unitIndex];
                                      return _UnitCard(
                                        unit: unit,
                                        unitIndex: unitIndex,
                                        isDark: isDark,
                                        language: resolveLangKey(selectedLanguage.value),
                                        level: effectiveLevel,
                                        ref: ref,
                                      )
                                          .animate(
                                              delay: (unitIndex * 60).ms)
                                    .fadeIn(duration: 300.ms)
                                          .slideY(begin: 0.15);
                              },
                                  ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final CurriculumUnit unit;
  final int unitIndex;
  final bool isDark;
  final String language;
  final String level;
  final WidgetRef ref;

  const _UnitCard({
    required this.unit,
    required this.unitIndex,
    required this.isDark,
    required this.language,
    required this.level,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = unit.lessons.where((l) {
      return ref.read(curriculumProvider.notifier).isLessonCompleted(language, level, l.id);
    }).length;
    final progress = unit.lessons.isNotEmpty ? completedCount / unit.lessons.length : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PanAfricanRadius.lg)),
          child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                Container(
                  width: 36.sp,
                  height: 36.sp,
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${unitIndex + 1}',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: PanAfricanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.title, style: PanAfricanTypography.titleMedium(context)),
                      SizedBox(height: 2),
                      Text(
                        '$completedCount / ${unit.lessons.length} lessons',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                minHeight: 6.h,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...unit.lessons.asMap().entries.map((entry) {
              final lesson = entry.value;
              final isCompleted = ref.read(curriculumProvider.notifier).isLessonCompleted(language, level, lesson.id);
              return _LessonTile(
                lesson: lesson,
                isCompleted: isCompleted,
                isDark: isDark,
                onTap: () async {
                  final completed = await Navigator.push<bool>(
                    context,
                    SmoothPageRoute(
                      child: AuthenticLessonFlowScreen(
                        lesson: lesson,
                        language: language,
                        level: level,
                        unitQuiz: unit.unitQuiz,
                      ),
                    ),
                  );
                  if (completed == true) {
                    ref.read(curriculumProvider.notifier).markLessonComplete(language, level, lesson.id);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final CurriculumLesson lesson;
  final bool isCompleted;
  final bool isDark;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.isCompleted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${lesson.title}. ${isCompleted ? "Completed" : "Not completed"}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: PanAfricanSpacing.sm,
            horizontal: PanAfricanSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isCompleted ? PanAfricanColors.success : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: 22.sp,
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Text(
                  lesson.title,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? (isDark ? Colors.grey[500] : Colors.grey[500])
                        : null,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 20.sp,
              ),
            ],
        ),
      ),
      ),
    );
  }
}
