import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/approvals_screen.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

class _FakeApprovalService extends GuardianApprovalService {
  _FakeApprovalService(this._rows);

  final List<GuardianGroupJoinRequestRow> _rows;

  @override
  Future<List<GuardianGroupJoinRequestRow>> fetchApprovals() async => _rows;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state shows guardian.approvals.empty copy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService([]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(GuardianApprovalsScreen.guardianApprovalsEmptyTitle), findsOneWidget);
    expect(find.textContaining('circle or classroom'), findsOneWidget);
  });

  testWidgets('pending request shows approve affordance with semantics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService([
            GuardianGroupJoinRequestRow(
              requestId: 'req-1',
              childUserId: 42,
              groupKind: 'classroom',
              groupName: 'Yoruba Circle Class',
              memberCount: 12,
              adultMemberCount: 2,
              moderationStatus: 'moderated',
              status: 'pending',
              expiresAt: DateTime.utc(2026, 2, 1),
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yoruba Circle Class'), findsOneWidget);
    expect(find.text('Approve join'), findsOneWidget);
    expect(find.textContaining('Posts are moderated'), findsOneWidget);
  });

  testWidgets('approved request shows revoke control', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianApprovalsScreen(
          approvalService: _FakeApprovalService([
            GuardianGroupJoinRequestRow(
              requestId: 'req-2',
              childUserId: 7,
              groupKind: 'circle',
              groupName: 'Study circle',
              memberCount: 5,
              adultMemberCount: 1,
              moderationStatus: 'open',
              status: 'approved',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Revoke access'), findsOneWidget);
  });
}
