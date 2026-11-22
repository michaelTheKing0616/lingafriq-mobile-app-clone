import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/conversation_analytics_model.dart';
import 'package:lingafriq/models/roleplay_progress_model.dart';
import 'package:lingafriq/navigation/hub_speak.dart';
import 'package:lingafriq/screens/ai_chat/conversation_analytics_screen.dart';
import 'package:lingafriq/screens/ai_chat/roleplay_completion_summary_screen.dart';
import 'package:lingafriq/screens/ai_chat/roleplay_progress_dashboard_screen.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';

const String _practiceCopy =
    'Pronunciation scoring is unavailable. You can keep practising without a ranked score.';

const String _unsureCopy =
    'We could not score this clearly. No score is shown.';

const RoleplaySceneRow _market = RoleplaySceneRow(id: 'market', name: 'Market');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reachability scan from lib/main.dart includes the three screens', () {
    expect(ConversationAnalyticsScreen.routePath, '/speak/coach-insights');
    expect(ConversationAnalyticsScreen.routeKey, 'speak/coach-insights');
    expect(
      RoleplayCompletionSummaryScreen.routePath,
      '/speak/roleplay-summary',
    );
    expect(RoleplayCompletionSummaryScreen.routeKey, 'speak/roleplay-summary');
    expect(
      RoleplayProgressDashboardScreen.routePath,
      '/speak/roleplay-progress',
    );
    expect(RoleplayProgressDashboardScreen.routeKey, 'speak/roleplay-progress');

    expect(SpeakRoutes.coachInsights, ConversationAnalyticsScreen.routePath);
    expect(
      SpeakRoutes.roleplaySummary,
      RoleplayCompletionSummaryScreen.routePath,
    );
    expect(
      SpeakRoutes.roleplayProgress,
      RoleplayProgressDashboardScreen.routePath,
    );
    expect(SpeakRoutes.paths, contains(SpeakRoutes.coachInsights));
    expect(SpeakRoutes.paths, contains(SpeakRoutes.roleplaySummary));
    expect(SpeakRoutes.paths, contains(SpeakRoutes.roleplayProgress));
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.coachInsights),
      isA<SpeakCoachOpening>(),
    );
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.roleplaySummary),
      isA<SpeakRoleplaySummaryOpening>(),
    );
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.roleplayProgress),
      isA<SpeakRoleplayProgressOpening>(),
    );
    expect(
      SpeakRoutes.places
          .singleWhere((SpeakPlace place) => place.id == 'coach')
          .kind,
      SpeakPlaceKind.ready,
    );
    expect(
      SpeakRoutes.places
          .singleWhere((SpeakPlace place) => place.id == 'roleplaySummary')
          .kind,
      SpeakPlaceKind.ready,
    );
    expect(
      SpeakRoutes.places
          .singleWhere((SpeakPlace place) => place.id == 'roleplayProgress')
          .kind,
      SpeakPlaceKind.ready,
    );

    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('ConversationAnalyticsScreen.routeKey'));
    expect(app, contains('RoleplayCompletionSummaryScreen.routeKey'));
    expect(app, contains('RoleplayProgressDashboardScreen.routeKey'));
    expect(
      app,
      contains("import 'screens/ai_chat/conversation_analytics_screen.dart'"),
    );
    expect(
      app,
      contains(
        "import 'screens/ai_chat/roleplay_completion_summary_screen.dart'",
      ),
    );
    expect(
      app,
      contains(
        "import 'screens/ai_chat/roleplay_progress_dashboard_screen.dart'",
      ),
    );
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains("import 'my_app.dart'"),
    );

    final Set<String> reachable = _reachableFromMain();
    expect(
      reachable,
      contains('lib/screens/ai_chat/conversation_analytics_screen.dart'),
    );
    expect(
      reachable,
      contains('lib/screens/ai_chat/roleplay_completion_summary_screen.dart'),
    );
    expect(
      reachable,
      contains('lib/screens/ai_chat/roleplay_progress_dashboard_screen.dart'),
    );

    for (final String path in <String>[
      'lib/screens/ai_chat/conversation_analytics_screen.dart',
      'lib/screens/ai_chat/roleplay_completion_summary_screen.dart',
      'lib/screens/ai_chat/roleplay_progress_dashboard_screen.dart',
      'lib/services/conversation_analytics_service.dart',
      'lib/navigation/hub_speak.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('\u2014')));
    }
  });

  test('a stored fluency number without a real scorer is not shown', () {
    final ConversationAnalytics invented = ConversationAnalytics(
      language: 'yoruba',
      averageFluency: 80,
    );
    expect(storyFromAnalytics(invented), isNull);

    final ConversationSession session = ConversationSession(
      sessionId: 's1',
      language: 'yoruba',
      startTime: DateTime.utc(2026, 1, 1),
      messageCount: 3,
      wordCount: 4,
      topics: const <String>['Market'],
      fluencyScore: 80,
    );
    final CoachInsightStory? story = storyFromAnalytics(
      ConversationAnalytics(
        language: 'yoruba',
        sessions: <ConversationSession>[session],
        averageFluency: 100,
        totalMessages: 3,
      ),
    );
    expect(story, isNotNull);
    expect(story!.topics, <String>['Market']);
    expect(story.sessions, 1);
    expect(story.pronunciation, isNull);
    expect(story.tone, isNull);
    expect(scoreFromMetadata(session.metadata, 'pronunciation'), isNull);
    expect(scoreFromMetadata(session.metadata, 'tone'), isNull);

    final GameScore? real = scoreFromMetadata(<String, dynamic>{
      'score_source': 'real_scorer',
      'pronunciation_accuracy': 0.5,
      'scorer_version': 'coach-real',
    }, 'pronunciation');
    expect(real, isNotNull);
    expect(real!.source, GameScoreSource.realScorer);
    expect(shownScorerPercent(real), 50);
    expect(scorerReadout(real).kind, ScorerReadoutKind.number);

    final GameScore? unsure = scoreFromMetadata(<String, dynamic>{
      'score_source': 'unsure',
      'pronunciation_accuracy': 1,
    }, 'pronunciation');
    expect(unsure, isNotNull);
    expect(unsure!.isUnsure, isTrue);
    expect(shownScorerPercent(unsure), isNull);

    final GameScore? missing = scoreFromMetadata(<String, dynamic>{
      'fluency_score': 80,
      'tone_accuracy': 0,
    }, 'tone');
    expect(missing, isNull);
    expect(scorerReadout(null).kind, ScorerReadoutKind.hidden);

    expect(shownScorerPercent(GameScore.correct(accuracy: 0.8)), isNull);
    expect(shownScorerPercent(GameScore.scorerError(message: 'down')), isNull);
    expect(
      shownScorerPercent(GameScore.honestPractice(message: 'unavailable')),
      isNull,
    );
    expect(shownScorerPercent(GameScore.unsure(message: 'unsure')), isNull);

    final RoleplaySummaryStory? bare = summaryFromResult(
      RoleplaySessionResult(
        scenarioId: '',
        language: 'yoruba',
        turnCount: 0,
        accuracy: 0.8,
        fluency: 1,
        score: 100,
        timeSpent: 0,
        completedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    expect(bare, isNull);

    final RoleplaySummaryStory? named = summaryFromResult(
      RoleplaySessionResult(
        scenarioId: 'market',
        language: 'yoruba',
        turnCount: 2,
        accuracy: 0.8,
        fluency: 0,
        score: 80,
        timeSpent: 0,
        completedAt: DateTime.utc(2026, 1, 1),
        metadata: const <String, dynamic>{'scenario_name': 'Market'},
      ),
    );
    expect(named, isNotNull);
    expect(named!.title, 'Market');
    expect(named.pronunciation, isNull);
    expect(named.tone, isNull);
  });

  testWidgets('Speak hub entries open the three routes', (tester) async {
    await tester.pumpWidget(_host(const SpeakHub()));
    await tester.pumpAndSettle();

    const List<(String, Type, String)> rows = <(String, Type, String)>[
      ('coach', ConversationAnalyticsScreen, '/speak/coach-insights'),
      (
        'roleplaySummary',
        RoleplayCompletionSummaryScreen,
        '/speak/roleplay-summary',
      ),
      (
        'roleplayProgress',
        RoleplayProgressDashboardScreen,
        '/speak/roleplay-progress',
      ),
    ];
    for (final (String id, Type page, String path) in rows) {
      await tester.ensureVisible(find.byKey(SpeakHub.placeKey(id)));
      await tester.tap(find.byKey(SpeakHub.placeKey(id)));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget);
      expect(find.byType(SpeakNotAvailablePage), findsNothing);
      expect(
        ModalRoute.of(tester.element(find.byType(page)))!.settings.name,
        path,
      );
      expect(find.byType(LingEmptyState), findsOneWidget);
      expect(find.byType(LingErrorState), findsNothing);
      _expectNoPlaceholder(tester);
      await tester.ensureVisible(find.text('Back to Speak'));
      await tester.tap(find.text('Back to Speak'));
      await tester.pumpAndSettle();
      expect(find.byType(SpeakHubPage), findsOneWidget);
    }
  });

  testWidgets('the registered routes open from the shell map', (tester) async {
    await tester.pumpWidget(_routes());
    for (final (String key, Type page, String path) in <(String, Type, String)>[
      ('open-coach', ConversationAnalyticsScreen, '/speak/coach-insights'),
      (
        'open-summary',
        RoleplayCompletionSummaryScreen,
        '/speak/roleplay-summary',
      ),
      (
        'open-progress',
        RoleplayProgressDashboardScreen,
        '/speak/roleplay-progress',
      ),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>(key)));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byType(page)))!.settings.name,
        path,
      );
      expect(find.byType(LingEmptyState), findsOneWidget);
      await tester.tap(find.text('Back to Speak'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('no conversation shows the empty state', (tester) async {
    await tester.pumpWidget(_host(const ConversationAnalyticsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationAnalyticsScreen.emptyKey), findsOneWidget);
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.text('No conversation is saved.'), findsOneWidget);
    expect(find.byKey(ConversationAnalyticsScreen.storyKey), findsNothing);
    expect(find.byKey(ConversationAnalyticsScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('no scenario summary shows the empty state', (tester) async {
    await tester.pumpWidget(_host(const RoleplayCompletionSummaryScreen()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(RoleplayCompletionSummaryScreen.emptyKey),
      findsOneWidget,
    );
    expect(find.text('No scenario summary is ready.'), findsOneWidget);
    expect(find.byKey(RoleplayCompletionSummaryScreen.storyKey), findsNothing);
    expect(find.byKey(RoleplayCompletionSummaryScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('no roleplay list shows the empty state', (tester) async {
    await tester.pumpWidget(_host(const RoleplayProgressDashboardScreen()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(RoleplayProgressDashboardScreen.emptyKey),
      findsOneWidget,
    );
    expect(find.text('No scenarios are listed.'), findsOneWidget);
    expect(find.byKey(RoleplayProgressDashboardScreen.listKey), findsNothing);
    expect(find.byKey(RoleplayProgressDashboardScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a coach load error clears the previous story', (tester) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_scoredPost),
    ))!;
    expect(score.source, GameScoreSource.realScorer);
    expect(shownScorerPercent(score), 50);
    var fail = false;
    await tester.pumpWidget(
      _host(
        ConversationAnalyticsScreen(
          load: () async {
            if (fail) throw StateError('load');
            return CoachInsightLoad.ready(
              CoachInsightStory(
                languageName: 'Yoruba',
                topics: const <String>['Market'],
                pronunciation: score,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationAnalyticsScreen.storyKey), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    fail = true;
    await tester.tap(find.byKey(ConversationAnalyticsScreen.refreshKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationAnalyticsScreen.errorKey), findsOneWidget);
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('Coach insights did not open.'), findsOneWidget);
    expect(
      find.text('The conversation story did not come back.'),
      findsOneWidget,
    );
    expect(find.byKey(ConversationAnalyticsScreen.storyKey), findsNothing);
    expect(find.text('Market'), findsNothing);
    expect(find.text('50%'), findsNothing);
    expect(find.byKey(ConversationAnalyticsScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a summary load error clears the previous story', (tester) async {
    var fail = false;
    await tester.pumpWidget(
      _host(
        RoleplayCompletionSummaryScreen(
          load: () async {
            if (fail) throw StateError('load');
            return const RoleplaySummaryLoad.ready(
              RoleplaySummaryStory(title: 'Market', turns: 2),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('2 turns'), findsOneWidget);

    fail = true;
    await tester.tap(find.byKey(RoleplayCompletionSummaryScreen.refreshKey));
    await tester.pumpAndSettle();

    expect(
      find.byKey(RoleplayCompletionSummaryScreen.errorKey),
      findsOneWidget,
    );
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('The scenario summary did not open.'), findsOneWidget);
    expect(
      find.text('Nothing from that scenario is still on screen.'),
      findsOneWidget,
    );
    expect(find.byKey(RoleplayCompletionSummaryScreen.storyKey), findsNothing);
    expect(find.text('Market'), findsNothing);
    expect(find.text('2 turns'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a progress load error clears the previous list', (tester) async {
    var fail = false;
    await tester.pumpWidget(
      _host(
        RoleplayProgressDashboardScreen(
          load: () async {
            if (fail) throw StateError('load');
            return const RoleplayProgressLoad.ready(<RoleplaySceneRow>[
              _market,
            ]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(RoleplayProgressDashboardScreen.listKey), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);

    fail = true;
    await tester.tap(find.byKey(RoleplayProgressDashboardScreen.refreshKey));
    await tester.pumpAndSettle();

    expect(
      find.byKey(RoleplayProgressDashboardScreen.errorKey),
      findsOneWidget,
    );
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('Roleplay progress did not open.'), findsOneWidget);
    expect(find.text('The scenario list did not come back.'), findsOneWidget);
    expect(find.byKey(RoleplayProgressDashboardScreen.listKey), findsNothing);
    expect(find.text('Market'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('an offline reload clears the previous story', (tester) async {
    var offline = false;
    await tester.pumpWidget(
      _host(
        ConversationAnalyticsScreen(
          load: () async {
            if (offline) throw const SpeakDataUnavailable(offline: true);
            return const CoachInsightLoad.ready(
              CoachInsightStory(
                languageName: 'Yoruba',
                topics: <String>['Market'],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);

    offline = true;
    await tester.tap(find.byKey(ConversationAnalyticsScreen.refreshKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationAnalyticsScreen.offlineKey), findsOneWidget);
    expect(find.byType(LingOfflineState), findsOneWidget);
    expect(find.text('Market'), findsNothing);
    expect(find.byKey(ConversationAnalyticsScreen.storyKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a real scorer result shows its percent', (tester) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_scoredPost),
    ))!;
    expect(score.source, GameScoreSource.realScorer);
    expect(shownScorerPercent(score), 50);
    await tester.pumpWidget(
      _host(
        ConversationAnalyticsScreen(
          load: () async {
            return CoachInsightLoad.ready(
              CoachInsightStory(
                languageName: 'Yoruba',
                topics: const <String>['Market'],
                pronunciation: score,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationAnalyticsScreen.scoreKey), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Pronunciation'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.byKey(ConversationAnalyticsScreen.practiceKey), findsNothing);
    expect(find.byKey(ConversationAnalyticsScreen.unsureKey), findsNothing);
    expect(_digits(tester), <String>['50']);
  });

  testWidgets('a real scorer result shows on the scenario summary', (
    tester,
  ) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_scoredPost),
    ))!;
    expect(shownScorerPercent(score), 50);
    await tester.pumpWidget(
      _host(
        RoleplayCompletionSummaryScreen(
          load: () async {
            return RoleplaySummaryLoad.ready(
              RoleplaySummaryStory(title: 'Market', pronunciation: score),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(RoleplayCompletionSummaryScreen.scoreKey),
      findsOneWidget,
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(_digits(tester), <String>['50']);
  });

  testWidgets('a local score hides 80 and shows no number', (tester) async {
    await tester.pumpWidget(
      _host(
        ConversationAnalyticsScreen(
          load: () async {
            return CoachInsightLoad.ready(
              CoachInsightStory(
                languageName: 'Yoruba',
                topics: const <String>['Market'],
                pronunciation: GameScore.correct(accuracy: 0.8),
                tone: GameScore.correct(accuracy: 1),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationAnalyticsScreen.practiceKey), findsOneWidget);
    expect(find.text(_practiceCopy), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.byKey(ConversationAnalyticsScreen.scoreKey), findsNothing);
    expect(find.byKey(ConversationAnalyticsScreen.toneKey), findsNothing);
    expect(find.text('80%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    expect(find.text('0%'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('an unsure scorer shows no placeholder number', (tester) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_unsurePost),
    ))!;
    expect(score.isUnsure, isTrue);
    expect(shownScorerPercent(score), isNull);
    await tester.pumpWidget(
      _host(
        RoleplayCompletionSummaryScreen(
          load: () async {
            return RoleplaySummaryLoad.ready(
              RoleplaySummaryStory(title: 'Market', pronunciation: score),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(RoleplayCompletionSummaryScreen.unsureKey),
      findsOneWidget,
    );
    expect(find.text(_unsureCopy), findsOneWidget);
    expect(find.byKey(RoleplayCompletionSummaryScreen.scoreKey), findsNothing);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('50%'), findsNothing);
    expect(find.text('80'), findsNothing);
    expect(find.text('100'), findsNothing);
    expect(find.text('0'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('an unavailable scorer shows practice and no number', (
    tester,
  ) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_unavailablePost),
    ))!;
    expect(score.honestPracticeMode, isTrue);
    expect(shownScorerPercent(score), isNull);
    await tester.pumpWidget(
      _host(
        RoleplayProgressDashboardScreen(
          load: () async {
            return RoleplayProgressLoad.ready(const <RoleplaySceneRow>[
              _market,
            ], pronunciation: score);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(RoleplayProgressDashboardScreen.practiceKey),
      findsOneWidget,
    );
    expect(find.text(_practiceCopy), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.byKey(RoleplayProgressDashboardScreen.scoreKey), findsNothing);
    expect(find.byType(LingErrorState), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('80'), findsNothing);
    expect(find.text('100'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a missing scorer hides the number', (tester) async {
    await tester.pumpWidget(
      _host(
        RoleplayCompletionSummaryScreen(
          result: RoleplaySessionResult(
            scenarioId: 'market',
            language: 'yoruba',
            turnCount: 2,
            accuracy: 0,
            fluency: 0.8,
            score: 100,
            timeSpent: 0,
            completedAt: DateTime.utc(2026, 1, 1),
            metadata: const <String, dynamic>{'scenario_name': 'Market'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('2 turns'), findsOneWidget);
    expect(find.byKey(RoleplayCompletionSummaryScreen.scoreKey), findsNothing);
    expect(
      find.byKey(RoleplayCompletionSummaryScreen.practiceKey),
      findsNothing,
    );
    expect(find.byKey(RoleplayCompletionSummaryScreen.unsureKey), findsNothing);
    expect(find.text('0%'), findsNothing);
    expect(find.text('80%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    expect(find.text('100'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(_digits(tester), <String>['2']);
  });

  testWidgets('empty coach insights at 200% text does not throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ConversationAnalyticsScreen(), scale: 2, reduced: true),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationAnalyticsScreen.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<GameScore> _engineScore(LensScorePost post) async {
  final File audio = await _audioFile();
  try {
    final RealScorerSpeakingEngine engine = RealScorerSpeakingEngine(
      post: post,
    );
    final GameScore score = await engine.score(
      GameTurnContext(
        content: const <String, String>{'expectedText': 'E kaaro'},
        input: GameSpeakingTurnInput(
          audioPath: audio.path,
          expectedText: 'E kaaro',
          language: 'yoruba',
        ),
        session: GameSession(
          sessionId: 'coach',
          userId: 'learner',
          gameId: 'coach',
          language: 'yoruba',
          startTime: DateTime.now(),
          metadata: const <String, dynamic>{'core_verb': 'speak'},
        ),
        metadata: const <String, dynamic>{
          'requiresServerScoring': true,
          'coreVerb': 'speak',
        },
      ),
    );
    return score;
  } finally {
    await _delete(audio);
  }
}

Future<Response<dynamic>> _unsurePost(String path, FormData data) async {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: <String, dynamic>{
      'status': 'unsure',
      'retry_requested': true,
      'score': 100,
      'confidence': 80,
      'syllables': <Map<String, dynamic>>[
        <String, dynamic>{
          'label': 'e',
          'expected_tone_label': 'M',
          'reason': 'unsure',
          'native_contour': <double>[0, 1],
          'learner_contour': <double>[0, 1],
        },
      ],
    },
  );
}

Future<Response<dynamic>> _unavailablePost(String path, FormData data) async {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 503,
    data: <String, dynamic>{
      'code': 'scorer_unavailable',
      'retryable': true,
      'score': 0,
    },
  );
}

Future<Response<dynamic>> _scoredPost(String path, FormData data) async {
  expect(path, '/api/ai/score/utterance');
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: <String, dynamic>{
      'scorer_version': 'coach-real',
      'confidence': 0.91,
      'syllables': <Map<String, dynamic>>[
        <String, dynamic>{
          'label': 'e',
          'expected_tone_label': 'M',
          'correct': true,
          'native_contour': <double>[0, 1],
          'learner_contour': <double>[0, 1],
        },
        <String, dynamic>{
          'label': 'ka',
          'expected_tone_label': 'L',
          'correct': false,
          'native_contour': <double>[1, 0],
          'learner_contour': <double>[0, 0],
        },
      ],
    },
  );
}

Future<File> _audioFile() async {
  final File file = File(
    '${Directory.systemTemp.path}/coach_${DateTime.now().microsecondsSinceEpoch}.wav',
  );
  await file.writeAsBytes(<int>[0, 1, 2, 3]);
  return file;
}

Future<void> _delete(File file) async {
  if (await file.exists()) await file.delete();
}

List<String> _digits(WidgetTester tester) {
  final StringBuffer buffer = StringBuffer();
  for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
    final String? data = text.data;
    if (data != null) buffer.writeln(data);
    final InlineSpan? span = text.textSpan;
    if (span != null) buffer.writeln(span.toPlainText());
  }
  return RegExp(r'\d+')
      .allMatches(buffer.toString())
      .map((Match match) => match.group(0)!)
      .toList();
}

void _expectNoPlaceholder(WidgetTester tester) {
  final List<String> digits = _digits(tester);
  expect(digits, isNot(contains('0')));
  expect(digits, isNot(contains('80')));
  expect(digits, isNot(contains('100')));
}

Set<String> _reachableFromMain() {
  final Set<String> seen = <String>{};
  final List<String> queue = <String>['lib/main.dart'];
  final RegExp importPattern = RegExp('''import\\s+['"]([^'"]+)['"]''');
  while (queue.isNotEmpty) {
    final String path = queue.removeLast();
    if (!seen.add(path)) continue;
    final File file = File(path);
    if (!file.existsSync()) continue;
    for (final RegExpMatch match in importPattern.allMatches(
      file.readAsStringSync(),
    )) {
      final String? next = _resolveImport(path, match.group(1)!);
      if (next != null && !seen.contains(next)) queue.add(next);
    }
  }
  return seen;
}

String? _resolveImport(String from, String uri) {
  if (uri.startsWith('package:lingafriq/')) {
    return 'lib/${uri.substring('package:lingafriq/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  final String base = from.substring(0, from.lastIndexOf('/'));
  final List<String> parts = <String>[...base.split('/'), ...uri.split('/')];
  final List<String> out = <String>[];
  for (final String part in parts) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (out.isNotEmpty) out.removeLast();
      continue;
    }
    out.add(part);
  }
  final String resolved = out.join('/');
  if (!resolved.endsWith('.dart')) return null;
  return resolved;
}

Widget _host(Widget child, {double scale = 1, bool reduced = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? built) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Widget _routes() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: (RouteSettings settings) {
      final String raw = settings.name ?? '';
      final String key = raw.startsWith('/') ? raw.substring(1) : raw;
      if (key == ConversationAnalyticsScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ConversationAnalyticsScreen(),
        );
      }
      if (key == RoleplayCompletionSummaryScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RoleplayCompletionSummaryScreen(),
        );
      }
      if (key == RoleplayProgressDashboardScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RoleplayProgressDashboardScreen(),
        );
      }
      return null;
    },
    home: Builder(
      builder: (BuildContext context) {
        return Column(
          children: <Widget>[
            TextButton(
              key: const ValueKey<String>('open-coach'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(ConversationAnalyticsScreen.routePath);
              },
              child: const Text('open-coach'),
            ),
            TextButton(
              key: const ValueKey<String>('open-summary'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(RoleplayCompletionSummaryScreen.routePath);
              },
              child: const Text('open-summary'),
            ),
            TextButton(
              key: const ValueKey<String>('open-progress'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(RoleplayProgressDashboardScreen.routePath);
              },
              child: const Text('open-progress'),
            ),
          ],
        );
      },
    ),
  );
}
