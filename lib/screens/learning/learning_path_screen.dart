import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/loading_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_widget.dart';

final lessonsListProvider = FutureProvider.autoDispose.family<LessonResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getLessons(id);
});

/// Full-screen learning path view showing lessons in a Duolingo-style scrollable path.
class LearningPathScreen extends ConsumerStatefulWidget {
  final Language language;

  const LearningPathScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLesson(int currentIndex, double nodeSpacing) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final targetOffset = (currentIndex * nodeSpacing) - 200.h;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsListProvider(widget.language.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      body: lessonsAsync.when(
        data: (lessonResponse) {
          final lessons = lessonResponse.results
              .where((e) => e.lessons_language == widget.language.id)
              .toList();

          if (lessons.isEmpty) {
            return Column(
              children: [
                TopGradientBox(
                  borderRadius: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButton(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.md,
                        ),
                        child: Text(
                          widget.language.name ?? 'Learning Path',
                          style: PanAfricanTypography.headlineMedium(context)
                              .copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64.sp,
                          color: PanAfricanColors.neutralMedium,
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          'No Lessons Available',
                          style: PanAfricanTypography.titleLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'Lessons will appear here once they\'re added.',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final currentIndex = _findCurrentLessonIndex(lessons);
          final nodeSpacing = 120.h;
          final totalHeight = (lessons.length * nodeSpacing) + 200.h;

          _scrollToCurrentLesson(currentIndex, nodeSpacing);

          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackButton(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.language.name ?? 'Learning Path',
                            style: PanAfricanTypography.headlineMedium(context)
                                .copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          _buildProgressInfo(context, lessons, currentIndex),
                        ],
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.lg),
                  child: SizedBox(
                    height: totalHeight,
                    child: LearningPathWidget(
                      lessons: lessons,
                      currentIndex: currentIndex,
                      scrollController: _scrollController,
                      nodeSize: 64,
                      nodeSpacing: nodeSpacing,
                      horizontalPadding: 80,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, s) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackButton(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.md,
                      ),
                      child: Text(
                        widget.language.name ?? 'Learning Path',
                        style: PanAfricanTypography.headlineMedium(context)
                            .copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                  ],
                ),
              ),
              Expanded(
                child: StreamErrorWidget(
                  error: e,
                  onTryAgain: () {
                    ref.invalidate(lessonsListProvider(widget.language.id));
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Column(
          children: [
            TopGradientBox(
              borderRadius: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButton(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.md,
                    ),
                    child: Text(
                      widget.language.name ?? 'Learning Path',
                      style: PanAfricanTypography.headlineMedium(context)
                          .copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                ],
              ),
            ),
            const Expanded(
              child: LoadingBuilder(title: "Loading Learning Path"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(
    BuildContext context,
    List<Lesson> lessons,
    int currentIndex,
  ) {
    final completed = lessons.where((l) => l.completed == l.count && l.count > 0).length;
    final total = lessons.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completed of $total lessons completed',
                style: PanAfricanTypography.bodySmall(context).copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.85),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xxs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4.h,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        IconButton(
          icon: Icon(
            Icons.list_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            ref.read(navigationProvider).navigateTo(
                  LessonsListScreen(language: widget.language),
                );
          },
          tooltip: 'View as list',
        ),
      ],
    );
  }

  int _findCurrentLessonIndex(List<Lesson> lessons) {
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final isCompleted = lesson.completed == lesson.count && lesson.count > 0;
      
      if (!isCompleted) {
        final isUnlocked = i == 0 ||
            (lessons[i - 1].completed == lessons[i - 1].count &&
                lessons[i - 1].count > 0);
        
        if (isUnlocked) {
          return i;
        }
      }
    }
    
    return lessons.length;
  }
}
