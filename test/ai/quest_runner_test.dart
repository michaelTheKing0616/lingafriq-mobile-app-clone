import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';

void main() {
  late String questJson;

  setUp(() {
    questJson = File(kYaaAsantewaaQuestAssetPath).readAsStringSync();
  });

  group('P11-016 Yaa Asantewaa quest structure', () {
    test('chapter count, CEFR A2–B1, 25 min, three layers', () {
      final quest = PersonaQuestRunner.parseQuestJson(questJson);
      expect(quest.personaId, 'yaa_asantewaa');
      expect(quest.chapters.length, 4);
      expect(quest.cefrMin, 'A2');
      expect(quest.cefrMax, 'B1');
      expect(quest.runtimeMinutes, 25);
      expect(quest.replayable, isTrue);
      expect(
        quest.experienceLayers,
        containsAll(['narrative', 'language', 'history']),
      );
      expect(
        quest.chapters.fold<int>(0, (s, c) => s + c.estimatedMinutes),
        25,
      );
    });

    test('chapter 1 young messenger honorific objective', () {
      final quest = PersonaQuestRunner.parseQuestJson(questJson);
      final ch1 = quest.chapters.first;
      expect(ch1.index, 1);
      expect(ch1.learnerRole, 'young_messenger');
      expect(ch1.objectiveEn.toLowerCase(), contains('queen mother'));
      expect(ch1.objectiveEn.toLowerCase(), contains('honorific'));
      expect(ch1.interactionModes, contains('tone_lens'));
    });

    test('replay resets chapter progress, keeps vocabulary', () {
      var progress = PersonaQuestProgress.initial('yaa_asantewaa_golden_stool');
      progress = progress
          .completeChapter(1)
          .completeChapter(2)
          .recordVocabulary(['lexeme-honorific-slot']);
      final replayed = progress.startReplay();
      expect(replayed.currentChapterIndex, 1);
      expect(replayed.completedChapterIndices, isEmpty);
      expect(replayed.earnedVocabularyIds, contains('lexeme-honorific-slot'));
    });

    test('loadYaaAsantewaaQuest reads authored file', () async {
      final quest = await PersonaQuestRunner.loadYaaAsantewaaQuest();
      expect(quest.questId, 'yaa_asantewaa_golden_stool');
      expect(quest.twiSurfacePolicy, 'native_signoff_required');
      expect(quest.historianReviewGate, 'EXT-15');
    });
  });
}
