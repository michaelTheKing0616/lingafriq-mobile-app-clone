import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/settings/downloads_screen.dart';
import 'package:lingafriq/services/offline/lesson_download_service.dart';

import '../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/offline/download_policy_test.dart'),
    );
  });

  test('mobile data waits and a pack over 30 MB is flagged', () {
    expect(
      downloadGate(wifiOnly: true, onWifi: false, allowMobile: false, lowStorage: false),
      DownloadGate.waitForWifi,
    );
    expect(
      downloadGate(wifiOnly: true, onWifi: false, allowMobile: true, lowStorage: false),
      DownloadGate.proceed,
    );
    expect(
      downloadGate(wifiOnly: true, onWifi: true, allowMobile: false, lowStorage: false),
      DownloadGate.proceed,
    );
    expect(
      downloadGate(wifiOnly: false, onWifi: false, allowMobile: false, lowStorage: true),
      DownloadGate.lowStorage,
    );
    expect(packExceedsCeiling(31 * 1024 * 1024), isTrue);
    expect(packExceedsCeiling(12 * 1024 * 1024), isFalse);
    expect(declaredPackBytes({'totalBytes': 12 * 1024 * 1024}), 12 * 1024 * 1024);
    expect(formatPackSize(12 * 1024 * 1024), '12.0 MB');
  });

  testWidgets('download states show size, Wi-Fi wait, and delete', (WidgetTester tester) async {
    await pinSurface(tester, size: const Size(360, 640));
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: DownloadsScreen(
          wifiOnly: true,
          lowStorage: true,
          onWifiOnlyChanged: (_) {},
          onDownload: (language, {required allowMobile}) {},
          onDelete: (language) async {
            deleted = true;
          },
          units: const [
            DownloadUnit(
              language: 'yoruba',
              title: 'Yoruba unit',
              bytes: 12 * 1024 * 1024,
              state: DownloadUnitState.pausedWifi,
            ),
            DownloadUnit(
              language: 'swahili',
              title: 'Swahili unit',
              bytes: 32 * 1024 * 1024,
              state: DownloadUnitState.complete,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12.0 MB'), findsOneWidget);
    expect(find.text('Waiting for Wi-Fi'), findsOneWidget);
    expect(find.text('Over 30 MB'), findsOneWidget);
    expect(find.text('Not enough storage'), findsWidgets);

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Yoruba unit? This frees the storage it uses.'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../golden/goldens/downloads_states.png'),
    );
  });
}
