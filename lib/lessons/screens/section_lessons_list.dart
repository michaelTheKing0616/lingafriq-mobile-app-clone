import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/utils.dart';

import '../../detail_types/correction_screen.dart';
import '../../detail_types/quiz_screen.dart';
import '../../detail_types/tutorial_detail_screen.dart';
import '../../models/quiz_model.dart';
import '../../models/word_correction_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/api.dart';
import '../../widgets/error_widet.dart';
import '../../widgets/info_widget.dart';
import '../../widgets/language_type_header_builder.dart';
import '../../widgets/loading_builder.dart';
import '../../widgets/top_gradient_box_builder.dart';
import '../models/section_lesson_model.dart';

final sectionLessonsProvider =
    FutureProvider.autoDispose.family<List<SectionLessonModel>, int>((ref, id) {
  return ref.read(apiProvider.notifier).getSectionLessons(id);
});

class LessonSectionsListScreen extends ConsumerWidget {
  final Lesson lesson;
  const LessonSectionsListScreen({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionLessonsAsync = ref.watch(sectionLessonsProvider(lesson.id));
    return Scaffold(
      body: sectionLessonsAsync.when(
        data: (sectionLessons) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackButton(color: Theme.of(context).colorScheme.onPrimary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Hero(
                        tag: 'path_node_${lesson.id}',
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lesson.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LangguageTypeHeaderBuilder(
                      title: "Lessons",
                      level: '',
                      count: sectionLessons.where((e) => e.isTutorial).length,
                      points: sectionLessons.sum((p0) => p0.score).toInt(),
                      allCount: sectionLessons.length,
                      type: "",
                      completed: sectionLessons.where((e) => e.isCompleted(ref)).length,
                    ),
                  ],
                ),
              ),
              if (sectionLessons.isEmpty)
                const InfoWidget(
                  text: "No Lesson Found :(",
                  subText: "We're working to add some lessons for you.",
                ).expand(),
              if (sectionLessons.isNotEmpty)
                _SectionLessonsList(
                  lesson: lesson,
                  sectionLessons: sectionLessons,
                ).expand()
            ],
          );
        },
        error: (e, s) {
          return StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(sectionLessonsProvider(lesson.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "Lessons"),
      ),
    );
  }
}

class _SectionLessonsList extends ConsumerWidget {
  final Lesson lesson;
  final List<SectionLessonModel> sectionLessons;

  const _SectionLessonsList({
    required this.lesson,
    required this.sectionLessons,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(sectionLessonsProvider(lesson.id));
        return Future.value();
      },
      child: ListView.builder(
        itemCount: sectionLessons.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final sectionLesson = sectionLessons[index];
          final isEnabled = (() {
            if (index == 0) {
              return true;
            }
            return sectionLessons[index - 1].completed ?? true;
          }).call();
          return _SectionLessonItem(
            lessonId: lesson.id,
            sectionLesson: sectionLesson,
            enabled: sectionLesson.completed_by != null || isEnabled,
            onOpen: () async {
              // Classic lesson/quiz flow is the default path.
              // Expanded Curriculum remains available via dedicated entry points.
              final result = await openQuizDetail(sectionLesson, ref);

              // Refresh section lessons list after returning.
              ref.invalidate(sectionLessonsProvider(lesson.id));

              // If lesson was completed, parent flow can decide next navigation.
              if (result == true) {
                // no-op: list refresh already reflects completion state
              }
            },
          );
        },
      ),
    );
  }

  Future<bool?> openQuizDetail(SectionLessonModel sectionLesson, WidgetRef ref) async {
    if (sectionLesson.isTutorial) {
      return openTutorialScreen(sectionLesson, ref);
    } else if (sectionLesson.isQuiz) {
      return openChoiceQuizScreen(sectionLesson, ref);
    } else if (sectionLesson.isWordQuiz) {
      return openWordQuizScreen(sectionLesson, ref);
    } else {
      await ref.read(dialogProvider("")).showPlatformDialogue(
            title: "Unhandled",
            content: Text(sectionLesson.toString()),
          );
      return false;
    }
  }

  Future<bool?> openTutorialScreen(SectionLessonModel sectionLesson, WidgetRef ref) async {
    final tutorialScreen = TutorialDetailScreen(
      title: sectionLesson.title,
      text: sectionLesson.otherData?['text'] ?? sectionLesson.otherData?['title'],
      audio: sectionLesson.otherData['audio'],
      video: sectionLesson.otherData['video'],
      image: sectionLesson.otherData['image'],
      endpointToHit: Api.completeLessonTutorial(lesson.id, sectionLesson.id),
      isCompleted: sectionLesson.isCompleted(ref),
    );
    return await ref.read(navigationProvider).navigateTo(tutorialScreen);
  }

  Future<bool?> openChoiceQuizScreen(SectionLessonModel sectionLesson, WidgetRef ref) async {
    'openChoiceQuizScreen'.log("openChoiceQuizScreen");
    try {
      final rawQuestions = sectionLesson.otherData['question'];
      if (rawQuestions == null || rawQuestions is! List || rawQuestions.isEmpty) {
        ref.read(dialogProvider('No quiz questions available for this lesson.')).showExceptionDialog();
        return false;
      }
      final questions = rawQuestions;

      final quiz = questions.where((e) {
        // Defensive: skip malformed entries
        return e is Map && e['question'] is Map && e['choices'] is List;
      }).map((e) {
        final question = e['question']["question"] as String;
        final choices = e["choices"] as List;
        final correctAnswersList = choices.where((e) => e['correct_answer'] == true);
        if (correctAnswersList.isEmpty) return null;

        return QuizModel(
          question: question,
          score: sectionLesson.score / questions.length,
          answer: correctAnswersList.first['text'],
          choices: choices.map((e) => e['text'] as String).toList(),
        );
      }).whereType<QuizModel>().toList();

      if (quiz.isEmpty) {
        ref.read(dialogProvider('Quiz data is incomplete. Please try again later.')).showExceptionDialog();
        return false;
      }

      final result = await ref.read(navigationProvider).navigateTo(QuizScreen(
            title: sectionLesson.title,
            quiz: quiz,
            endpointToHit: Api.completeLessonQuiz(lesson.id, sectionLesson.id),
            isCompleted: sectionLesson.isCompleted(ref),
          ));
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showExceptionDialog();
      if (kDebugMode) rethrow;
      return false;
    }
  }

  Future<bool?> openWordQuizScreen(SectionLessonModel sectionLesson, WidgetRef ref) async {
    try {
      final questions = sectionLesson.otherData['word_question'] as List;
      final question = (questions.first as List).first;
      final text = '${question['text'] as String}[]';
      // const text = '''Fill in the brackets with the correct translation.
      // Ling: Let me tell you a story.
      // Once upon a time, in one little town. There was this family of four. The [Father/Baba] a sarki (king),  and  [Mother/Mama] a sarauniya (queen) had two children. The [Female/Na mace] was [older/Babba], the  [Male/Na miji] was [Younger/Karami]. One day, the [Son/Da] said to his Father, “when I grow up, I want to wear babban riga like you. Babban riga is a big robe don by Hausa men of status during festivities.
      // The father laughed and said to him “you will also wear rawani (crown), bejewelled takalmi (shoes) during your turbaning ceremony."  “What about me?"  “You will grow to become the most beautiful in all of Kebbi. One day, you’ll wear the finest of zinariya (gold), a kallabi (head tie) and be cloaked by an alkyabba (a big embroidered cloak worn by royalty), my [Daughter/ya.]."
      // The children giggled and said in unison. “I can’t wait to grow up!”

      // The End.''';
      // text.toString().log();
      final brackets = <String>[];
      // final bracketsIncluded = <String>[];
      final regex = RegExp(r'\[(.*?)\]');
      text.splitMapJoin(regex, onMatch: (match) {
        brackets.add(match[1].toString());
        return '';
      });
      // brackets.toString().log('brackerts');
      // brackets.removeWhere((e) => e.isEmpty);
      final splittedTextOnBrackets = text.split(regex);
      final englishChoices = brackets.map((e) => e.split("/").last.trim()).toList();
      final choiceQuestions = brackets.map((e) => e.split("/").first.trim()).toList();
      final wordCorrections = choiceQuestions.asMap().entries.map((e) {
        final index = e.key;
        final value = e.value;
        final shuffleableChoicesList = List<String>.from(englishChoices.where((e) => e.isNotEmpty));
        shuffleableChoicesList.shuffle();
        return WordCorrectionModel(
          choices: shuffleableChoicesList,
          answer: englishChoices.elementAt(index),
          question: value,
          description: "${splittedTextOnBrackets[index]} ",
        );
      }).toList();

      final result = await ref.read(navigationProvider).navigateTo(
            CorrectionScreen(
              title: sectionLesson.title,
              score: sectionLesson.score,
              wordCorrections: wordCorrections,
              endpointToHit: Api.completeLessonQuiz(lesson.id, sectionLesson.id),
              isCompleted: sectionLesson.isCompleted(ref),
            ),
          );
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showExceptionDialog();
      if (kDebugMode) rethrow;
      return false;
    }
  }
}

class _SectionLessonItem extends ConsumerWidget {
  final int lessonId;
  final SectionLessonModel sectionLesson;
  final bool enabled;
  final VoidCallback onOpen;
  const _SectionLessonItem({
    required this.lessonId,
    required this.sectionLesson,
    required this.enabled,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Theme.of(context).colorScheme.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionLesson.title.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "Points • ${sectionLesson.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (sectionLesson.isCompleted(ref))
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
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
