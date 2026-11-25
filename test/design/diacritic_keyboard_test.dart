import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/text/diacritic_keyboard.dart';
import 'package:lingafriq/design/tokens.g.dart';

Finder _label(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  );
}

Widget _host({
  required String languageId,
  required TextEditingController controller,
  required String noLayoutMessage,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(
      body: DiacriticKeyboard(
        languageId: languageId,
        controller: controller,
        noLayoutMessage: noLayoutMessage,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeDiacritics', () {
    test('reorders dot below under the tone and composes the base', () {
      expect(normalizeDiacritics('e\u0301\u0323').runes.toList(), <int>[0x1EB9, 0x0301]);
      expect(normalizeDiacritics('e\u0323\u0301').runes.toList(), <int>[0x1EB9, 0x0301]);
      expect(normalizeDiacritics('o\u0300\u0323').runes.toList(), <int>[0x1ECD, 0x0300]);
      expect(normalizeDiacritics('\u1EB9\u0301').runes.toList(), <int>[0x1EB9, 0x0301]);
    });

    test('leaves hooked Hausa letters and Swahili ng\' alone', () {
      expect(normalizeDiacritics('\u0253\u0257\u0199\u01B4'), '\u0253\u0257\u0199\u01B4');
      expect(normalizeDiacritics("ng'"), "ng'");
      expect(normalizeDiacritics('n\u0307').runes.toList(), <int>[0x1E45]);
    });

    test('is idempotent', () {
      const sample = 'e\u0301\u0323 \u0253 ng\'';
      final once = normalizeDiacritics(sample);
      expect(normalizeDiacritics(once), once);
    });
  });

  group('variant map', () {
    test('covers the required letters and does not invent tone on non-tonal rows', () {
      final yo = DiacriticLayouts.forLanguage('yo')!.variants;
      expect(yo, containsAll(<String>['\u1EB9', '\u1ECD', '\u1E63', '\u1EB9\u0301', '\u1ECD\u0300']));

      final ig = DiacriticLayouts.forLanguage('ig')!.variants.toList();
      expect(ig, containsAll(<String>['\u1ECB', '\u1E45', '\u1ECD', '\u1EE5']));
      expect(ig, isNot(contains('\u00E9')));

      final ha = DiacriticLayouts.forLanguage('ha')!.variants;
      expect(ha, containsAll(<String>['\u0253', '\u0257', '\u0199', '\u01B4']));

      final zu = DiacriticLayouts.forLanguage('zu')!.variants.toList();
      expect(zu, containsAll(<String>['ch', 'gc', 'nc', 'ngc', 'qh', 'gq', 'nq', 'ngq', 'xh', 'gx', 'nx', 'ngx']));
      expect(zu, isNot(contains('nkc')));

      final xh = DiacriticLayouts.forLanguage('xh')!.variants;
      expect(xh, containsAll(<String>['nkc', 'nkq', 'nkx', 'xh']));

      expect(DiacriticLayouts.forLanguage('sw')!.variants, contains("ng'"));
      expect(DiacriticLayouts.forLanguage('YO')?.languageId, 'yo');
      expect(DiacriticLayouts.forLanguage('tw'), isNull);
      expect(DiacriticLayouts.forLanguage('am'), isNull);
    });
  });

  test('insertDiacritic writes NFC and keeps the caret after the cluster', () {
    final controller = TextEditingController(text: 'ea');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 1);
    insertDiacritic(controller, '\u0301\u0323');
    expect(controller.text.runes.toList(), <int>[0x1EB9, 0x0301, 0x61]);
    expect(controller.selection.extentOffset, 2);
  });

  Future<void> openBase(WidgetTester tester, String label) async {
    await tester.longPress(_label(label));
    await tester.pump();
  }

  testWidgets('Yoruba long-press shows ẹ ọ ṣ ẹ́ ọ̀ and inserts NFC', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'yo', controller: controller, noLayoutMessage: 'none'));

    for (final base in ['a', 'e', 'i', 'o', 'u', 's', 'n']) {
      expect(_label(base), findsOneWidget);
    }

    await openBase(tester, 'e');
    expect(find.byKey(const ValueKey<String>('diacritic-variants-e')), findsOneWidget);
    expect(_label('\u1EB9'), findsOneWidget);
    expect(_label('\u1EB9\u0301'), findsOneWidget);
    await tester.tap(_label('\u1EB9\u0301'));
    await tester.pump();
    expect(controller.text.runes.toList(), <int>[0x1EB9, 0x0301]);

    await openBase(tester, 'o');
    expect(_label('\u1ECD'), findsOneWidget);
    expect(_label('\u1ECD\u0300'), findsOneWidget);
    await tester.tap(_label('\u1ECD\u0300'));
    await tester.pump();

    await openBase(tester, 's');
    expect(_label('\u1E63'), findsOneWidget);
    await tester.tap(_label('\u1E63'));
    await tester.pump();
    expect(controller.text.runes.toList(), <int>[0x1EB9, 0x0301, 0x1ECD, 0x0300, 0x1E63]);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('Igbo long-press shows ị ṅ ọ ụ', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'ig', controller: controller, noLayoutMessage: 'none'));

    await openBase(tester, 'i');
    expect(_label('\u1ECB'), findsOneWidget);
    await openBase(tester, 'n');
    expect(_label('\u1E45'), findsOneWidget);
    await openBase(tester, 'o');
    expect(_label('\u1ECD'), findsOneWidget);
    await openBase(tester, 'u');
    expect(_label('\u1EE5'), findsOneWidget);
    await tester.tap(_label('\u1EE5'));
    await tester.pump();
    expect(controller.text, '\u1EE5');
    handle.dispose();
  });

  testWidgets('Hausa long-press shows ɓ ɗ ƙ ƴ', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'ha', controller: controller, noLayoutMessage: 'none'));

    final expected = <String, String>{
      'b': '\u0253',
      'd': '\u0257',
      'k': '\u0199',
      'y': '\u01B4',
    };
    for (final entry in expected.entries) {
      await openBase(tester, entry.key);
      expect(_label(entry.value), findsOneWidget);
    }
    await tester.tap(_label('\u01B4'));
    await tester.pump();
    expect(controller.text, '\u01B4');
    handle.dispose();
  });

  testWidgets('Zulu long-press shows the click series and not the Xhosa nkc row', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'zu', controller: controller, noLayoutMessage: 'none'));

    await openBase(tester, 'c');
    expect(_label('ch'), findsOneWidget);
    expect(_label('ngc'), findsOneWidget);
    expect(_label('nkc'), findsNothing);
    await openBase(tester, 'x');
    expect(_label('xh'), findsOneWidget);
    expect(_label('ngx'), findsOneWidget);
    await tester.tap(_label('xh'));
    await tester.pump();
    expect(controller.text, 'xh');
    handle.dispose();
  });

  testWidgets('Xhosa long-press adds nkc nkq nkx', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'xh', controller: controller, noLayoutMessage: 'none'));

    await openBase(tester, 'c');
    expect(_label('nkc'), findsOneWidget);
    await openBase(tester, 'q');
    expect(_label('nkq'), findsOneWidget);
    await openBase(tester, 'x');
    expect(_label('nkx'), findsOneWidget);
    expect(_label('xh'), findsOneWidget);
    handle.dispose();
  });

  testWidgets("Swahili long-press on n offers ng'", (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(languageId: 'sw', controller: controller, noLayoutMessage: 'none'));

    expect(_label('a'), findsNothing);
    await openBase(tester, 'n');
    expect(_label("ng'"), findsOneWidget);
    await tester.tap(_label("ng'"));
    await tester.pump();
    expect(controller.text, "ng'");
    handle.dispose();
  });

  testWidgets('reduced motion shows the variants on the next frame', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    late Duration duration;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Builder(
              builder: (context) {
                duration = DiacriticKeyboard.popupDuration(context);
                return child ?? const SizedBox.shrink();
              },
            ),
          );
        },
        home: Scaffold(
          body: DiacriticKeyboard(
            languageId: 'yo',
            controller: controller,
            noLayoutMessage: 'none',
          ),
        ),
      ),
    );
    expect(duration, Duration.zero);
    expect(
      const Duration(milliseconds: LingAfriqTokens.motionProductInstant).inMilliseconds,
      lessThan(LingAfriqTokens.motionProductFast),
    );

    await tester.longPress(_label('e'));
    await tester.pump();
    await tester.tap(_label('\u1EB9'));
    await tester.pump();
    expect(controller.text, '\u1EB9');
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('a language with no layout shows an error state and keeps a normal field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    const message = 'No diacritic layout for this language.';
    await tester.pumpWidget(_host(languageId: 'am', controller: controller, noLayoutMessage: message));

    final keyboard = tester.widget<DiacriticKeyboard>(find.byType(DiacriticKeyboard));
    expect(keyboard.status, DiacriticKeyboardStatus.noLayout);
    final notice = tester.widget<DiacriticKeyboardNoLayout>(find.byType(DiacriticKeyboardNoLayout));
    expect(notice.languageId, 'am');
    expect(find.text(message), findsOneWidget);
    expect(_label('\u1EB9'), findsNothing);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly, isFalse);
    expect(field.enabled ?? true, isTrue);
    expect(field.keyboardType, isNot(TextInputType.none));

    await tester.enterText(find.byType(TextField), 'ሰላም');
    expect(controller.text, 'ሰላም');
    expect(tester.takeException(), isNull);
  });
}
