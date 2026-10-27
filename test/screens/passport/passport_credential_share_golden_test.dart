import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';
import 'package:lingafriq/services/passport/passport_service.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/passport/passport_credential_share_golden_test.dart'),
    );
  });

  testWidgets('credential_share_golden issued with Open Badge action', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
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
          credentialId: 'cred-golden',
          methodologyVersionId: kPassportMethodologyVersionId,
          issuedAt: DateTime(2026, 10, 20),
          debugPortfolioLoading: false,
          debugPortfolioPrereqBlocked: false,
          debugPortfolioEntries: [
            PassportPortfolioEntry(
              taskId: 'speak-greet',
              canDoId: 'greet_morning',
              cefrLevel: 'A1',
              scorerAttemptId: 'sc-1',
              scorerConfidence: 0.88,
              passedAt: DateTime(2026, 10, 20),
            ),
          ],
          debugOpenBadgeCredential: {
            '@context': ['https://www.w3.org/ns/credentials/v2'],
            'type': ['VerifiableCredential', 'OpenBadgeCredential'],
            'name': 'LingAfriq Proficiency Passport — YO B1',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share Open Badge'), findsOneWidget);
    expect(find.textContaining('verified can-do'), findsOneWidget);

    await expectLater(
      find.byType(PassportCredentialScreen),
      matchesGoldenFile('goldens/credential_share_golden.png'),
    );
  });
}
