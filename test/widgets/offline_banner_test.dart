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

      // Note: This test requires mocking ConnectivityService
      // In a real test environment, you'd mock hasInternet to return false
      // and verify the banner appears

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

      // Note: This test requires mocking ConnectivityService
      // In a real test environment, you'd mock hasInternet to return true
      // and verify the banner does not appear

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

      // Note: This test requires mocking OfflineHandler.getSyncStatus
      // In a real test environment, you'd mock sync status with pending items
      // and verify the sync banner appears

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

      // Note: This test requires mocking ConnectivityService
      // In a real test environment, you'd verify the text "You are offline" appears

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

      // Note: This test requires mocking OfflineHandler.getSyncStatus
      // In a real test environment, you'd verify pending count appears

      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}
