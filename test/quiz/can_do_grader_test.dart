import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/quiz/items/conversation_task_item.dart';
import 'package:lingafriq/services/quiz/can_do_grader.dart';

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

EvidenceTurn _turn({
  required String id,
  required String canDoId,
  required double? confidence,
  required bool? met,
  bool scorerAvailable = true,
  String text = 'turn',
}) {
  return EvidenceTurn(
    id: id,
    canDoId: canDoId,
    text: text,
    scorerAvailable: scorerAvailable,
    confidence: confidence,
    met: met,
  );
}

void main() {
  test('a met can-do and a not-met can-do keep their evidence turns', () {
    final grade = gradeConversation(
      canDoIds: const ['greet', 'bargain'],
      scorerAvailable: true,
      turns: [
        _turn(
          id: 't-greet',
          canDoId: 'greet',
          confidence: 0.8,
          met: true,
          text: 'Ẹ káàrọ̀',
        ),
        _turn(
          id: 't-bargain',
          canDoId: 'bargain',
          confidence: 0.9,
          met: false,
          text: 'Ẹ̀ló ni?',
        ),
      ],
    );

    expect(grade.phase, 'graded');
    expect(grade.stored, isTrue);
    final greet = grade.results.singleWhere(
      (result) => result.canDoId == 'greet',
    );
    final bargain = grade.results.singleWhere(
      (result) => result.canDoId == 'bargain',
    );
    expect(greet.status, 'met');
    expect(greet.evidenceTurnIds, ['t-greet']);
    expect(bargain.status, 'not-met');
    expect(bargain.evidenceTurnIds, ['t-bargain']);
    expect(grade.metCanDoIds, ['greet']);
  });

  test('a confident met turn is the evidence even beside a not-met turn', () {
    final grade = gradeConversation(
      canDoIds: const ['greet'],
      scorerAvailable: true,
      turns: [
        _turn(id: 'weak', canDoId: 'greet', confidence: 0.2, met: true),
        _turn(id: 'no', canDoId: 'greet', confidence: 0.95, met: false),
        _turn(id: 'yes', canDoId: 'greet', confidence: 0.8, met: true),
      ],
    );

    expect(grade.results.single.status, 'met');
    expect(grade.results.single.evidenceTurnIds, ['yes']);
    expect(grade.metCanDoIds, ['greet']);
  });

  test('a can-do with no turns is unsure and is not met', () {
    final grade = gradeConversation(
      canDoIds: const ['greet'],
      turns: const [],
      scorerAvailable: true,
    );

    expect(grade.phase, 'unsure');
    expect(grade.stored, isTrue);
    expect(grade.results.single.status, 'unsure');
    expect(grade.results.single.evidenceTurnIds, isEmpty);
    expect(grade.metCanDoIds, isEmpty);
  });

  test('confidence at 0.6 is enough to mark met or not-met', () {
    final grade = gradeConversation(
      canDoIds: const ['greet', 'bargain'],
      scorerAvailable: true,
      turns: [
        _turn(id: 't-yes', canDoId: 'greet', confidence: 0.6, met: true),
        _turn(id: 't-no', canDoId: 'bargain', confidence: 0.6, met: false),
      ],
    );

    expect(grade.phase, 'graded');
    expect(grade.results.map((result) => result.status), ['met', 'not-met']);
    expect(grade.results.first.evidenceTurnIds, ['t-yes']);
    expect(grade.results.last.evidenceTurnIds, ['t-no']);
    expect(grade.metCanDoIds, ['greet']);
  });

  test('a missing confidence or met flag is unsure and is not met', () {
    final grade = gradeConversation(
      canDoIds: const ['no-confidence', 'no-flag'],
      scorerAvailable: true,
      turns: [
        _turn(id: 't1', canDoId: 'no-confidence', confidence: null, met: true),
        _turn(id: 't2', canDoId: 'no-flag', confidence: 0.9, met: null),
      ],
    );

    expect(grade.phase, 'unsure');
    expect(grade.results.map((result) => result.status), ['unsure', 'unsure']);
    expect(grade.metCanDoIds, isEmpty);
  });

  test('confidence below 0.6 is unsure and is not met', () {
    final grade = gradeConversation(
      canDoIds: const ['greet'],
      scorerAvailable: true,
      turns: [_turn(id: 't-low', canDoId: 'greet', confidence: 0.4, met: true)],
    );

    expect(grade.phase, 'unsure');
    expect(grade.results.single.status, 'unsure');
    expect(grade.results.single.evidenceTurnIds, isEmpty);
    expect(grade.metCanDoIds, isEmpty);
  });

  test('a turn the scorer did not return is not evidence', () {
    final grade = gradeConversation(
      canDoIds: const ['greet'],
      scorerAvailable: true,
      turns: [
        _turn(
          id: 't-missing',
          canDoId: 'greet',
          confidence: 0.9,
          met: true,
          scorerAvailable: false,
        ),
      ],
    );

    expect(grade.results.single.status, 'unsure');
    expect(grade.results.single.evidenceTurnIds, isEmpty);
    expect(grade.metCanDoIds, isEmpty);
  });

  test('an unavailable scorer stores nothing and marks nothing met', () {
    final grade = gradeConversation(
      canDoIds: const ['greet', 'bargain'],
      scorerAvailable: false,
      turns: [
        _turn(id: 't-greet', canDoId: 'greet', confidence: 0.99, met: true),
      ],
    );

    expect(grade.phase, 'unavailable');
    expect(grade.stored, isFalse);
    expect(grade.results, isEmpty);
    expect(grade.metCanDoIds, isEmpty);
  });

  testWidgets(
    'finish shows a met can-do, the unsure copy, and the evidence turn',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ConversationTaskItem(
            prompt: 'Greet the elder',
            canDoIds: const ['greet', 'bargain'],
            scorerAvailable: true,
            turns: [
              _turn(
                id: 't-greet',
                canDoId: 'greet',
                confidence: 0.8,
                met: true,
                text: 'Ẹ káàrọ̀',
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const ValueKey('phase-task')), findsOneWidget);
      expect(find.bySemanticsLabel('item.conv'), findsOneWidget);
      expect(find.bySemanticsLabel('item.candos'), findsOneWidget);

      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(find.byKey(const ValueKey('phase-graded')), findsOneWidget);
      expect(find.text('met'), findsOneWidget);
      expect(find.text(ConversationCopy.unsure), findsOneWidget);
      expect(find.text('t-greet'), findsOneWidget);
      expect(find.text('not-met'), findsNothing);
    },
  );

  testWidgets(
    'finish with no scorer shows unavailable and stores no met status',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ConversationTaskItem(
            prompt: 'Greet the elder',
            canDoIds: const ['greet'],
            scorerAvailable: false,
            turns: [
              _turn(
                id: 't-greet',
                canDoId: 'greet',
                confidence: 1,
                met: true,
                text: 'Ẹ káàrọ̀',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(find.byKey(const ValueKey('phase-unavailable')), findsOneWidget);
      expect(find.text(ConversationCopy.unavailable), findsOneWidget);
      expect(find.text('met'), findsNothing);
    },
  );

  testWidgets('tapping the prompt moves the task in progress before finish', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ConversationTaskItem(
          prompt: 'Greet the elder',
          canDoIds: ['greet'],
          scorerAvailable: true,
          turns: [],
        ),
      ),
    );

    await tester.tap(find.text('Greet the elder'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-in-progress')), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pump();
    expect(find.byKey(const ValueKey('phase-unsure')), findsOneWidget);
    expect(find.text(ConversationCopy.unsure), findsOneWidget);
    expect(find.text('met'), findsNothing);
  });
}
