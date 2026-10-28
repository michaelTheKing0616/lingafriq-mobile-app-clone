import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/village/flashcard_focus_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final defaultOnError = FlutterError.onError;
  setUp(() {
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        return;
      }
      defaultOnError?.call(details);
    };
  });
  tearDown(() => FlutterError.onError = defaultOnError);

  Future<void> pumpStrip(
    WidgetTester tester, {
    required FlashcardGroupStudyRoster roster,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(tester.view.resetPhysicalSize);
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: FlashcardCoLearnerStrip(roster: roster),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no hard-coded co-learner names in solo mode', (tester) async {
    await pumpStrip(tester, roster: const FlashcardGroupStudyRoster.solo());
    expect(find.text('Amina'), findsNothing);
    expect(find.text('Kwame'), findsNothing);
    expect(find.text(kFlashcardCoLearnersEmpty), findsOneWidget);
  });

  test('flashcardRosterFromApi never fabricates peers on failure', () {
    expect(
      flashcardRosterFromApi({'ok': false}),
      const FlashcardGroupStudyRoster.solo(),
    );
    expect(
      flashcardRosterFromApi({
        'ok': true,
        'roster': {
          'mode': 'matched_peers',
          'peers': [
            {'display_name': '  ', 'is_practice_bot': false},
          ],
        },
      }),
      const FlashcardGroupStudyRoster.solo(),
    );
  });

  test('flashcardRosterFromApi parses matched peers from server', () {
    final roster = flashcardRosterFromApi({
      'ok': true,
      'roster': {
        'mode': 'matched_peers',
        'peers': [
          {'display_name': 'Circle peer', 'is_practice_bot': false, 'has_mic': true},
        ],
      },
    });
    expect(roster.mode, FlashcardStudyMode.matchedPeers);
    expect(roster.peers.single.displayName, 'Circle peer');
    expect(roster.peers.single.hasMic, isTrue);
  });

  testWidgets('practice_bot_label visible for bot roster', (tester) async {
    await pumpStrip(
      tester,
      roster: const FlashcardGroupStudyRoster.practiceBot(),
    );
    expect(find.text(FlashcardFocusScreen.practiceBotLabel), findsOneWidget);
  });

  testWidgets('practice_bot_label_golden matched peer shows display name',
      (tester) async {
    await pumpStrip(
      tester,
      roster: FlashcardGroupStudyRoster.matched([
        const FlashcardCoLearner.matched(displayName: 'Circle peer'),
      ]),
    );
    expect(find.text('Circle peer'), findsOneWidget);
    expect(find.text(FlashcardFocusScreen.practiceBotLabel), findsNothing);
  });
}
