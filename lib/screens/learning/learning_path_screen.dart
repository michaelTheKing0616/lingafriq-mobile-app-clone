import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/learning_path_provider.dart';
import 'package:lingafriq/screens/learning/dialect_variant_picker.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/griot/griot_widgets.dart';
import 'package:lingafriq/widgets/learning_path/lesson_preview_sheet.dart';
import 'package:lingafriq/widgets/learning_path/path_journey_node_row.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/path_section_banner.dart';
import 'package:lingafriq/widgets/learning_path/path_sticky_header.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

/// Journey learning path — Mimo units on a Candy Crush clay map.
///
/// Sticky Duo-style unit banner only. Busuu checkpoints every 5. Finch kind
/// streak. Drift-first via [pathLessonsProvider] / [pathUnitsProvider]
/// (P7-952). Never gates on hearts/energy (P8-907).
class LearningPathScreen extends ConsumerStatefulWidget {
  final Language language;

  const LearningPathScreen({super.key, required this.language});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  final ScrollController _scrollController = ScrollController();
  final PathFrameBudgetSampler _frameSampler = PathFrameBudgetSampler();
  int? _pendingScrollLessonIndex;
  bool _didInitialScroll = false;
  bool _didShowPathCompleteCelebration = false;
  bool _listView = false;
  double _scrollPixels = 0;
  int _stickyUnitOrdinal = 0;

  @override
  void initState() {
    super.initState();
    _frameSampler.attach();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _frameSampler.detach();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final px = _scrollController.offset;
    if ((px - _scrollPixels).abs() >= 1) {
      setState(() => _scrollPixels = px);
    }
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
      if (!_scrollController.hasClients) return;
      final scrollIndex =
          pathScrollIndexForLesson(items, _pendingScrollLessonIndex!);
      final raw = pathScrollOffsetForIndex(items, scrollIndex);
      final viewport = _scrollController.position.viewportDimension;
      final target = (raw -
              viewport * (1 - PathLayout.currentNodeViewportFraction))
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(target);
      _pendingScrollLessonIndex = null;
      _didInitialScroll = true;
    });
  }

  void _openPreview(
    BuildContext context, {
    required Lesson lesson,
    required PathNodeVisualState state,
    required VoidCallback onStart,
    int? lessonIndex,
    int? totalLessons,
  }) {
    LessonPreviewSheet.show(
      context,
      lesson: lesson,
      goal: pathLessonGoal(lesson),
      estimatedMinutes: estimatePathLessonMinutes(lesson),
      xpReward: estimatePathLessonXp(lesson),
      isReview: pathLessonIsReview(state),
      lessonNumber: lessonIndex == null ? null : lessonIndex + 1,
      totalLessons: totalLessons,
      onPrimaryAction: onStart,
    );
  }

  void _updateStickyUnit(List<PathScrollItem> items, int? active) {
    if (items.isEmpty) return;
    final lessonIdx = active ?? 0;
    var ordinal = 0;
    var found = 0;
    for (final item in items) {
      if (item is PathScrollBannerItem) {
        if (item.banner.firstLessonIndex <= lessonIdx) {
          found = ordinal;
        }
        ordinal++;
      }
    }
    if (found != _stickyUnitOrdinal) {
      setState(() => _stickyUnitOrdinal = found);
    }
  }

  ({int completed, int total}) _unitProgress({
    required List<PathScrollItem> items,
    required List<Lesson> lessons,
    required int unitOrdinal,
  }) {
    final banners = items.whereType<PathScrollBannerItem>().toList();
    if (banners.isEmpty) {
      final done = lessons.where(_sectionCompleted).length;
      return (completed: done, total: lessons.length);
    }
    final idx = unitOrdinal.clamp(0, banners.length - 1);
    final start = banners[idx].banner.firstLessonIndex;
    final end = idx + 1 < banners.length
        ? banners[idx + 1].banner.firstLessonIndex
        : lessons.length;
    var completed = 0;
    for (var i = start; i < end && i < lessons.length; i++) {
      if (_sectionCompleted(lessons[i])) completed++;
    }
    return (completed: completed, total: (end - start).clamp(0, lessons.length));
  }

  int _unitOrdinalForLesson(List<PathScrollItem> items, int lessonIndex) {
    var ordinal = 0;
    var found = 0;
    for (final item in items) {
      if (item is PathScrollBannerItem) {
        if (item.banner.firstLessonIndex <= lessonIndex) {
          found = ordinal;
        }
        ordinal++;
      }
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(pathLessonsProvider(widget.language));
    final unitsAsync = ref.watch(pathUnitsProvider(widget.language));
    final gamification = ref.watch(gamificationProvider).gamification;
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final lowEndStatic = _frameSampler.exceedsBudget();

    if (lessonsAsync.hasError && !lessonsAsync.hasValue) {
      debugPrint(
        '[LearningPathScreen] failed to load lessons: ${lessonsAsync.error}',
      );
      return _errorState(context);
    }

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
        _updateStickyUnit(items, active);

        final bannerOrdinalByItemIndex = <int, int>{};
        var bannerOrdinal = 0;
        for (var idx = 0; idx < items.length; idx++) {
          if (items[idx] is PathScrollBannerItem) {
            bannerOrdinalByItemIndex[idx] = bannerOrdinal;
            bannerOrdinal++;
          }
        }

        final completedCount = lessons.where(_sectionCompleted).length;
        final studyKey =
            LearningExperienceNavigation.languageKeyFor(widget.language) ??
                widget.language.name;
        final pathComplete = completedCount == lessons.length;
        final welcomeBack =
            gamification.dailyStreak == 0 && completedCount > 0;
        final mascotMood = welcomeBack
            ? PoliePathMood.sleepy
            : (completedCount == 0
                ? PoliePathMood.pointUp
                : (pathComplete ? PoliePathMood.cheer : PoliePathMood.idle));

        if (pathComplete && !_didShowPathCompleteCelebration) {
          _didShowPathCompleteCelebration = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showPathCompleteCelebration(context);
          });
        }

        final stickyBanner = _resolveStickyBanner(
          items: items,
          ordinal: _stickyUnitOrdinal,
          active: active,
          lessons: lessons,
        );
        final unitProgress = _unitProgress(
          items: items,
          lessons: lessons,
          unitOrdinal: _stickyUnitOrdinal,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final place = PathLayout.placeThemeForUnit(_stickyUnitOrdinal);
        final parchment = isDark
            ? PathBrandColors.parchmentDark
            : Color.alphaBlend(
                pathPlaceWashColor(place, isDark: false).withValues(alpha: 0.45),
                pathParchmentColorFor(studyKey),
              );

        return GriotScaffold(
          backgroundColor: parchment,
          body: SafeArea(
            child: Column(
              children: [
                PathStickyHeader(
                  languageName: widget.language.name,
                  streakCount: gamification.dailyStreak,
                  cowriesCount: gamification.cowries,
                  scrollPixels: _scrollPixels,
                  isOffline: snapshot.source == PathLessonSource.drift,
                  welcomeBack: welcomeBack,
                  listViewActive: _listView,
                  reducedMotion: reducedMotion,
                  onBack: () => Navigator.maybePop(context),
                  onLanguageTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Studying ${widget.language.name}',
                        ),
                      ),
                    );
                  },
                  onStreakTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          welcomeBack
                              ? 'Welcome back. Your freeze is ready. No shame, just the next step.'
                              : 'Streak: ${gamification.dailyStreak} day${gamification.dailyStreak == 1 ? '' : 's'}',
                        ),
                      ),
                    );
                  },
                  onCowriesTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${gamification.cowries} cowries',
                        ),
                      ),
                    );
                  },
                  onToggleListView: () {
                    HapticFeedback.selectionClick();
                    setState(() => _listView = !_listView);
                  },
                  onDialectTap: () async {
                    HapticFeedback.lightImpact();
                    await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => DialectVariantPicker(
                        umbrellaLanguage:
                            widget.language.name.toLowerCase(),
                      ),
                    );
                  },
                ),
                if (stickyBanner != null)
                  PathStickyUnitBanner(
                    unitName: stickyBanner.unitName,
                    cefrLevel: stickyBanner.cefrLevel,
                    canDoStatement: stickyBanner.canDoStatement,
                    unitOrdinal: _stickyUnitOrdinal,
                    completedInUnit: unitProgress.completed,
                    totalInUnit: unitProgress.total,
                    reducedMotion: reducedMotion,
                    locked: active != null &&
                        stickyBanner.firstLessonIndex > active,
                    onGuideTap: () => _showUnitGuide(context, stickyBanner),
                  ),
                if (welcomeBack)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PathBrandColors.gold.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: PathBrandColors.gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        child: Text(
                          'Welcome back. Your freeze is ready. Pick up where you left off.',
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                          ).copyWith(
                            color: isDark
                                ? PathBrandColors.parchment
                                : const Color(0xFF5C3A12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _listView
                      ? _buildListAlternate(
                          context,
                          lessons: lessons,
                          studyKey: studyKey,
                          active: active,
                          reducedMotion: reducedMotion,
                          isOffline:
                              snapshot.source == PathLessonSource.drift,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.only(
                            bottom: 24.h,
                            top: 8.h,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (item is PathScrollBannerItem) {
                              final b = item.banner;
                              final ordinal =
                                  bannerOrdinalByItemIndex[index] ?? 0;
                              final dimmed = pathSceneDimmedForLesson(
                                lessonIndex: b.firstLessonIndex,
                                activeLessonIndex: active,
                              );
                              final progress = _unitProgress(
                                items: items,
                                lessons: lessons,
                                unitOrdinal: ordinal,
                              );
                              return PathSectionBanner(
                                unitName: b.unitName,
                                cefrLevel: b.cefrLevel,
                                canDoStatement: b.canDoStatement,
                                unitOrdinal: ordinal,
                                completedInUnit: progress.completed,
                                totalInUnit: progress.total,
                                showSceneArt: !lowEndStatic,
                                languageKey: studyKey,
                                unitIndex: ordinal,
                                sceneDimmed: dimmed,
                                reducedMotion:
                                    reducedMotion || lowEndStatic,
                                parallaxOffset: _scrollPixels,
                                onGuideTap: () =>
                                    _showUnitGuide(context, b),
                              );
                            }
                            final node = item as PathScrollNodeItem;
                            final i = node.lessonIndex;
                            final lesson = node.lesson;
                            final seqUnlocked =
                                _sectionUnlocked(i, lessons);
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
                            final unitOrd =
                                _unitOrdinalForLesson(items, i);
                            return PathJourneyNodeRow(
                              lesson: lesson,
                              lessonIndex: i,
                              state: state,
                              unitOrdinal: unitOrd,
                              languageKey: studyKey,
                              reducedMotion: reducedMotion,
                              lowEndStatic: lowEndStatic,
                              isRtl: isRtl,
                              savedOffline: snapshot.source ==
                                  PathLessonSource.drift,
                              totalLessons: lessons.length,
                              parallaxScroll: _scrollPixels,
                              showSideScenery: i % 2 == 0,
                              polieMood: mascotMood,
                              onTap: state == PathNodeVisualState.locked
                                  ? null
                                  : () {
                                      _openPreview(
                                        context,
                                        lesson: lesson,
                                        lessonIndex: i,
                                        totalLessons: lessons.length,
                                        state: state,
                                        onStart: () {
                                          LearningExperienceNavigation
                                              .openLessonSections(
                                            context,
                                            lesson: lesson,
                                            studyLanguageKey: studyKey,
                                          );
                                        },
                                      );
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _loadingState(context, reducedMotion),
      error: (e, _) => _errorState(context),
    );
  }

  PathUnitBannerData? _resolveStickyBanner({
    required List<PathScrollItem> items,
    required int ordinal,
    required int? active,
    required List<Lesson> lessons,
  }) {
    final banners = items.whereType<PathScrollBannerItem>().toList();
    if (banners.isEmpty) {
      return PathUnitBannerData(
        unitKey: 'path',
        unitName: widget.language.name,
        cefrLevel: widget.language.level_language,
        canDoStatement: '${lessons.length} lessons on your path',
        firstLessonIndex: 0,
      );
    }
    final idx = ordinal.clamp(0, banners.length - 1);
    return banners[idx].banner;
  }

  Widget _buildListAlternate(
    BuildContext context, {
    required List<Lesson> lessons,
    required String studyKey,
    required int? active,
    required bool reducedMotion,
    required bool isOffline,
  }) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, i) {
        final lesson = lessons[i];
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
        final cs = Theme.of(context).colorScheme;
        final locked = state == PathNodeVisualState.locked;
        final isCheckpoint = PathLayout.isCheckpoint(i);
        return Semantics(
          button: true,
          enabled: !locked,
          label: pathNodeSemanticsLabel(
            nodeNumber: i + 1,
            title: lesson.name,
            state: state,
            reviewDueLabel: 'Review due',
            totalLessons: lessons.length,
          ),
          child: Material(
            color: isCheckpoint
                ? PathBrandColors.gold.withValues(alpha: 0.18)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: locked
                  ? null
                  : () => _openPreview(
                        context,
                        lesson: lesson,
                        lessonIndex: i,
                        totalLessons: lessons.length,
                        state: state,
                        onStart: () {
                          LearningExperienceNavigation.openLessonSections(
                            context,
                            lesson: lesson,
                            studyLanguageKey: studyKey,
                          );
                        },
                      ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: PathNodeWidget(
                        lesson: lesson,
                        state: state,
                        index: i,
                        size: 48,
                        reducedMotion: true,
                        savedOffline: isOffline,
                        isCheckpoint: isCheckpoint,
                        onTap: null,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCheckpoint ? 'Checkpoint · ${lesson.name}' : lesson.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ModernGriotTypography.titleSmall(
                              context: context,
                            ),
                          ),
                          Text(
                            locked
                                ? 'Locked'
                                : (state == PathNodeVisualState.current
                                    ? 'Current'
                                    : (state == PathNodeVisualState.done
                                        ? 'Done'
                                        : state.name)),
                            style: ModernGriotTypography.bodySmall(
                              context: context,
                            ).copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (!locked)
                      Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUnitGuide(BuildContext context, PathUnitBannerData banner) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              banner.unitName,
              style: ModernGriotTypography.titleLarge(context: ctx),
            ),
            SizedBox(height: 8.h),
            Text(
              banner.canDoStatement.isNotEmpty
                  ? banner.canDoStatement
                  : 'Browse the phrases and goals for this unit.',
              style: ModernGriotTypography.bodyLarge(context: ctx),
            ),
            if (banner.cefrLevel.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                'Level ${banner.cefrLevel}',
                style: ModernGriotTypography.labelLarge(context: ctx),
              ),
            ],
            SizedBox(height: 20.h),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  SmoothPageRoute.platform(
                    child: LessonsListScreen(language: widget.language),
                  ),
                );
              },
              child: const Text('Open phrase list'),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPathCompleteCelebration(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              image: true,
              label: 'Trophy — you finished every lesson on this path',
              child: Icon(
                Icons.emoji_events_rounded,
                size: 56.sp,
                color: PathBrandColors.gold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Path complete!',
              textAlign: TextAlign.center,
              style: ModernGriotTypography.titleLarge(context: sheetContext),
            ),
            SizedBox(height: 8.h),
            Text(
              "You've mastered every lesson in ${widget.language.name}. "
              "Polie couldn't be prouder.",
              textAlign: TextAlign.center,
              style: ModernGriotTypography.bodySmall(context: sheetContext),
            ),
            SizedBox(height: 20.h),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PathBrandColors.coral,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Keep practicing'),
            ),
            SizedBox(height: MediaQuery.paddingOf(sheetContext).bottom),
          ],
        ),
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
              Semantics(
                image: true,
                label: 'Polie sketching out a new path',
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 48.sp,
                  color: PathBrandColors.coral,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "We're still weaving your ${widget.language.name} path",
                textAlign: TextAlign.center,
                style: ModernGriotTypography.titleSmall(context: context),
              ),
              SizedBox(height: 8.h),
              Text(
                'Hop into the lesson list for now — your path will be ready soon.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(context: context),
              ),
              SizedBox(height: 20.h),
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

  Widget _loadingState(BuildContext context, bool reducedMotion) {
    return GriotScaffold(
      body: Center(
        child: Semantics(
          label: 'Loading your learning path',
          liveRegion: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              reducedMotion
                  ? Icon(
                      Icons.hourglass_top_rounded,
                      size: 32.sp,
                      color: PathBrandColors.coral,
                    )
                  : const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading your path…',
                style: ModernGriotTypography.bodySmall(context: context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return GriotScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 40.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(
                "We couldn't load your path",
                style: ModernGriotTypography.titleSmall(context: context),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your progress is saved — check your connection and try again.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(context: context),
              ),
              SizedBox(height: 16.h),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(pathLessonsProvider(widget.language)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
