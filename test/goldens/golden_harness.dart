import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/text/diacritic_keyboard.dart';
import 'package:lingafriq/design/typography.dart';

/// Loads bundled Andika and the body face the same way the screen-frame
/// test does, then compares every declared catalogue state.
Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(asset).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(LingAfriqType.targetFamily, 'assets/google_fonts/Andika-Regular.ttf');
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('widgetbook stays out of the release app', () {
    final String root = File('pubspec.yaml').readAsStringSync().toLowerCase();
    expect(root.contains('widgetbook'), isFalse);
    final String catalogue = File('widgetbook/pubspec.yaml').readAsStringSync();
    expect(catalogue.contains('widgetbook: 3.25.0'), isTrue);
    expect(catalogue.contains('path: ..'), isTrue);
    expect(_treeMentions(Directory('android'), 'widgetbook'), isFalse);
    expect(_treeMentions(Directory('ios'), 'widgetbook'), isFalse);
  });

  test('every use case declares a real state list', () {
    expect(catalogueUseCases, isNotEmpty);
    final Set<String> ids = <String>{};
    for (final CatalogueUseCase useCase in catalogueUseCases) {
      expect(ids.add(useCase.id), isTrue, reason: '${useCase.id} is duplicated');
      expect(useCase.states, isNotEmpty, reason: '${useCase.id} has no states');
      expect(useCase.states.toSet().length, useCase.states.length);
    }
    expect(catalogueTargetSample, LingAfriqType.glyphProof.split(' · ').first);
    expect(catalogueSurface.width, 390);
    expect(catalogueTextScales, <double>[1, 2]);
    expect(catalogueBrightnesses, <Brightness>[Brightness.light, Brightness.dark]);
  });

  test('the pixel spec lists size and token ids without a hex colour', () {
    final String spec = File('test/goldens/pixel_spec.md').readAsStringSync();
    expect(spec.contains('\u2014'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(spec), isFalse);
    expect(RegExp(r'0x[0-9A-Fa-f]{6,8}').hasMatch(spec), isFalse);
    expect(spec.toLowerCase().contains('world-class'), isFalse);
    expect(spec.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(spec), isFalse);
    expect(RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(spec), isFalse);
    expect(spec.contains('390'), isTrue);
    expect(spec.contains('640'), isTrue);
    expect(spec.contains('LingAfriqTokens'), isTrue);
    expect(spec.contains('LingAfriqType'), isTrue);
    expect(spec.contains('LingAfriqTokens.spacing16'), isTrue);
    expect(spec.contains('LingAfriqTokens.spacing12'), isTrue);
    expect(spec.contains('LingAfriqTokens.spacing8'), isTrue);
    expect(spec.contains('LingAfriqTokens.spacing4'), isTrue);
    expect(spec.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(spec.contains('LingAfriqTokens.radiussm'), isTrue);
    expect(spec.contains('LingAfriqTokens.elevationLightsm'), isTrue);
    expect(spec.contains('LingAfriqTokens.elevationDarksm'), isTrue);
    expect(spec.contains('LingAfriqTokens.navy'), isTrue);
    expect(spec.contains('LingAfriqType.target'), isTrue);
    expect(spec.contains('LingAfriqType.ui'), isTrue);
    expect(spec.contains('LingAfriqType.targetNow'), isTrue);
    expect(spec.contains('LingAfriqType.bodyFamily'), isTrue);
    expect(spec.contains('LingAfriqType.bodySize'), isTrue);
    expect(spec.contains('LingAfriqType.targetHeight'), isTrue);
    for (final CatalogueUseCase useCase in catalogueUseCases) {
      expect(spec.contains(useCase.id), isTrue, reason: spec);
      for (final String state in useCase.states) {
        expect(spec.contains(state), isTrue, reason: '${useCase.id} $state');
      }
    }
  });

  for (final CatalogueUseCase useCase in catalogueUseCases) {
    for (final String state in useCase.states) {
      for (final Brightness brightness in catalogueBrightnesses) {
        for (final double scale in catalogueTextScales) {
          final String name = _goldenName(useCase.id, state, brightness, scale);
          testWidgets(name, (WidgetTester tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = catalogueSurface;
            addTearDown(tester.view.reset);
            await tester.binding.setSurfaceSize(catalogueSurface);
            addTearDown(() => tester.binding.setSurfaceSize(null));

            await tester.pumpWidget(useCase.build(brightness, scale, state));
            expect(tester.takeException(), isNull);
            _expectState(tester, useCase.id, state);

            await expectLater(
              find.byKey(catalogueSurfaceKey),
              matchesGoldenFile(name),
            );
          });
        }
      }
    }
  }
}

void _expectState(WidgetTester tester, String useCaseId, String state) {
  switch (useCaseId) {
    case 'targetText':
      expect(find.text(catalogueTargetSample), findsOneWidget);
    case 'diacriticKeyboard':
      final DiacriticKeyboard keyboard = tester.widget<DiacriticKeyboard>(
        find.byType(DiacriticKeyboard),
      );
      if (state == 'yoruba') {
        expect(keyboard.languageId, 'yo');
        expect(keyboard.status, DiacriticKeyboardStatus.ready);
        expect(find.byType(DiacriticKeyboardNoLayout), findsNothing);
      } else {
        expect(keyboard.languageId, 'am');
        expect(keyboard.status, DiacriticKeyboardStatus.noLayout);
        expect(find.text(catalogueNoLayoutMessage), findsOneWidget);
      }
      final ScrollableState scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(DiacriticKeyboard),
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(scroll.position.maxScrollExtent, 0);
    case 'readingOption':
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, state == 'on');
      final Text title = tester.widget<Text>(find.text(ReadingOptionController.title));
      expect(
        title.style?.fontFamily,
        state == 'on' ? LingAfriqType.targetFamily : LingAfriqType.bodyFamily,
      );
  }
}

String _goldenName(String id, String state, Brightness brightness, double scale) {
  final String scaleLabel = scale.toStringAsFixed(1);
  return '${id}_${state}_${brightness.name}_$scaleLabel.png';
}

bool _treeMentions(Directory root, String needle) {
  expect(root.existsSync(), isTrue, reason: root.path);
  for (final FileSystemEntity entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final String path = entity.path.toLowerCase();
    if (_skipBinary(path)) continue;
    if (entity.lengthSync() > 1000000) continue;
    final String text = entity.readAsStringSync().toLowerCase();
    if (text.contains(needle)) {
      fail('$path references $needle');
    }
  }
  return false;
}

bool _skipBinary(String path) {
  const List<String> suffixes = <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.jar',
    '.so',
    '.a',
    '.zip',
    '.ttf',
    '.otf',
    '.bin',
  ];
  for (final String suffix in suffixes) {
    if (path.endsWith(suffix)) return true;
  }
  return false;
}
