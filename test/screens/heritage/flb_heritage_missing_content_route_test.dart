import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/heritage/flb_heritage_detail_screen.dart';

void main() {
  testWidgets(
    'heritage detail route with null args shows AppLocalizations message',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/flb-heritage-detail');
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
          routes: {
            '/flb-heritage-detail': (context) {
              final content = heritageDetailFromArguments(null);
              if (content == null) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      AppLocalizations.of(context)!.flbHeritageMissingContent,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Missing heritage content'), findsOneWidget);
    },
  );
}
