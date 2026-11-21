import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/focus_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('focus follows reading order and can leave the column', (tester) async {
    final List<FocusNode> nodes = List<FocusNode>.generate(3, (_) => FocusNode());
    final FocusNode outside = FocusNode();
    addTearDown(() {
      for (final FocusNode node in nodes) {
        node.dispose();
      }
      outside.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              LingFocusOrder(
                children: <Widget>[
                  for (var index = 0; index < nodes.length; index++)
                    TextButton(
                      focusNode: nodes[index],
                      onPressed: () {},
                      child: Text('Item ${index + 1}'),
                    ),
                ],
              ),
              TextButton(
                focusNode: outside,
                onPressed: () {},
                child: const Text('Outside'),
              ),
            ],
          ),
        ),
      ),
    );

    final List<FocusTraversalOrder> orders = tester
        .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
        .toList();
    expect(
      orders.map((FocusTraversalOrder order) => (order.order as NumericFocusOrder).order),
      <double>[0, 1, 2],
    );

    nodes[0].requestFocus();
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);

    expect(nodes[0].nextFocus(), isTrue);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);

    expect(nodes[1].nextFocus(), isTrue);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);

    expect(nodes[2].previousFocus(), isTrue);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);

    nodes[2].requestFocus();
    await tester.pump();
    expect(nodes[2].nextFocus(), isTrue);
    await tester.pump();
    expect(outside.hasFocus, isTrue);
    expect(nodes[0].hasFocus, isFalse);
    expect(nodes[2].hasFocus, isFalse);
  });

  testWidgets('the last item does not wrap back to the first', (tester) async {
    final List<FocusNode> nodes = List<FocusNode>.generate(3, (_) => FocusNode());
    addTearDown(() {
      for (final FocusNode node in nodes) {
        node.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LingFocusOrder(
            children: <Widget>[
              for (final FocusNode node in nodes)
                TextButton(
                  focusNode: node,
                  onPressed: () {},
                  child: const Text('Step'),
                ),
            ],
          ),
        ),
      ),
    );

    nodes[2].requestFocus();
    await tester.pump();
    expect(nodes[2].nextFocus(), isFalse);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);
    expect(nodes[0].hasFocus, isFalse);
  });
}
