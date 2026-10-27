import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/chapter3.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

Future<void> _pumpChapter3(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 1600),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapScroll(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 400);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersonaQuestChapter demand;
  late PersonaQuestChapter council;

  setUp(() async {
    final quest = await PersonaQuestRunner.loadYaaAsantewaaQuest();
    demand = quest.chapters[1];
    council = quest.chapters[2];
  });

  testWidgets('subtitle toggle and checkpoint replay on failure', (tester) async {
    await _pumpChapter3(
      tester,
      YaaQuestChapter3Scene(
        demandChapter: demand,
        councilChapter: council,
        learnerCefr: 'B1',
      ),
    );

    expect(find.text(QuestChapter3Copy.subtitlesToggleLabel), findsOneWidget);
    await _tapScroll(tester, find.text('Continue'));
    await _tapScroll(tester, find.text('Start comprehension'));

    await _tapScroll(
      tester,
      find.text('A trade coin').first,
    );
    expect(find.text(QuestChapter3Copy.checkpointReplay), findsOneWidget);
  });
}
