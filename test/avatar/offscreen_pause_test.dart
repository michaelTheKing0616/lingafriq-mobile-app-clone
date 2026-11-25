import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/viewport_gate.dart';

void main() {
  testWidgets('offscreen child reports not visible', (tester) async {
    final seen = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: ListView(
              children: [
                const SizedBox(height: 400),
                ViewportGate(
                  onVisible: seen.add,
                  child: const SizedBox(key: Key('row'), height: 40, width: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(seen, isNotEmpty);
    expect(seen.last, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(seen.last, isTrue);
  });
}
