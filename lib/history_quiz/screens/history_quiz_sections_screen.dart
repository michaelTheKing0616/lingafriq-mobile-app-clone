import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../detail_types/correction_screen.dart';
import '../../detail_types/quiz_screen.dart';
import '../../models/quiz_model.dart';
import '../../models/word_correction_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/dialog_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/api.dart';
import '../../widgets/adaptive_progress_indicator.dart';
import '../../widgets/error_widet.dart';
import '../../widgets/greegins_builder.dart';
import '../../widgets/info_widget.dart';
import '../../widgets/top_gradient_box_builder.dart';
import '../models/history_quiz_lesson_model.dart';
import '../models/history_quiz_response.dart';

final historyQuizSectionsProvider =
    FutureProvider.autoDispose.family<HistoryQuizResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getHistoryQuiz();
});

class HistoryQuizSectionsListScreen extends StatefulWidget {
  final Language language;
  const HistoryQuizSectionsListScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  State<HistoryQuizSectionsListScreen> createState() => _HistoryQuizSectionsListScreenState();
}

class _HistoryQuizSectionsListScreenState extends State<HistoryQuizSectionsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BackButton(color: Colors.white),
                // PointsAndProfileImageBuilder(size: Size(0.1.sh, 0.1.sh)),

                // 0.05.sh.heightBox,
                GreetingsBuilder(
                  greetingTitle: '',
                  pageTitle: "History Quiz",
                )
              ],
            ),
          ),
          HistoryQuizSectionsList(language: widget.language).expand(),
        ],
      ),
    );
  }
}

class HistoryQuizSectionsList extends HookConsumerWidget {
  final Language language;
  const HistoryQuizSectionsList({Key? key, required this.language}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final historyQuizSectionsAsync = ref.watch(historyQuizSectionsProvider(language.id));
    return historyQuizSectionsAsync.when(
      data: (sections) {
        final historyQuizSections =
            sections.results.where((e) => e.language == language.id).toList();

        if (historyQuizSections.isEmpty) {
          return const InfoWidget(
            text: "No History Quiz Found :(",
            subText: "We're working to add some History Quizes for you.",
          );
        }

        return LoadingOverlayPro(
          isLoading: isLoading.value,
          child: RefreshIndicator(
            onRefresh: () {
              ref.invalidate(historyQuizSectionsProvider(language.id));
              return Future.value();
            },
            child: ListView.builder(
              itemCount: historyQuizSections.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final historyQuiz = historyQuizSections[index];
                final isEnabled = (() {
                  if (index == 0) {
                    return true;
                  }
                  return historyQuizSections[index - 1].completed ==
                      historyQuizSections[index - 1].count;
                }).call();
                historyQuiz.toString().log('historyQuiz');
                return _HistoryQuizItem(
                  languageId: language.id,
                  historyQuiz: historyQuiz,
                  enabled: historyQuiz.completed == historyQuiz.count || isEnabled,
                  onOpen: () async {
                    try {
                      isLoading.value = true;
                      final historySectionQuizes =
                          await ref.read(apiProvider.notifier).getHistoryQuizLessons(historyQuiz.id);
                      isLoading.value = false;
                      // historySectionQuizes.shuffle();
                      if (historySectionQuizes.isEmpty) {
                        ref
                            .read(dialogProvider("We're working to add history quiz!"))
                            .showSuccessSnackBar();
                        return;
                      }
                      final random = Random();
                      do {
                        final indexToOpen = random.randomUpto(historySectionQuizes.length);
                        final quiz = historySectionQuizes[indexToOpen];
                        final result = await openQuizDetail(quiz, historyQuiz.id, ref, historyQuiz);
                        if (result == null) break;
                        if (result == true) {
                          historySectionQuizes.removeAt(indexToOpen);
                        }
                      } while (historySectionQuizes.isNotEmpty);
                    } catch (e) {
                      isLoading.value = false;
                      ref.read(dialogProvider(e)).showExceptionDialog();
                    }
                    // int indexToOpen = 0;
                    // do {
                    //   final quiz = historySectionQuizes[indexToOpen];
                    //   final result = await openQuizDetail(quiz, historyQuiz.id, ref);
                    //   if (result != true) break;
                    //   indexToOpen++;
                    // } while (indexToOpen != historySectionQuizes.length);
                  },
                );
              },
            ),
          ),
        );
      },
      error: (e, s) {
        // throw e;
        return StreamErrorWidget(
          error: e,
          onTryAgain: () {
            ref.invalidate(historyQuizSectionsProvider(language.id));
          },
        );
      },
      loading: () => const AdaptiveProgressIndicator(),
    );
  }

  Future<bool?> openQuizDetail(
    HistoryQuizLessonModel randomQuiz,
    int sectionId,
    WidgetRef ref,
    HistoryQuiz historyQuiz,
  ) async {
    if (randomQuiz.isQuiz) {
      return openChoiceQuizScreen(randomQuiz, sectionId, ref, historyQuiz);
    } else if (randomQuiz.isWordQuiz) {
      return openWordQuizScreen(randomQuiz, sectionId, ref, historyQuiz);
    } else {
      await ref.read(dialogProvider("")).showPlatformDialogue(
            title: "Unhandled",
            content: Text(randomQuiz.toString()),
          );
      return false;
    }
  }

  Future<bool?> openChoiceQuizScreen(
    HistoryQuizLessonModel sectionHistory,
    int sectionId,
    WidgetRef ref,
    HistoryQuiz historyQuiz,
  ) async {
    try {
      final questions = sectionHistory.otherData['question'] as List;
      final quiz = questions.map((e) {
        final question = e['question']["question"] as String;
        final choices = e["choices"] as List;
        return QuizModel(
          question: question,
          score: sectionHistory.score / questions.length,
          answer: choices.where((e) => e['correct_answer'] == true).first['text'],
          choices: choices.map((e) => e['text'] as String).toList(),
        );
      }).toList();
      final result = await ref.read(navigationProvider).naviateTo(QuizScreen(
            title: sectionHistory.title,
            quiz: quiz,
            isTakeQuiz: true,
            endpointToHit: Api.completeHistoryInstantQuiz(sectionId, sectionHistory.id),
            isCompleted: historyQuiz.completed == historyQuiz.count,
          ));
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }

  Future<bool?> openWordQuizScreen(
    HistoryQuizLessonModel sectionHistory,
    int sectionId,
    WidgetRef ref,
    HistoryQuiz historyQuiz,
  ) async {
    try {
      final questions = sectionHistory.otherData['word_question'] as List;
      final question = (questions.first as List).first;
      final text = question['text'] as String;
      final brackets = <String>[];
      // final bracketsIncluded = <String>[];
      final regex = RegExp(r'\[(.*?)\]');
      text.splitMapJoin(regex, onMatch: (match) {
        brackets.add(match[1].toString());
        // bracketsIncluded.add(match[0].toString());
        return '';
      });
      final splittedTextOnBrackets = text.split(regex);
      final englishChoices = brackets.map((e) => e.split("/").last.trim()).toList();
      final choiceQuestions = brackets.map((e) => e.split("/").first.trim()).toList();
      final wordCorrections = choiceQuestions.asMap().entries.map((e) {
        final index = e.key;
        final value = e.value;
        final shuffleableChoicesList = List<String>.from(englishChoices);
        shuffleableChoicesList.shuffle();
        return WordCorrectionModel(
          choices: shuffleableChoicesList,
          answer: englishChoices.elementAt(index),
          question: value,
          description: "${splittedTextOnBrackets[index]} ",
        );
      }).toList();

      final result = await ref.read(navigationProvider).naviateTo(
            CorrectionScreen(
              title: sectionHistory.title,
              score: sectionHistory.score,
              wordCorrections: wordCorrections,
              isTakeQuiz: true,
              endpointToHit: Api.completeHistoryInstantQuiz(sectionId, sectionHistory.id),
              isCompleted: historyQuiz.completed == historyQuiz.count,
            ),
          );
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }
}

class _HistoryQuizItem extends ConsumerWidget {
  final int languageId;
  final HistoryQuiz historyQuiz;
  final bool enabled;
  final VoidCallback onOpen;
  const _HistoryQuizItem({
    Key? key,
    required this.languageId,
    required this.historyQuiz,
    required this.enabled,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
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
                    historyQuiz.name.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "Points • ${historyQuiz.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (historyQuiz.completed == historyQuiz.count)
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
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(100),
            //   child: LinearProgressIndicator(
            //     color: enabled ? null : context.adaptive12,
            //     backgroundColor: enabled ? null : context.adaptive12,
            //     value: completedLectures / lecturesCount,
            //     minHeight: 6,
            //   ),
            // ),
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
