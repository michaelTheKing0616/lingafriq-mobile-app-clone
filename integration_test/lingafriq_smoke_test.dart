import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device/integration smoke: app mounts with the same [ProviderScope] overrides as production [main].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp mounts without throwing', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider
              .overrideWithValue(SharedPreferencesProvider(prefs)),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
