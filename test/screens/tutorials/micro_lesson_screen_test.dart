import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/models/micro_lesson.dart';
import 'package:lingafriq/screens/tutorials/micro_lesson_screen.dart';
import 'package:lingafriq/services/tutorials/micro_lesson_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

MicroLesson _validLesson({String id = 'demo-1'}) {
  return MicroLesson(
    id: id,
    steps: const [
      MicroLessonStepContent(
        kind: MicroLessonStepKind.learn,
        body: 'Learn body',
        durationSeconds: 20,
        mediaKind: MicroLessonMediaKind.none,
      ),
      MicroLessonStepContent(
        kind: MicroLessonStepKind.see,
        body: 'See body',
        durationSeconds: 20,
        mediaUri: 'https://example.com/clip.mp4',
        mediaKind: MicroLessonMediaKind.video,
      ),
      MicroLessonStepContent(
        kind: MicroLessonStepKind.tryStep,
        body: 'Try body',
        durationSeconds: 25,
        mediaKind: MicroLessonMediaKind.none,
      ),
    ],
  );
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('micro-lesson content', () {
    test('step order must be learn, see, try', () {
      final bad = MicroLesson(
        id: 'x',
        steps: const [
          MicroLessonStepContent(
            kind: MicroLessonStepKind.see,
            body: 'a',
            durationSeconds: 20,
          ),
          MicroLessonStepContent(
            kind: MicroLessonStepKind.learn,
            body: 'b',
            durationSeconds: 20,
          ),
          MicroLessonStepContent(
            kind: MicroLessonStepKind.tryStep,
            body: 'c',
            durationSeconds: 20,
          ),
        ],
      );
      expect(
        () => assertMicroLessonContentValid(bad),
        throwsA(isA<MicroLessonContentException>()),
      );
      expect(microLessonStepOrderIsValid(bad.steps), isFalse);
      expect(microLessonStepOrderIsValid(_validLesson().steps), isTrue);
    });

    test('runtime validator accepts 60–90s and rejects out of range', () {
      expect(microLessonRuntimeInRange(const Duration(seconds: 59)), isFalse);
      expect(microLessonRuntimeInRange(const Duration(seconds: 60)), isTrue);
      expect(microLessonRuntimeInRange(const Duration(seconds: 90)), isTrue);
      expect(microLessonRuntimeInRange(const Duration(seconds: 91)), isFalse);

      final short = MicroLesson(
        id: 'short',
        steps: const [
          MicroLessonStepContent(
            kind: MicroLessonStepKind.learn,
            body: 'a',
            durationSeconds: 10,
          ),
          MicroLessonStepContent(
            kind: MicroLessonStepKind.see,
            body: 'b',
            durationSeconds: 10,
          ),
          MicroLessonStepContent(
            kind: MicroLessonStepKind.tryStep,
            body: 'c',
            durationSeconds: 10,
          ),
        ],
      );
      expect(
        () => MicroLessonService().validateContent(short),
        throwsA(
          predicate<MicroLessonContentException>(
            (e) => e.code == MicroLessonContentCodes.runtimeOutOfRange,
          ),
        ),
      );
      MicroLessonService().validateContent(_validLesson());
    });
  });

  group('MicroLessonScreen', () {
    late Map<String, String> prefsStore;

    setUp(() {
      prefsStore = <String, String>{};
      SharedPreferences.setMockInitialValues(prefsStore);
    });

    testWidgets('plays learn, see, try in order', (tester) async {
      final service = MicroLessonService();
      await tester.pumpWidget(
        _wrap(
          MicroLessonScreen(
            lesson: _validLesson(),
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn it'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('See it'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Try it'), findsOneWidget);
    });

    testWidgets('resumes at saved step after background', (tester) async {
      final lesson = _validLesson(id: 'resume-lesson');
      final service = MicroLessonService();
      await service.saveSession(
        const MicroLessonSessionState(
          lessonId: 'resume-lesson',
          stepIndex: 1,
          paused: true,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          MicroLessonScreen(lesson: lesson, service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('See it'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('See it'), findsOneWidget);
    });

    testWidgets('shows typed media error and retry', (tester) async {
      var attempts = 0;
      final service = MicroLessonService(
        mediaLoader: (step) async {
          if (step.kind != MicroLessonStepKind.see) return;
          attempts++;
          if (attempts == 1) {
            throw MicroLessonMediaException(MicroLessonMediaCodes.missing);
          }
        },
      );

      await tester.pumpWidget(
        _wrap(
          MicroLessonScreen(
            lesson: _validLesson(),
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MEDIA_MISSING'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MEDIA_MISSING'), findsNothing);
    });
  });
}
