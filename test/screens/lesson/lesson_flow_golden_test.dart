import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../compliance/golden_kit.dart';

const _date = '2024-01-01T00:00:00';

final _sections = [
  for (var i = 1; i <= 3; i++)
    SectionLessonModel(
      id: i,
      title: 'Greetings $i',
      score: 10,
      types: 'Tutorial',
      dateTime: _date,
      completed: false,
      completed_by: null,
      otherData: {'text': 'Ẹ káàárọ̀ means good morning in Yorùbá.'},
    ),
];

Widget _screen() => LessonFlowScreen(
  lessonId: 77,
  sectionLessons: _sections,
  lessonTitle: 'Greetings',
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await loadComplianceFonts(
      'test/screens/lesson/lesson_flow_golden_test.dart',
    );
    // Tutorial audio uses audioplayers, whose per-player event channels have
    // random ids; answer every audioplayers call as a silent no-op.
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

  for (final v in goldenVariants) {
    testWidgets('lesson flow ${v.name}: no overflow, localised, golden', (
      t,
    ) async {
      await pumpVariant(t, v, _screen());
      expectNoLayoutErrors(t);
      final close = find.byKey(const Key('lesson-close'));
      expect(close, findsOneWidget);
      expect(t.getSize(close).width, greaterThanOrEqualTo(48));
      final isAr = v.locale.languageCode == 'ar';
      expect(
        find.byTooltip(isAr ? 'الخروج من الدرس' : 'Exit lesson'),
        findsOneWidget,
      );
      expect(find.text(isAr ? 'متابعة' : 'Continue'), findsOneWidget);
      expect(find.text(isAr ? '0 نقطة' : '0 Points'), findsOneWidget);
      if (isAr) {
        // ✕ sits at the visual start (right edge) in RTL.
        expect(t.getCenter(close).dx, greaterThan(v.size.width / 2));
      }
      await expectLater(
        find.byType(LessonFlowScreen),
        matchesGoldenFile('goldens/lesson_flow_${v.name}.png'),
      );
      await t.tap(close);
      await t.pumpAndSettle();
      expectNoLayoutErrors(t);
      // No user signed in: nothing may count as done (null == null bug).
      expect(
        find.text(isAr ? 'تبقّت 3 أقسام' : '3 sections left'),
        findsOneWidget,
      );
      // Both choices stay fully on-screen at every size and text scale.
      for (final k in ['lesson-keep-learning', 'lesson-end-session']) {
        final r = t.getRect(find.byKey(Key(k)));
        expect(r.bottom, lessThanOrEqualTo(v.size.height));
        expect(r.height, greaterThanOrEqualTo(48 - 1e-6)); // float layout
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/lesson_flow_quit_${v.name}.png'),
      );
    });
  }

  testWidgets('French quit sheet copy is genuine French', (t) async {
    await pumpVariant(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _screen(),
    );
    await t.tap(find.byKey(const Key('lesson-close')));
    await t.pumpAndSettle();
    expect(find.text('Quitter cette leçon ?'), findsOneWidget);
    expect(find.text('Continuer à apprendre'), findsOneWidget);
    expect(find.text('Arrêter la leçon'), findsOneWidget);
    expect(find.text('Encore 3 sections'), findsOneWidget);
  });

  testWidgets('system back asks first; End lesson leaves', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
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
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => _screen()));
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Leave this lesson?'), findsOneWidget);
    expect(find.byType(LessonFlowScreen), findsOneWidget);
    await t.tap(find.byKey(const Key('lesson-end-session')));
    await t.pumpAndSettle();
    expect(find.byType(LessonFlowScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('quit steps fill one pill per finished section', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: LessonQuitSteps(done: 2, total: 5)),
    );
    final boxes = t
        .widgetList<Container>(
          find.descendant(
            of: find.byType(LessonQuitSteps),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(boxes.length, 5);
    expect(boxes.where((c) => c != null).length, 2);
    expect(boxes.take(2).every((c) => c != null), isTrue);
  });

  testWidgets('system 200% text applies even under a pinned 1.0 shell', (
    t,
  ) async {
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    late double inside;
    await t.pumpWidget(
      MaterialApp(
        builder: (ctx, child) => MediaQuery(
          // Mirrors lib/my_app.dart, which pins the scale app-wide.
          data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
        home: LessonSystemTextScale(
          child: Builder(
            builder: (ctx) {
              inside = MediaQuery.textScalerOf(ctx).scale(10) / 10;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(inside, 2);
    t.platformDispatcher.textScaleFactorTestValue = 3.5;
    await t.pump();
    expect(inside, LessonSystemTextScale.maxScale);
  });
}
