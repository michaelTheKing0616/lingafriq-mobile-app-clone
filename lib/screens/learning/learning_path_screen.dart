import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';
import 'package:lingafriq/providers/learning_path_provider.dart';
import 'package:lingafriq/screens/learning/dialect_variant_picker.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/griot/griot_widgets.dart';
import 'package:lingafriq/widgets/learning_path/lesson_preview_sheet.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_section_banner.dart';

/// Winding learning path with unit banners, preview sheet, and Drift-first rows (P7-952).
class LearningPathScreen extends ConsumerStatefulWidget {
  final Language language;

  const LearningPathScreen({super.key, required this.language});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  final ScrollController _scrollController = ScrollController();
  final PathFrameBudgetSampler _frameSampler = PathFrameBudgetSampler();
  final Set<int> _builtScrollIndices = {};
  int? _pendingScrollLessonIndex;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _frameSampler.attach();
  }

  @override
  void dispose() {
    _frameSampler.detach();
    _scrollController.dispose();
    super.dispose();
  }

  bool _sectionUnlocked(int index, List<Lesson> lessons) {
    if (index <= 0) return true;
    final prev = lessons[index - 1];
    return prev.count == prev.completed;
  }

  bool _sectionCompleted(Lesson lesson) =>
      lesson.count > 0 && lesson.completed >= lesson.count;

  int? _activeIndex(List<Lesson> lessons) {
    for (var i = 0; i < lessons.length; i++) {
      if (!_sectionUnlocked(i, lessons)) return null;
      if (!_sectionCompleted(lessons[i])) return i;
    }
    return null;
  }

  void _scheduleScrollToLesson(int lessonIndex, List<PathScrollItem> items) {
    _pendingScrollLessonIndex = lessonIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingScrollLessonIndex == null) return;
      final scrollIndex = pathScrollIndexForLesson(items, _pendingScrollLessonIndex!);
      final offset = pathScrollOffsetForIndex(items, scrollIndex);
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0.0, max));
      _pendingScrollLessonIndex = null;
      _didInitialScroll = true;
    });
  }

  void _openPreview(
    BuildContext context, {
    required Lesson lesson,
    required PathNodeVisualState state,
    required VoidCallback onStart,
  }) {
    LessonPreviewSheet.show(
      context,
      lesson: lesson,
      goal: pathLessonGoal(lesson),
      estimatedMinutes: estimatePathLessonMinutes(lesson),
      xpReward: estimatePathLessonXp(lesson),
      isReview: pathLessonIsReview(state),
      onPrimaryAction: onStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(pathLessonsProvider(widget.language));
    final unitsAsync = ref.watch(pathUnitsProvider(widget.language));

    return lessonsAsync.when(
      data: (snapshot) {
        final lessons = snapshot.lessons;
        if (lessons.isEmpty) {
          return _emptyState(context);
        }

        final units = unitsAsync.maybeWhen(
          data: (u) => u,
          orElse: () => const <PathUnitBannerData>[],
        );
        final items = buildPathScrollItems(lessons: lessons, units: units);
        final active = _activeIndex(lessons);
        if (!_didInitialScroll && active != null) {
          _scheduleScrollToLesson(active, items);
        }

        final completedCount = lessons.where(_sectionCompleted).length;
        final studyKey = LearningExperienceNavigation.languageKeyFor(widget.language);

        return GriotScaffold(
          body: SafeArea(
            child: Column(
              children: [
                _header(context, completedCount, lessons.length, snapshot.source),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.only(bottom: 24.h, top: 8.h),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      _builtScrollIndices.add(index);
                      final item = items[index];
                      if (item is PathScrollBannerItem) {
                        final b = item.banner;
                        return PathSectionBanner(
                          unitName: b.unitName,
                          cefrLevel: b.cefrLevel,
                          canDoStatement: b.canDoStatement,
                        );
                      }
                      final node = item as PathScrollNodeItem;
                      final i = node.lessonIndex;
                      final lesson = node.lesson;
                      final seqUnlocked = _sectionUnlocked(i, lessons);
                      final progress = PathLessonProgress(
                        lessonId: lesson.id.toString(),
                        title: lesson.name,
                        index: i,
                        isCompleted: _sectionCompleted(lesson),
                      );
                      final state = resolvePathNodeState(
                        lesson: progress,
                        activeIndex: active,
                        pacing: const PathPacingOverlay(),
                        sequentiallyUnlocked: seqUnlocked,
                      );
                      final alignRight = i.isOdd;
                      return Align(
                        alignment: alignRight
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28.w),
                          child: PathNodeWidget(
                            lesson: lesson,
                            state: state,
                            index: i,
                            studyLanguageKey: studyKey,
                            onTap: state == PathNodeVisualState.locked
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _openPreview(
                                      context,
                                      lesson: lesson,
                                      state: state,
                                      onStart: () {
                                        LearningExperienceNavigation.openLessonSections(
                                          context,
                                          lesson: lesson,
                                          studyLanguageKey: studyKey,
                                        );
                                      },
                                    );
                                  },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const GriotScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => GriotScaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Could not load lessons',
                  style: ModernGriotTypography.titleSmall(),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.bodySmall(),
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(pathLessonsProvider(widget.language)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    int completed,
    int total,
    PathLessonSource source,
  ) {
    final offlineTag = source == PathLessonSource.drift ? ' · offline' : '';
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Path',
                  style: ModernGriotTypography.titleLarge(),
                ),
                Text(
                  '$completed of $total sections$offlineTag',
                  style: ModernGriotTypography.bodySmall(),
                ),
              ],
            ),
          ),
          GriotBadgePill(
            label: '${(completed / total * 100).round()}%',
            icon: Icons.trending_up_rounded,
            color: Theme.of(context).colorScheme.secondaryContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: 10.w),
          IconButton(
            tooltip: 'Dialect mode (Common vs Local)',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DialectVariantPicker(
                  umbrellaLanguage: widget.language.name.toLowerCase(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return GriotScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'No lesson sections yet for ${widget.language.name}.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.titleSmall(),
              ),
              SizedBox(height: 24.h),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    SmoothPageRoute.platform(
                      child: LessonsListScreen(language: widget.language),
                    ),
                  );
                },
                child: const Text('Open lesson list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
