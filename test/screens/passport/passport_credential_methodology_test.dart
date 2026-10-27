import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';

import '../../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/screens/passport/passport_credential_methodology_test.dart'),
    );
  });

  testWidgets('methodology_link_golden shows CEFR methodology row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: const PassportCredentialScreen(
          verifyToken: 'payload.sig',
          level: 'B1',
          score: 72,
          methodologyVersionId: kPassportMethodologyVersionId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CEFR mapping methodology'), findsOneWidget);
    expect(find.textContaining('Version $kPassportMethodologyVersionId'), findsOneWidget);

    await expectLater(
      find.byType(PassportCredentialScreen),
      matchesGoldenFile('goldens/methodology_link_golden.png'),
    );
  });
}
