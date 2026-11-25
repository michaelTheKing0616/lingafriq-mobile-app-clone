import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('the choice survives a new controller', () async {
    final first = ReadingOptionController();
    await first.setEnabled(true);
    final second = ReadingOptionController();
    await second.load();
    expect(second.enabled, isTrue);
    expect(LingAfriqType.targetNow(second).fontFamily, LingAfriqType.targetFamily);
    expect(LingAfriqType.targetNow(second).letterSpacing, LingAfriqTokens.spacing4 / 16);
    expect(LingAfriqType.ui(second).fontFamily, LingAfriqType.targetFamily);
  });

  testWidgets('toggling applies Andika spacing without a new app', (tester) async {
    final option = ReadingOptionController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingOptionScope(
            controller: option,
            child: const _Preview(),
          ),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('Ẹ kú')).style?.letterSpacing, isNull);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Text>(find.text('Ẹ kú')).style?.fontFamily, 'Andika');
    expect(
      tester.widget<Text>(find.text('Ẹ kú')).style?.letterSpacing,
      LingAfriqTokens.spacing4 / 16,
    );
  });

  testWidgets('200% text does not overflow the row', (tester) async {
    final option = ReadingOptionController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: Scaffold(
            body: ReadingOptionTile(
              controller: option,
              title: ReadingOptionController.title,
              subtitle: ReadingOptionController.subtitle,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(ReadingOptionController.title), findsOneWidget);
  });
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final option = ReadingOptionScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ẹ kú', style: LingAfriqType.targetNow(option)),
        ReadingOptionTile(
          controller: option,
          title: ReadingOptionController.title,
          subtitle: ReadingOptionController.subtitle,
        ),
      ],
    );
  }
}
