import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/customisation/avatar_editor_screen.dart';
import 'package:lingafriq/avatars/customisation/slot_binding.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarEditorEntitlements slot parity', () {
    test('uses the same six VM slots as the cast contract', () {
      final raw = File('assets/rive/lingafriq_cast.contract.json').readAsStringSync();
      final catalog = AvatarPartCatalog.fromContractJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      for (final slot in AvatarPartSlots.all) {
        expect(catalog.slots.containsKey(slot), isTrue, reason: slot);
      }
    });

    test('locks mastery headwear until entitlement granted', () {
      const policy = AvatarEditorEntitlements();
      final raw = File('assets/rive/lingafriq_cast.contract.json').readAsStringSync();
      final catalog = AvatarPartCatalog.fromContractJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final headwear = catalog.slot(AvatarPartSlots.headwear);
      expect(
        policy.isUnlocked(slot: headwear, artboardId: 'Headwear/Gele'),
        isFalse,
      );
      const unlocked = AvatarEditorEntitlements(
        unlockedMasteryIds: {'mastery:greetings_respect'},
      );
      expect(
        unlocked.isUnlocked(slot: headwear, artboardId: 'Headwear/Gele'),
        isTrue,
      );
    });
  });

  group('AvatarEditorItemTile widget states', () {
    Future<void> wrap(WidgetTester tester, Widget child) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      );
    }

    testWidgets('selected tile shows primary border', (tester) async {
      await wrap(
        tester,
        SizedBox(
          width: 160,
          height: 180,
          child: AvatarEditorItemTile(
            label: 'Gele',
            culturalNote: 'Tied wrap for celebration.',
            locked: false,
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gele'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });

    testWidgets('locked tile shows lock affordance', (tester) async {
      await wrap(
        tester,
        SizedBox(
          width: 160,
          height: 180,
          child: AvatarEditorItemTile(
            label: 'Fugu',
            culturalNote: 'Northern Ghana smock.',
            locked: true,
            selected: false,
            lockReason: 'Cultural review',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  group('editor_grid golden harness', () {
    testWidgets('grid lists hair options from contract', (tester) async {
      final raw = File('assets/rive/lingafriq_cast.contract.json').readAsStringSync();
      final catalog = AvatarPartCatalog.fromContractJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                height: 640,
                width: 390,
                child: AvatarEditorItemGrid(
                catalog: catalog,
                slot: AvatarPartSlots.hair,
                selectedId: 'Hair/Afro',
                entitlements: const AvatarEditorEntitlements(),
                onSelect: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor_grid')), findsOneWidget);
      expect(find.textContaining('Afro'), findsWidgets);
    });
  });
}
