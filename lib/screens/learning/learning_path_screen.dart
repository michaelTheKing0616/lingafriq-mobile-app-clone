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
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/griot/griot_widgets.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_painter.dart';
import 'package:lingafriq/widgets/learning_path/lesson_preview_sheet.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/path_section_banner.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

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
  bool _didShowPathCompleteCelebration = false;

  /// Horizontal distance a node is pushed from the row's centre to form the
  /// zig-zag; kept as a named constant (not an inline literal) per row so
  /// its one usage below is self-documenting.
  static const double _kPathNodeHorizontalInset = 28;

  /// Vertical breathing room between consecutive node bubbles. Without this
  /// the circles render edge-to-edge in the list with zero gap, which read
  /// as a visual bug rather than a path.
  static const double _kPathNodeVerticalGap = 18;

  /// Reserved space below the last (bottom-most, since the list is
  /// `reverse: true`) row so it can never sit under the floating
  /// `PoliePathMascot`.
  ///
  /// Verified by walking the actual numbers rather than eyeballing it: the
  /// mascot's `PositionedDirectional` floats `PanAfricanSpacing.md` (16) off
  /// the screen bottom with a 90-tall box, i.e. its top edge sits 106 above
  /// the screen bottom. The first on-screen row's lane alternates by
  /// `lessonIndex.isOdd` (see the zig-zag logic below), so only every other
  /// row ever shares the mascot's side of the screen — but the very next
  /// row up (the first "end lane" row, on the mascot's side) would, with the
  /// previous flat `24` bottom padding, have landed with its bottom edge at
  /// exactly `24 + PathNodeWidget.defaultSize(64) + _kPathNodeVerticalGap(18)
  /// = 106` above the screen bottom — precisely flush against the mascot's
  /// top edge, a zero-margin coincidence rather than a real guarantee (and
  /// one that doesn't hold once `.w` vs `.h` ScreenUtil scale factors
  /// diverge on non-design-ratio screens). Reserving `106 + 16` of bottom
  /// padding instead guarantees a real 16px clearance gap under the mascot
  /// on every device, independent of that coincidence.
  static const double _kPathMascotClearanceBottomPadding = 122;

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
    // Respects the OS-level "reduce motion" accessibility setting. Every
    // animated affordance below (node pulse, path glow) is gated on this so
    // the screen degrades to an equally legible static layout.
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Riverpod's `FutureProvider` retries failed futures in the background
    // by default, so a failure never settles into a plain `AsyncError` —
    // it stays `AsyncLoading` with the error attached while it retries
    // (see `AsyncValue.isLoading`/`hasError` both true). Checked ahead of
    // `.when()` so learners see the error-and-retry affordance immediately
    // instead of an infinite spinner.
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

        // One pass to label each banner with its running unit number, so the
        // scene-art slot can pick a stable (not repeating) artboard per unit
        // without recomputing this inside every list item build.
        final bannerOrdinalByItemIndex = <int, int>{};
        var bannerOrdinal = 0;
        for (var idx = 0; idx < items.length; idx++) {
          if (items[idx] is PathScrollBannerItem) {
            bannerOrdinalByItemIndex[idx] = bannerOrdinal;
            bannerOrdinal++;
          }
        }

        final completedCount = lessons.where(_sectionCompleted).length;
        final studyKey = LearningExperienceNavigation.languageKeyFor(widget.language);
        final pathComplete = completedCount == lessons.length;
        final mascotMood = completedCount == 0
            ? PoliePathMood.pointUp
            : (pathComplete ? PoliePathMood.cheer : PoliePathMood.idle);

        if (pathComplete && !_didShowPathCompleteCelebration) {
          _didShowPathCompleteCelebration = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showPathCompleteCelebration(context);
          });
        }

        return GriotScaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _header(context, completedCount, lessons.length, snapshot.source),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.only(
                          bottom: _kPathMascotClearanceBottomPadding.h,
                          top: 8.h,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          _builtScrollIndices.add(index);
                          final item = items[index];
                          if (item is PathScrollBannerItem) {
                            final b = item.banner;
                            final dimmed = pathSceneDimmedForLesson(
                              lessonIndex: b.firstLessonIndex,
                              activeLessonIndex: active,
                            );
                            return PathSectionBanner(
                              unitName: b.unitName,
                              cefrLevel: b.cefrLevel,
                              canDoStatement: b.canDoStatement,
                              showSceneArt: true,
                              languageKey: studyKey,
                              unitIndex: bannerOrdinalByItemIndex[index] ?? 0,
                              sceneDimmed: dimmed,
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

                          // `true` = this lesson's bubble sits in the
                          // writing-direction "end" lane (right in LTR,
                          // left in RTL); alternates every row to form the
                          // zig-zag. The *previous* row's lane is derived
                          // the same way so the decorative connector below
                          // lines up across row boundaries.
                          final thisIsEndLane = i.isOdd;
                          final prevIsEndLane = i > 0 ? (i - 1).isOdd : thisIsEndLane;
                          final traveled = state != PathNodeVisualState.locked;

                          return SizedBox(
                            height: PathNodeWidget.defaultSize.w + _kPathNodeVerticalGap.h,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: PathRowConnector(
                                    fromLane: pathLaneSign(
                                      isEndLane: prevIsEndLane,
                                      isRtl: isRtl,
                                    ),
                                    toLane: pathLaneSign(
                                      isEndLane: thisIsEndLane,
                                      isRtl: isRtl,
                                    ),
                                    traveled: traveled,
                                  ),
                                ),
                                Align(
                                  alignment: thisIsEndLane
                                      ? AlignmentDirectional.centerEnd
                                      : AlignmentDirectional.centerStart,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: _kPathNodeHorizontalInset.w,
                                      end: _kPathNodeHorizontalInset.w,
                                    ),
                                    child: PathNodeWidget(
                                      lesson: lesson,
                                      state: state,
                                      index: i,
                                      studyLanguageKey: studyKey,
                                      reducedMotion: reducedMotion,
                                      totalLessons: lessons.length,
                                      onTap: state == PathNodeVisualState.locked
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              _openPreview(
                                                context,
                                                lesson: lesson,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                PositionedDirectional(
                  bottom: PanAfricanSpacing.md,
                  end: PanAfricanSpacing.md,
                  child: SizedBox(
                    width: 76.w,
                    height: 90.h,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: PoliePathMascot(
                        mood: mascotMood,
                        reducedMotion: reducedMotion,
                        onTap: () => _showPolieEncouragement(context, mascotMood),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _loadingState(context, reducedMotion),
      // Unreachable in practice (the `hasError` check above intercepts
      // failures first) but kept as a defensive fallback so this remains
      // exhaustive and safe if that retry behavior ever changes upstream.
      error: (e, _) => _errorState(context),
    );
  }

  Widget _header(
    BuildContext context,
    int completed,
    int total,
    PathLessonSource source,
  ) {
    final isOffline = source == PathLessonSource.drift;
    final percent = total > 0 ? (completed / total * 100).round() : 0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Material's "back" glyph points left; mirror it for RTL locales
    // (Arabic / Darija) instead of relying on an auto-mirror that Icons
    // don't get for free.
    final backIcon = isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;

    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: AdaptiveLayout.minTouchTarget.w,
                height: AdaptiveLayout.minTouchTarget.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(backIcon, size: 20.sp),
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Path',
                  // At large text-scale factors this `Expanded` column gets
                  // squeezed by its `Flexible` siblings (the Offline/percent
                  // badges) and the fixed-size back/dialect buttons. Without
                  // a line cap, unbounded wrapping here is what actually
                  // drove the header's `Column` past the screen height (see
                  // the 2.0x text-scale regression test) — one line with
                  // ellipsis keeps this row's height bounded no matter how
                  // narrow it gets squeezed.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ModernGriotTypography.titleLarge(context: context),
                ),
                Text(
                  '$completed of $total sections',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ModernGriotTypography.bodySmall(context: context),
                ),
              ],
            ),
          ),
          if (isOffline) ...[
            // `GriotBadgePill`'s own `Text` has no `maxLines`/`overflow` (it's
            // outside this screen's edit scope to change), so its width grows
            // unbounded at large text-scale factors. `Flexible` + `FittedBox`
            // guarantees this header `Row` never overflows regardless — the
            // pill shrinks to fit rather than pushing past its allotted space.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Semantics(
                  label: 'Offline — showing your last saved progress',
                  excludeSemantics: true,
                  child: GriotBadgePill(
                    label: 'Offline',
                    icon: Icons.cloud_off_rounded,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Semantics(
                label: '$percent percent complete',
                excludeSemantics: true,
                child: GriotBadgePill(
                  label: '$percent%',
                  icon: Icons.trending_up_rounded,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.xs + 2.w),
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

  /// Lightweight full-screen celebration once every section on the path is
  /// mastered. Shown once per screen lifetime via `_didShowPathCompleteCelebration`
  /// (not every rebuild) and gated on `pathComplete`, which is already derived
  /// from `completedCount == lessons.length`. A modal bottom sheet rather than
  /// a confetti overlay so it stays reduced-motion safe by construction (no
  /// animation to gate) and consistent with the rest of the app's sheet
  /// pattern (e.g. `DialectVariantPicker`, `LessonPreviewSheet`).
  void _showPathCompleteCelebration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              image: true,
              label: 'Trophy — you finished every lesson on this path',
              child: Icon(
                Icons.emoji_events_rounded,
                size: 56.sp,
                color: cs.primary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Path complete!',
              textAlign: TextAlign.center,
              style: ModernGriotTypography.titleLarge(context: sheetContext),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              "You've mastered every lesson in ${widget.language.name}. "
              "Polie couldn't be prouder.",
              textAlign: TextAlign.center,
              style: ModernGriotTypography.bodySmall(context: sheetContext),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Keep practicing'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolieEncouragement(BuildContext context, PoliePathMood mood) {
    final message = switch (mood) {
      PoliePathMood.pointUp =>
        "Let's take the first step together — tap any unlocked stop to begin.",
      PoliePathMood.cheer => "You've walked the whole path — I'm so proud of you!",
      PoliePathMood.idle || PoliePathMood.sleepy =>
        'Keep going — every lesson gets you closer.',
    };
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _emptyState(BuildContext context) {
    return GriotScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                image: true,
                label: 'Polie sketching out a new path',
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 48.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                "We're still weaving your ${widget.language.name} path",
                textAlign: TextAlign.center,
                style: ModernGriotTypography.titleSmall(context: context),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                'Hop into the lesson list for now — your path will be ready soon.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(context: context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
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
              // An indeterminate spinner communicates required state (we
              // don't yet know how long the load will take) even with
              // reduced motion on — platform guidance treats this as
              // essential, not decorative, motion. We still swap to a
              // static icon so nothing spins when the OS asks for it.
              reducedMotion
                  ? Icon(
                      Icons.hourglass_top_rounded,
                      size: 32.sp,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const CircularProgressIndicator(),
              SizedBox(height: PanAfricanSpacing.md),
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
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 40.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                "We couldn't load your path",
                style: ModernGriotTypography.titleSmall(context: context),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                'Your progress is saved — check your connection and try again.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(context: context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
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
