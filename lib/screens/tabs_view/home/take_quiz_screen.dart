import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/history_quiz/screens/history_quiz_sections_screen.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../../detail_types/correction_screen.dart';
import '../../../detail_types/quiz_screen.dart';
import '../../../language_quiz/screens/language_quiz_sections_screen.dart';
import '../../../models/quiz_model.dart';
import '../../../models/word_correction_model.dart';
import '../../../providers/dialog_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../random_quiz/models/random_quiz_lesson_model.dart';
import '../../../screens/tabs_view/app_drawer/app_drawer.dart';
import '../../../screens/tabs_view/tabs_view.dart';
import '../../../utils/api.dart';
import '../../../utils/constants.dart';
import '../../../widgets/greegins_builder.dart';

class TakeQuizScreen extends ConsumerWidget {
  final Language language;
  const TakeQuizScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(navigationProvider).pop();
        }
      },
      child: LoadingOverlayPro(
        isLoading: isLoading,
        child: Scaffold(
          drawer: const AppDrawer(),
          body: Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white),
                          onPressed: () {
                            ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                          },
                        ),
                        const BackButton(color: Colors.white),
                      ],
                    ),
                  // PointsAndProfileImageBuilder(size: Size(0.1.sh, 0.1.sh)),
                  GreetingsBuilder(
                    greetingTitle: '',
                    pageTitle: "Take Quiz",
                  )
                ],
              ),
            ),
            Stack(
              children: [
                IgnorePointer(
                  ignoring: true,
                  child: Image.asset(
                    Images.languaeDetailBackground,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Padding(
                              padding: EdgeInsets.all(16.0.sp),
                              child: Stack(
                                children: [
                                  IgnorePointer(
                                    ignoring: true,
                                    child:
                                        Image.asset(Images.map).offset(offset: Offset(0, -12.sp)),
                                  ),
                                  Positioned(
                                    left: constraints.maxWidth * 0.12,
                                    top: constraints.maxHeight * 0.075,
                                    child: _RandomTextBuilder(
                                      onTap: () async {
                                        final randomQuizes = await ref
                                            .read(apiProvider.notifier)
                                            .getRandomQuizLessons(language.id);
                                        // randomQuizes.shuffle();
                                        if (randomQuizes.isEmpty) {
                                          ref
                                              .read(dialogProvider(
                                                  "We're working to add random quiz!"))
                                              .showSuccessSnackBar();
                                          return;
                                        }
                                        final random = Random();
                                        do {
                                          final indexToOpen =
                                              random.randomUpto(randomQuizes.length);
                                          final quiz = randomQuizes[indexToOpen];
                                          final result = await openQuizDetail(quiz, ref);
                                          if (result == null) break;
                                          if (result == true) {
                                            randomQuizes.removeAt(indexToOpen);
                                          }
                                        } while (randomQuizes.isNotEmpty);
                                      },
                                    ).animate(effects: kGradientTextEffects),
                                  ),
                                  Positioned(
                                    left: constraints.maxWidth * 0.365,
                                    top: constraints.maxHeight * (context.isSmall ? 0.315 : 0.265),
                                    child: _LanguageTextBuilder(
                                      onTap: () {
                                        ref.read(navigationProvider).naviateTo(
                                              LanguageQuizSectionsListScreen(language: language),
                                            );
                                      },
                                    ).animate(effects: kGradientTextEffects),
                                  ),
                                  Positioned(
                                    left: constraints.maxWidth * (context.isSmall ? 0.45 : 0.425),
                                    top: constraints.maxHeight * (context.isSmall ? 0.6 : 0.475),
                                    child: _HistoryTextBuilder(
                                      size: Size(18.sp, 18.sp),
                                      onTap: () {
                                        ref.read(navigationProvider).naviateTo(
                                              HistoryQuizSectionsListScreen(language: language),
                                            );
                                      },
                                    ).animate(effects: kGradientTextEffects),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).px16(),
                      ),
                      20.heightBox,
                      PrimaryButton(
                        width: 0.6.sw,
                        onTap: () {},
                        color: Colors.transparent,
                        text: "",
                      ).centered(),
                    ],
                  ),
                )
              ],
            ).expand()
          ],
        ),
        ),
      ),
    );
  }

  Future<bool?> openQuizDetail(RandomQuizLessonModel randomQuiz, WidgetRef ref) async {
    if (randomQuiz.isQuiz) {
      return openChoiceQuizScreen(randomQuiz, ref);
    } else if (randomQuiz.isWordQuiz) {
      return openWordQuizScreen(randomQuiz, ref);
    } else {
      await ref.read(dialogProvider("")).showPlatformDialogue(
            title: "Unhandled",
            content: Text(randomQuiz.toString()),
          );
      return false;
    }
  }

  Future<bool?> openChoiceQuizScreen(RandomQuizLessonModel randomQuiz, WidgetRef ref) async {
    try {
      final questions = [randomQuiz.otherData['question']];
      final quiz = questions.map((e) {
        final question = e['question'] as String;
        final choices = randomQuiz.otherData["choices"] as List;
        return QuizModel(
          question: question,
          score: randomQuiz.score / questions.length,
          answer: choices.where((e) => e['correct_answer'] == true).first['text'],
          choices: choices.map((e) => e['text'] as String).toList(),
        );
      }).toList();
      final result = await ref.read(navigationProvider).naviateTo(QuizScreen(
            title: randomQuiz.title,
            quiz: quiz,
            isTakeQuiz: true,
            endpointToHit: Api.completeRandomInstantQuiz(language.id, randomQuiz.id),
          ));
      "$result".log("openChoiceQuizScreen");
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }

  Future<bool?> openWordQuizScreen(RandomQuizLessonModel randomQuiz, WidgetRef ref) async {
    try {
      // final questions = randomQuiz.otherData['word_question'] as List;
      final question = randomQuiz.otherData; // (questions.first as List).first;
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
              title: randomQuiz.title,
              score: randomQuiz.score,
              wordCorrections: wordCorrections,
              isTakeQuiz: true,
              endpointToHit: Api.completeRandomWordQuiz(language.id, randomQuiz.id),
            ),
          );
      "$result".log("openWordQuizScreen");
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }
}

class _RandomTextBuilder extends StatelessWidget {
  final VoidCallback onTap;
  const _RandomTextBuilder({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['r', 'a', 'n', 'd', 'o', 'm'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 20.sp,
                height: 20.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: 20.sp * 5.5,
          //   child: const LinearProgressIndicator(value: 1).offset(offset: Offset(8.sp, 0)),
          // ),
        ],
      ),
    );
  }
}

class _LanguageTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  const _LanguageTextBuilder({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['l', 'a', 'n', 'g', 'u', 'a', 'g', 'e'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 18.sp,
                height: 18.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: 18.sp * 7.5,
          //   child: const LinearProgressIndicator(value: 1).offset(
          //     offset: Offset(8.sp, 0),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _HistoryTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  final Size? size;
  const _HistoryTextBuilder({
    Key? key,
    this.size,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['h', 'i', 's', 't', 'o', 'r', 'y'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: size?.width ?? 20.sp,
                height: size?.height ?? 20.sp,
              );
            }).toList(),
          ),
          // 8.heightBox,
          // SizedBox(
          //   width: (size?.width ?? 20.sp) * 6.3,
          //   child: const LinearProgressIndicator(value: 1).offset(
          //     offset: Offset(4.sp, 0),
          //   ),
          // ),
        ],
      ),
    );
  }
}
