import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/tutorials/perception_check.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PerceptionCheckSessionGuard.resetForTest);

  group('perception check timer math', () {
    test('duration is 30 seconds', () {
      expect(perceptionCheckDurationSeconds, 30);
      expect(perceptionCheckDuration.inSeconds, 30);
    });

    test('seconds remaining counts down to zero', () {
      expect(
        perceptionCheckSecondsRemaining(elapsed: Duration.zero),
        30,
      );
      expect(
        perceptionCheckSecondsRemaining(elapsed: const Duration(seconds: 29)),
        1,
      );
      expect(
        perceptionCheckSecondsRemaining(elapsed: const Duration(seconds: 30)),
        0,
      );
      expect(perceptionCheckTimerComplete(const Duration(seconds: 30)), isTrue);
    });
  });

  group('session guard', () {
    test('abandon clears in-flight without retaining partial result', () {
      PerceptionCheckSessionGuard.markStarted('t1');
      expect(PerceptionCheckSessionGuard.wasInFlight('t1'), isTrue);
      PerceptionCheckSessionGuard.markAbandoned('t1');
      expect(PerceptionCheckSessionGuard.wasInFlight('t1'), isFalse);
    });
  });

  group('TutorialPerceptionCheck widget', () {
    testWidgets('runs 30s then shows learner-only result picker', (tester) async {
      PerceptionCheckLearnerResult? captured;
      await tester.pumpWidget(
        _wrap(
          TutorialPerceptionCheck(
            checkId: 'yo-tones-1',
            prompt: 'Listen for tone on ọkọ́ vs ọkọ̀',
            nonAudioDescription:
                'Focus on pitch movement on the first syllable.',
            responseOptions: const ['High tone', 'Low tone', 'Not sure'],
            checkDuration: const Duration(seconds: 2),
            onFinished: (r) => captured = r,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2'), findsOneWidget);

      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('What did you notice?'), findsOneWidget);
      expect(find.textContaining('benchmark'), findsNothing);

      await tester.tap(find.text('High tone'));
      await tester.pump();

      expect(captured?.selectedResponse, 'High tone');
      expect(captured?.listeningSeconds, 2);
      expect(find.text('Your result'), findsOneWidget);
      expect(find.textContaining('no class average'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('leaving mid-check abandons session; return restarts timer',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TutorialPerceptionCheck(
            checkId: 'restart-1',
            prompt: 'Listen',
            nonAudioDescription: 'Read the prompt.',
            responseOptions: const ['A'],
            checkDuration: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(PerceptionCheckSessionGuard.wasInFlight('restart-1'), isFalse);

      await tester.pumpWidget(
        _wrap(
          TutorialPerceptionCheck(
            checkId: 'restart-1',
            prompt: 'Listen',
            nonAudioDescription: 'Read the prompt.',
            responseOptions: const ['A'],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Your result'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
