import 'package:lingafriq/widgets/points_and_profile_image_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/screens/lesson/lesson_provider.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../compliance/golden_kit.dart';

enum _Mode { quiz, error, loading }

/// Real notifier except for loading: fixtures in, no network, no sound
/// plugin (its method channel never resolves under flutter_test).
class _FixtureNotifier extends LessonFlowNotifier {
  _FixtureNotifier(Ref ref, this.mode)
    : super(ref, 9, ComboTracker(), ref.read(soundEffectsProvider));

  final _Mode mode;
  int initCalls = 0;

  @override
  Future<void> initialize(List<SectionLessonModel> sectionLessons) async {
    initCalls++;
    switch (mode) {
      case _Mode.loading:
        state = state.copyWith(isLoading: true);
      case _Mode.error:
        state = state.copyWith(isLoading: false, error: 'offline');
      case _Mode.quiz:
        state = state.copyWith(sections: [_quiz], isLoading: false);
    }
  }

  @override
  Future<bool> checkQuizAnswer(int s, int q, String a) async => a == 'Ẹ káàsán';
}

final _quiz = LessonContent(
  id: 1,
  sectionId: 1,
  title: 'Greetings',
  type: LessonSectionType.instantQuiz,
  score: 10,
  isCompleted: false,
  questions: [
    QuizQuestion(
      id: 1,
      question: 'How do you say “good afternoon” in Yorùbá?',
      options: [
        QuizOption(id: 1, text: 'Ẹ káàárọ̀', isCorrect: false),
        QuizOption(id: 2, text: 'Ẹ káàsán', isCorrect: true),
        QuizOption(id: 3, text: 'Ẹ kúùrọ̀lẹ́', isCorrect: false),
      ],
    ),
  ],
);

_FixtureNotifier? _last;

Widget _app(_Mode mode, Locale locale) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, __) => ProviderScope(
    overrides: [
      lessonFlowProvider(
        9,
      ).overrideWith((ref) => _last = _FixtureNotifier(ref, mode)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: complianceTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LessonFlowScreen(
        lessonId: 9,
        sectionLessons: [],
        lessonTitle: 'Greetings',
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester t,
  _Mode mode, {
  Locale locale = const Locale('en'),
}) async {
  t.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(mode, locale));
  await t.pumpAndSettle();
  // Decode the persona avatar so every golden shows the same header.
  final ctx = t.element(find.byType(LessonFlowScreen));
  await t.runAsync(
    () => precacheImage(AssetImage(kAvatarsList.values.first), ctx),
  );
  await t.pumpAndSettle();
  // flutter_animate starts card entrances from a zero-length timer; let it
  // fire, then settle the fade so goldens show the finished frame.
  await t.pump(const Duration(milliseconds: 1));
  await t.pumpAndSettle();
}

Future<void> _golden(WidgetTester t, String name) => expectLater(
  find.byType(LessonFlowScreen),
  matchesGoldenFile('goldens/lesson_state_$name.png'),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await loadComplianceFonts(
      'test/screens/lesson/lesson_flow_states_golden_test.dart',
    );
    // Sound effects use audioplayers; answer its channels as silent no-ops.
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('xyz.luan/audioplayers')) {
        return const StandardMethodCodec().encodeSuccessEnvelope(null);
      }
      return handler?.call(message);
    };
  });
  tearDownAll(
    () =>
        TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .allMessagesHandler =
            null,
  );

  testWidgets('exercise step: question, options, Check', (t) async {
    await _pump(t, _Mode.quiz);
    expectNoLayoutErrors(t);
    expect(find.textContaining('good afternoon'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    await _golden(t, 'exercise');
  });

  for (final c in [
    ('correct', 'Ẹ káàsán', 'Nice work!'),
    ('incorrect', 'Ẹ káàárọ̀', 'Not quite'),
  ]) {
    testWidgets('feedback ${c.$1}: verdict panel with the next action', (
      t,
    ) async {
      await _pump(t, _Mode.quiz);
      await t.tap(find.text(c.$2));
      await t.pump();
      await t.tap(find.text('Check'));
      await t.pumpAndSettle();
      expectNoLayoutErrors(t);
      expect(find.byKey(Key('lesson-feedback-${c.$1}')), findsOneWidget);
      expect(find.text(c.$3), findsOneWidget);
      if (c.$1 == 'incorrect') {
        expect(find.text('Correct answer: Ẹ káàsán'), findsOneWidget);
      }
      // No hearts or paywall: a wrong answer never locks the learner out.
      expect(find.text('Finish'), findsOneWidget);
      await _golden(t, 'feedback_${c.$1}');
    });
  }

  testWidgets('French exercise step is genuine French', (t) async {
    await _pump(t, _Mode.quiz, locale: const Locale('fr'));
    expectNoLayoutErrors(t);
    expect(find.text('Vérifier'), findsOneWidget);
    await _golden(t, 'exercise_fr');
  });

  testWidgets('Arabic UI keeps Latin answers left-to-right', (t) async {
    await _pump(t, _Mode.quiz, locale: const Locale('ar'));
    final q = t.widget<Text>(find.textContaining('good afternoon').first);
    expect(q.textDirection, TextDirection.ltr);
    await _golden(t, 'exercise_ar');
  });

  testWidgets('exercise fits 320x568 at 200% in Arabic', (t) async {
    await pumpVariant(
      t,
      goldenVariants.last,
      const LessonFlowScreen(
        lessonId: 9,
        sectionLessons: [],
        lessonTitle: 'Greetings',
      ),
      overrides: [
        lessonFlowProvider(
          9,
        ).overrideWith((ref) => _FixtureNotifier(ref, _Mode.quiz)),
      ],
    );
    expectNoLayoutErrors(t);
    await _golden(t, 'exercise_${goldenVariants.last.name}');
  });

  testWidgets('error header: ✕ and system back both leave the lesson', (
    t,
  ) async {
    for (final viaBack in [false, true]) {
      final container = ProviderContainer(
        overrides: [
          lessonFlowProvider(
            9,
          ).overrideWith((ref) => _FixtureNotifier(ref, _Mode.error)),
        ],
      );
      final key = container.read(navigationProvider).navigatorKey;
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp(
              navigatorKey: key,
              home: const Scaffold(body: Text('home')),
            ),
          ),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const LessonFlowScreen(
            lessonId: 9,
            sectionLessons: [],
            lessonTitle: 'Greetings',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      final close = find.byKey(const Key('lesson-error-close'));
      expect(t.getSize(close).width, greaterThanOrEqualTo(48));
      if (viaBack) {
        await t.binding.handlePopRoute();
      } else {
        await t.tap(close);
      }
      await t.pumpAndSettle();
      expect(find.byType(LessonFlowScreen), findsNothing, reason: '$viaBack');
      expect(find.text('home'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      container.dispose();
    }
  });

  testWidgets('loading: localised preparing state', (t) async {
    await _pump(t, _Mode.loading);
    expectNoLayoutErrors(t);
    expect(find.byKey(const Key('lesson-skeleton')), findsOneWidget);
    expect(find.text('Preparing your lesson'), findsOneWidget);
    await _golden(t, 'loading');
  });

  testWidgets('error: warm copy and retry reloads', (t) async {
    await _pump(t, _Mode.error);
    expectNoLayoutErrors(t);
    final retry = find.text('Retry');
    expect(retry, findsOneWidget);
    await _golden(t, 'error');
    final before = _last!.initCalls;
    await t.tap(retry);
    await t.pumpAndSettle();
    expect(_last!.initCalls, before + 1);
  });

  testWidgets('header avatar sits on an opaque disc (not faded)', (t) async {
    await _pump(t, _Mode.quiz);
    final disc = t.widget<DecoratedBox>(
      find.byKey(const Key('header-avatar-disc')),
    );
    final color = (disc.decoration as BoxDecoration).color!;
    expect(color.a, 1.0);
    expect(color, kHeaderAvatarDisc);
  });
}
