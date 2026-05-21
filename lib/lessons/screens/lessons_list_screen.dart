import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/info_widget.dart';
import 'package:lingafriq/widgets/language_type_header_builder.dart';
import 'package:lingafriq/widgets/loading_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/offline_download_provider.dart';
import '../../screens/learning/learning_path_screen.dart';
import '../models/lesson_response.dart';
import 'section_lessons_list.dart';
import 'package:lingafriq/navigation/learning_experience_navigation.dart';

final lessonsListProvider = FutureProvider.autoDispose.family<LessonResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getLessons(id);
});

class LessonsListScreen extends ConsumerWidget {
  final Language language;
  const LessonsListScreen({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsListProvider(language.id));
    return Scaffold(
      body: lessonsAsync.when(
        data: (lessonResponse) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackButton(color: Theme.of(context).colorScheme.onPrimary),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.route_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            ref.read(navigationProvider).navigateTo(
                                  LearningPathScreen(language: language),
                                );
                          },
                          tooltip: 'View learning path',
                        ),
                      ],
                    ),
                    LangguageTypeHeaderBuilder(
                      title: "Sections",
                      level: '',
                      count: lessonResponse.results
                          .where((e) => e.lessons_language == language.id)
                          .toList()
                          .length,
                      points: lessonResponse.results
                          .where((e) => e.lessons_language == language.id)
                          .sumBy((e) => e.score),
                      type: "Written & Oral",
                      completed: lessonResponse.results
                          .where((e) => e.lessons_language == language.id)
                          .where((e) => e.completed == e.count)
                          .toList()
                          .length,
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final lessons = lessonResponse.results
                      .where((e) => e.lessons_language == language.id)
                      .toList();
                  if (lessons.isEmpty) {
                    return const InfoWidget(
                      text: "No Lesson Sections",
                      subText: "We're working to add some lesson sections for you.",
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () {
                      ref.invalidate(lessonsListProvider(language.id));
                      return Future.value();
                    },
                    child: ListView.builder(
                      itemCount: lessons.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final isEnabled = (() {
                          if (index == 0) {
                            return true;
                          }
                          return lessons[index - 1].count == lessons[index - 1].completed;
                        }).call();
                        return _LessonItem(
                          lesson: lesson,
                          enabled: kDebugMode ? true : isEnabled,
                          index: index,
                        )
                            .animate(delay: Duration(milliseconds: index * 50))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
                  );
                },
              ).expand(),
            ],
          );
        },
        error: (e, s) {
          return StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(lessonsListProvider(language.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "Sections"),
      ),
    );
  }
}

class _LessonItem extends ConsumerWidget {
  final Lesson lesson;
  final bool enabled;
  final int index;
  const _LessonItem({
    required this.lesson,
    required this.enabled,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineDownloadProvider);
    final offlineNotifier = ref.read(offlineDownloadProvider.notifier);
    final lessonId = lesson.id.toString();
    final isDownloaded = offlineNotifier.isDownloaded(lessonId);
    final downloadProgress = offlineNotifier.getDownloadProgress(lessonId);
    final isDownloading = offlineState.isDownloading && offlineState.currentDownloadingLessonId == lessonId;
    
    return Card(
      color: context.isDarkMode ? context.cardColor : Theme.of(context).colorScheme.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled
            ? () async {
                LearningExperienceNavigation.openLessonSections(
                      context,
                      lesson: lesson,
                      studyLanguageKey:
                          LearningExperienceNavigation.languageKeyFor(language),
                    );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'lesson_icon_${lesson.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: enabled
                          ? LinearGradient(
                              colors: [
                                context.primaryColor,
                                context.primaryColor.withOpacity(0.7),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                context.adaptive26,
                                context.adaptive26,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: enabled
                          ? Colors.white
                          : context.adaptive54,
                      size: 24,
                    ),
                  ),
                ),
                12.widthBox,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    lesson.name.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "${lesson.count} Lessons • ${lesson.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: downloadProgress,
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          isDownloaded ? Icons.cloud_done : Icons.cloud_download,
                          color: isDownloaded ? Colors.green : context.primaryColor,
                          size: 24,
                        ),
                        onPressed: () async {
                          if (isDownloaded) {
                            await offlineNotifier.deleteLesson(lessonId);
                          } else {
                            try {
                              await offlineNotifier.downloadLesson(lessonId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lesson downloaded successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to download lesson: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        tooltip: isDownloaded ? 'Remove from offline' : 'Download for offline',
                      ),
                    if (lesson.count == lesson.completed)
                      Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.adaptive8),
                        child: Icon(
                          Icons.check,
                          color: context.primaryColor,
                        ),
                      )
                  ],
                ),
              ],
            ),
            12.heightBox,
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                color: enabled ? null : context.adaptive12,
                backgroundColor: enabled ? null : context.adaptive12,
                value: lesson.count == 0 ? 1 : lesson.completed / lesson.count,
                minHeight: 6,
              ),
            ),
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
