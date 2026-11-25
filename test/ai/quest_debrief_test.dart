import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/debrief.dart';

void main() {
  group('P11-019 debrief domain', () {
    test('primary source JSON validates', () {
      final json = File(kYaaQuestPrimarySourcePath).readAsStringSync();
      final card = parsePrimarySourceJson(json);
      expect(card.sourceId, 'src-yaa-co-1900');
      expect(card.licenceId, isNotEmpty);
      expect(card.imageAltEn, isNotEmpty);
    });

    test('historian note blocked until approved', () {
      expect(
        historianNoteReadyForRelease(
          approvedForRelease: false,
          noteBody: kYaaQuestHistorianNoteBody,
        ),
        isFalse,
      );
      expect(
        historianNoteReadyForRelease(
          approvedForRelease: true,
          noteBody: kYaaQuestHistorianNoteBody,
        ),
        isTrue,
      );
      expect(
        historianNoteReadyForRelease(
          approvedForRelease: true,
          noteBody: '   ',
        ),
        isFalse,
      );
    });

    test('mini-quiz stores result against chapter 4', () {
      final questions = defaultYaaAftermathQuiz();
      final answers = {for (final q in questions) q.id: q.correctOptionId};
      final result = evaluateMiniQuiz(
        questId: 'yaa_asantewaa_golden_stool',
        chapterIndex: 4,
        questions: questions,
        answersByQuestionId: answers,
      );
      expect(result.chapterIndex, 4);
      expect(result.passed, isTrue);
      expect(result.correctCount, 3);
    });

    test('deck insertion idempotent', () {
      var progress = PersonaQuestProgress.initial('yaa_asantewaa_golden_stool');
      final ids = defaultYaaQuestVocabularyLexemeIds();
      progress = mergeQuestVocabularyIdempotent(progress, ids);
      expect(progress.earnedVocabularyIds.length, ids.length);
      progress = mergeQuestVocabularyIdempotent(progress, ids);
      expect(progress.earnedVocabularyIds.length, ids.length);
    });
  });
}
