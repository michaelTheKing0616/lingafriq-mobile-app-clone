import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/debrief.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

Future<void> _pumpDebrief(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 2000),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersonaQuestChapter ch4;
  late QuestPrimarySourceCard source;

  setUp(() async {
    final quest = await PersonaQuestRunner.loadYaaAsantewaaQuest();
    ch4 = quest.chapters[3];
    source = await loadYaaQuestPrimarySource();
  });

  testWidgets('missing historian note shows error state', (tester) async {
    await _pumpDebrief(
      tester,
      YaaQuestDebriefScene(
        chapter: ch4,
        questId: 'yaa_asantewaa_golden_stool',
        vocabularyDeckId: 'deck.yaa_asantewaa_golden_stool',
        historianNoteApprovedForRelease: false,
      ),
    );
    expect(find.text(QuestDebriefCopy.missingNoteTitle), findsOneWidget);
  });

  testWidgets('full debrief flow with approved note', (tester) async {
    var completed = false;
    await _pumpDebrief(
      tester,
      YaaQuestDebriefScene(
        chapter: ch4,
        questId: 'yaa_asantewaa_golden_stool',
        vocabularyDeckId: 'deck.yaa_asantewaa_golden_stool',
        historianNoteApprovedForRelease: true,
        primarySource: source,
        onQuestComplete: () => completed = true,
      ),
    );

    await tester.tap(find.text(QuestDebriefCopy.continueLabel));
    await tester.pumpAndSettle();

    for (final q in defaultYaaAftermathQuiz()) {
      final correct = q.options.firstWhere((o) => o.id == q.correctOptionId);
      await tester.tap(find.text(correct.labelEn));
      await tester.pumpAndSettle();
    }

    expect(find.text(QuestDebriefCopy.primarySourceTitle), findsOneWidget);
    await tester.tap(find.text(QuestDebriefCopy.continueLabel));
    await tester.pumpAndSettle();

    expect(find.text(QuestDebriefCopy.vocabularyAdded), findsOneWidget);
    await tester.tap(find.text(QuestDebriefCopy.finishQuest));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
