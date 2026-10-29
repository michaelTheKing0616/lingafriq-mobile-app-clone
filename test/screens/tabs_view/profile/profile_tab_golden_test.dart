import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart' show tabIndexProvider;
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../compliance/golden_kit.dart';

ProfileModel _ada({int streak = 12, int xp = 1840, int? rank = 37}) =>
    ProfileModel(
      id: 1,
      email: 'ada@example.com',
      username: 'adaobi',
      first_name: 'Adaobi',
      last_name: 'Okafor',
      is_current_user: true,
      rank: rank,
      nationality: 'NG',
      agree_to_privacy_terms: true,
      avatar: null,
      completed_point: xp,
      level: 'A2',
      learningLanguage: 'yo',
      streak: streak,
    );

ProfileModel? _profile = _ada();

class _User extends UserProvider {
  @override
  ProfileModel? build() => _profile;
}

/// No cached user; the refresh never finishes (loading).
class _Pending extends UserProvider {
  @override
  ProfileModel? build() => null;
  @override
  Future<void> refreshUser() => Completer<void>().future;
}

/// No cached user; the refresh fails (error).
class _Failing extends UserProvider {
  static int calls = 0;
  @override
  ProfileModel? build() => null;
  @override
  Future<void> refreshUser() async {
    calls++;
    throw Exception('offline');
  }
}

List<Override> _o({
  UserProvider Function()? user,
  String? tier,
  bool online = true,
}) => [
  userProvider.overrideWith(user ?? _User.new),
  ageTierStatusProvider.overrideWith(
    (ref) async => tier == null
        ? null
        : AgeTierStatus(assigned: true, tier: tier, status: 'active'),
  ),
  profileOnlineProvider.overrideWith((ref) async => online),
  profileWalletProvider.overrideWithValue((120, 45, 3)),
];

Future<void> _pump(
  WidgetTester t,
  GoldenVariant v,
  List<Override> o, {
  bool settle = true,
}) async {
  t.view.devicePixelRatio = 1;
  await pumpVariant(t, v, const ProfileTab(), overrides: o);
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/tabs_view/profile/profile_tab_golden_test.dart',
    ),
  );
  setUp(() => _profile = _ada());

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
  ]) {
    testWidgets('profile golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProfileTab),
        matchesGoldenFile('goldens/profile_${v.name}.png'),
      );
    });
  }

  final base = goldenVariants.first;
  for (final (name, o, settle, setup) in [
    ('loading', _o(user: _Pending.new), false, () {}),
    ('error', _o(user: _Failing.new), true, () {}),
    ('offline', _o(online: false), true, () {}),
    ('child', _o(tier: 'child'), true, () {}),
    ('empty', _o(), true, () => _profile = _ada(streak: 0, xp: 0, rank: null)),
  ]) {
    testWidgets('profile state golden $name', (t) async {
      setup();
      await _pump(t, base, o, settle: settle);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProfileTab),
        matchesGoldenFile('goldens/profile_state_$name.png'),
      );
    });
  }

  testWidgets('shows name, handle with learning language, stats, wallet', (
    t,
  ) async {
    await _pump(t, base, _o());
    expect(find.text('Adaobi Okafor'), findsOneWidget);
    expect(find.text('\u2066@ADAOBI\u2069 · LEARNING YORÙBÁ'), findsOneWidget);
    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('1840 XP'), findsOneWidget);
    expect(find.text('#37'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Cowries'), findsOneWidget);
  });

  testWidgets('every existing account action is still offered', (t) async {
    await _pump(t, base, _o());
    for (final s in [
      'Edit profile',
      'Change password',
      'Give us feedback',
      'Who we are',
      'Privacy and user policy',
      'Delete your account',
    ]) {
      await t.scrollUntilVisible(find.text(s), 80);
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });

  testWidgets('rank tile opens the leaderboard tab', (t) async {
    await _pump(t, base, _o());
    final c = ProviderScope.containerOf(t.element(find.byType(ProfileTab)));
    final sub = c.listen(tabIndexProvider, (_, _) {});
    await t.tap(find.byKey(const Key('profile-rank')));
    await t.pump();
    expect(sub.read(), 2);
    sub.close();
  });

  testWidgets('child and teen profiles are private: rank hidden', (t) async {
    for (final tier in ['child', 'teen']) {
      await t.pumpWidget(const SizedBox());
      await _pump(t, base, _o(tier: tier));
      expect(find.byKey(const Key('profile-rank')), findsNothing);
      expect(find.byKey(const Key('profile-private')), findsOneWidget);
      expect(find.text('#37'), findsNothing);
    }
  });

  testWidgets('empty profile shows encouraging values, not zeros', (t) async {
    _profile = _ada(streak: 0, xp: 0, rank: null);
    await _pump(t, base, _o());
    expect(find.text('Start today'), findsOneWidget);
    expect(find.text('Not ranked yet'), findsOneWidget);
  });

  testWidgets('no offline note when online', (t) async {
    await _pump(t, base, _o());
    expect(find.byKey(const Key('profile-offline')), findsNothing);
  });

  testWidgets('offline note when offline, profile still shown', (t) async {
    await _pump(t, base, _o(online: false));
    expect(find.byKey(const Key('profile-offline')), findsOneWidget);
    expect(find.text('Adaobi Okafor'), findsOneWidget);
  });

  testWidgets('loading then error with a working retry', (t) async {
    _Failing.calls = 0;
    await _pump(t, base, _o(user: _Failing.new), settle: false);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profile-error')), findsOneWidget);
    expect(_Failing.calls, 1);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(_Failing.calls, 2);
  });

  testWidgets('loading state is announced', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, base, _o(user: _Pending.new), settle: false);
    expect(find.bySemanticsLabel('Loading your profile…'), findsOneWidget);
    h.dispose();
  });

  testWidgets('Arabic: RTL chevrons, localized labels, a11y guidelines', (
    t,
  ) async {
    final h = t.ensureSemantics();
    await _pump(t, goldenVariants[1], _o());
    expect(find.text('الترتيب العالمي'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    final edit = t.getSize(find.byKey(const Key('profile-edit')));
    expect(edit.width, greaterThanOrEqualTo(48));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('French plural streak', (t) async {
    _profile = _ada(streak: 1);
    await _pump(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _o(),
    );
    expect(find.text('1 jour'), findsOneWidget);
  });
}
