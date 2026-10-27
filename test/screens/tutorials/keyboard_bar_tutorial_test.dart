import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/tutorials/keyboard_bar_tutorial.dart';
import 'package:lingafriq/widgets/diacritic_keyboard_bar.dart';

import '../../helpers/test_utils.dart';

DiacriticKeyboardLayouts _layoutsFromRepo() {
  final path = File('assets/data/keyboard/layouts.json');
  return DiacriticKeyboardLayouts.fromJsonString(path.readAsStringSync());
}

void main() {
  late DiacriticKeyboardLayouts layouts;

  setUp(() {
    layouts = _layoutsFromRepo();
  });

  group('keyboardBarCharacterMatches', () {
    test('matches NFC target letter', () {
      expect(keyboardBarCharacterMatches('ẹ', 'ẹ'), isTrue);
      expect(keyboardBarCharacterMatches('e', 'ẹ'), isFalse);
    });
  });

  group('KeyboardBarTutorialScreen', () {
    Future<void> pumpTutorial(
      WidgetTester tester, {
      required String languageId,
      bool isOffline = false,
    }) async {
      await pumpWidgetWithScreenUtil(
        tester,
        KeyboardBarTutorialScreen(
          languageId: languageId,
          layouts: layouts,
          isOffline: isOffline,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('intro then typing shows language diacritics on bar', (tester) async {
      await pumpTutorial(tester, languageId: 'yo');
      expect(find.byKey(const ValueKey('kbd-tutorial-intro')), findsOneWidget);
      await tester.tap(find.text('Start typing'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('diacritic-bar-visible')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('diacritic-bar-visible')),
          matching: find.text('ẹ'),
        ),
        findsOneWidget,
      );
      expect(find.text(kTutorialKbdTry), findsOneWidget);
    });

    testWidgets('wrong answer explains mismatch and retry works', (tester) async {
      await pumpTutorial(tester, languageId: 'yo');
      await tester.tap(find.text('Start typing'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'e');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
      expect(
        find.textContaining('That is not ẹ'),
        findsWidgets,
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('diacritic-bar-visible')),
          matching: find.text('ẹ'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('kbd-tutorial-correct')), findsOneWidget);
    });

    testWidgets('keyboard bar inserts letter for try step', (tester) async {
      await pumpTutorial(tester, languageId: 'ig');
      await tester.tap(find.text('Start typing'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('diacritic-bar-visible')),
          matching: find.text('ị'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('kbd-tutorial-correct')), findsOneWidget);
    });

    testWidgets('offline state', (tester) async {
      await pumpTutorial(tester, languageId: 'yo', isOffline: true);
      expect(find.byKey(const ValueKey('kbd-tutorial-offline')), findsOneWidget);
    });

    testWidgets('unsupported language shows error', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        KeyboardBarTutorialScreen(
          languageId: 'sw',
          layouts: layouts,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('kbd-tutorial-error')), findsOneWidget);
    });

    testWidgets('loading state visible before layouts resolve', (tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        KeyboardBarTutorialScreen(
          languageId: 'yo',
          layoutsLoader: () async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return layouts;
          },
        ),
      );
      expect(find.byKey(const ValueKey('kbd-tutorial-loading')), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('kbd-tutorial-intro')), findsOneWidget);
    });
  });
}
