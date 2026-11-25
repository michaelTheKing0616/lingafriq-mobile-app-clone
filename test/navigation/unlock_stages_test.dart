import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/unlock_stages.dart';

final UnlockStages _stages = UnlockStages.parse(
  File(kUnlockStagesAsset).readAsStringSync(),
);

const List<String> _day1 = <String>[
  'today',
  'first_unit',
  'polie_basic',
  'lens',
  'games',
  'word_card',
  'magazine',
  'events',
];

const List<String> _account = <String>[
  'streaks',
  'circles',
  'square',
  'global_handle',
];

const List<String> _week1 = <String>[
  'personas',
  'scenarios',
  'chats',
  'status',
  'practice',
];

const List<String> _a2 = <String>[
  'clips',
  'native_corrections',
  'passport',
  'code_switch',
  'respect',
  'radio',
];

const List<String> _b1 = <String>['create', 'host_rooms', 'mentoring'];

const List<String> _native = <String>['contribute', 'verify'];

const List<String> _callerGames = <String>['a', 'b', 'c', 'd', 'e'];

Set<String> _openIds(UnlockLearner learner) {
  return _stages
      .decideAll(learner)
      .where((UnlockDecision decision) => decision.open)
      .map((UnlockDecision decision) => decision.id)
      .toSet();
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
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipped stage table loads from the config file', () {
    final String raw = File(kUnlockStagesAsset).readAsStringSync();
    expect(raw.contains('\u2014'), isFalse);
    expect(raw.toLowerCase().contains('world-class'), isFalse);
    expect(raw.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(raw), isFalse);
    expect(
      RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(raw),
      isFalse,
    );
    expect(raw.toLowerCase().contains('confidence'), isFalse);
    expect(_stages.version, 1);
    expect(_stages.stages.map((UnlockStage stage) => stage.id), <String>[
      'day_1',
      'account',
      'week_1_or_a1_unit_3',
      'a2',
      'b1',
      'native_speaker',
    ]);
    expect(_stages.stage('day_1').requires, 'none');
    expect(_stages.stage('day_1').opens, _day1);
    expect(_stages.stage('account').requires, 'account');
    expect(_stages.stage('account').opens, <String>[
      'streaks',
      'games',
      ..._account.where((String id) => id != 'streaks'),
    ]);
    expect(
      _stages.stage('week_1_or_a1_unit_3').requires,
      'week_1_or_a1_unit_3',
    );
    expect(_stages.stage('week_1_or_a1_unit_3').opens, _week1);
    expect(_stages.stage('a2').requires, 'level');
    expect(_stages.stage('a2').level, 'A2');
    expect(_stages.stage('a2').opens, _a2);
    expect(_stages.stage('b1').level, 'B1');
    expect(_stages.stage('b1').opens, _b1);
    expect(_stages.stage('native_speaker').requires, 'native_speaker');
    expect(_stages.stage('native_speaker').opens, _native);
    expect(_stages.feature('games').day1Count, 3);
    expect(_stages.feature('games').allOn, 'account');
    expect(_stages.feature('magazine').access, UnlockAccess.readOnly);
    expect(_stages.feature('events').access, UnlockAccess.readOnly);
    expect(_stages.feature('polie_basic').access, UnlockAccess.basic);
    expect(_stages.feature('lens').access, UnlockAccess.pointSay);
    expect(_stages.feature('circles').access, UnlockAccess.join);
    expect(_stages.feature('square').access, UnlockAccess.read);
    expect(_stages.feature('native_corrections').access, UnlockAccess.post);
    expect(_stages.feature('radio').access, UnlockAccess.speak);
    expect(_stages.feature('create').access, UnlockAccess.ugc);
    expect(_stages.feature('chats').safety, UnlockSafety.guardian);
    expect(_stages.feature('chats').adultsOnly, isTrue);
    expect(_stages.feature('calls').safety, UnlockSafety.guardian);
    expect(_stages.feature('calls').stageIds, isEmpty);
    expect(_stages.feature('public_post').safety, UnlockSafety.guardian);
    expect(
      () => UnlockStages.parse('{"version": 1, "note": "a\u2014b"}'),
      throwsFormatException,
    );
    expect(() => UnlockStages.parse('{'), throwsFormatException);
    expect(
      () => _stages.decide(const UnlockLearner(), 'school'),
      throwsArgumentError,
    );
  });

  test('a blank learner is not a native speaker and has no level', () {
    const UnlockLearner learner = UnlockLearner();
    expect(learner.hasAccount, isFalse);
    expect(learner.week1Reached, isFalse);
    expect(learner.level, isNull);
    expect(learner.unit, isNull);
    expect(learner.nativeSpeaker, isFalse);
    expect(learner.minor, isFalse);
  });

  group('AC2 day 1 with no account', () {
    const UnlockLearner learner = UnlockLearner();

    test('opens today, the first unit, Polie basic, Lens, and Word Card', () {
      expect(_openIds(learner), _day1.toSet());
      expect(_stages.decide(learner, 'polie_basic').access, UnlockAccess.basic);
      expect(_stages.decide(learner, 'lens').access, UnlockAccess.pointSay);
      expect(_stages.decide(learner, 'magazine').access, UnlockAccess.readOnly);
      expect(_stages.decide(learner, 'events').access, UnlockAccess.readOnly);
      expect(
        unlockLine(l10nEn(), _stages.decide(learner, 'clips')),
        'Unlocks at A2.',
      );
    });

    test('opens the first 3 games the caller lists and locks the rest', () {
      final UnlockDecision games = _stages.decide(learner, 'games');
      expect(games.open, isTrue);
      expect(games.allGames, isFalse);
      expect(games.gameLimit, 3);
      final UnlockGameAccess slice = _stages.games(learner, _callerGames);
      expect(slice.day1Count, 3);
      expect(slice.allOpen, isFalse);
      expect(slice.openIds, <String>['a', 'b', 'c']);
      expect(slice.lockedIds, <String>['d', 'e']);
      expect(
        _stages.games(learner, const <String>['tone', 'words']).openIds,
        <String>['tone', 'words'],
      );
      expect(_stages.games(learner, const <String>[]).openIds, isEmpty);
      expect(
        _stages.games(learner, const <String>['a', 'a', 'b', 'c', 'd']).openIds,
        <String>['a', 'b', 'c'],
      );
    });

    test('keeps every later feature locked', () {
      for (final String id in <String>[
        ..._account,
        ..._week1,
        ..._a2,
        ..._b1,
        ..._native,
        'calls',
        'public_post',
      ]) {
        final UnlockDecision decision = _stages.decide(learner, id);
        expect(decision.open, isFalse, reason: id);
        expect(decision.canOpenAnyway, isTrue, reason: id);
      }
      expect(_stages.decide(learner, 'contribute').open, isFalse);
      expect(_stages.decide(learner, 'verify').open, isFalse);
    });
  });

  group('AC3 account created', () {
    const UnlockLearner learner = UnlockLearner(hasAccount: true);

    test(
      'unlocks streaks, circles join, square read, and the global handle',
      () {
        expect(_openIds(learner), <String>{..._day1, ..._account});
        expect(_stages.decide(learner, 'circles').access, UnlockAccess.join);
        expect(_stages.decide(learner, 'square').access, UnlockAccess.read);
        expect(_stages.decide(learner, 'personas').open, isFalse);
        expect(_stages.decide(learner, 'clips').open, isFalse);
        expect(learner.week1Reached, isFalse);
        expect(learner.level, isNull);
        expect(learner.nativeSpeaker, isFalse);
      },
    );

    test('unlocks every game the caller lists', () {
      final UnlockGameAccess slice = _stages.games(learner, _callerGames);
      expect(slice.allOpen, isTrue);
      expect(slice.openIds, _callerGames);
      expect(slice.lockedIds, isEmpty);
      expect(_stages.games(learner, const <String>[]).openIds, isEmpty);
      expect(_stages.decide(learner, 'games').allGames, isTrue);
      expect(_stages.decide(learner, 'games').gameLimit, isNull);
    });
  });

  group('AC4 week 1 or A1 unit 3', () {
    test('week 1 unlocks personas, scenarios, chats, status, and practice', () {
      const UnlockLearner learner = UnlockLearner(week1Reached: true);
      expect(_openIds(learner), <String>{..._day1, ..._week1});
      expect(_stages.decide(learner, 'chats').open, isTrue);
      expect(_stages.decide(learner, 'clips').open, isFalse);
      expect(_stages.decide(learner, 'streaks').open, isFalse);
      expect(learner.hasAccount, isFalse);
      expect(learner.level, isNull);
    });

    test('A1 unit 3 unlocks the same set without week 1', () {
      const UnlockLearner learner = UnlockLearner(level: 'A1', unit: 3);
      expect(_openIds(learner), <String>{..._day1, ..._week1});
      expect(learner.week1Reached, isFalse);
      expect(_stages.decide(learner, 'practice').open, isTrue);
      expect(_stages.decide(learner, 'clips').open, isFalse);
    });

    test('A1 unit 2 does not unlock that set', () {
      const UnlockLearner learner = UnlockLearner(level: 'A1', unit: 2);
      expect(_stages.decide(learner, 'personas').open, isFalse);
      expect(_stages.decide(learner, 'status').open, isFalse);
      expect(_openIds(learner), _day1.toSet());
    });

    test('A1 with no unit does not unlock that set', () {
      expect(
        _stages.decide(const UnlockLearner(level: 'a1'), 'scenarios').open,
        isFalse,
      );
    });

    test('chats stay locked for a minor', () {
      const UnlockLearner learner = UnlockLearner(
        week1Reached: true,
        minor: true,
      );
      expect(_stages.decide(learner, 'chats').open, isFalse);
      expect(_stages.decide(learner, 'chats').safetyLocked, isTrue);
      expect(_stages.decide(learner, 'chats').canOpenAnyway, isFalse);
      expect(_stages.decide(learner, 'personas').open, isTrue);
      expect(
        unlockLine(l10nEn(), _stages.decide(learner, 'chats')),
        'A guardian must open this.',
      );
      final UnlockOpening opening = _stages.open(
        learner,
        'chats',
        anyway: true,
      );
      expect(opening.opened, isFalse);
      expect(opening.safetyLocked, isTrue);
      expect(learner.nativeSpeaker, isFalse);
    });
  });

  group('AC5 A2, B1, and native speakers', () {
    test(
      'A2 unlocks clips, corrections, passport, coaches, and radio speak',
      () {
        const UnlockLearner learner = UnlockLearner(level: 'A2');
        expect(_stages.decide(learner, 'clips').open, isTrue);
        expect(
          _stages.decide(learner, 'native_corrections').access,
          UnlockAccess.post,
        );
        expect(_stages.decide(learner, 'native_corrections').open, isTrue);
        expect(_stages.decide(learner, 'passport').open, isTrue);
        expect(_stages.decide(learner, 'code_switch').open, isTrue);
        expect(_stages.decide(learner, 'respect').open, isTrue);
        expect(_stages.decide(learner, 'radio').access, UnlockAccess.speak);
        expect(_stages.decide(learner, 'radio').open, isTrue);
        expect(_stages.decide(learner, 'personas').open, isTrue);
        expect(_stages.decide(learner, 'create').open, isFalse);
        expect(_stages.decide(learner, 'host_rooms').open, isFalse);
        expect(_stages.decide(learner, 'mentoring').open, isFalse);
        expect(_stages.decide(learner, 'contribute').open, isFalse);
        expect(_stages.decide(learner, 'verify').open, isFalse);
        expect(learner.nativeSpeaker, isFalse);
        expect(learner.week1Reached, isFalse);
      },
    );

    test('B1 unlocks create, host rooms, and mentoring', () {
      const UnlockLearner learner = UnlockLearner(level: 'b1');
      expect(_stages.decide(learner, 'create').open, isTrue);
      expect(_stages.decide(learner, 'create').access, UnlockAccess.ugc);
      expect(_stages.decide(learner, 'host_rooms').open, isTrue);
      expect(_stages.decide(learner, 'mentoring').open, isTrue);
      expect(_stages.decide(learner, 'clips').open, isTrue);
      expect(_stages.decide(learner, 'contribute').open, isFalse);
      expect(_stages.decide(learner, 'verify').open, isFalse);
      expect(learner.nativeSpeaker, isFalse);
    });

    test('a high level does not mark a native speaker', () {
      const UnlockLearner learner = UnlockLearner(level: 'C2');
      expect(_stages.decide(learner, 'mentoring').open, isTrue);
      expect(_stages.decide(learner, 'contribute').open, isFalse);
      expect(_stages.decide(learner, 'verify').open, isFalse);
      expect(
        unlockLine(l10nEn(), _stages.decide(learner, 'contribute')),
        'Unlocks for native speakers.',
      );
    });

    test('native speakers open contribute and verify at any level', () {
      const UnlockLearner learner = UnlockLearner(nativeSpeaker: true);
      expect(learner.level, isNull);
      expect(learner.hasAccount, isFalse);
      expect(_stages.decide(learner, 'contribute').open, isTrue);
      expect(_stages.decide(learner, 'verify').open, isTrue);
      expect(_stages.decide(learner, 'create').open, isFalse);
      expect(_stages.decide(learner, 'clips').open, isFalse);
      expect(_openIds(learner), <String>{..._day1, ..._native});

      const UnlockLearner early = UnlockLearner(
        nativeSpeaker: true,
        level: 'A1',
        unit: 1,
      );
      expect(_stages.decide(early, 'contribute').open, isTrue);
      expect(_stages.decide(early, 'verify').open, isTrue);
      expect(_stages.decide(early, 'personas').open, isFalse);

      const UnlockLearner both = UnlockLearner(
        nativeSpeaker: true,
        level: 'B1',
      );
      expect(_stages.decide(both, 'contribute').open, isTrue);
      expect(_stages.decide(both, 'create').open, isTrue);
    });
  });

  test('open anyway does not invent progress', () {
    const UnlockLearner learner = UnlockLearner();
    final UnlockOpening held = _stages.open(learner, 'clips');
    expect(held.opened, isFalse);
    expect(held.anyway, isFalse);
    final UnlockOpening opened = _stages.open(learner, 'clips', anyway: true);
    expect(opened.opened, isTrue);
    expect(opened.anyway, isTrue);
    expect(opened.featureId, 'clips');
    expect(learner.level, isNull);
    expect(learner.hasAccount, isFalse);
    expect(learner.week1Reached, isFalse);
    expect(learner.nativeSpeaker, isFalse);
    expect(learner.minor, isFalse);
    expect(_stages.games(learner, _callerGames).openIds, <String>[
      'a',
      'b',
      'c',
    ]);
    expect(_stages.decide(learner, 'clips').open, isFalse);
    final UnlockOpening calls = _stages.open(learner, 'calls', anyway: true);
    expect(calls.opened, isTrue);
    expect(_stages.decide(learner, 'calls').open, isFalse);
  });

  test('a minor guardian gate stays locked', () {
    const UnlockLearner learner = UnlockLearner(minor: true, hasAccount: true);
    for (final String id in <String>['calls', 'public_post', 'chats']) {
      final UnlockDecision decision = _stages.decide(learner, id);
      expect(decision.open, isFalse, reason: id);
      expect(decision.safetyLocked, isTrue, reason: id);
      expect(decision.canPreview, isTrue, reason: id);
      expect(decision.canOpenAnyway, isFalse, reason: id);
      final UnlockOpening opening = _stages.open(learner, id, anyway: true);
      expect(opening.opened, isFalse, reason: id);
      expect(opening.safetyLocked, isTrue, reason: id);
    }
    expect(_stages.decide(learner, 'square').open, isTrue);
    expect(_stages.decide(learner, 'games').allGames, isTrue);
    expect(_stages.decide(learner, 'clips').canOpenAnyway, isFalse);
  });

  testWidgets('AC1 an adult open anyway opens the locked feature', (
    tester,
  ) async {
    const UnlockLearner learner = UnlockLearner();
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        UnlockFeatureEntry(
          stages: _stages,
          learner: learner,
          featureId: 'clips',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(UnlockGate.featureKey('clips')));
    expect(find.byKey(UnlockGate.gateKey), findsOneWidget);
    expect(find.text('Clips'), findsWidgets);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Unlocks at A2.'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Open anyway'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(UnlockGate.gateKey)).label,
      'Clips, Locked. Unlocks at A2.',
    );

    await _tap(tester, find.byKey(UnlockGate.previewKey));
    expect(find.byKey(UnlockGate.previewBodyKey), findsOneWidget);
    expect(
      find.text('This preview does not mark a lesson done.'),
      findsOneWidget,
    );
    expect(find.byKey(UnlockGate.openedKey), findsNothing);
    expect(find.text('Clips is open.'), findsNothing);
    expect(learner.level, isNull);

    await _tap(tester, find.byKey(UnlockGate.backKey));
    expect(find.text('Open anyway'), findsOneWidget);

    await _tap(tester, find.byKey(UnlockGate.openAnywayKey));
    expect(find.byKey(UnlockGate.openedKey), findsOneWidget);
    expect(find.text('Clips is open.'), findsOneWidget);
    expect(find.text('Open anyway'), findsNothing);
    expect(learner.hasAccount, isFalse);
    expect(learner.level, isNull);
    expect(learner.nativeSpeaker, isFalse);
    expect(learner.week1Reached, isFalse);
    expect(_stages.decide(learner, 'clips').open, isFalse);
    handle.dispose();
  });

  testWidgets('AC1 a minor guardian gate does not offer open anyway', (
    tester,
  ) async {
    const UnlockLearner learner = UnlockLearner(
      minor: true,
      week1Reached: true,
    );
    await tester.pumpWidget(
      _host(
        UnlockFeatureEntry(
          stages: _stages,
          learner: learner,
          featureId: 'chats',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(UnlockGate.featureKey('chats')));
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('A guardian must open this.'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Open anyway'), findsNothing);
    expect(find.text('Unlocks at Week 1 or A1 unit 3.'), findsNothing);
    expect(find.byKey(UnlockGate.openAnywayKey), findsNothing);

    final UnlockOpening opening = _stages.open(learner, 'chats', anyway: true);
    expect(opening.opened, isFalse);
    expect(opening.safetyLocked, isTrue);
    expect(find.byKey(UnlockGate.openedKey), findsNothing);
  });

  testWidgets('an open day 1 feature opens without a lock', (tester) async {
    await tester.pumpWidget(
      _host(
        UnlockFeatureEntry(
          stages: _stages,
          learner: const UnlockLearner(),
          featureId: 'today',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(UnlockGate.featureKey('today')));
    expect(find.byKey(UnlockGate.openedKey), findsOneWidget);
    expect(find.text('Today is open.'), findsOneWidget);
    expect(find.text('Open anyway'), findsNothing);
    expect(find.text('Locked'), findsNothing);
  });

  testWidgets('the gate wraps at 200 percent and keeps a 48 target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        UnlockFeatureEntry(
          stages: _stages,
          learner: const UnlockLearner(),
          featureId: 'passport',
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _tap(tester, find.byKey(UnlockGate.featureKey('passport')));
    expect(find.text('Unlocks at A2.'), findsOneWidget);
    final Finder open = find.byKey(UnlockGate.openAnywayKey);
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(open).height,
      greaterThanOrEqualTo(LingAfriqTokens.spacing48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion still shows preview and open anyway', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        UnlockFeatureEntry(
          stages: _stages,
          learner: const UnlockLearner(),
          featureId: 'mentoring',
        ),
        reduced: true,
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(UnlockGate.featureKey('mentoring')));
    expect(find.text('Unlocks at B1.'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Open anyway'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
