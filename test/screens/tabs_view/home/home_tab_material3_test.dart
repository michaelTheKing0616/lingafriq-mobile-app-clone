import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Language _language({
  required int id,
  required String name,
  int totalScore = 0,
  bool isPublished = true,
}) {
  return Language(
    id: id,
    total_score: totalScore,
    total_count: 10,
    completed: 0,
    name: name,
    background: '',
    Inrtoduction: '',
    is_published: isPublished,
    is_featured: false,
    level_language: 'A1',
  );
}

ProfileModel _profile({String username = 'Ada', int streak = 0}) {
  return ProfileModel(
    id: 1,
    email: 'ada@example.com',
    username: username,
    first_name: 'Ada',
    last_name: 'Lovelace',
    is_current_user: true,
    rank: null,
    nationality: 'NG',
    agree_to_privacy_terms: true,
    avatar: null,
    completed_point: 0,
    streak: streak,
  );
}

class _FakeUserProvider extends UserProvider {
  _FakeUserProvider(this._user);
  final ProfileModel? _user;

  @override
  ProfileModel? build() => _user;
}

/// Avoids the real [DailyGoalsProvider]'s backend sync (a live network
/// call), which is unrelated to this screen's own behaviour and would
/// otherwise leave a pending timer/HTTP call dangling in every test.
class _FakeDailyGoalsProvider extends DailyGoalsProvider {
  @override
  BaseProviderState build() => BaseProviderState();
}

Future<void> _pumpHomeTab(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await ScreenUtil.ensureScreenSize();

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const MaterialApp(home: HomeTabMaterial3()),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows a loading indicator while languages are fetching', (tester) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith((ref) => Completer<LanguageResponse>().future),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    // Intentionally avoid pumpAndSettle: the languages future never
    // resolves. Advance time once so the hero card's one-shot entrance
    // animation finishes its timer instead of leaving it pending at
    // teardown.
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.textContaining('Loading your languages'), findsOneWidget);
  });

  testWidgets('shows hero card, streak and language cards once loaded', (tester) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => LanguageResponse(
            count: 2,
            next: null,
            previous: null,
            results: [
              _language(id: 1, name: 'Swahili', totalScore: 40),
              _language(id: 2, name: 'Yoruba'),
            ],
          ),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile(username: 'Ada', streak: 5))),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back, Ada'), findsOneWidget);
    expect(find.text('Swahili'), findsOneWidget);
    expect(find.text('Yoruba'), findsOneWidget);
    expect(find.textContaining('5-day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('5 days streak'), findsOneWidget);
  });

  testWidgets('shows a warm empty state with a way forward for first-time users', (tester) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => LanguageResponse(count: 0, next: null, previous: null, results: []),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('No languages yet'), findsOneWidget);
    expect(find.text('Search Languages'), findsOneWidget);
  });

  testWidgets('shows a distinct offline state when the fetch fails with a connectivity error', (
    tester,
  ) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => throw Exception('SocketException: Failed host lookup'),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('shows the generic error panel (not the offline state) for a non-connectivity failure', (
    tester,
  ) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => throw Exception('500 Internal Server Error'),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('renders an unpublished language as a non-navigating "coming soon" card', (
    tester,
  ) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => LanguageResponse(
            count: 1,
            next: null,
            previous: null,
            results: [_language(id: 3, name: 'Darija', isPublished: false)],
          ),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Darija language card, coming soon, not available yet'),
      findsOneWidget,
    );

    await tester.tap(find.text('Darija'));
    // A single pump (not pumpAndSettle) avoids racing the SnackBar's
    // auto-dismiss timer while still letting it appear.
    await tester.pump();

    expect(find.textContaining('coming soon'), findsWidgets);
  });

  testWidgets('exposes accessibility semantics for key interactive elements', (tester) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async => LanguageResponse(
            count: 1,
            next: null,
            previous: null,
            results: [_language(id: 1, name: 'Swahili', totalScore: 20)],
          ),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Search languages'), findsOneWidget);
    expect(find.bySemanticsLabel('Open menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Daily goals'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Swahili language card, 20% complete'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows a waiting-for-guardian banner for a minor account pending guardian consent',
    (tester) async {
      await _pumpHomeTab(
        tester,
        overrides: [
          languagesProvider.overrideWith(
            (ref) async =>
                LanguageResponse(count: 0, next: null, previous: null, results: []),
          ),
          userProvider.overrideWith(() => _FakeUserProvider(_profile())),
          dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
          ageTierStatusProvider.overrideWith(
            (ref) async => AgeTierStatus(assigned: true, tier: 'under_13', status: 'pending_guardian'),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Waiting for a guardian'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Waiting for a guardian. Lessons are open, but chat, Village, '
          'and purchases stay paused until a guardian approves.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('hides the guardian banner once an adult/non-pending status is confirmed', (
    tester,
  ) async {
    await _pumpHomeTab(
      tester,
      overrides: [
        languagesProvider.overrideWith(
          (ref) async =>
              LanguageResponse(count: 0, next: null, previous: null, results: []),
        ),
        userProvider.overrideWith(() => _FakeUserProvider(_profile())),
        dailyGoalsProvider.overrideWith(() => _FakeDailyGoalsProvider()),
        ageTierStatusProvider.overrideWith(
          (ref) async => AgeTierStatus(assigned: true, tier: 'adult', status: 'active'),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for a guardian'), findsNothing);
  });
}
