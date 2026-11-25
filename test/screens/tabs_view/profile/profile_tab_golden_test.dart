import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/achievement_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_data.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart'
    show tabIndexProvider;
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

Language _lang(int id, String name, int score, String level) => Language(
  id: id,
  total_score: score,
  total_count: 10,
  completed: 0,
  name: name,
  background: '',
  Inrtoduction: '',
  is_published: true,
  is_featured: false,
  level_language: level,
);

Achievement _badge(String id, String name, AchievementType t, bool on) =>
    Achievement(
      id: id,
      name: name,
      description: '',
      type: t,
      rarity: AchievementRarity.common,
      icon: '',
      xpReward: 10,
      isUnlocked: on,
    );

final shared = <String>[];

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
  profileWeekProvider.overrideWithValue([10, 0, 25, 12, 0, 30, 18]),
  progressClockProvider.overrideWithValue(() => DateTime(2026, 10, 29, 18)),
  profileLanguagesProvider.overrideWith(
    (ref) async => [
      _lang(1, 'Yoruba', 42, 'A2'),
      _lang(2, 'Swahili', 15, 'A1'),
      _lang(3, 'Zulu', 0, 'A1'),
    ],
  ),
  profileBadgesProvider.overrideWithValue([
    _badge('a', 'Week Warrior', AchievementType.streak, true),
    _badge('b', 'First Steps', AchievementType.milestone, true),
    _badge('c', 'Monthly Master', AchievementType.streak, false),
    _badge('d', 'XP Hunter', AchievementType.xp, false),
  ]),
  profileShareProvider.overrideWithValue(shared.add),
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
    // Decode the avatar art off the fake clock so every golden shows it.
    final ctx = t.element(find.byType(ProfileTab));
    final images = t.widgetList<Image>(find.byType(Image)).toList();
    await t.runAsync(() async {
      for (final i in images) {
        await precacheImage(i.image, ctx);
      }
    });
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
    ('teen', _o(tier: 'teen'), true, () {}),
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
    expect(
      find.text('\u2066@ADAOBI\u2069 · LEARNING \u2068YORÙBÁ\u2069'),
      findsOneWidget,
    );
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
      'About LingAfriq',
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

  testWidgets('pack sections: week strip, languages with level, badges', (
    t,
  ) async {
    await _pump(t, base, _o());
    expect(find.byKey(const Key('profile-week')), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('profile-badges')), 100);
    expect(find.text('Level A2 · 42%'), findsOneWidget);
    expect(find.text('Kiswahili'), findsOneWidget);
    expect(
      find.text('Zulu'),
      findsNothing,
      reason: 'not started, not learning',
    );
    expect(find.text('2 of 4 unlocked'), findsOneWidget);
    expect(find.text('Week Warrior'), findsOneWidget);
  });

  testWidgets('week strip speaks each day', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, base, _o());
    expect(find.bySemanticsLabel('Thursday: practised'), findsOneWidget);
    expect(find.bySemanticsLabel('Saturday: no practice'), findsOneWidget);
    h.dispose();
  });

  testWidgets('share card shares streak and XP', (t) async {
    shared.clear();
    await _pump(t, base, _o());
    final btn = find.byKey(const Key('profile-share-button'));
    await t.ensureVisible(btn);
    await t.pumpAndSettle();
    await t.tap(btn);
    expect(shared, [
      "I'm learning Yorùbá on LingAfriq: 12-day streak and 1840 XP!",
    ]);
  });

  testWidgets('share card hidden for child, teen and offline', (t) async {
    for (final o in [_o(tier: 'child'), _o(tier: 'teen'), _o(online: false)]) {
      await t.pumpWidget(const SizedBox());
      await _pump(t, base, o);
      await t.scrollUntilVisible(find.text('Delete your account'), 150);
      expect(find.byKey(const Key('profile-share')), findsNothing);
    }
  });

  testWidgets('error state has a header with a working close', (t) async {
    await _pump(t, base, _o(user: _Failing.new));
    expect(find.text('Profile'), findsOneWidget);
    final c = ProviderScope.containerOf(t.element(find.byType(ProfileTab)));
    final sub = c.listen(tabIndexProvider, (_, _) {});
    sub.read();
    c.read(tabIndexProvider.notifier).setIndex(4);
    await t.tap(find.byKey(const Key('profile-close')));
    await t.pump();
    expect(sub.read(), 0);
    sub.close();
  });

  testWidgets('loading skeleton mirrors header and stats layout', (t) async {
    await _pump(t, base, _o(user: _Pending.new), settle: false);
    final skel = find.byKey(const Key('profile-loading'));
    expect(skel, findsOneWidget);
    final circles = t
        .widgetList<Container>(
          find.descendant(of: skel, matching: find.byType(Container)),
        )
        .where(
          (c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        );
    expect(
      circles.length,
      10,
      reason: 'avatar + 7 week days + 2 language rows',
    );
    final navy = t
        .widgetList<ColoredBox>(
          find.descendant(of: skel, matching: find.byType(ColoredBox)),
        )
        .where((b) => b.color == kProfileNavy);
    expect(navy, isNotEmpty, reason: 'same navy header as loaded profile');
  });

  testWidgets('teen profile shows its own privacy card, child does not', (
    t,
  ) async {
    await _pump(t, base, _o(tier: 'teen'));
    expect(find.byKey(const Key('profile-teen-card')), findsOneWidget);
    expect(find.text('Private profile'), findsOneWidget);
    expect(find.text("Adults can't send you direct messages."), findsOneWidget);
    expect(
      find.text(
        'Your account is linked to a parent or guardian, who gave consent.',
      ),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    await _pump(t, base, _o(tier: 'child'));
    expect(find.byKey(const Key('profile-teen-card')), findsNothing);
  });

  for (final (name, o, key) in [
    ('badges', _o(), 'profile-badges'),
    ('share', _o(), 'profile-share'),
    ('share_hidden_offline', _o(online: false), 'profile-badges'),
  ]) {
    testWidgets('profile scrolled golden $name', (t) async {
      await _pump(t, base, o);
      final target = find.byKey(Key(key));
      await t.ensureVisible(target);
      await t.pumpAndSettle();
      // Bring the section title into frame too.
      await t.drag(find.byType(CustomScrollView), const Offset(0, 90));
      await t.pumpAndSettle();
      if (name.startsWith('share_hidden')) {
        expect(find.byKey(const Key('profile-share')), findsNothing);
      }
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProfileTab),
        matchesGoldenFile('goldens/profile_scrolled_$name.png'),
      );
    });
  }

  testWidgets('RTL handle isolates Latin runs', (t) async {
    await _pump(t, goldenVariants[1], _o());
    final txt = t.widget<Text>(find.byKey(const Key('profile-handle'))).data!;
    expect(txt, startsWith('\u2066@ADAOBI\u2069'));
    expect(txt, contains('\u2068YORÙBÁ\u2069'));
  });
}
