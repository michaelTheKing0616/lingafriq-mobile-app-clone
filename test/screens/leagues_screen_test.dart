import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/leaderboard_provider.dart';
import 'package:lingafriq/screens/village/leagues_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NotEnrolledLeaderboard extends LeaderboardProvider {
  @override
  BaseProviderState build() => BaseProviderState();

  @override
  bool get leagueEnrolled => false;

  @override
  List<String> get leagueAllowedKinds => const ['public', 'circle', 'class'];

  @override
  Future<void> refreshLeagueMembership() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('leagues_join_golden shows opt-in before enrolled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaderboardProvider.overrideWith(() => _NotEnrolledLeaderboard()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: LeaguesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly leagues'), findsOneWidget);
    expect(find.textContaining('optional'), findsOneWidget);
  });
}
