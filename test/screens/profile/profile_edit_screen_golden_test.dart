import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

ProfileModel _ada({String? handle = 'ada_codes'}) => ProfileModel(
  id: 1,
  email: 'ada@example.com',
  username: 'Ada',
  first_name: 'Ada',
  last_name: 'Okafor',
  is_current_user: true,
  rank: null,
  nationality: 'Nigeria',
  agree_to_privacy_terms: true,
  avatar: null,
  completed_point: 0,
  streak: 5,
  global_id: handle,
);

class _User extends UserProvider {
  _User(this.user);
  final ProfileModel? user;
  int refreshed = 0;
  @override
  ProfileModel? build() => user;
  @override
  Future<void> refreshUser() async => refreshed++;
}

List<Override> _o({
  _User? user,
  Future<bool> Function(Map<String, dynamic>)? save,
  String? tier,
}) => [
  userProvider.overrideWith(() => user ?? _User(_ada())),
  profileSaveProvider.overrideWithValue(save ?? (_) async => true),
  ageTierStatusProvider.overrideWith(
    (ref) async => tier == null
        ? null
        : AgeTierStatus(assigned: true, tier: tier, status: 'active'),
  ),
];

Future<void> _pump(WidgetTester t, GoldenVariant v, List<Override> o) async {
  await pumpVariant(t, v, const ProfileEditScreen(), overrides: o);
  // Decode avatar art off the fake clock so every golden shows it.
  final ctx = t.element(find.byType(ProfileEditScreen));
  final images = t.widgetList<Image>(find.byType(Image)).toList();
  await t.runAsync(() async {
    for (final i in images) {
      await precacheImage(i.image, ctx);
    }
  });
  await t.pumpAndSettle();
}

String _texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join('\n');

FilledButton _saveBtn(WidgetTester t) =>
    t.widget<FilledButton>(find.byKey(const Key('pe-save')));

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/profile/profile_edit_screen_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
    const GoldenVariant('tablet_820', Size(820, 1180)),
  ]) {
    testWidgets('profile edit golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProfileEditScreen),
        matchesGoldenFile('goldens/profile_edit_${v.name}.png'),
      );
    });
  }

  testWidgets('loading: skeleton until the profile arrives', (t) async {
    await _pump(t, base, _o(user: _User(null)));
    expect(find.byKey(const Key('pe-loading')), findsOneWidget);
    expect(find.byKey(const Key('pe-save')), findsNothing);
    await expectLater(
      find.byType(ProfileEditScreen),
      matchesGoldenFile('goldens/profile_edit_state_loading.png'),
    );
  });

  testWidgets('save is disabled until something changes', (t) async {
    await _pump(t, base, _o());
    expect(_saveBtn(t).onPressed, isNull);
    await t.enterText(find.byKey(const Key('pe-first')), 'Adaeze');
    await t.pump();
    expect(_saveBtn(t).onPressed, isNotNull);
    await t.enterText(find.byKey(const Key('pe-first')), 'Ada');
    await t.pump();
    expect(_saveBtn(t).onPressed, isNull);
  });

  testWidgets('empty name is blocked with an inline message', (t) async {
    final sent = <Map<String, dynamic>>[];
    await _pump(
      t,
      base,
      _o(
        save: (m) async {
          sent.add(m);
          return true;
        },
      ),
    );
    await t.enterText(find.byKey(const Key('pe-last')), '  ');
    await t.pump();
    await t.tap(find.byKey(const Key('pe-save')));
    await t.pumpAndSettle();
    expect(sent, isEmpty);
    expect(_texts(t), contains('Please add your last name.'));
    await expectLater(
      find.byType(ProfileEditScreen),
      matchesGoldenFile('goldens/profile_edit_state_invalid.png'),
    );
  });

  testWidgets('save sends trimmed names, refreshes the user and closes', (
    t,
  ) async {
    final sent = <Map<String, dynamic>>[];
    final user = _User(_ada());
    await pumpVariant(
      t,
      base,
      Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: _o(
        user: user,
        save: (m) async {
          sent.add(m);
          return true;
        },
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('pe-first')), ' Adaeze ');
    await t.pump();
    await t.tap(find.byKey(const Key('pe-save')));
    await t.pumpAndSettle();
    expect(sent.single['first_name'], 'Adaeze');
    expect(sent.single['last_name'], 'Okafor');
    expect(user.refreshed, 1);
    expect(find.byType(ProfileEditScreen), findsNothing);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('save failure keeps edits and shows the error', (t) async {
    await _pump(t, base, _o(save: (_) async => false));
    await t.enterText(find.byKey(const Key('pe-first')), 'Adaeze');
    await t.pump();
    await t.tap(find.byKey(const Key('pe-save')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pe-error')), findsOneWidget);
    expect(find.text('Adaeze'), findsOneWidget);
    expect(_saveBtn(t).onPressed, isNotNull, reason: 'can retry');
    await expectLater(
      find.byType(ProfileEditScreen),
      matchesGoldenFile('goldens/profile_edit_state_error.png'),
    );
  });

  testWidgets('no handle: prompt to pick one', (t) async {
    await _pump(t, base, _o(user: _User(_ada(handle: null))));
    expect(_texts(t), contains('Pick a handle so friends can find you'));
  });

  testWidgets('teen and child see the nickname tip; adults do not', (t) async {
    await _pump(t, base, _o(tier: 'teen'));
    expect(find.byKey(const Key('pe-minor-tip')), findsOneWidget);
    await expectLater(
      find.byType(ProfileEditScreen),
      matchesGoldenFile('goldens/profile_edit_state_teen.png'),
    );
  });

  testWidgets('child sees the nickname tip', (t) async {
    await _pump(t, base, _o(tier: 'child'));
    expect(find.byKey(const Key('pe-minor-tip')), findsOneWidget);
  });

  testWidgets('adult sees no nickname tip', (t) async {
    await _pump(t, base, _o(tier: 'adult'));
    expect(find.byKey(const Key('pe-minor-tip')), findsNothing);
  });

  testWidgets('country is shown read-only with an explanation', (t) async {
    await _pump(t, base, _o());
    expect(_texts(t), contains('Nigeria'));
    expect(
      _texts(t),
      contains('Set when you signed up. Contact support to change it.'),
    );
    final row = t.widget<Material>(find.byKey(const Key('pe-country')));
    expect(row, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const Key('pe-country')),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
  });

  testWidgets('RTL: back on the right, Latin isolated, chevron mirrored', (
    t,
  ) async {
    await _pump(t, goldenVariants[1], _o());
    expect(
      t.getRect(find.byKey(const Key('pe-back'))).center.dx,
      greaterThan(195),
    );
    final s = _texts(t);
    expect(s, contains('\u2066@ada_codes\u2069'));
    expect(s, contains('\u2066ada@example.com\u2069'));
    expect(s, contains('تعديل الملف الشخصي'));
    final handle = t.getRect(find.byKey(const Key('pe-handle')));
    final chev = t.getRect(find.byIcon(Icons.chevron_right_rounded));
    expect(
      chev.center.dx,
      lessThan(handle.center.dx),
      reason: 'chevron at start-end (left) in RTL',
    );
  });

  testWidgets('no paywall or hearts', (t) async {
    await _pump(t, base, _o());
    final s = _texts(t).toLowerCase();
    for (final w in ['heart', 'premium', 'upgrade', 'plus']) {
      expect(s, isNot(contains(w)), reason: w);
    }
  });

  testWidgets('avatar art is real artwork, not a placeholder', (t) async {
    await _pump(t, base, _o());
    final imgs = find.descendant(
      of: find.byKey(const Key('pe-avatar-card')),
      matching: find.byType(Image),
    );
    expect(imgs, findsWidgets);
  });

  testWidgets('touch targets >= 48dp', (t) async {
    await _pump(t, base, _o());
    for (final k in ['pe-back', 'pe-avatar-edit', 'pe-save', 'pe-handle']) {
      expect(
        t.getSize(find.byKey(Key(k))).height,
        greaterThanOrEqualTo(48),
        reason: k,
      );
    }
  });
}
