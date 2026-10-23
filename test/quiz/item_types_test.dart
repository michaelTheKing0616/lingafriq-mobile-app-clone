import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/quiz/items/listen_choose_item.dart';
import 'package:lingafriq/screens/quiz/items/picture_match_item.dart';
import 'package:lingafriq/screens/quiz/items/tone_id_item.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';

class _FakeAudio implements ItemAudio {
  _FakeAudio({this.fail = false});

  final bool fail;
  final refs = <String>[];
  Completer<void>? gate;

  @override
  Future<void> play(String ref) {
    refs.add(ref);
    if (fail) throw StateError('audio failed');
    gate = Completer<void>();
    return gate!.future;
  }

  @override
  Future<void> dispose() async {}
}

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  test('listen grading follows the answer spec', () {
    const spec = AnswerSpec(
      correct: 'àárọ̀',
      variants: ['aaro'],
      diacriticInsensitive: true,
    );
    expect(gradeAnswer(response: 'aaro', spec: spec).correct, isTrue);
    expect(gradeAnswer(response: 'ọkọ̀', spec: spec).correct, isFalse);
    const exact = AnswerSpec(correct: 'àárọ̀', variants: [], diacriticInsensitive: false);
    expect(gradeAnswer(response: 'aaro', spec: exact).correct, isFalse);
    expect(gradeAnswer(response: 'àárọ̀', spec: exact).correct, isTrue);
  });

  test('tone grading uses the lexeme tone pattern', () {
    expect(
      gradeTone(chosen: const ['M', 'L'], tonePattern: const ['M', 'L']).correct,
      isTrue,
    );
    expect(
      gradeTone(chosen: const ['H', 'L'], tonePattern: const ['M', 'L']).correct,
      isFalse,
    );
    expect(
      gradeTone(chosen: const ['M', 'L'], tonePattern: const []).correct,
      isFalse,
    );
  });

  testWidgets('listen-and-choose plays the item-bank ref and grades the choice', (tester) async {
    final audio = _FakeAudio();
    await tester.pumpWidget(_host(ListenChooseItem(
      audioRef: 'audio/yo/aaro.ogg',
      options: const ['àárọ̀', 'ọkọ̀'],
      spec: const AnswerSpec(correct: 'àárọ̀', variants: const ['aaro'], diacriticInsensitive: true),
      audio: audio,
    )));
    expect(find.byKey(const ValueKey('phase-idle')), findsOneWidget);

    await tester.tap(find.text(ItemCopy.listen));
    await tester.pump();
    expect(audio.refs, ['audio/yo/aaro.ogg']);
    expect(find.byKey(const ValueKey('phase-playing')), findsOneWidget);

    audio.gate!.complete();
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-idle')), findsOneWidget);

    await tester.tap(find.text('àárọ̀'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-answered-correct')), findsOneWidget);
    expect(find.text(ItemCopy.correct), findsOneWidget);
  });

  testWidgets('a failed clip shows the error state', (tester) async {
    await tester.pumpWidget(_host(ListenChooseItem(
      audioRef: 'audio/yo/aaro.ogg',
      options: const ['àárọ̀'],
      spec: const AnswerSpec(correct: 'àárọ̀', variants: [], diacriticInsensitive: false),
      audio: _FakeAudio(fail: true),
    )));
    await tester.tap(find.text(ItemCopy.listen));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-error')), findsOneWidget);
    expect(find.text(ItemCopy.audioError), findsOneWidget);
  });

  testWidgets('tone identification grades the lexeme pattern', (tester) async {
    await tester.pumpWidget(_host(ToneIdItem(
      prompt: 'ọkọ̀',
      tonePattern: const ['M', 'L'],
      choices: const [
        ToneChoice(label: 'M L', pattern: ['M', 'L']),
        ToneChoice(label: 'H L', pattern: ['H', 'L']),
      ],
    )));
    expect(find.bySemanticsLabel('item.tone'), findsOneWidget);
    await tester.tap(find.text('H L'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-answered-wrong')), findsOneWidget);
    expect(find.text(ItemCopy.wrong), findsOneWidget);
  });

  testWidgets('picture matching exposes alt text and grades the answer spec', (tester) async {
    await tester.pumpWidget(_host(PictureMatchItem(
      spec: const AnswerSpec(correct: 'plantain', variants: [], diacriticInsensitive: false),
      choices: const [
        PictureChoice(id: 'plantain', imageRef: 'images/plantain.png', altText: 'A ripe plantain'),
        PictureChoice(id: 'mortar', imageRef: 'images/mortar.png', altText: 'A wooden mortar'),
      ],
    )));
    expect(find.bySemanticsLabel('A ripe plantain'), findsOneWidget);
    expect(find.bySemanticsLabel('A wooden mortar'), findsOneWidget);
    await tester.tap(find.text('A ripe plantain'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-answered-correct')), findsOneWidget);
  });

  test('a picture without alt text is rejected', () {
    expect(
      () => PictureMatchItem(
        spec: const AnswerSpec(correct: 'plantain', variants: [], diacriticInsensitive: false),
        choices: const [
          PictureChoice(id: 'plantain', imageRef: 'images/plantain.png', altText: ' '),
        ],
      ),
      throwsArgumentError,
    );
  });
}
