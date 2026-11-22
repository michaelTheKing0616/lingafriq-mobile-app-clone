import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_speak.dart';
import 'package:lingafriq/screens/tutor/shadowing_exercise_screen.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';

const String _practiceCopy =
    'Pronunciation scoring is unavailable. You can keep practising without a ranked score.';

const String _unsureCopy =
    'We could not score this clearly. No score is shown.';

const ShadowingClip _clip = ShadowingClip(
  id: 'clip-1',
  text: 'E kaaro',
  language: 'yoruba',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app registers /speak/shadowing and main can reach the screen', () {
    expect(ShadowingExerciseScreen.routePath, '/speak/shadowing');
    expect(ShadowingExerciseScreen.routeKey, 'speak/shadowing');
    expect(SpeakRoutes.shadowing, ShadowingExerciseScreen.routePath);
    expect(SpeakRoutes.paths, contains(SpeakRoutes.shadowing));
    expect(SpeakRoutes.isRegistered(SpeakRoutes.shadowing), isTrue);
    expect(
      SpeakRoutes.openingFor(SpeakRoutes.shadowing),
      isA<SpeakShadowingOpening>(),
    );
    final SpeakPlace place = SpeakRoutes.places.singleWhere(
      (SpeakPlace item) => item.id == 'shadowing',
    );
    expect(place.kind, SpeakPlaceKind.ready);
    expect(place.path, '/speak/shadowing');

    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('ShadowingExerciseScreen.routeKey'));
    expect(
      app,
      contains("import 'screens/tutor/shadowing_exercise_screen.dart'"),
    );
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains("import 'my_app.dart'"),
    );
    expect(
      _reachableFromMain(),
      contains('lib/screens/tutor/shadowing_exercise_screen.dart'),
    );

    final String screen = File(
      'lib/screens/tutor/shadowing_exercise_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('RealScorerSpeakingEngine'));
    expect(screen, isNot(contains('shadowingExercise')));
    expect(screen, isNot(contains('\u2014')));
    expect(_practiceCopy.contains('\u2014'), isFalse);
    expect(_practiceCopy.endsWith('.'), isTrue);
    expect(_practiceCopy.split('. '), <String>[
      'Pronunciation scoring is unavailable',
      'You can keep practising without a ranked score.',
    ]);
  });

  test('a percent is kept only for a real scorer result', () {
    final GameScore real = GameScore(
      accuracy: 0.5,
      isPerfect: false,
      isFail: false,
      confidence: 0.91,
      source: GameScoreSource.realScorer,
      countsForRewards: true,
    );
    expect(shadowingShownPercent(real), 50);
    expect(shadowingStatusForScore(real), ShadowingPageStatus.scored);

    final GameScore unsure = GameScore.unsure(message: 'unsure');
    expect(shadowingShownPercent(unsure), isNull);
    expect(shadowingStatusForScore(unsure), ShadowingPageStatus.unsure);

    final GameScore practice = GameScore.honestPractice(message: 'unavailable');
    expect(shadowingShownPercent(practice), isNull);
    expect(shadowingStatusForScore(practice), ShadowingPageStatus.practice);

    final GameScore down = GameScore.scorerError(message: 'down');
    expect(shadowingShownPercent(down), isNull);
    expect(shadowingStatusForScore(down), ShadowingPageStatus.practice);

    final GameScore invented = GameScore.correct(accuracy: 0.8);
    expect(invented.source, GameScoreSource.local);
    expect(shadowingShownPercent(invented), isNull);
    expect(shadowingStatusForScore(invented), ShadowingPageStatus.practice);

    final GameScore perfectLocal = GameScore.correct(accuracy: 1);
    expect(shadowingShownPercent(perfectLocal), isNull);
  });

  testWidgets('Speak hub entry opens /speak/shadowing', (tester) async {
    await tester.pumpWidget(_host(const SpeakHub()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeakHub.placeKey('shadowing')));
    await tester.pumpAndSettle();

    expect(find.byType(ShadowingExerciseScreen), findsOneWidget);
    expect(find.byType(SpeakNotAvailablePage), findsNothing);
    final ModalRoute<dynamic> route = ModalRoute.of(
      tester.element(find.byType(ShadowingExerciseScreen)),
    )!;
    expect(route.settings.name, '/speak/shadowing');
    expect(find.byKey(ShadowingExerciseScreen.emptyKey), findsOneWidget);
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('the registered route opens the screen from the shell map', (
    tester,
  ) async {
    await tester.pumpWidget(_routes());
    await tester.tap(find.byKey(const ValueKey<String>('open-shadowing')));
    await tester.pumpAndSettle();
    expect(find.byType(ShadowingExerciseScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(ShadowingExerciseScreen)),
      )!.settings.name,
      ShadowingExerciseScreen.routePath,
    );
    expect(find.byKey(ShadowingExerciseScreen.emptyKey), findsOneWidget);
  });

  testWidgets('no clip shows the empty state', (tester) async {
    await tester.pumpWidget(
      _host(ShadowingExerciseScreen(loadClip: () async => null)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.emptyKey), findsOneWidget);
    expect(find.text('No clip is ready.'), findsOneWidget);
    expect(find.byType(LingErrorState), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('no attempt shows the empty state', (tester) async {
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.emptyKey), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.clipKey), findsOneWidget);
    expect(find.text('No attempt yet.'), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.attemptKey), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a load error shows the error state and no score', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(loadClip: () async => throw StateError('load')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.errorKey), findsOneWidget);
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('Shadowing did not open.'), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.attemptKey), findsNothing);
    expect(find.text('50%'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a real scorer result shows its percent', (tester) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_scoredPost),
    ))!;
    expect(score.source, GameScoreSource.realScorer);
    expect(shadowingShownPercent(score), 50);
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async =>
              const ShadowingAttempt(audioPath: 'clip.wav'),
          scoreAttempt: (ShadowingClip clip, ShadowingAttempt attempt) async {
            return score;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.attemptKey), findsOneWidget);
    expect(_digits(tester), <String>['50']);
    expect(find.byKey(ShadowingExerciseScreen.practiceKey), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.unsureKey), findsNothing);
  });

  testWidgets('a score error clears the previous attempt and score', (
    tester,
  ) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_scoredPost),
    ))!;
    var fail = false;
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async =>
              const ShadowingAttempt(audioPath: 'clip.wav'),
          scoreAttempt: (ShadowingClip clip, ShadowingAttempt attempt) async {
            if (fail) throw StateError('score');
            return score;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);

    fail = true;
    await tester.tap(find.byKey(ShadowingExerciseScreen.recordKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ShadowingExerciseScreen.errorKey), findsOneWidget);
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('The attempt was not scored.'), findsOneWidget);
    expect(find.text('50%'), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.attemptKey), findsNothing);
    expect(find.text('E kaaro'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('an unsure scorer shows no placeholder number', (tester) async {
    final GameScore score = (await tester.runAsync(
      () => _engineScore(_unsurePost),
    ))!;
    expect(score.isUnsure, isTrue);
    expect(shadowingShownPercent(score), isNull);
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async =>
              const ShadowingAttempt(audioPath: 'clip.wav'),
          scoreAttempt: (ShadowingClip clip, ShadowingAttempt attempt) async {
            return score;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.unsureKey), findsOneWidget);
    expect(find.text(_unsureCopy), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.byKey(ShadowingExerciseScreen.attemptKey), findsNothing);
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
    expect(shadowingShownPercent(score), isNull);
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async =>
              const ShadowingAttempt(audioPath: 'clip.wav'),
          scoreAttempt: (ShadowingClip clip, ShadowingAttempt attempt) async {
            return score;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.practiceKey), findsOneWidget);
    expect(find.text(_practiceCopy), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.byType(LingErrorState), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('a local score is not shown as a number', (tester) async {
    await tester.pumpWidget(
      _host(
        ShadowingExerciseScreen(
          loadClip: () async => _clip,
          readAttempt: () async =>
              const ShadowingAttempt(audioPath: 'clip.wav'),
          scoreAttempt: (ShadowingClip clip, ShadowingAttempt attempt) async {
            return GameScore.correct(accuracy: 0.8);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.practiceKey), findsOneWidget);
    expect(find.byKey(ShadowingExerciseScreen.scoreKey), findsNothing);
    expect(find.text('80%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets('empty state at 200% text does not throw', (tester) async {
    await tester.pumpWidget(_host(const ShadowingExerciseScreen(), scale: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(ShadowingExerciseScreen.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<GameScore> _engineScore(LensScorePost post) async {
  final File audio = await _audioFile();
  try {
    return await scoreShadowingAttempt(
      clip: _clip,
      attempt: ShadowingAttempt(audioPath: audio.path),
      post: post,
    );
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
      'scorer_version': 'shadow-real',
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
    '${Directory.systemTemp.path}/shadowing_${DateTime.now().microsecondsSinceEpoch}.wav',
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
  expect(
    digits.where(
      (String digit) => digit == '0' || digit == '80' || digit == '100',
    ),
    isEmpty,
  );
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

Widget _host(Widget child, {double scale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? built) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(textScaler: TextScaler.linear(scale)),
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
      if (key == ShadowingExerciseScreen.routeKey) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ShadowingExerciseScreen(),
        );
      }
      return null;
    },
    home: Builder(
      builder: (BuildContext context) {
        return TextButton(
          key: const ValueKey<String>('open-shadowing'),
          onPressed: () {
            Navigator.of(context).pushNamed(ShadowingExerciseScreen.routePath);
          },
          child: const Text('open-shadowing'),
        );
      },
    ),
  );
}
