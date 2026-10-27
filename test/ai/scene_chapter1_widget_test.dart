import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/scene_chapter1.dart';
import 'package:lingafriq/services/tutorials/speaking_try_client.dart';

Future<void> _pumpScene(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 1400),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 400);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersonaQuestChapter chapter;

  setUp(() async {
    final quest = await PersonaQuestRunner.loadYaaAsantewaaQuest();
    chapter = quest.chapters.first;
  });

  testWidgets('respect kneel updates feedback copy', (tester) async {
    await _pumpScene(
      tester,
      YaaQuestChapter1Scene(chapter: chapter),
    );

    await _tapWhenVisible(tester, find.text(QuestChapter1Copy.respectKneelLabel));
    await _tapWhenVisible(tester, find.text(QuestChapter1Copy.confirmRespect));
    await tester.pumpAndSettle();

    expect(find.textContaining('You kneel with respect'), findsOneWidget);
  });

  test('gateway unsure maps to tone lens unsure phase', () {
    final outcome = parseSpeakingTryScoreBody({
      'syllables': [
        {
          'label': 'a',
          'expected_tone_label': 'H',
          'correct': null,
          'reason': 'unsure',
          'native_contour': [0, 1],
          'learner_contour': [0, 0.5],
        },
      ],
    });
    final result = speakingTryResultFromLens(outcome);
    expect(result.phase, SpeakingTryPhase.unsure);
  });
}
