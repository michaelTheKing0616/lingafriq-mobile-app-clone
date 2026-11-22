import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/daily_challenge_model.dart';
import 'package:lingafriq/navigation/hub_today.dart';
import 'package:lingafriq/providers/daily_challenges_provider.dart';
import 'package:lingafriq/screens/goals/daily_challenges_screen.dart';
import 'package:lingafriq/screens/help/feature_preloader_screen.dart';
import 'package:lingafriq/screens/help/games_preloader.dart';
import 'package:lingafriq/screens/help/gamification_preloader.dart';
import 'package:lingafriq/screens/help/polie_preloader.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab.dart';
import 'package:lingafriq/widgets/first_use_tip.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a failed load keeps no challenge rows', () {
    final DailyChallenge kept = _row(title: 'Use five words');
    final DailyChallengesState previous = DailyChallengesState(
      challenges: <DailyChallenge>[kept],
      weekendChallenges: <DailyChallenge>[_row(id: 'w1', title: 'Weekend row')],
    );
    final DailyChallengesState failed = dailyChallengesAfterLoadFailure(
      StateError('missing'),
    );
    expect(previous.challenges, isNotEmpty);
    expect(failed.challenges, isEmpty);
    expect(failed.weekendChallenges, isEmpty);
    expect(failed.error, contains('missing'));
    expect(failed.isLoading, isFalse);
    expect(
      failed.challenges.map((DailyChallenge row) => row.title),
      isNot(contains('Use five words')),
    );
  });

  test('saved challenges are only the rows on the phone', () async {
    final DailyChallengeBoard empty = await loadSavedDailyChallenges();
    expect(empty.status, DailyChallengeBoardStatus.empty);
    expect(empty.challenges, isEmpty);

    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues(<String, Object>{
      DailyChallengeStoreKeys.day: dailyChallengeDayKey(yesterday),
      DailyChallengeStoreKeys.challenges: jsonEncode(<Map<String, dynamic>>[
        _row(title: 'Use five words').toJson(),
      ]),
    });
    final DailyChallengeBoard stale = await loadSavedDailyChallenges();
    expect(stale.status, DailyChallengeBoardStatus.empty);
    expect(stale.challenges, isEmpty);

    SharedPreferences.setMockInitialValues(<String, Object>{
      DailyChallengeStoreKeys.day: dailyChallengeDayKey(DateTime.now()),
      DailyChallengeStoreKeys.challenges: '{',
    });
    final DailyChallengeBoard broken = await loadSavedDailyChallenges();
    expect(broken.status, DailyChallengeBoardStatus.error);
    expect(broken.challenges, isEmpty);

    SharedPreferences.setMockInitialValues(<String, Object>{
      DailyChallengeStoreKeys.day: dailyChallengeDayKey(DateTime.now()),
      DailyChallengeStoreKeys.challenges: jsonEncode(<Map<String, dynamic>>[
        _row(title: 'Use five words').toJson(),
      ]),
    });
    final DailyChallengeBoard saved = await loadSavedDailyChallenges();
    expect(saved.status, DailyChallengeBoardStatus.ready);
    expect(saved.challenges.map((DailyChallenge row) => row.title), <String>[
      'Use five words',
    ]);
    expect(
      saved.challenges.map((DailyChallenge row) => row.title),
      isNot(contains('Daily Learner')),
    );
  });

  test('shell routes register the revived screens', () {
    expect(DailyChallengesScreen.routePath, '/today/daily-challenges');
    expect(DailyChallengesScreen.routeKey, 'today/daily-challenges');
    expect(
      TodayHubRoutes.dailyChallenges.path,
      DailyChallengesScreen.routePath,
    );
    expect(TodayHubRoutes.dailyChallenges.built, isTrue);
    expect(
      todayOpenedScreen(TodayHubRoutes.dailyChallenges),
      isA<DailyChallengesScreen>(),
    );
    expect(todayOpenedScreen(TodayHubRoutes.quests), isNull);

    expect(GamesPreloader.routePath, '/help/games-tip');
    expect(GamificationPreloader.routePath, '/help/gamification-tip');
    expect(PoliePreloader.routePath, '/help/polie-tip');
    expect(FeaturesHelpPreloader.routePath, '/help/features-tip');

    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('DailyChallengesScreen.routeKey'));
    expect(app, contains('const DailyChallengesScreen.saved()'));
    expect(app, contains('GamesPreloader.routeKey'));
    expect(app, contains('const GamesPreloader()'));
    expect(app, contains('GamificationPreloader.routeKey'));
    expect(app, contains('const GamificationPreloader()'));
    expect(app, contains('PoliePreloader.routeKey'));
    expect(app, contains('const PoliePreloader()'));
    expect(app, contains('FeaturesHelpPreloader.routeKey'));
    expect(app, contains('const FeaturesHelpPreloader()'));
    expect(
      app,
      contains("import 'screens/goals/daily_challenges_screen.dart'"),
    );
    expect(app, contains("import 'screens/help/games_preloader.dart'"));
    expect(app, contains("import 'screens/help/gamification_preloader.dart'"));
    expect(app, contains("import 'screens/help/polie_preloader.dart'"));
    expect(
      app,
      contains("import 'screens/help/feature_preloader_screen.dart'"),
    );
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains("import 'my_app.dart'"),
    );
  });

  testWidgets('Today opens /today/daily-challenges', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const HomeTab()));
    await tester.pumpAndSettle();

    final Finder row = find.byKey(
      TodayHubMarks.destination(TodayRouteKind.dailyChallenges),
    );
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(DailyChallengesScreen), findsOneWidget);
    final ModalRoute<dynamic> named = ModalRoute.of(
      tester.element(find.byType(DailyChallengesScreen)),
    )!;
    expect(named.settings.name, '/today/daily-challenges');
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.emptyKey), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
    expect(find.text('Daily Learner'), findsNothing);
    expect(find.text('XP Hunter'), findsNothing);
  });

  testWidgets('no saved challenges show the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const DailyChallengesScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.emptyKey), findsOneWidget);
    expect(find.text('No challenges are saved.'), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
    expect(find.text('Daily Learner'), findsNothing);

    await tester.pumpWidget(_host(const DailyChallengesScreen.saved()));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyChallengesScreen.emptyKey), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
  });

  testWidgets('a load error drops the challenge list', (
    WidgetTester tester,
  ) async {
    final List<DailyChallengeBoard> boards = <DailyChallengeBoard>[
      DailyChallengeBoard.ready(<DailyChallenge>[
        _row(title: 'Use five words'),
      ]),
      const DailyChallengeBoard.error(),
    ];
    int index = 0;
    Future<DailyChallengeBoard> load() async => boards[index++];

    await tester.pumpWidget(_host(DailyChallengesScreen(load: load)));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyChallengesScreen.listKey), findsOneWidget);
    expect(find.text('Use five words'), findsOneWidget);
    expect(find.text('1 of 5'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        DailyChallengesScreen(
          load: () async => const DailyChallengeBoard.error(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Use five words'), findsNothing);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.errorKey), findsOneWidget);
    expect(find.text('Use five words'), findsNothing);
    expect(find.text('1 of 5'), findsNothing);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
  });

  testWidgets('offline drops the challenge list', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        DailyChallengesScreen(
          load: () async => DailyChallengeBoard.ready(<DailyChallenge>[
            _row(title: 'Use five words'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Use five words'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        DailyChallengesScreen(
          load: () async => const DailyChallengeBoard.offline(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Use five words'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingOfflineState), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.offlineKey), findsOneWidget);
    expect(find.byKey(DailyChallengesScreen.listKey), findsNothing);
    expect(find.text('Use five words'), findsNothing);
  });

  testWidgets('empty challenges at 200 percent text stay on screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const DailyChallengesScreen(), scale: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyChallengesScreen.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a dismissed first-use tip stays dismissed', (
    WidgetTester tester,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FirstUseTipStore store = FirstUseTipStore(
      FirstUseTipDismissStorage.sharedPreferences(prefs),
    );

    await tester.pumpWidget(_tipHost(GamesPreloader(tipStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('phase-shown')), findsOneWidget);
    expect(find.text(FirstUseTipCopy.games), findsWidgets);
    expect(find.text('Dismiss'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();

    expect(prefs.getBool(firstUseTipPrefKey(FirstUseTipIds.games)), isTrue);
    expect(find.byKey(const ValueKey<String>('phase-hidden')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('phase-shown')), findsNothing);
    expect(find.text(FirstUseTipCopy.games), findsNothing);
    expect(store.isDismissed(FirstUseTipIds.polie), isFalse);

    final FirstUseTipStore reloaded = FirstUseTipStore(
      FirstUseTipDismissStorage.sharedPreferences(
        await SharedPreferences.getInstance(),
      ),
    );
    expect(reloaded.isDismissed(FirstUseTipIds.games), isTrue);
    expect(reloaded.isDismissed(FirstUseTipIds.polie), isFalse);

    await tester.pumpWidget(_tipHost(GamesPreloader(tipStore: reloaded)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('phase-shown')), findsNothing);
    expect(find.byKey(const ValueKey<String>('phase-hidden')), findsOneWidget);
    expect(find.text(FirstUseTipCopy.games), findsNothing);

    await tester.pumpWidget(_tipHost(PoliePreloader(tipStore: reloaded)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('phase-shown')), findsOneWidget);
    expect(find.text(FirstUseTipCopy.polie), findsWidgets);

    await tester.pumpWidget(
      _tipHost(GamificationPreloader(tipStore: reloaded)),
    );
    await tester.pumpAndSettle();
    expect(find.text(FirstUseTipCopy.gamification), findsWidgets);

    await tester.pumpWidget(
      _tipHost(FeaturesHelpPreloader(tipStore: reloaded)),
    );
    await tester.pumpAndSettle();
    expect(find.text(FirstUseTipCopy.features), findsWidgets);
  });
}

DailyChallenge _row({String id = 'c1', String title = 'Use five words'}) {
  final DateTime now = DateTime.now();
  return DailyChallenge(
    id: id,
    title: title,
    description: 'Saved on the phone',
    emoji: 'o',
    type: ChallengeType.wordsLearned,
    difficulty: ChallengeDifficulty.easy,
    target: 5,
    progress: 1,
    xpReward: 10,
    cowriesReward: 0,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 1)),
  );
}

Widget _host(Widget child, {double scale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(textScaler: TextScaler.linear(scale)),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Widget _tipHost(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (BuildContext context, Widget? _) {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
    },
  );
}
