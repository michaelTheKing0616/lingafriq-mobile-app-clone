import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/leaderboard_entry_model.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/gamification_state.dart';
import 'package:lingafriq/providers/leaderboard_provider.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/services/gamification/socket_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

LeaderboardEntry _e(String id, String name, int xp, int rank, {int? prev}) =>
    LeaderboardEntry(
      userId: id,
      username: name,
      xp: xp,
      level: 3,
      levelTitle: 'Griot',
      dailyStreak: rank * 2,
      rank: rank,
      previousRank: prev,
    );

final _board = [
  _e('7', 'Chiamaka', 1840, 1, prev: 2),
  _e('8', 'Kwame', 1720, 2, prev: 1),
  _e('9', 'Amina', 1610, 3),
  _e('1', 'Ada', 1490, 4, prev: 7),
  _e('10', 'Tendai', 1200, 5),
  _e('11', 'Zanele', 990, 6, prev: 5),
  _e('12', 'Yusuf', 870, 7),
];

/// Fake board: canned lists, records fetches, optional error.
class _Lb extends LeaderboardProvider {
  _Lb({
    this.global = const [],
    this.tribe = const [],
    this.loading = false,
    this.error,
  });
  final List<LeaderboardEntry> global, tribe;
  final bool loading;
  String? error;
  final fetched = <LeaderboardType>[];

  @override
  BaseProviderState build() =>
      BaseProviderState(isLoading: loading, errorMessage: error);

  @override
  List<LeaderboardEntry> getGlobalLeaderboard() => _g;
  List<LeaderboardEntry> get _g => error != null ? const [] : global;

  @override
  List<LeaderboardEntry> getTribeLeaderboard(String t) => tribe;

  @override
  List<LeaderboardEntry> getCountryLeaderboard(String c) => _g;

  @override
  Map<String, dynamic>? get userRanks => null;

  @override
  Future<void> fetchUserRanks(String userId) async {}

  @override
  Future<void> fetchLeaderboards({
    LeaderboardType type = LeaderboardType.global,
    String? tribe,
    String? country,
    String? continent,
    bool forceRefresh = false,
  }) async => fetched.add(type);

  @override
  Future<void> refresh({
    LeaderboardType type = LeaderboardType.global,
    String? tribe,
    String? country,
    String? continent,
  }) async {
    fetched.add(type);
    error = null;
    state = BaseProviderState();
  }
}

class _User extends UserProvider {
  @override
  ProfileModel? build() => ProfileModel(
    id: 1,
    email: 'ada@example.com',
    username: 'Ada',
    first_name: 'Ada',
    last_name: 'L',
    is_current_user: true,
    rank: null,
    nationality: 'NG',
    agree_to_privacy_terms: true,
    avatar: null,
    completed_point: 0,
    streak: 5,
  );
}

class _Gam extends GamificationProvider {
  _Gam(this.tribe);
  final String? tribe;
  @override
  GamificationState build() =>
      GamificationState(gamification: UserGamificationModel(tribe: tribe));
}

late _Lb _lb;

List<Override> _o({
  _Lb? board,
  bool online = true,
  String? tier,
  String? tribe = 'Yoruba',
}) {
  _lb = board ?? _Lb(global: _board, tribe: _board.take(3).toList());
  return [
    leaderboardProvider.overrideWith(() => _lb),
    userProvider.overrideWith(_User.new),
    gamificationProvider.overrideWith(() => _Gam(tribe)),
    socketServiceProvider.overrideWithValue(GamificationSocketService()),
    leaderboardOnlineProvider.overrideWith((ref) async => online),
    ageTierStatusProvider.overrideWith(
      (ref) async => tier == null
          ? null
          : AgeTierStatus(assigned: true, tier: tier, status: 'active'),
    ),
  ];
}

Future<void> _pump(
  WidgetTester t,
  GoldenVariant v,
  List<Override> o, {
  bool settle = true,
}) async {
  await pumpVariant(
    t,
    v,
    const LeaderboardScreen(),
    overrides: o,
    settle: settle,
  );
  if (!settle) await t.pump(const Duration(milliseconds: 50));
}

String _texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/gamification/leaderboard_screen_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
    const GoldenVariant('tablet_820', Size(820, 1180)),
  ]) {
    testWidgets('leaderboard golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('goldens/leaderboard_${v.name}.png'),
      );
    });
  }

  for (final (name, make, settle) in [
    ('loading', () => _o(board: _Lb(loading: true)), false),
    (
      'error',
      () => _o(
        board: _Lb(global: _board, error: 'x'),
      ),
      true,
    ),
    (
      'offline',
      () => _o(
        board: _Lb(global: _board, error: 'x'),
        online: false,
      ),
      true,
    ),
    ('empty', () => _o(board: _Lb()), true),
    ('child', () => _o(tier: 'child'), true),
    ('teen', () => _o(tier: 'teen'), true),
  ]) {
    testWidgets('leaderboard state golden $name', (t) async {
      await _pump(t, base, make(), settle: settle);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('goldens/leaderboard_state_$name.png'),
      );
    });
  }

  testWidgets('champion, medals, movement and pinned self row', (t) async {
    await _pump(t, base, _o());
    expect(
      find.descendant(
        of: find.byKey(const Key('lb-champion')),
        matching: find.text('Chiamaka'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Rank 4, You, 1490 XP, Up 3 places')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Rank 2, Kwame, 1720 XP, Down 1')),
      findsOneWidget,
    );
    expect(find.text('Your rank: #4'), findsOneWidget);
    expect(find.text('Ada'), findsNothing, reason: 'self shown as You');
  });

  testWidgets('switching scope fetches that board', (t) async {
    await _pump(t, base, _o());
    await t.tap(find.byKey(const Key('lb-tab-tribe')));
    await t.pumpAndSettle();
    expect(_lb.fetched, contains(LeaderboardType.tribe));
    expect(find.byKey(const Key('lb-list-tribe')), findsOneWidget);
    expect(find.byKey(const Key('lb-row-10')), findsNothing);
  });

  testWidgets('no tribe shows pick-a-tribe, without fetching', (t) async {
    await _pump(t, base, _o(tribe: null));
    await t.tap(find.byKey(const Key('lb-tab-tribe')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lb-no-tribe')), findsOneWidget);
    expect(_lb.fetched, isNot(contains(LeaderboardType.tribe)));
    await expectLater(
      find.byType(LeaderboardScreen),
      matchesGoldenFile('goldens/leaderboard_state_no_tribe.png'),
    );
  });

  testWidgets('error retry reloads the board', (t) async {
    await _pump(
      t,
      base,
      _o(
        board: _Lb(global: _board, error: 'x'),
      ),
    );
    expect(find.byKey(const Key('lb-error')), findsOneWidget);
    await t.tap(find.byKey(const Key('lb-retry')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lb-champion')), findsOneWidget);
  });

  testWidgets('child sees no other learner names', (t) async {
    await _pump(t, base, _o(tier: 'child'));
    final s = _texts(t);
    for (final n in ['Chiamaka', 'Kwame', 'Amina', 'Tendai']) {
      expect(s, isNot(contains(n)));
    }
    expect(s, contains('Learner 1'));
    expect(find.byKey(const Key('lb-minor-note')), findsOneWidget);
  });

  testWidgets('teen sees privacy note', (t) async {
    await _pump(t, base, _o(tier: 'teen'));
    expect(find.textContaining('Your profile is private'), findsOneWidget);
  });

  testWidgets('RTL: back arrow mirrors and names are isolated', (t) async {
    await _pump(t, goldenVariants[1], _o());
    final back = find.byKey(const Key('lb-back'));
    expect(t.getCenter(back).dx, greaterThan(300));
    expect(find.text('لوحة الصدارة'), findsOneWidget);
    final name = t.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('lb-champion')),
        matching: find.text('Chiamaka'),
      ),
    );
    expect(name.textDirection, TextDirection.ltr);
  });

  testWidgets('targets are at least 48dp', (t) async {
    await _pump(t, goldenVariants[3], _o());
    for (final k in ['lb-back', 'lb-tab-global', 'lb-tab-tribe']) {
      expect(t.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(48));
    }
  });
}
