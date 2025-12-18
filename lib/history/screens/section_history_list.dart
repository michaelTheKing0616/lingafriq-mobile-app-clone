import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/history/models/history_response.dart';
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
import '../models/section_history_model.dart';

final sectionHistoryProvider =
    FutureProvider.autoDispose.family<List<SectionHistoryModel>, int>((ref, id) {
  return ref.read(apiProvider.notifier).getSectionHistory(id);
});

class HistorySectionsListScreen extends ConsumerWidget {
  final History history;
  const HistorySectionsListScreen({
    Key? key,
    required this.history,
  }) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionHistoriesAsync = ref.watch(sectionHistoryProvider(history.id));

    return Scaffold(
      body: sectionHistoriesAsync.when(
        data: (sectionHistories) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(color: Colors.white),
                    // PointsAndProfileImageBuilder(size: Size(0.1.sh, 0.1.sh)),
                    LangguageTypeHeaderBuilder(
                      title: "History",
                      level: '',
                      count: sectionHistories.where((e) => e.isTutorial).length,
                      points: sectionHistories.sum((p0) => p0.score).toInt(),
                      allCount: sectionHistories
                          // .where((e) => e.isTutorial)
                          .length,
                      type: "",
                      completed: sectionHistories.where((e) => e.completed_by != null).length,
                    ),
                  ],
                ),
              ),
              if (sectionHistories.isEmpty)
                const InfoWidget(
                  text: "No History Found :(",
                  subText: "We're working to add some history for you.",
                ).expand(),
              if (sectionHistories.isNotEmpty)
                _SectionHistoryList(
                  history: history,
                  sectionHistories: sectionHistories,
                ).expand()
            ],
          );
        },
        error: (e, s) {
          return StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(sectionHistoryProvider(history.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "History"),
      ),
    );
  }
}

class _SectionHistoryList extends ConsumerWidget {
  final History history;
  final List<SectionHistoryModel> sectionHistories;
  const _SectionHistoryList({
    Key? key,
    required this.history,
    required this.sectionHistories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(sectionHistoryProvider(history.id));
        return Future.value();
      },
      child: ListView.builder(
        itemCount: sectionHistories.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final sectionHistory = sectionHistories[index];
          final isEnabled = (() {
            if (index == 0) {
              return true;
            }
            return sectionHistories[index - 1].completed ?? true;
          }).call();
          return _SectionHistoryItem(
            historyId: history.id,
            sectionHistory: sectionHistory,
            enabled: sectionHistory.completed_by != null || isEnabled,
            onOpen: () async {
              int indexToOpen = index;
              do {
                final history = sectionHistories[indexToOpen];
                final result = await openQuizDetail(history, ref);
                if (result != true) break;
                indexToOpen++;
              } while (indexToOpen != sectionHistories.length);
              ref.invalidate(sectionHistoryProvider(history.id));
              if (indexToOpen == sectionHistories.length) {
                ref.read(navigationProvider).pop();
              }
            },
          );
        },
      ),
    );
  }

  Future<bool?> openQuizDetail(SectionHistoryModel sectionHistory, WidgetRef ref) async {
    if (sectionHistory.isTutorial) {
      return openTutorialScreen(sectionHistory, ref);
    } else if (sectionHistory.isQuiz) {
      return openChoiceQuizScreen(sectionHistory, ref);
    } else if (sectionHistory.isWordQuiz) {
      return openWordQuizScreen(sectionHistory, ref);
    } else {
      await ref.read(dialogProvider("")).showPlatformDialogue(
            title: "Unhandled",
            content: Text(sectionHistory.toString()),
          );
      return false;
    }
  }

  Future<bool?> openTutorialScreen(SectionHistoryModel sectionHistory, WidgetRef ref) async {
    final tutorialScreen = TutorialDetailScreen(
      title: sectionHistory.title,
      text: sectionHistory.otherData?['text'] ?? sectionHistory.otherData?['title'],
      audio: sectionHistory.otherData['audio'],
      video: sectionHistory.otherData['video'],
      image: sectionHistory.otherData['image'],
      endpointToHit: Api.completeHistoryTutorial(history.id, sectionHistory.id),
      isCompleted: sectionHistory.completed_by != null,
    );
    return await ref.read(navigationProvider).naviateTo(tutorialScreen);
  }

  Future<bool?> openChoiceQuizScreen(SectionHistoryModel sectionHistory, WidgetRef ref) async {
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
            endpointToHit: Api.completeHistoryQuiz(history.id, sectionHistory.id),
            isCompleted: sectionHistory.completed_by != null,
          ));
      return result;
    } catch (e) {
      ref.read(dialogProvider(e)).showPlatformDialogue(title: "Error Parsing");
      if (kDebugMode) rethrow;
      return false;
    }
  }

  Future<bool?> openWordQuizScreen(SectionHistoryModel sectionHistory, WidgetRef ref) async {
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
              endpointToHit: Api.completeHistoryQuiz(history.id, sectionHistory.id),
              isCompleted: sectionHistory.completed_by != null,
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

class _SectionHistoryItem extends ConsumerWidget {
  final int historyId;
  final SectionHistoryModel sectionHistory;
  final bool enabled;
  final VoidCallback onOpen;
  const _SectionHistoryItem({
    Key? key,
    required this.historyId,
    required this.sectionHistory,
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
                    sectionHistory.title.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "Points • ${sectionHistory.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (sectionHistory.completed_by != null)
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
