import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_today.dart';
import 'package:lingafriq/screens/goals/daily_challenges_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> _sitemap = <String>[
  '/today',
  'daily plan',
  'daily challenges',
  'quests',
  'events and festivals',
  'streaks',
];

class _PlanSource implements TodayPlanSource {
  _PlanSource(this.plan);

  final TodayPlan? plan;
  int calls = 0;

  @override
  TodayPlan? load() {
    calls += 1;
    return plan;
  }
}

class _ThrowSource implements TodayPlanSource {
  _ThrowSource(this.kind);

  final TodayUnavailableKind kind;

  @override
  TodayPlan? load() => throw TodayUnavailable(kind);
}

class _Script implements TodayPlanSource {
  _Script(this.steps);

  final List<Object?> steps;
  int calls = 0;

  @override
  TodayPlan? load() {
    final int index = calls >= steps.length ? steps.length - 1 : calls;
    calls += 1;
    final Object? step = steps[index];
    if (step is TodayUnavailable) throw step;
    return step as TodayPlan?;
  }
}

Widget _host(Widget child, {double scale = 1, bool reduced = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

TodayPlan _plan({int minutes = 12, bool lesson = true, bool reviews = true}) {
  return TodayPlan(
    minutes: minutes,
    dueReviews: reviews
        ? const <TodayDueReview>[
            TodayDueReview(id: 'r1', label: 'Hello review'),
            TodayDueReview(id: 'r2', label: 'Market review'),
          ]
        : const <TodayDueReview>[],
    nextLesson: lesson
        ? const TodayNextLesson(
            id: 'l1',
            title: 'Morning greetings',
            targetLine: 'Ẹ kú àárọ̀',
          )
        : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('sitemap routes are registered and within two taps', () {
    expect(TodayHubRoutes.all.map((TodayRoute route) => route.id), _sitemap);
    expect(TodayHubRoutes.withinTwoTaps, isTrue);
    for (final String id in _sitemap) {
      final TodayRoute? route = TodayHubRoutes.resolve(id);
      expect(route, isNotNull);
      expect(route!.taps, lessThanOrEqualTo(2));
      expect(TodayHubRoutes.resolve(route.path), route);
    }
    expect(TodayHubRoutes.resolve('/today/no-such'), isNull);
    expect(TodayHubRoutes.dailyPlan.taps, 0);
    expect(TodayHubRoutes.hub.taps, 0);
    expect(TodayHubRoutes.links, hasLength(4));
  });

  test('an absent provider does not invent a plan', () {
    expect(
      resolveTodaySurface(null),
      isA<TodaySurfaceBlocked>().having(
        (TodaySurfaceBlocked surface) => surface.kind,
        'kind',
        TodayUnavailableKind.providerAbsent,
      ),
    );
    expect(resolveTodaySurface(_PlanSource(null)), isA<TodaySurfaceEmpty>());
    final TodaySurface partial = resolveTodaySurface(
      _PlanSource(_plan(lesson: false)),
    );
    expect(
      partial,
      isA<TodaySurfaceBlocked>().having(
        (TodaySurfaceBlocked surface) => surface.kind,
        'kind',
        TodayUnavailableKind.planOutOfRange,
      ),
    );
    final TodaySurface ready = resolveTodaySurface(_PlanSource(_plan()));
    expect(ready, isA<TodaySurfaceReady>());
    final TodayShownPlan shown = (ready as TodaySurfaceReady).plan;
    expect(shown.minutes, inInclusiveRange(10, 15));
    expect(shown.dueReviews.map((TodayDueReview review) => review.label), [
      'Hello review',
      'Market review',
    ]);
    expect(shown.nextLesson.title, 'Morning greetings');
    expect(
      resolveTodaySurface(_PlanSource(_plan(minutes: 9))),
      isA<TodaySurfaceBlocked>(),
    );
    expect(
      resolveTodaySurface(_PlanSource(_plan(minutes: 16))),
      isA<TodaySurfaceBlocked>(),
    );
    expect(
      resolveTodaySurface(_ThrowSource(TodayUnavailableKind.offline)),
      isA<TodaySurfaceBlocked>().having(
        (TodaySurfaceBlocked surface) => surface.kind,
        'kind',
        TodayUnavailableKind.offline,
      ),
    );
  });

  testWidgets('every sitemap row is on the hub or one tap away', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const HomeTab()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('The daily plan is not available.'), findsOneWidget);
    expect(find.text('The plan provider is not here.'), findsOneWidget);
    expect(find.byKey(TodayHubMarks.plan), findsNothing);
    expect(find.byKey(TodayHubMarks.lessonTitle), findsNothing);
    expect(find.byKey(TodayHubMarks.dueReviews), findsNothing);
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).kind,
      TodaySurfaceKind.notAvailable,
    );
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).reason,
      TodayUnavailableKind.providerAbsent,
    );

    for (final TodayRoute link in TodayHubRoutes.links) {
      expect(link.taps, 1);
      final Finder row = find.byKey(TodayHubMarks.destination(link.kind));
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      final Size size = tester.getSize(row);
      expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      await tester.tap(row);
      await tester.pumpAndSettle();
      if (link.kind == TodayRouteKind.dailyChallenges) {
        expect(link.built, isTrue);
        expect(find.byType(DailyChallengesScreen), findsOneWidget);
        final ModalRoute<dynamic> named = ModalRoute.of(
          tester.element(find.byType(DailyChallengesScreen)),
        )!;
        expect(named.settings.name, TodayHubRoutes.dailyChallenges.path);
        expect(find.byKey(DailyChallengesScreen.emptyKey), findsOneWidget);
        expect(find.text('This part is not available yet.'), findsNothing);
        expect(find.text('Daily Learner'), findsNothing);
        await tester.tap(find.byKey(DailyChallengesScreen.backKey));
        await tester.pumpAndSettle();
        expect(find.text('Today'), findsOneWidget);
        continue;
      }
      expect(find.text('This part is not available yet.'), findsOneWidget);
      expect(find.text('It is not built yet.'), findsOneWidget);
      expect(find.byKey(TodayHubMarks.plan), findsNothing);
      expect(find.byKey(TodayHubMarks.lessonTitle), findsNothing);
      expect(find.text('Hello review'), findsNothing);
      expect(find.text('Morning greetings'), findsNothing);
      expect(
        tester.widget<TodayStateMark>(find.byType(TodayStateMark)).reason,
        TodayUnavailableKind.notBuilt,
      );
      await tester.tap(find.text('Back to Today'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
    }
  });

  testWidgets('a real plan lists due reviews, the next lesson, and 10 to 15 minutes', (
    WidgetTester tester,
  ) async {
    TodayNextLesson? started;
    await tester.pumpWidget(
      _host(
        HomeTab(
          planSource: _PlanSource(_plan()),
          onStartLesson: (TodayNextLesson lesson) => started = lesson,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TodayHubMarks.plan), findsOneWidget);
    expect(find.text('12 minutes'), findsOneWidget);
    expect(find.text('Due reviews'), findsOneWidget);
    expect(find.text('Hello review'), findsOneWidget);
    expect(find.text('Market review'), findsOneWidget);
    expect(find.text('Next lesson'), findsOneWidget);
    expect(find.text('Morning greetings'), findsOneWidget);
    expect(find.text('Ẹ kú àárọ̀'), findsOneWidget);
    expect(find.text('Speaking'), findsNothing);
    expect(find.text('Start'), findsOneWidget);
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).kind,
      TodaySurfaceKind.ready,
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(started?.id, 'l1');
    expect(started?.title, 'Morning greetings');
    expect(find.text('This part is not available yet.'), findsNothing);
  });

  testWidgets('an empty hub points at the next step', (WidgetTester tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _host(HomeTab(planSource: _PlanSource(null), onOpenPath: () => opened += 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TodayHubMarks.empty), findsOneWidget);
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Open Path and start the first lesson.'), findsOneWidget);
    expect(find.text('Open Path'), findsOneWidget);
    expect(find.byKey(TodayHubMarks.lessonTitle), findsNothing);
    expect(find.text('Daily Challenges'), findsOneWidget);
    await tester.tap(find.text('Open Path'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('a plan outside 10 to 15 minutes is not shown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(HomeTab(planSource: _PlanSource(_plan(minutes: 40)))),
    );
    await tester.pumpAndSettle();

    expect(find.text('This plan cannot be shown.'), findsOneWidget);
    expect(find.text('Hello review'), findsNothing);
    expect(find.text('Morning greetings'), findsNothing);
    expect(find.text('40 minutes'), findsNothing);
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).reason,
      TodayUnavailableKind.planOutOfRange,
    );
  });

  testWidgets('a missing lesson is not filled in', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(HomeTab(planSource: _PlanSource(_plan(lesson: false)))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello review'), findsNothing);
    expect(find.byKey(TodayHubMarks.lessonTitle), findsNothing);
    expect(find.text('This plan cannot be shown.'), findsOneWidget);
  });

  testWidgets('start without a lesson screen shows not-available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(HomeTab(planSource: _PlanSource(_plan()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('This part is not available yet.'), findsOneWidget);
    expect(find.text('Morning greetings'), findsNothing);
    expect(find.byKey(TodayHubMarks.plan), findsNothing);
  });

  testWidgets('error and offline stay typed and can be tried again', (
    WidgetTester tester,
  ) async {
    final _Script source = _Script(<Object?>[
      const TodayUnavailable(TodayUnavailableKind.failed),
      const TodayUnavailable(TodayUnavailableKind.offline),
      _plan(minutes: 10),
    ]);
    await tester.pumpWidget(_host(HomeTab(planSource: source)));
    await tester.pumpAndSettle();
    expect(find.text('The plan did not open.'), findsOneWidget);
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).kind,
      TodaySurfaceKind.error,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(find.text('This plan is not saved on the phone.'), findsOneWidget);
    expect(
      tester.widget<TodayStateMark>(find.byType(TodayStateMark)).kind,
      TodaySurfaceKind.offline,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.text('Hello review'), findsOneWidget);
    expect(source.calls, 3);
  });

  testWidgets('the daily plan route is the same plan', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        HomeTab(
          planSource: _PlanSource(_plan(minutes: 15)),
          initialRoute: TodayHubRoutes.dailyPlan.path,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily plan'), findsOneWidget);
    expect(find.text('15 minutes'), findsOneWidget);
    expect(find.text('Next lesson'), findsOneWidget);
    expect(find.text('Morning greetings'), findsOneWidget);
  });

  testWidgets('200 percent text and reduced motion still open a destination', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(const HomeTab(), scale: 2, reduced: true),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final Finder streaks = find.byKey(
      TodayHubMarks.destination(TodayRouteKind.streaks),
    );
    await tester.ensureVisible(streaks);
    await tester.pumpAndSettle();
    await tester.tap(streaks);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Streaks'), findsOneWidget);
    expect(find.text('This part is not available yet.'), findsOneWidget);
    expect(find.text('No streak yet'), findsNothing);
  });
}
