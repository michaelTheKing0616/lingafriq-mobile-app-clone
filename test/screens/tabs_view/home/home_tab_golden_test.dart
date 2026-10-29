import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:lingafriq/screens/tabs_view/home/home_parts.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../../compliance/golden_kit.dart';

Language _lang(int id, String name, {int score = 0, bool published = true}) =>
    Language(
      id: id,
      total_score: score,
      total_count: 10,
      completed: 0,
      name: name,
      background: '',
      Inrtoduction: '',
      is_published: published,
      is_featured: false,
      level_language: 'A1',
    );

class _User extends UserProvider {
  @override
  ProfileModel? build() => ProfileModel(
    id: 1,
    email: 'ada@example.com',
    username: 'Ada',
    first_name: 'Ada',
    last_name: 'Lovelace',
    is_current_user: true,
    rank: null,
    nationality: 'NG',
    agree_to_privacy_terms: true,
    avatar: null,
    completed_point: 0,
    streak: 5,
  );
}

class _Goals extends DailyGoalsProvider {
  @override
  BaseProviderState build() => BaseProviderState();
}

// Day 2 -> "Karibu" (Swahili), a stable word for goldens.
List<Override> _overrides(
  List<Language> langs, {
  int day = 2,
  Future<LanguageResponse> Function()? load,
  AgeTierStatus? tier,
}) => [
  languagesProvider.overrideWith(
    (ref) =>
        load?.call() ??
        Future.value(
          LanguageResponse(
            count: langs.length,
            next: null,
            previous: null,
            results: langs,
          ),
        ),
  ),
  userProvider.overrideWith(_User.new),
  dailyGoalsProvider.overrideWith(_Goals.new),
  ageTierStatusProvider.overrideWith((ref) async => tier),
  homeClockProvider.overrideWithValue(() => DateTime(2026, 10, day)),
];

final _langs = [
  _lang(1, 'Swahili', score: 40),
  _lang(2, 'Yoruba'),
  _lang(5, 'Hausa'),
  _lang(3, 'Zulu', published: false),
];

/// Bundled tile illustrations decode off the fake clock; finish them so
/// goldens show the art, not a blank frame.
Future<void> _precacheArt(WidgetTester tester) async {
  final ctx = tester.element(find.byType(HomeTabMaterial3));
  await tester.runAsync(() async {
    for (final a in kLanguageArtAssets.values) {
      await precacheImage(AssetImage(a), ctx);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _stateGolden(
  WidgetTester tester,
  String name,
  List<Override> overrides, {
  GoldenVariant? variant,
}) async {
  final v = variant ?? goldenVariants.first;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await pumpVariant(tester, v, const HomeTabMaterial3(), overrides: overrides);
  expectNoLayoutErrors(tester);
  await expectLater(
    find.byType(HomeTabMaterial3),
    matchesGoldenFile('goldens/home_state_$name.png'),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await loadComplianceFonts(
      'test/screens/tabs_view/home/home_tab_golden_test.dart',
    );
  });

  for (final v in goldenVariants) {
    testWidgets('home golden ${v.name}', (tester) async {
      await pumpVariant(
        tester,
        v,
        const HomeTabMaterial3(),
        overrides: _overrides(_langs),
      );
      await _precacheArt(tester);
      expectNoLayoutErrors(tester);
      await expectLater(
        find.byType(HomeTabMaterial3),
        matchesGoldenFile('goldens/home_${v.name}.png'),
      );
    });
  }

  testWidgets(
    'Continue card shows only for an in-progress published language',
    (tester) async {
      await pumpVariant(
        tester,
        goldenVariants.first,
        const HomeTabMaterial3(),
        overrides: _overrides(_langs),
      );
      expect(find.byKey(const Key('home-continue-card')), findsOneWidget);
      expect(find.text('Continue Swahili'), findsOneWidget);
    },
  );

  testWidgets('no Continue card when nothing is in progress', (tester) async {
    await pumpVariant(
      tester,
      goldenVariants.first,
      const HomeTabMaterial3(),
      overrides: _overrides([
        _lang(2, 'Yoruba'),
        _lang(4, 'Igbo', score: 30, published: false),
      ]),
    );
    expect(find.byKey(const Key('home-continue-card')), findsNothing);
  });

  testWidgets('word of the day is localised and hidden for plain Welcome', (
    tester,
  ) async {
    final fr = goldenVariants.first;
    await pumpVariant(
      tester,
      GoldenVariant('fr', fr.size, locale: const Locale('fr')),
      const HomeTabMaterial3(),
      overrides: _overrides(_langs),
    );
    expect(
      find.text('Mot du jour : Karibu, « bienvenue » en swahili'),
      findsOneWidget,
    );
    await pumpVariant(
      tester,
      goldenVariants[1],
      const HomeTabMaterial3(),
      overrides: _overrides(_langs),
    );
    expect(
      find.text('كلمة اليوم: Karibu، وتعني «مرحبًا» في السواحيلية'),
      findsOneWidget,
    );
    // day 6 -> index 6 -> plain "Welcome": nothing to teach.
    await pumpVariant(
      tester,
      fr,
      const HomeTabMaterial3(),
      overrides: _overrides(_langs, day: 6),
    );
    expect(find.byKey(const Key('home-word-of-day')), findsNothing);
  });

  testWidgets('goal ring announces progress', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpVariant(
      tester,
      goldenVariants.first,
      const HomeTabMaterial3(),
      overrides: _overrides(_langs),
    );
    expect(find.byKey(const Key('home-goal-ring')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r"^Today's goal progress: \d+%$")),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('designed states', () {
    testWidgets('loading skeleton', (tester) async {
      await _stateGolden(
        tester,
        'loading',
        _overrides(const [], load: () => Completer<LanguageResponse>().future),
      );
      expect(find.byKey(const Key('home-skeleton')), findsOneWidget);
      expect(find.textContaining('Loading your languages'), findsOneWidget);
    });

    testWidgets('server error with retry', (tester) async {
      var calls = 0;
      await _stateGolden(
        tester,
        'error',
        _overrides(
          const [],
          load: () {
            calls++;
            return Future.error(Exception('500 Internal Server Error'));
          },
        ),
      );
      expect(find.byKey(const Key('home-state-error')), findsOneWidget);
      expect(find.text("We couldn't load your languages"), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(calls, 2, reason: 'Try Again refetches');
    });

    testWidgets('offline', (tester) async {
      await _stateGolden(
        tester,
        'offline',
        _overrides(
          const [],
          load: () =>
              Future.error(Exception('SocketException: Failed host lookup')),
        ),
      );
      expect(find.byKey(const Key('home-state-offline')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _stateGolden(tester, 'empty', _overrides(const []));
      expect(find.byKey(const Key('home-state-empty')), findsOneWidget);
      expect(find.text('Search Languages'), findsOneWidget);
    });

    testWidgets('kids mode banner, lessons still open', (tester) async {
      await _stateGolden(
        tester,
        'kids',
        _overrides(
          _langs,
          tier: AgeTierStatus(assigned: true, tier: 'child', status: 'active'),
        ),
      );
      expect(find.byKey(const Key('home-kids-banner')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Kids mode is on')), findsOneWidget);
      expect(find.byKey(const Key('home-continue-card')), findsOneWidget);
    });

    testWidgets('French home', (tester) async {
      await _stateGolden(
        tester,
        'fr',
        _overrides(_langs),
        variant: GoldenVariant(
          'fr_390',
          goldenVariants.first.size,
          locale: const Locale('fr'),
        ),
      );
      expect(find.text('Continuer : Swahili'), findsOneWidget);
    });
  });

  testWidgets('each language gets its own art, never the generic globe', (
    tester,
  ) async {
    await pumpVariant(
      tester,
      goldenVariants.first,
      const HomeTabMaterial3(),
      overrides: _overrides(_langs),
    );
    expect(find.byIcon(Icons.language), findsNothing);
    expect(find.byType(LanguageArt), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('lang-art-image')),
      findsOneWidget,
      reason: 'Hausa uses its bundled illustration',
    );
    expect(find.byKey(const ValueKey('lang-art-monogram')), findsNWidgets(3));
    expect(languageTileColor('Swahili'), languageTileColor('Swahili'));
    expect(
      languageTileColor('Swahili') == languageTileColor('Yoruba') &&
          languageTileColor('Yoruba') == languageTileColor('Zulu'),
      isFalse,
    );
    expect(languageMonogram('Ẹdo'), 'Ẹ');
  });
}
