import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/quiz/items/listen_choose_item.dart';
import 'package:lingafriq/screens/quiz/widgets/item_feedback_panel.dart';
import 'package:lingafriq/services/quiz/feedback_resolver.dart';

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

class _FakeItemAudio implements ItemAudio {
  String? lastPlayedRef;

  @override
  Future<void> play(String ref) async {
    lastPlayedRef = ref;
  }

  @override
  Future<void> dispose() async {}
}

FeedbackInput _input({
  required String itemId,
  required bool correct,
  String correctForm = 'àárọ̀',
  String? audioRef,
  String? rationale,
}) {
  return FeedbackInput(
    itemId: itemId,
    correct: correct,
    correctForm: correctForm,
    audioRef: audioRef,
    rationale: rationale,
  );
}

void main() {
  group('resolveFeedback', () {
    test('correct answer keeps form and audio, does not flag', () {
      final report = RationaleReport();
      final feedback = resolveFeedback(
        _input(
          itemId: 'item-1',
          correct: true,
          audioRef: 'audio/ref.mp3',
        ),
        report,
      );

      expect(feedback.phase, 'correct');
      expect(feedback.correctForm, 'àárọ̀');
      expect(feedback.audioRef, 'audio/ref.mp3');
      expect(feedback.flagged, isFalse);
      expect(report.contains('item-1'), isFalse);
    });

    test('wrong answer with rationale resolves wrong and keeps exact sentence', () {
      final report = RationaleReport();
      const sentence = 'Tone is high, not low.';
      final feedback = resolveFeedback(
        _input(
          itemId: 'item-2',
          correct: false,
          rationale: sentence,
        ),
        report,
      );

      expect(feedback.phase, 'wrong');
      expect(feedback.rationale, sentence);
      expect(feedback.flagged, isFalse);
      expect(report.contains('item-2'), isFalse);
    });

    test('wrong answer with null rationale flags item', () {
      final report = RationaleReport();
      final feedback = resolveFeedback(
        _input(itemId: 'item-3', correct: false, rationale: null),
        report,
      );

      expect(feedback.phase, 'no-rationale');
      expect(feedback.rationale, isNull);
      expect(feedback.flagged, isTrue);
      expect(report.contains('item-3'), isTrue);
    });

    test('wrong answer with blank rationale flags item', () {
      final report = RationaleReport();
      final feedback = resolveFeedback(
        _input(itemId: 'item-4', correct: false, rationale: '   '),
        report,
      );

      expect(feedback.phase, 'no-rationale');
      expect(feedback.rationale, isNull);
      expect(feedback.flagged, isTrue);
      expect(report.contains('item-4'), isTrue);
    });
  });

  group('ItemFeedbackPanel', () {
    testWidgets('correct phase shows form and replay calls audio', (tester) async {
      final fakeAudio = _FakeItemAudio();
      const ref = 'bank/yoruba/aaro.mp3';
      final feedback = resolveFeedback(
        _input(itemId: 'w-1', correct: true, audioRef: ref),
        RationaleReport(),
      );

      await tester.pumpWidget(_host(
        ItemFeedbackPanel(feedback: feedback, audio: fakeAudio),
      ));

      expect(find.byKey(const ValueKey('phase-correct')), findsOneWidget);
      expect(find.text('àárọ̀'), findsOneWidget);
      expect(find.text('Replay the correct form'), findsOneWidget);

      await tester.tap(find.text('Replay the correct form'));
      await tester.pump();
      expect(fakeAudio.lastPlayedRef, ref);
    });

    testWidgets('wrong phase shows Why and rationale', (tester) async {
      const sentence = 'Tone is high, not low.';
      final feedback = resolveFeedback(
        _input(itemId: 'w-2', correct: false, rationale: sentence),
        RationaleReport(),
      );

      await tester.pumpWidget(_host(ItemFeedbackPanel(feedback: feedback)));

      expect(find.byKey(const ValueKey('phase-wrong')), findsOneWidget);
      expect(find.text(FeedbackCopy.why), findsOneWidget);
      expect(find.text(sentence), findsOneWidget);
    });

    testWidgets('no-rationale phase hides Why; report flags item', (tester) async {
      final report = RationaleReport();
      final feedback = resolveFeedback(
        _input(itemId: 'w-3', correct: false, rationale: null),
        report,
      );

      await tester.pumpWidget(_host(ItemFeedbackPanel(feedback: feedback)));

      expect(find.byKey(const ValueKey('phase-no-rationale')), findsOneWidget);
      expect(find.text('àárọ̀'), findsOneWidget);
      expect(find.text(FeedbackCopy.why), findsNothing);
      expect(report.contains('w-3'), isTrue);
    });
  });
}
