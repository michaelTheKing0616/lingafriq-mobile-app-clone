import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/games/templates/game_template_shell.dart';

void main() {
  group('GameTemplateShell', () {
    testWidgets('renders title, play area, and action bar', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: GameTemplateShell(
              title: 'Template Test',
              progressLabel: '1/5',
              scoreLabel: '10',
              playArea: const Center(child: Text('Play Area')),
              actionBar: const Text('Action Bar'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Template Test'), findsOneWidget);
      expect(find.text('Play Area'), findsOneWidget);
      expect(find.text('Action Bar'), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows loading overlay message when loading is true', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: GameTemplateShell(
              title: 'Loading Test',
              loading: true,
              loadingMessage: 'Preparing game',
              playArea: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Preparing game'), findsOneWidget);
    });
  });
}
