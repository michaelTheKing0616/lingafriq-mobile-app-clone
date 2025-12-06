import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';

import '../models/word_correction_model.dart';
import '../providers/navigation_provider.dart';
import '../widgets/points_and_profile_image_builder.dart';

class ChoicesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setChoices(List<String> value) {
    state = value;
  }
}

final _choicesProvider =
    NotifierProvider.autoDispose<ChoicesNotifier, List<String>>(() {
  return ChoicesNotifier();
});

class CorrectionScreen extends StatefulHookConsumerWidget {
  final String title;
  final List<WordCorrectionModel> wordCorrections;
  final String endpointToHit;
  final bool isTakeQuiz;
  final int score;
  final bool isCompleted;

  const CorrectionScreen({
    Key? key,
    required this.title,
    required this.wordCorrections,
    required this.endpointToHit,
    required this.score,
    this.isTakeQuiz = false,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  ConsumerState<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends ConsumerState<CorrectionScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(_choicesProvider.notifier)
          .setChoices(List<String>.from(widget.wordCorrections.first.choices));
      widget.wordCorrections.first.choices.log("First Choices");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // widget.wordCorrections.map((e) => e.toMap().prettyJson()).toList().log();
    final jsonStructure = widget.wordCorrections;
    final selectedAnswers = jsonStructure.map((e) {
      return useState<Map<String, String?>>({e.question: e.answer == '' ? '' : null});
    }).toList();
    final correctAnswers = jsonStructure.map((e) {
      return useState<Map<String, String>>({e.question: e.answer});
    }).toList();
    correctAnswers.map((e) => e.value).toList().log();

    final hasSubmitted = useState<bool>(false);
    final showResults = useState(false);

    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    final showIndicator = useState({"isLoading": false, "isCorrect": true});

    ref.watch(_choicesProvider);

    final content = PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (!didPop) {
              ref.read(navigationProvider).pop();
            }
          },
          child: Scaffold(
            body: Column(
              children: [
                TopGradientBox(
                  borderRadius: 0,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BackButton(color: Colors.white),
                        widget.title.text.xl2.semiBold
                            .maxLines(2)
                            .ellipsis
                            .color(Colors.white)
                            .make()
                            .p16(),
                      ],
                    ).expand(),
                    PointsAndProfileImageBuilder(
                      size: Size(0.07.sh, 0.07.sh),
                    ),
                    16.widthBox,
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Card(
                      color: context.isDarkMode ? context.cardColor : Colors.white,
                      elevation: 12,
                      shadowColor: Colors.black38,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // description.text.xl.make(),
                          // 8.heightBox,
                          Container(
                            color: context.adaptive5,
                            padding: const EdgeInsets.all(12),
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: TextStyle(fontSize: 19.sp, height: 1.5),
                                children: jsonStructure.asMap().entries.map((value) {
                                  final e = value.value;
                                  // final choices = e.choices;
                                  final question = e.question;
                                  final description = e.description;
                                  final answer = e.answer;
                                  final selected = selectedAnswers[value.key].value[question];
                                  const orangeColor = Color(0xffE26C23);

                                  final color = (() {
                                    if (showResults.value) {
                                      return selected == answer
                                          ? const Color(0XFF009245)
                                          : const Color(0XFFFF0000);
                                    }
                                    return selected != null ? const Color(0XFF009245) : orangeColor;
                                  }).call();

                                  return TextSpan(
                                    children: [
                                      description.textSpan.color(context.adaptive75).make(),
                                      "${selected ?? question} "
                                          .textSpan
                                          .medium
                                          .tap(() async {
                                            final answer = await _ChoicesSheet.showChoicesSheet(
                                              context,
                                              selectedAnswers.map((e) => e.value).toList(),
                                            );
                                            if (answer != null) {
                                              showResults.value = false;
                                            }
                                            selectedAnswers[jsonStructure.indexOf(e)].value = {
                                              question: answer
                                            };
                                          })
                                          .color(color)
                                          .make(),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ).p12(),
                    ).p16().scrollVertical().expand(),
                    12.heightBox,
                    PrimaryButton(
                      width: 0.6.sw,
                      onTap: () async {
                        final incorrectAnswers = <String>[];
                        // ref
                        //     .read(_choicesProvider.notifier)
                        //     .setChoices(List<String>.from(widget.wordCorrections.first.choices));
                        bool allCorrect = true;
                        for (var i = 0; i < selectedAnswers.length; i++) {
                          final selected = selectedAnswers[i].value;
                          selected.log("Selected");
                          final correct = correctAnswers[i].value;
                          final equals = mapEquals(selected, correct);
                          if (!equals) {
                            incorrectAnswers.add(correct.values.last);
                            allCorrect = false;
                            // selectedAnswers[i].value = null;
                            selectedAnswers[i].value = {
                              selectedAnswers[i].value.keys.first: null,
                            };
                            // break;
                          }
                        }
                        // ref
                        //     .read(_choicesProvider.notifier)
                        //     .setChoices(List<String>.from(incorrectAnswers));
                        if (allCorrect) {
                          hasSubmitted.value = false;
                          showResults.value = true;
                          showIndicator.value = {"isLoading": true, "isCorrect": true};
                          await Future.delayed(const Duration(milliseconds: 500));
                          showIndicator.value = {"isLoading": false, "isCorrect": true};
                          if (!widget.isCompleted) {
                            final success = await ref.read(apiProvider.notifier).markAsComplete(widget.endpointToHit);
                            if (!success) {
                              "Failed to mark correction as complete".log("correction_screen");
                            }
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } else {
                          showIndicator.value = {"isLoading": true, "isCorrect": false};
                          await Future.delayed(const Duration(milliseconds: 500));
                          showIndicator.value = {"isLoading": false, "isCorrect": false};
                          if (widget.isTakeQuiz) {
                            if (context.mounted) {
                              Navigator.of(context).pop(false);
                            }
                            return;
                          }
                          showResults.value = true;
                          hasSubmitted.value = true;
                        }
                      },
                      text: (hasSubmitted.value) ? "Try Again" : "Continue",
                    ),
                  ],
                ),
              ).expand()
            ],
          ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        content,
        if (isLoading)
          const Positioned.fill(
            child: IgnorePointer(child: DynamicLoadingScreen()),
          ),
        if (showIndicator.value['isLoading'] as bool)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: singleQuizIndicatorBuilder(
                    showIndicator.value['isCorrect'] as bool,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget singleQuizIndicatorBuilder(bool isCorrect) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(
            isCorrect ? Icons.done : Icons.close,
            size: 46.sp,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        12.heightBox,
        () {
          if (isCorrect) {
            return widget.isTakeQuiz ? widget.score.toString() : "Correct";
          }
          if (widget.isTakeQuiz) return '';
          return "Try Again";
        }.call().text.xl3.medium.white.make(),
      ],
    );
  }

  String get description =>
      """Jonny narrates his experience on a trip to Nigeria. Translated the Pidgin to English.""";
}

class _ChoicesSheet extends ConsumerWidget {
  final List<Map<String, String?>> selected;
  const _ChoicesSheet({
    Key? key,
    required this.selected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = ref.watch(_choicesProvider);
    // choices.toString().log("Choices");
    choices.shuffle();

    final mappedSelected =
        selected.where((e) => e.values.first != null).map((e) => e.values.first).toList();
    mappedSelected.log('mappedSelected');
    return SizedBox(
      height: 0.5.sh,
      child: ListView(
        children: choices
            .where((e) => !mappedSelected.contains(e))
            .map((e) => ListTile(
                  onTap: () {
                    // ref.read(_choicesProvider).remove(e);
                    Navigator.of(context).pop(e);
                  },
                  title: e.text.make(),
                  trailing: const Icon(Icons.chevron_right),
                ))
            .toList(),
      ),
    );
  }

  static Future<String?> showChoicesSheet(
    context,
    List<Map<String, String?>> selected,
  ) {
    return showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return _ChoicesSheet(selected: selected);
        // return _ChoicesSheet(choices: choices);
      },
    );
  }
}
