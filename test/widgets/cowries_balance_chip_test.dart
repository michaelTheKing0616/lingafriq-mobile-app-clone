import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/gamification/gamification_widgets.dart';

void main() {
  testWidgets('CowriesBalanceChip exposes semantics label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CowriesBalanceChip(amount: 1200)),
      ),
    );
    expect(find.bySemanticsLabel('Cowries balance'), findsOneWidget);
    expect(find.text('1.2K'), findsOneWidget);
  });
}
