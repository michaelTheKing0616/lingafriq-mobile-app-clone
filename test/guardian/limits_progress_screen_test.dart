import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/limits_progress_screen.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

class _FakeLimitsService extends GuardianLimitsService {
  _FakeLimitsService(this._rows, {this.blocked = false});

  final List<GuardianChildProgressRow> _rows;
  final bool blocked;

  @override
  Future<List<GuardianChildProgressRow>> fetchProgress() async => _rows;

  @override
  Future<GuardianChildLimitStatus?> pollChildStatus({bool forceRefresh = false}) async {
    return GuardianChildLimitStatus(
      dailyMinutesLimit: 30,
      minutesUsedToday: blocked ? 30 : 5,
      sessionBlocked: blocked,
      policyRevision: 1,
      localDayKey: '2026-01-01',
      timezone: 'UTC',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state shows guardian.limits empty copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _FakeLimitsService([]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(GuardianLimitsProgressScreen.guardianLimitsEmptyTitle), findsOneWidget);
  });

  testWidgets('loaded child shows minutes and can-do summary', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _FakeLimitsService([
            GuardianChildProgressRow(
              childUserId: 42,
              minutesLearnedToday: 18,
              dailyMinutesLimit: 45,
              canDoVerifiedCount: 3,
              approvedGroups: [
                GuardianApprovedGroupRow(
                  groupKind: 'circle',
                  groupName: 'Yoruba study circle',
                  groupId: 'c1',
                ),
              ],
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('18 min practiced'), findsOneWidget);
    expect(find.textContaining('3 can-dos verified'), findsOneWidget);
    expect(find.text('Yoruba study circle'), findsOneWidget);
  });

  testWidgets('limit reached gate shows calm end-of-session state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianSessionLimitGate(
          limitsService: _FakeLimitsService([], blocked: true),
          childBuilder: (context) => const Text('lesson body'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(GuardianLimitsProgressScreen.guardianLimitsReachedTitle), findsOneWidget);
    expect(find.text('lesson body'), findsNothing);
  });

  testWidgets('golden limit reached layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(const GuardianDailyLimitReachedScreen()),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuardianDailyLimitReachedScreen),
      matchesGoldenFile('goldens/guardian_limit_reached.png'),
    );
  });
}
