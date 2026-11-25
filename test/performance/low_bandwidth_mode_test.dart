import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/performance/low_bandwidth_mode.dart';

import '../golden/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/performance/low_bandwidth_mode_test.dart'),
    );
  });

  test('Data Saver turns the mode on and a manual choice wins', () {
    expect(
      resolveLowBandwidth(choice: LowBandwidthChoice.auto, dataSaverOn: true).source,
      'auto-on',
    );
    expect(
      resolveLowBandwidth(choice: LowBandwidthChoice.off, dataSaverOn: true).enabled,
      isFalse,
    );
    final manual = resolveLowBandwidth(choice: LowBandwidthChoice.on, dataSaverOn: false);
    expect(manual.enabled, isTrue);
    expect(manual.source, 'manual-on');
    expect(loadAudioImmediately(manual), isFalse);
    expect(
      imageLightUrl('https://cdn.example/photo.jpg', lowBandwidth: true),
      'https://cdn.example/photo.jpg?w=480&q=40',
    );
    expect(
      imageLightUrl('https://cdn.example/photo.jpg', lowBandwidth: false),
      'https://cdn.example/photo.jpg',
    );
  });

  testWidgets('settings show Data Saver and a manual on state', (WidgetTester tester) async {
    await pinSurface(tester, size: const Size(360, 180));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        home: const Scaffold(
          body: Column(
            children: [
              LowBandwidthSettingsTile(
                dataSaverOn: true,
                initial: LowBandwidthDecision(enabled: true, source: 'auto-on'),
              ),
              LowBandwidthSettingsTile(
                initial: LowBandwidthDecision(enabled: true, source: 'manual-on'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('On because Data Saver is on'), findsOneWidget);
    expect(find.text('On until you turn it off'), findsOneWidget);
    expect(find.text('Low bandwidth'), findsNWidgets(2));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../golden/goldens/lowbw_settings.png'),
    );
  });
}
