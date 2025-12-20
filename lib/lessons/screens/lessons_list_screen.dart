import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../models/lesson_response.dart';
import 'section_lessons_list.dart';

final lessonsListProvider = FutureProvider.autoDispose.family<LessonResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getLessons(id);
});

class LessonsListScreen extends ConsumerWidget {
  final Language language;
  const LessonsListScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

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
                    const BackButton(color: Colors.white),
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
                        );
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
  const _LessonItem({
    Key? key,
    required this.lesson,
    required this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled
            ? () async {
                ref.read(navigationProvider).naviateTo(LessonSectionsListScreen(lesson: lesson));
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                if (lesson.count == lesson.completed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.adaptive8),
                    child: Icon(
                      Icons.check,
                      color: context.primaryColor,
                    ),
                  )
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
