import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:lingafriq/screens/help/stitch_navigation_hub_screen.dart';
import 'package:lingafriq/widgets/pan_african_drawer.dart';

import '../../compliance/golden_kit.dart';

// This test is about which entries exist, not the legacy drawer's layout
// (its header overflows in the test font); only overflow reports are ignored.
Future<void> _pump(WidgetTester t, bool visible) async {
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.toString().contains('overflowed')) return;
    prev?.call(d);
  };
  addTearDown(() => FlutterError.onError = prev);
  await _pumpDrawer(t, visible);
}

Future<void> _pumpDrawer(WidgetTester t, bool visible) => pumpVariant(
  t,
  const GoldenVariant('tall', Size(400, 3000)),
  const Scaffold(body: PanAfricanDrawer()),
  overrides: [globalChatEntryVisibleProvider.overrideWithValue(visible)],
  settle: false,
);

void main() {
  testWidgets('drawer hides Global Chat when policy denies', (t) async {
    await _pump(t, false);
    expect(find.text('Global Chat'), findsNothing);
  });

  testWidgets('drawer shows Global Chat for allowed adults', (t) async {
    await _pump(t, true);
    expect(find.text('Global Chat'), findsOneWidget);
  });

  for (final visible in [false, true]) {
    testWidgets('Stitch hub lists Global chat only when allowed ($visible)', (
      t,
    ) async {
      await pumpVariant(
        t,
        const GoldenVariant('tall', Size(400, 3000)),
        const StitchNavigationHubScreen(),
        overrides: [globalChatEntryVisibleProvider.overrideWithValue(visible)],
      );
      await t.tap(find.text('Community · chat · classroom'));
      await t.pumpAndSettle();
      expect(find.text('Private chat inbox'), findsOneWidget);
      expect(
        find.text('/global_chat'),
        visible ? findsOneWidget : findsNothing,
      );
    });
  }
}
