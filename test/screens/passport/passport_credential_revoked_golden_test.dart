import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/passport/passport_credential_revoked_golden_test.dart'),
    );
  });

  testWidgets('credential_revoked_golden shows reason and next step', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: PassportCredentialScreen(
          verifyToken: 'payload.sig',
          level: 'B1',
          score: 72,
          credentialId: 'cred-revoked',
          methodologyVersionId: kPassportMethodologyVersionId,
          debugPublicationStatus: 'revoked',
          debugRevokedReason: 'Integrity review found mismatched proctor signals.',
          debugPublicationStatusLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This credential was revoked'), findsOneWidget);
    expect(find.textContaining('Integrity review'), findsOneWidget);
    expect(find.text('Email support'), findsOneWidget);

    await expectLater(
      find.byType(PassportCredentialScreen),
      matchesGoldenFile('goldens/credential_revoked_golden.png'),
    );
  });
}
