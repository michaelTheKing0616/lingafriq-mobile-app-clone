import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/quiz/items/dictation_item.dart';
import 'package:lingafriq/screens/quiz/items/sentence_build_item.dart';
import 'package:lingafriq/services/quiz/diacritic_grader.dart';

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  test('a decomposed vowel matches its NFC form', () {
    final grade = gradeDictation(response: 'a\u0301', correct: 'á', asciiVariants: const []);
    expect(grade.full, isTrue);
    expect(grade.passed, isTrue);
    expect(grade.phase, 'correct');
  });

  test('missing tone marks are a diacritic error and are not fully correct', () {
    final grade = gradeDictation(response: 'aaro', correct: 'àárọ̀', asciiVariants: const []);
    expect(grade.full, isFalse);
    expect(grade.passed, isFalse);
    expect(grade.lettersMatch, isTrue);
    expect(grade.phase, 'diacritic-hint');
  });

  test('an accepted ASCII variant passes with a diacritic hint', () {
    final grade = gradeDictation(
      response: 'aaro',
      correct: 'àárọ̀',
      asciiVariants: const ['aaro'],
    );
    expect(grade.passed, isTrue);
    expect(grade.full, isFalse);
    expect(grade.phase, 'diacritic-hint');
  });

  test('sentence building accepts only the listed orderings', () {
    const accepted = [
      ['Mo', 'jẹ́', 'akẹ́kọ̀ọ́'],
      ['Akẹ́kọ̀ọ́', 'ni', 'mo'],
    ];
    expect(sentenceAccepted(const ['Mo', 'jẹ́', 'akẹ́kọ̀ọ́'], accepted), isTrue);
    expect(sentenceAccepted(const ['Mo', 'akẹ́kọ̀ọ́', 'jẹ́'], accepted), isFalse);
    expect(sentenceAccepted(const ['a\u0301'], const [['á']]), isTrue);
  });

  testWidgets('dictation shows the hint and the diacritic keys', (tester) async {
    await tester.pumpWidget(_host(const DictationItem(correct: 'àárọ̀', asciiVariants: ['aaro'])));
    expect(find.bySemanticsLabel(ItemBuildCopy.lowTone), findsWidgets);
    await tester.enterText(find.byType(TextField), 'aaro');
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-typing')), findsOneWidget);
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-diacritic-hint')), findsOneWidget);
    expect(find.text(ItemBuildCopy.variantHint), findsOneWidget);
  });

  testWidgets('sentence building fails an unlisted order', (tester) async {
    await tester.pumpWidget(_host(const SentenceBuildItem(
      tiles: ['Mo', 'jẹ́', 'akẹ́kọ̀ọ́'],
      accepted: [
        ['Mo', 'jẹ́', 'akẹ́kọ̀ọ́'],
      ],
    )));
    await tester.tap(find.text('jẹ́'));
    await tester.pump();
    await tester.tap(find.text('Mo'));
    await tester.pump();
    await tester.tap(find.text('akẹ́kọ̀ọ́'));
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-wrong')), findsOneWidget);
    expect(find.text(ItemBuildCopy.wrong), findsOneWidget);
  });
}
