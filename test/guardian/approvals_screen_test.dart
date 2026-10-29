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
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: textDirection,
              child: child,
            ),
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
  })  : _rows = rows ?? const [],
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

  testWidgets('loading state shows an accessible progress indicator', (tester) async {
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

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your approvals'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('empty state shows guardian.approvals.empty copy', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(rows: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(GuardianApprovalsScreen.guardianApprovalsEmptyTitle), findsOneWidget);
    expect(find.textContaining('circle or classroom'), findsOneWidget);
  });

  testWidgets('error state shows retry and reloads on tap', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(
      fetchError: GuardianApiException(message: 'The approvals server is napping.'),
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

  testWidgets('offline state with no cached rows shows the offline banner', (tester) async {
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

    expect(find.text(GuardianApprovalsScreen.offlineBanner), findsOneWidget);
  });

  testWidgets('pending request shows approve affordance with scoped semantics', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(rows: [_pendingRow()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yoruba Circle Class'), findsOneWidget);
    expect(find.text('Approve join'), findsOneWidget);
    expect(find.textContaining('Posts are moderated'), findsOneWidget);
    expect(find.text(GuardianApprovalsScreen.reviewSectionTitle), findsOneWidget);
    expect(
      find.bySemanticsLabel('Approve Yoruba Circle Class join request for learner 42'),
      findsOneWidget,
    );
  });

  testWidgets('approving a pending request shows a confirming snackbar', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_pendingRow()]);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve join'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.lastApproveId, 'req-1');
    expect(find.textContaining('Approved'), findsWidgets);
  });

  testWidgets('a failed approve shows a try-again snackbar, not a false success', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_pendingRow()], approveResult: false);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve join'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('We could not approve that request. Try again.'), findsOneWidget);
  });

  testWidgets('approved request shows revoke control and decided section', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService(rows: [_approvedRow()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revoke access'), findsOneWidget);
    expect(find.text(GuardianApprovalsScreen.decidedSectionTitle), findsOneWidget);
    expect(
      find.bySemanticsLabel('Revoke access to Study circle for learner 7'),
      findsOneWidget,
    );
  });

  testWidgets('revoking an approved request shows a confirming snackbar', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_approvedRow()]);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revoke access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.lastRevokeId, 'req-2');
    expect(find.textContaining('Revoked'), findsWidgets);
  });

  testWidgets('a failed revoke shows a try-again snackbar, not a false success', (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    final service = _FakeApprovalService(rows: [_approvedRow()], revokeResult: false);
    await tester.pumpWidget(
      _wrap(GuardianApprovalsScreen(approvalService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revoke access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('We could not revoke that approval. Try again.'), findsOneWidget);
  });

  testWidgets('mixed pending and decided requests render both sections', (tester) async {
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

    expect(find.text(GuardianApprovalsScreen.reviewSectionTitle), findsOneWidget);
    expect(find.text(GuardianApprovalsScreen.decidedSectionTitle), findsOneWidget);
    expect(find.text('Approve join'), findsOneWidget);
    expect(find.text('Revoke access'), findsOneWidget);
  });

  testWidgets('large text scale does not overflow the approval card actions', (tester) async {
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
    expect(find.text('Approve join'), findsOneWidget);

    // At this text scale, the decided-section card may render below the
    // initial viewport + cache extent, same as a real device would need a
    // scroll. Scroll to it explicitly rather than assuming it is prebuilt.
    await tester.scrollUntilVisible(
      find.text('Revoke access'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revoke access'), findsOneWidget);
  });

  testWidgets('approve and revoke controls meet the 48dp minimum tap target', (tester) async {
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
          find.ancestor(
            of: find.text('Approve join').first,
            matching: find.byType(ConstrainedBox),
          ).first,
        )
        .height;
    final revokeHeight = tester
        .getSize(
          find.ancestor(
            of: find.text('Revoke access').first,
            matching: find.byType(ConstrainedBox),
          ).first,
        )
        .height;

    expect(approveHeight, greaterThanOrEqualTo(48));
    expect(revokeHeight, greaterThanOrEqualTo(48));
  });

  testWidgets('renders without overflow on a small phone width', (tester) async {
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
    expect(find.text('Approve join'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Revoke access'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revoke access'), findsOneWidget);
  });

  testWidgets('renders without overflow on a large phone width', (tester) async {
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
    expect(find.text('Approve join'), findsOneWidget);
    expect(find.text('Revoke access'), findsOneWidget);
  });

  testWidgets('empty state skips its entrance animation when reduced motion is requested',
      (tester) async {
    _pinTestViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
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

    expect(find.text(GuardianApprovalsScreen.guardianApprovalsEmptyTitle), findsOneWidget);
    // The widget skips wrapping its content in TweenAnimationBuilder entirely
    // when reduced motion is requested (see _EmptyPanel.build), rather than
    // merely running the same animation at zero duration.
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets(
    'RTL mirrors section-header badge and chip order without hardcoded left/right',
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
      final titleLtr = tester.getTopLeft(find.text(GuardianApprovalsScreen.reviewSectionTitle));
      final badgeLtr = tester.getTopLeft(find.text('1'));
      final membersChipLtr = tester.getTopLeft(find.text('12 members'));
      final adultsChipLtr = tester.getTopLeft(find.text('2 adults'));
      expect(badgeLtr.dx, greaterThan(titleLtr.dx));
      expect(membersChipLtr.dx, lessThan(adultsChipLtr.dx));

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
      final titleRtl = tester.getTopLeft(find.text(GuardianApprovalsScreen.reviewSectionTitle));
      final badgeRtl = tester.getTopLeft(find.text('1'));
      final membersChipRtl = tester.getTopLeft(find.text('12 members'));
      final adultsChipRtl = tester.getTopLeft(find.text('2 adults'));
      expect(badgeRtl.dx, lessThan(titleRtl.dx));
      expect(membersChipRtl.dx, greaterThan(adultsChipRtl.dx));
    },
  );

  testWidgets('3.0x text scale on a small phone does not overflow cards or chips', (tester) async {
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
    expect(find.text('Approve join'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Revoke access'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revoke access'), findsOneWidget);
  });

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
}
