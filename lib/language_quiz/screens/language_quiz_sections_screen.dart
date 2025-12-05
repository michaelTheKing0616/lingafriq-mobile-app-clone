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
import '../../screens/loading/dynamic_loading_screen.dart';
import '../../widgets/greegins_builder.dart';
import '../../widgets/info_widget.dart';
import '../../widgets/top_gradient_box_builder.dart';
import '../models/language_quiz_lesson_model.dart';
import '../models/language_quiz_response.dart';

final languageQuizSectionsProvider =
    FutureProvider.autoDispose.family<LanguageQuizResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getLanguageQuiz();
});

class LanguageQuizSectionsListScreen extends StatefulWidget {
  final Language language;
  const LanguageQuizSectionsListScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  State<LanguageQuizSectionsListScreen> createState() => _LanguageQuizSectionsListScreenState();
}

class _LanguageQuizSectionsListScreenState extends State<LanguageQuizSectionsListScreen> {
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
                GreetingsBuilder(
                  greetingTitle: '',
                  pageTitle: "Language Quiz",
                )
              ],
            ),
          ),
          LanguageQuizSectionsList(language: widget.language).expand(),
        ],
      ),
    );
  }
}

class LanguageQuizSectionsList extends HookConsumerWidget {
  final Language language;
  const LanguageQuizSectionsList({Key? key, required this.language}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final languageQuizSectionsAsync = ref.watch(languageQuizSectionsProvider(language.id));
    return languageQuizSectionsAsync.when(
      data: (sections) {
        final languageQuizSections =
            sections.results.where((e) => e.language == language.id).toList();
        if (languageQuizSections.isEmpty) {
          return const InfoWidget(
            text: "No Language Quiz Found :(",
            subText: "We're working to add some Language Quizes for you.",
          );
        }

        return LoadingOverlayPro(
          isLoading: isLoading.value,
          child: RefreshIndicator(
            onRefresh: () {
              ref.invalidate(languageQuizSectionsProvider(language.id));
              return Future.value();
            },
            child: ListView.builder(
              itemCount: languageQuizSections.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final languageQuiz = languageQuizSections[index];
                final isEnabled = (() {
                  if (index == 0) {
                    return true;
                  }
                  return languageQuizSections[index - 1].completed ==
                      languageQuizSections[index - 1].count;
                }).call();
                return _LanguageQuizItem(
                  languageId: language.id,
                  languageQuiz: languageQuiz,
                  enabled: languageQuiz.completed == languageQuiz.count || isEnabled,
                  onOpen: () async {
                    try {
                      isLoading.value = true;
                      final languageSectionQuizes =
                          await ref.read(apiProvider.notifier).getLanguageQuizLessons(languageQuiz.id);
                      isLoading.value = false;
                      if (languageSectionQuizes.isEmpty) {
                        ref
                            .read(dialogProvider("We're working to add language quiz!"))
                            .showSuccessSnackBar();
                        return;
                      }
                      final random = Random();
                      do {
                        final indexToOpen = random.randomUpto(languageSectionQuizes.length);
                        final quiz = languageSectionQuizes[indexToOpen];
                        final result =
                            await openQuizDetail(quiz, languageQuiz.id, ref, languageQuiz);
                        if (result == null) break;
                        if (result == true) {
                          languageSectionQuizes.removeAt(indexToOpen);
                        }
                      } while (languageSectionQuizes.isNotEmpty);
                    } catch (e) {
                      isLoading.value = false;
                      ref.read(dialogProvider(e)).showExceptionDialog();
                      ref.read(dialogProvider(e)).showExceptionDialog();
                    }
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
            ref.invalidate(languageQuizSectionsProvider(language.id));
          },
        );
      },
      loading: () => const DynamicLoadingScreen(),
    );
  }

  Future<bool?> openQuizDetail(
    LanguageQuizLessonModel languageQuiz,
    int sectionId,
    WidgetRef ref,
    LangaugeQuiz langaugeQuiz,
  ) async {
    if (languageQuiz.isQuiz) {
      return openChoiceQuizScreen(languageQuiz, sectionId, ref, langaugeQuiz);
    } else if (languageQuiz.isWordQuiz) {
      return openWordQuizScreen(languageQuiz, sectionId, ref, langaugeQuiz);
    } else {
      await ref.read(dialogProvider("")).showPlatformDialogue(
            title: "Unhandled",
            content: Text(languageQuiz.toString()),
          );
      return false;
    }
  }

  Future<bool?> openChoiceQuizScreen(
    LanguageQuizLessonModel languageQuiz,
    int sectionId,
    WidgetRef ref,
    LangaugeQuiz langaugeQuiz,
  ) async {
    try {
      final questions = languageQuiz.otherData['question'] as List;
      final quiz = questions.map((e) {
        final question = e['question']["question"] as String;
        final choices = e["choices"] as List;
        return QuizModel(
          question: question,
          score: langaugeQuiz.score / questions.length,
          answer: choices.where((e) => e['correct_answer'] == true).first['text'],
          choices: choices.map((e) => e['text'] as String).toList(),
        );
      }).toList();
      final result = await ref.read(navigationProvider).naviateTo(QuizScreen(
            title: languageQuiz.title,
            quiz: quiz,
            isTakeQuiz: true,
            endpointToHit: Api.completelanguageInstantQuiz(sectionId, languageQuiz.id),
            isCompleted: langaugeQuiz.completed == langaugeQuiz.count,
          ));
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }

  Future<bool?> openWordQuizScreen(
    LanguageQuizLessonModel languageQuiz,
    int sectionId,
    WidgetRef ref,
    LangaugeQuiz langaugeQuiz,
  ) async {
    try {
      final questions = languageQuiz.otherData['word_question'] as List;
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
              title: languageQuiz.title,
              score: languageQuiz.score,
              wordCorrections: wordCorrections,
              isTakeQuiz: true,
              endpointToHit: Api.completelanguageInstantQuiz(sectionId, languageQuiz.id),
              isCompleted: langaugeQuiz.completed == langaugeQuiz.count,
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

class _LanguageQuizItem extends ConsumerWidget {
  final int languageId;
  final LangaugeQuiz languageQuiz;
  final bool enabled;
  final VoidCallback onOpen;
  const _LanguageQuizItem({
    Key? key,
    required this.languageId,
    required this.languageQuiz,
    required this.enabled,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    languageQuiz.completed.toString().log('completed');
    languageQuiz.count.toString().log('count');
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
                    languageQuiz.name.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "Points • ${languageQuiz.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                if (languageQuiz.completed == languageQuiz.count)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.adaptive8),
                    child: Icon(
                      Icons.check,
                      color: context.primaryColor,
                    ).pOnly(left: 4),
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
