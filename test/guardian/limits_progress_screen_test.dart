import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/limits_progress_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

/// Pins the test view to a known logical size so `flutter_screenutil`'s
/// `.w`/`.h`/`.sp` tokens scale ~1:1 with the 390x844 design size, matching
/// real devices. `tester.binding.setSurfaceSize` only affects golden capture
/// and does not update `MediaQuery`, so layouts relying on MediaQuery-driven
/// scaling must use `tester.view` instead.
void _setTestViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeLimitsService extends GuardianLimitsService {
  _FakeLimitsService(this._rows, {this.blocked = false, this.saveResult = true});

  final List<GuardianChildProgressRow> _rows;
  final bool blocked;
  final bool saveResult;

  int saveCallCount = 0;

  @override
  Future<List<GuardianChildProgressRow>> fetchProgress() async => _rows;

  @override
  Future<bool> saveDailyLimit({
    required int childUserId,
    required int dailyMinutes,
    required String timezone,
  }) async {
    saveCallCount++;
    return saveResult;
  }

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

/// Never resolves, so the screen stays on the loading state for assertions.
class _ForeverLoadingLimitsService extends GuardianLimitsService {
  @override
  Future<List<GuardianChildProgressRow>> fetchProgress() => Completer<List<GuardianChildProgressRow>>().future;
}

class _ErrorLimitsService extends GuardianLimitsService {
  _ErrorLimitsService([this.message]);

  final String? message;

  @override
  Future<List<GuardianChildProgressRow>> fetchProgress() async {
    throw GuardianApiException(message: message);
  }
}

class _OfflineLimitsService extends GuardianLimitsService {
  @override
  Future<List<GuardianChildProgressRow>> fetchProgress() async {
    throw const GuardianOfflineException();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading state shows an accessible progress indicator', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _ForeverLoadingLimitsService(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel("Loading your learners' progress"),
      findsOneWidget,
    );
  });

  testWidgets('a slow initial load shows a reassurance hint after a delay', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _ForeverLoadingLimitsService(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(GuardianLimitsProgressScreen.guardianLimitsSlowLoadHint), findsNothing);

    // Advance past the slow-load threshold without ever resolving the fetch.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(GuardianLimitsProgressScreen.guardianLimitsSlowLoadHint), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows message and a 48dp retry button', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _ErrorLimitsService('Server hiccup, try again.'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Server hiccup, try again.'), findsOneWidget);
    final retryButtonFinder = find.widgetWithText(FilledButton, 'Try again');
    expect(retryButtonFinder, findsOneWidget);
    expect(tester.getSize(retryButtonFinder).height, greaterThanOrEqualTo(48));
  });

  testWidgets('offline with no cached data shows a distinct offline empty state', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _OfflineLimitsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The top connectivity banner and the empty-state body must not repeat
    // the exact same sentence twice on screen.
    expect(find.text(GuardianLimitsProgressScreen.offlineBanner), findsOneWidget);
    expect(
      find.text(GuardianLimitsProgressScreen.guardianLimitsOfflineEmptyTitle),
      findsOneWidget,
    );
  });

  testWidgets('empty state shows guardian.limits empty copy', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
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

  testWidgets('loaded child shows minutes ring, can-do summary and groups', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
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
    expect(find.textContaining('18 of 45 min today'), findsOneWidget);
    expect(find.textContaining('3 can-dos verified'), findsOneWidget);
    expect(find.text('Yoruba study circle'), findsOneWidget);
    expect(find.text('Learner #42'), findsOneWidget);
  });

  testWidgets('loaded card does not double-announce its summary to screen readers', (tester) async {
    // Regression guard: the card wraps its ring/name/minutes/can-dos row in a
    // single Semantics(label: cardSemanticsLabel) summary. If that row's own
    // text and ring semantics are not excluded, assistive tech re-announces
    // the same numbers a second time as a separate, jumbled node right after
    // the clean summary — confirmed previously via a semantics-tree probe.
    _setTestViewSize(tester, const Size(390, 844));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _FakeLimitsService([
            GuardianChildProgressRow(
              childUserId: 42,
              minutesLearnedToday: 18,
              dailyMinutesLimit: 45,
              canDoVerifiedCount: 3,
              approvedGroups: const [],
              childDisplayName: 'Amina',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The clean, single-sentence card summary must exist exactly once.
    expect(
      find.bySemanticsLabel('Amina, 18 of 45 minutes used today, 3 can-dos verified'),
      findsOneWidget,
    );
    // The ring's own semantics label must not leak through as a second,
    // separately-reachable node once it is covered by the card summary.
    expect(
      find.bySemanticsLabel('18 of 45 minutes used today'),
      findsNothing,
    );

    handle.dispose();
  });

  testWidgets('loaded child uses the display name when the API provides one', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianLimitsProgressScreen(
          limitsService: _FakeLimitsService([
            GuardianChildProgressRow(
              childUserId: 7,
              minutesLearnedToday: 10,
              dailyMinutesLimit: 30,
              canDoVerifiedCount: 1,
              approvedGroups: const [],
              childDisplayName: 'Amina',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('Learner #7'), findsNothing);
  });

  testWidgets('saving a limit shows a success confirmation', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    final service = _FakeLimitsService([
      GuardianChildProgressRow(
        childUserId: 42,
        minutesLearnedToday: 18,
        dailyMinutesLimit: 45,
        canDoVerifiedCount: 3,
        approvedGroups: const [],
      ),
    ]);
    await tester.pumpWidget(
      _wrap(GuardianLimitsProgressScreen(limitsService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save limit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.saveCallCount, 1);
    expect(find.text(GuardianLimitsProgressScreen.saveLimitSuccess), findsOneWidget);
  });

  testWidgets('loaded card has no overflow at a large text scale factor', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.2)),
        child: _wrap(
          GuardianLimitsProgressScreen(
            limitsService: _FakeLimitsService([
              GuardianChildProgressRow(
                childUserId: 42,
                minutesLearnedToday: 180,
                dailyMinutesLimit: 180,
                canDoVerifiedCount: 12,
                approvedGroups: [
                  GuardianApprovedGroupRow(
                    groupKind: 'classroom',
                    groupName: 'A fairly long classroom name for wrapping',
                    groupId: 'c1',
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save surfaces a clear retry message', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
    final service = _FakeLimitsService(
      [
        GuardianChildProgressRow(
          childUserId: 42,
          minutesLearnedToday: 18,
          dailyMinutesLimit: 45,
          canDoVerifiedCount: 3,
          approvedGroups: const [],
        ),
      ],
      saveResult: false,
    );
    await tester.pumpWidget(
      _wrap(GuardianLimitsProgressScreen(limitsService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save limit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.saveCallCount, 1);
    expect(find.text(GuardianLimitsProgressScreen.saveLimitFailure), findsOneWidget);
  });

  testWidgets('renders with no overflow under RTL directionality', (tester) async {
    // Mirrors the RTL coverage pattern in guardian_link_screen_test.dart's
    // 'RTL flips the learner tile chevron direction' test. This screen has
    // no directional (chevron-style) icons to flip, so the meaningful
    // assertion here is that the loaded layout — ring, slider, save button,
    // approved-groups list — lays out without overflow/exceptions and still
    // exposes its key content when mirrored right-to-left.
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => ProviderScope(
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: GuardianLimitsProgressScreen(
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
                    childDisplayName: 'Amina',
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Amina'), findsOneWidget);
    expect(find.textContaining('18 of 45 min today'), findsOneWidget);
    expect(find.text('Yoruba study circle'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save limit'), findsOneWidget);
  });

  testWidgets('reduced motion skips the ring fill and state-switch animations', (tester) async {
    // Mirrors the reduced-motion coverage pattern in approvals_screen_test.dart
    // ('empty state skips its entrance animation when reduced motion is
    // requested'): wrap in a MediaQuery with disableAnimations: true via a
    // Builder so the override reaches the widget tree, matching how
    // MediaQuery.disableAnimationsOf(context) is read in production code.
    //
    // Unlike approvals_screen's _EmptyPanel (which omits its
    // TweenAnimationBuilder entirely when motion is reduced), this screen
    // keeps the animated widgets mounted but collapses their duration to
    // zero, so the correct assertion here is "duration == Duration.zero"
    // rather than "widget absent".
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: GuardianLimitsProgressScreen(
                  limitsService: _FakeLimitsService([
                    GuardianChildProgressRow(
                      childUserId: 42,
                      minutesLearnedToday: 18,
                      dailyMinutesLimit: 45,
                      canDoVerifiedCount: 3,
                      approvedGroups: const [],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);

    final ringAnimations = tester.widgetList<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(ringAnimations, isNotEmpty);
    for (final ring in ringAnimations) {
      expect(ring.duration, Duration.zero);
    }
  });

  testWidgets('limit reached gate shows calm end-of-session state', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
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
    _setTestViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(const GuardianDailyLimitReachedScreen()),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuardianDailyLimitReachedScreen),
      matchesGoldenFile('goldens/guardian_limit_reached.png'),
    );
  });

  testWidgets('golden loaded progress layout', (tester) async {
    _setTestViewSize(tester, const Size(390, 844));
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
              childDisplayName: 'Amina',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuardianLimitsProgressScreen),
      matchesGoldenFile('goldens/guardian_limits_loaded.png'),
    );
  });
}
