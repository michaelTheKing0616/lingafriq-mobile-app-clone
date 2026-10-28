import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/consent_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

class _ConsentFakeService extends GuardianLinkService {
  @override
  Future<GuardianSubmitState> submitConsent({
    required int childUserId,
    required bool attestationConfirmed,
  }) async {
    if (!attestationConfirmed) return GuardianSubmitState.error;
    return GuardianSubmitState.sent;
  }
}

void main() {
  testWidgets('consent requires attestation before submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 55,
          initialStatus: 'verifying',
          regime: 'NDPA_2023',
          guardianLinkService: _ConsentFakeService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Approve and unlock'));
    await tester.tap(find.text('Approve and unlock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Confirm the statement'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Approve and unlock'));
    await tester.tap(find.text('Approve and unlock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Social features are on'), findsOneWidget);
  });
}
