import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/diacritic_keyboard_bar.dart';

import '../helpers/test_utils.dart';

DiacriticKeyboardLayouts _layoutsFromRepoFile() {
  final path = File('assets/content/keyboard_layouts.json');
  return DiacriticKeyboardLayouts.fromJsonString(path.readAsStringSync());
}

void main() {
  late DiacriticKeyboardLayouts layouts;

  setUp(() {
    layouts = _layoutsFromRepoFile();
  });

  group('DiacriticKeyboardLayouts', () {
    test('parses wave-1 language layouts', () {
      expect(layouts.forLanguage('yo')?.letters, contains('ẹ'));
      expect(layouts.forLanguage('ig')?.letters, contains('ṅ'));
      expect(layouts.forLanguage('ha')?.letters, contains('ɓ'));
      expect(layouts.forLanguage('tw')?.letters, contains('ɛ'));
    });
  });

  group('insertDiacriticAtSelection', () {
    test('composes decomposed tone into NFC', () {
      final controller = TextEditingController(text: 'a');
      controller.selection = const TextSelection.collapsed(offset: 1);
      insertDiacriticAtSelection(controller, '\u0301');
      expect(controller.text, 'á');
    });
  });

  Widget _harness({
    required String languageId,
    required FocusNode focusNode,
    required TextEditingController controller,
    void Function(String id)? onLayoutMissing,
  }) {
    return Column(
      children: [
        TextField(controller: controller, focusNode: focusNode),
        DiacriticKeyboardBar(
          languageId: languageId,
          focusNode: focusNode,
          controller: controller,
          layouts: layouts,
          onLayoutMissing: onLayoutMissing,
        ),
      ],
    );
  }

  testWidgets('Yoruba bar shows ẹ ọ ṣ and tone keys', (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);

    await pumpWidgetWithScreenUtil(
      tester,
      _harness(languageId: 'yo', focusNode: focus, controller: controller),
    );
    focus.requestFocus();
    await tester.pump();

    expect(find.byKey(const ValueKey('diacritic-bar-visible')), findsOneWidget);
    expect(find.text('ẹ'), findsOneWidget);
    expect(find.text('ọ'), findsOneWidget);
    expect(find.text('ṣ'), findsOneWidget);
    expect(find.bySemanticsLabel('High tone mark'), findsOneWidget);

    await tester.tap(find.text('ẹ'));
    await tester.pump();
    expect(controller.text, 'ẹ');

    controller.text = 'o';
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.tap(find.bySemanticsLabel('Low tone mark'));
    await tester.pump();
    expect(controller.text, 'ò');
  });

  testWidgets('Igbo, Hausa and Twi show language-specific letters', (tester) async {
    final cases = <String, String>{
      'ig': 'ṅ',
      'ha': 'ɓ',
      'tw': 'ɛ',
    };

    for (final entry in cases.entries) {
      final focus = FocusNode();
      final controller = TextEditingController();
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);

      await pumpWidgetWithScreenUtil(
        tester,
        _harness(languageId: entry.key, focusNode: focus, controller: controller),
      );
      focus.requestFocus();
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('unknown language hides bar and reports missing layout', (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController();
    String? missing;
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);

    await pumpWidgetWithScreenUtil(
      tester,
      _harness(
        languageId: 'xx',
        focusNode: focus,
        controller: controller,
        onLayoutMissing: (id) => missing = id,
      ),
    );
    focus.requestFocus();
    await tester.pump();

    expect(find.byKey(const ValueKey('diacritic-bar-noLayout')), findsOneWidget);
    expect(missing, 'xx');
    expect(find.text('ẹ'), findsNothing);
  });

  testWidgets('bar stays hidden when field is not focused', (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);

    await pumpWidgetWithScreenUtil(
      tester,
      _harness(languageId: 'yo', focusNode: focus, controller: controller),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('diacritic-bar-hidden')), findsOneWidget);
  });
}
