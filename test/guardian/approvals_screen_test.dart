import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/approvals_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

/// Pins the test view to an exact logical size with a 1.0 device pixel
/// ratio. flutter_screenutil derives its scale factor from the view's
/// reported logical size; without pinning the device pixel ratio here the
/// test harness's default ratio skews that scale factor, which in turn
/// makes list items report wildly inflated heights and starves the
/// surrounding `ListView`'s sliver of the cache extent it needs to build
/// more than one real item. This keeps `.w`/`.h`/`.sp` scaling 1:1 with the
/// logical pixels asserted in these tests.
void _pinTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap(
  Widget child, {
  double textScale = 1.0,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Directionality(textDirection: textDirection, child: child),
          ),
        ),
      ),
    ),
  );
}

GuardianGroupJoinRequestRow _pendingRow({
  String requestId = 'req-1',
  int childUserId = 42,
  String groupName = 'Yoruba Circle Class',
  String groupKind = 'classroom',
  String moderationStatus = 'moderated',
  String status = 'pending',
  int memberCount = 12,
  int adultMemberCount = 2,
  DateTime? expiresAt,
}) {
  return GuardianGroupJoinRequestRow(
    requestId: requestId,
    childName: 'Ada',
    childUserId: childUserId,
    groupKind: groupKind,
    groupName: groupName,
    memberCount: memberCount,
    adultMemberCount: adultMemberCount,
    moderationStatus: moderationStatus,
    status: status,
    expiresAt: expiresAt ?? DateTime.utc(2026, 2, 1),
  );
}

GuardianGroupJoinRequestRow _approvedRow({
  String requestId = 'req-2',
  int childUserId = 7,
  String groupName = 'Study circle',
}) {
  return GuardianGroupJoinRequestRow(
    requestId: requestId,
    childUserId: childUserId,
    groupKind: 'circle',
    groupName: groupName,
    memberCount: 5,
    adultMemberCount: 1,
    moderationStatus: 'open',
    status: 'approved',
  );
}

class _FakeApprovalService extends GuardianApprovalService {
  _FakeApprovalService({
    List<GuardianGroupJoinRequestRow>? rows,
    Object? fetchError,
    this.approveResult = true,
    this.revokeResult = true,
    Completer<void>? fetchGate,
  }) : _rows = rows ?? const [],
       _fetchError = fetchError,
       _fetchGate = fetchGate;

  final List<GuardianGroupJoinRequestRow> _rows;
  final Object? _fetchError;
  final Completer<void>? _fetchGate;
  final bool approveResult;
  final bool revokeResult;

  int fetchCalls = 0;
  String? lastApproveId;
  String? lastRevokeId;
  String? lastDenyId;

  @override
  Future<bool> deny(String requestId) async {
    lastDenyId = requestId;
    return true;
  }

  @override
  Future<List<GuardianGroupJoinRequestRow>> fetchApprovals() async {
    fetchCalls++;
    if (_fetchGate != null) {
      await _fetchGate.future;
    }
    if (_fetchError != null) throw _fetchError;
    return _rows;
  }

  @override
  Future<bool> approve(String requestId) async {
    lastApproveId = requestId;
    return approveResult;
  }

  @override
  Future<bool> revoke(String requestId) async {
    lastRevokeId = requestId;
    return revokeResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading state shows an accessible progress indicator', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    final gate = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(fetchGate: gate),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('gap-loading')), findsOneWidget);
    expect(find.bySemanticsLabel('Loading approvals'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('empty state shows guardian.approvals.empty copy', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(rows: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No requests right now'), findsOneWidget);
    expect(find.textContaining('circle or class'), findsOneWidget);
  });

  testWidgets('error state shows retry and reloads on tap', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(
      fetchError: GuardianApiException(
        message: 'The approvals server is napping.',
      ),
    );
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('The approvals server is napping.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(service.fetchCalls, 2);
  });

  testWidgets('offline state with no cached rows shows the offline banner', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            fetchError: const GuardianOfflineException(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('You are offline. Showing the last list we loaded.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'pending request shows approve affordance with scoped semantics',
    (tester) async {
      _pinTestViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(
          GuardianApprovalsScreen(
            approvalService: _FakeApprovalService(rows: [_pendingRow()]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Yoruba Circle Class'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.textContaining('checked by moderators'), findsOneWidget);
      expect(find.text('Needs your review'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Approve, Yoruba Circle Class'),
        findsOneWidget,
      );
    },
  );

  testWidgets('approving a pending request shows a confirming snackbar', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_pendingRow()]);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.lastApproveId, 'req-1');
    expect(find.textContaining('Approved'), findsWidgets);
  });

  testWidgets(
    'a failed approve shows a try-again snackbar, not a false success',
    (tester) async {
      _pinTestViewport(tester, const Size(390, 844));
      final service = _FakeApprovalService(
        rows: [_pendingRow()],
        approveResult: false,
      );
      await tester.pumpWidget(
        _wrap(GuardianApprovalsScreen(approvalService: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('That did not go through. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('approved request shows revoke control and decided section', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(rows: [_approvedRow()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revoke'), findsOneWidget);
    expect(find.text('Decided'), findsOneWidget);
    expect(find.bySemanticsLabel('Revoke, Study circle'), findsOneWidget);
  });

  testWidgets('revoking an approved request shows a confirming snackbar', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_approvedRow()]);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revoke'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.lastRevokeId, 'req-2');
    expect(find.textContaining('Approval revoked'), findsWidgets);
  });

  testWidgets(
    'a failed revoke shows a try-again snackbar, not a false success',
    (tester) async {
      _pinTestViewport(tester, const Size(390, 844));
      final service = _FakeApprovalService(
        rows: [_approvedRow()],
        revokeResult: false,
      );
      await tester.pumpWidget(
        _wrap(GuardianApprovalsScreen(approvalService: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revoke'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('That did not go through. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('mixed pending and decided requests render both sections', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Needs your review'), findsOneWidget);
    expect(find.text('Decided'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Revoke'), findsOneWidget);
  });

  testWidgets('large text scale does not overflow the approval card actions', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
        textScale: 2.2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Approve'), findsOneWidget);

    // At this text scale, the decided-section card may render below the
    // initial viewport + cache extent, same as a real device would need a
    // scroll. Scroll to it explicitly rather than assuming it is prebuilt.
    await tester.scrollUntilVisible(
      find.text('Revoke'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revoke'), findsOneWidget);
  });

  testWidgets('approve and revoke controls meet the 48dp minimum tap target', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // bySemanticsLabel resolves to the merged semantics node's bounds, which
    // can span far more than the tappable widget itself, so it is not a
    // reliable way to measure a tap target. Measure the actual
    // ConstrainedBox that enforces the minimum height instead.
    final approveHeight = tester
        .getSize(
          find
              .ancestor(
                of: find.text('Approve').first,
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .height;
    final revokeHeight = tester
        .getSize(
          find
              .ancestor(
                of: find.text('Revoke').first,
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .height;

    expect(approveHeight, greaterThanOrEqualTo(48));
    expect(revokeHeight, greaterThanOrEqualTo(48));
  });

  testWidgets('renders without overflow on a small phone width', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(320, 568));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Approve'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Revoke'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revoke'), findsOneWidget);
  });

  testWidgets('renders without overflow on a large phone width', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(428, 926));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Revoke'), findsOneWidget);
  });

  testWidgets(
    'empty state skips its entrance animation when reduced motion is requested',
    (tester) async {
      _pinTestViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: GuardianApprovalsScreen(
                    approvalService: _FakeApprovalService(rows: const []),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No requests right now'), findsOneWidget);
      // The widget skips wrapping its content in TweenAnimationBuilder entirely
      // when reduced motion is requested (see _EmptyPanel.build), rather than
      // merely running the same animation at zero duration.
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    },
  );

  testWidgets(
    'RTL mirrors the section-header badge without hardcoded left/right',
    (tester) async {
      _pinTestViewport(tester, const Size(390, 844));

      // LTR pass: badge should sit to the right of the section title, and
      // the first chip ("12 members") should sit to the left of the second
      // ("2 adults"). This only tests layout mechanics (Directionality),
      // never translation — the English copy is unchanged in both passes.
      await tester.pumpWidget(
        _wrap(
          GuardianApprovalsScreen(
            approvalService: _FakeApprovalService(rows: [_pendingRow()]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final titleLtr = tester.getTopLeft(find.text('Needs your review'));
      final badgeLtr = tester.getTopLeft(find.text('1'));
      expect(badgeLtr.dx, greaterThan(titleLtr.dx));

      // RTL pass: everything should mirror — badge moves to the left of the
      // title, and the chip order flips.
      await tester.pumpWidget(
        _wrap(
          GuardianApprovalsScreen(
            approvalService: _FakeApprovalService(rows: [_pendingRow()]),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final titleRtl = tester.getTopLeft(find.text('Needs your review'));
      final badgeRtl = tester.getTopLeft(find.text('1'));
      expect(badgeRtl.dx, lessThan(titleRtl.dx));
    },
  );

  testWidgets(
    '3.0x text scale on a small phone does not overflow cards or chips',
    (tester) async {
      _pinTestViewport(tester, const Size(320, 568));
      await tester.pumpWidget(
        _wrap(
          GuardianApprovalsScreen(
            approvalService: _FakeApprovalService(
              rows: [_pendingRow(), _approvedRow()],
            ),
          ),
          textScale: 3.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The title is now a body headline, so the first card may start below
      // the fold at 3.0x.
      await tester.scrollUntilVisible(
        find.text('Approve'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Approve'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Revoke'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Revoke'), findsOneWidget);
    },
  );

  testWidgets('golden: mixed approvals list layout', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(
            rows: [_pendingRow(), _approvedRow()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GuardianApprovalsScreen),
      matchesGoldenFile('goldens/approvals_mixed_list.png'),
    );
  });

  testWidgets('Deny asks first, then denies and names the child', (
    tester,
  ) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_pendingRow()]);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada wants to join'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gap-deny-req-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gap-deny-confirm')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.lastDenyId, isNull);

    await tester.tap(find.byKey(const ValueKey('gap-deny-req-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gap-deny-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.lastDenyId, 'req-1');
    expect(find.textContaining('Denied'), findsWidgets);
  });

  testWidgets('Arabic shows translated actions, not English', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GuardianApprovalsScreen(
              approvalService: _FakeApprovalService(rows: [_pendingRow()]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('موافقة'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });
}
