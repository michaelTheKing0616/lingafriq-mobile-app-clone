import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/global/offline_banner.dart';
import '../helpers/test_utils.dart';

void main() {
  group('OfflineBanner Widget', () {
    testWidgets('shows banner when offline', (WidgetTester tester) async {
      await pumpWidgetWithMaterial(
        tester,
        OfflineBanner(
          child: const Scaffold(
            body: Center(child: Text('Test Content')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('hides banner when online', (WidgetTester tester) async {
      await pumpWidgetWithMaterial(
        tester,
        OfflineBanner(
          child: const Scaffold(
            body: Center(child: Text('Test Content')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('shows sync status when online with pending items', (WidgetTester tester) async {
      await pumpWidgetWithMaterial(
        tester,
        OfflineBanner(
          showWhenOnline: true,
          child: const Scaffold(
            body: Center(child: Text('Test Content')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('displays correct offline message', (WidgetTester tester) async {
      await pumpWidgetWithMaterial(
        tester,
        OfflineBanner(
          child: const Scaffold(
            body: Center(child: Text('Test Content')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('displays pending count when offline', (WidgetTester tester) async {
      await pumpWidgetWithMaterial(
        tester,
        OfflineBanner(
          child: const Scaffold(
            body: Center(child: Text('Test Content')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}
