import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';
import 'package:lingafriq/services/passport/passport_service.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/passport/passport_portfolio_golden_test.dart'),
    );
  });

  testWidgets('passport_portfolio_golden populated evidence list', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
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
          methodologyVersionId: kPassportMethodologyVersionId,
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your credential'), findsOneWidget);
    expect(find.text('Evidence portfolio'), findsOneWidget);
    expect(find.text('greet_morning'), findsOneWidget);

    await expectLater(
      find.byType(PassportCredentialScreen),
      matchesGoldenFile('goldens/passport_portfolio_golden.png'),
    );
  });

  testWidgets('passport_portfolio prereq blocked hides credential', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: const PassportCredentialScreen(
          verifyToken: 'payload.sig',
          level: 'B1',
          score: 72,
          debugPortfolioLoading: false,
          debugPortfolioPrereqBlocked: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passport is not available yet'), findsOneWidget);
    expect(find.text('Your credential'), findsNothing);
  });
}
