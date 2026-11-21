import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_bottom_sheet.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_card.dart';
import 'package:lingafriq/design/components/ling_chip.dart';
import 'package:lingafriq/design/components/ling_dialog.dart';
import 'package:lingafriq/design/components/ling_list_row.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/components/ling_text_field.dart';
import 'package:lingafriq/design/text/diacritic_keyboard.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/typography.dart';

/// Loads bundled Andika and the body face the same way the screen-frame
/// test does, then compares every declared catalogue state.
Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.targetFamily,
      'assets/google_fonts/Andika-Regular.ttf',
    );
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
      expect(
        ids.add(useCase.id),
        isTrue,
        reason: '${useCase.id} is duplicated',
      );
      expect(useCase.states, isNotEmpty, reason: '${useCase.id} has no states');
      expect(useCase.states.toSet().length, useCase.states.length);
    }
    expect(catalogueTargetSample, LingAfriqType.glyphProof.split(' · ').first);
    expect(catalogueSurface.width, 390);
    expect(catalogueTextScales, <double>[1, 2]);
    expect(catalogueBrightnesses, <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]);
    expect(
      catalogueCoreGoldenFrames
          .map(
            (CatalogueGoldenFrame frame) =>
                '${frame.brightness.name}:${frame.textScale}',
          )
          .toList(),
      <String>['light:1.0', 'dark:1.0', 'light:2.0'],
    );
  });

  test('the pixel spec lists size and token ids without a hex colour', () {
    final String spec = File('test/goldens/pixel_spec.md').readAsStringSync();
    expect(spec.contains('\u2014'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(spec), isFalse);
    expect(RegExp(r'0x[0-9A-Fa-f]{6,8}').hasMatch(spec), isFalse);
    expect(spec.toLowerCase().contains('world-class'), isFalse);
    expect(spec.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(spec), isFalse);
    expect(
      RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(spec),
      isFalse,
    );
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
      for (final CatalogueGoldenFrame frame in useCase.goldenFrames) {
        final String name = _goldenName(
          useCase.id,
          state,
          frame.brightness,
          frame.textScale,
        );
        testWidgets(name, (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = catalogueSurface;
          addTearDown(tester.view.reset);
          await tester.binding.setSurfaceSize(catalogueSurface);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            useCase.build(frame.brightness, frame.textScale, state),
          );
          expect(tester.takeException(), isNull);
          _expectState(tester, useCase.id, state, frame.brightness);

          await expectLater(
            find.byKey(catalogueSurfaceKey),
            matchesGoldenFile(name),
          );
        });
      }
    }
  }
}

void _expectState(
  WidgetTester tester,
  String useCaseId,
  String state,
  Brightness brightness,
) {
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
        find
            .descendant(
              of: find.byType(DiacriticKeyboard),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, 0);
    case 'readingOption':
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, state == 'on');
      final Text title = tester.widget<Text>(
        find.text(ReadingOptionController.title),
      );
      expect(
        title.style?.fontFamily,
        state == 'on' ? LingAfriqType.targetFamily : LingAfriqType.bodyFamily,
      );
    case 'lingButton':
      _expectLabeledControl<LingButton>(
        tester,
        state: state,
        brightness: brightness,
        role: LingFillRole.accent,
        label: tester.widget<LingButton>(find.byType(LingButton)).label,
        unavailable: tester
            .widget<LingButton>(find.byType(LingButton))
            .unavailableLabel,
      );
    case 'lingChip':
      _expectLabeledControl<LingChip>(
        tester,
        state: state,
        brightness: brightness,
        role: LingFillRole.container,
        label: tester.widget<LingChip>(find.byType(LingChip)).label,
        unavailable: tester
            .widget<LingChip>(find.byType(LingChip))
            .unavailableLabel,
      );
    case 'lingListRow':
      _expectLabeledControl<LingListRow>(
        tester,
        state: state,
        brightness: brightness,
        role: LingFillRole.container,
        label: tester.widget<LingListRow>(find.byType(LingListRow)).label,
        unavailable: tester
            .widget<LingListRow>(find.byType(LingListRow))
            .unavailableLabel,
      );
    case 'lingCard':
      final LingCard card = tester.widget<LingCard>(find.byType(LingCard));
      _expectPanel(
        tester,
        state: state,
        brightness: brightness,
        kept: find.byType(TargetText),
      );
      expect(find.text(catalogueTargetSample), findsOneWidget);
      if (state == 'disabled') {
        expect(find.text(card.unavailableLabel), findsOneWidget);
        _expectDisabledSemantics(tester, find.byType(LingCard));
      }
    case 'lingTextField':
      _expectField(tester, state, brightness);
    case 'lingBottomSheet':
      _expectPanel(
        tester,
        state: state,
        brightness: brightness,
        kept: find.text(
          tester.widget<LingBottomSheet>(find.byType(LingBottomSheet)).label,
        ),
      );
      _expectLabeledControl<LingButton>(
        tester,
        state: state,
        brightness: brightness,
        role: LingFillRole.accent,
        label: tester
            .widget<LingBottomSheet>(find.byType(LingBottomSheet))
            .actionLabel,
        unavailable: tester
            .widget<LingBottomSheet>(find.byType(LingBottomSheet))
            .unavailableLabel,
      );
    case 'lingDialog':
      _expectPanel(
        tester,
        state: state,
        brightness: brightness,
        kept: find.text(
          tester.widget<LingDialog>(find.byType(LingDialog)).title,
        ),
      );
      _expectLabeledControl<LingButton>(
        tester,
        state: state,
        brightness: brightness,
        role: LingFillRole.accent,
        label: tester.widget<LingDialog>(find.byType(LingDialog)).actionLabel,
        unavailable: tester
            .widget<LingDialog>(find.byType(LingDialog))
            .unavailableLabel,
      );
    default:
      fail('No state assertion for $useCaseId');
  }
}

void _expectLabeledControl<T extends Widget>(
  WidgetTester tester, {
  required String state,
  required Brightness brightness,
  required LingFillRole role,
  required String label,
  required String unavailable,
}) {
  final Size size = tester.getSize(find.byType(T));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  expect(find.text(label), findsWidgets);
  final LingPalette palette = LingPalette.of(brightness);
  final Color resting = role == LingFillRole.accent
      ? palette.accent
      : palette.surfaceContainer;
  final Material material = tester.widget<Material>(find.byKey(LingMarks.fill));
  final Text labelText = tester.widget<Text>(find.text(label).first);
  expect(labelText.maxLines, isNull);
  expect(labelText.overflow, TextOverflow.visible);
  switch (state) {
    case 'default':
      expect(material.color, resting);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    case 'pressed':
      expect(material.color, isNot(resting));
    case 'focused':
      expect(find.byKey(LingMarks.ring), findsWidgets);
      expect(material.color, resting);
    case 'disabled':
      expect(material.color, palette.surfaceContainer);
      expect(find.text(unavailable), findsWidgets);
      _expectDisabledSemantics(tester, find.byType(T));
    case 'loading':
      expect(find.text(label), findsWidgets);
      final CircularProgressIndicator indicator = tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          );
      expect(indicator.value, isNotNull);
    default:
      fail(state);
  }
  if (role == LingFillRole.container && state == 'default') {
    expect(material.color, isNot(palette.accent));
  }
}

void _expectPanel(
  WidgetTester tester, {
  required String state,
  required Brightness brightness,
  required Finder kept,
}) {
  expect(kept, findsOneWidget);
  final LingPalette palette = LingPalette.of(brightness);
  final Material material = tester.widget<Material>(
    find.byKey(LingMarks.panel).first,
  );
  switch (state) {
    case 'default':
      expect(material.color, palette.surfaceContainer);
    case 'pressed':
      expect(material.color, isNot(palette.surfaceContainer));
    case 'focused':
      expect(find.byKey(LingMarks.ring), findsWidgets);
    case 'disabled':
    case 'loading':
      expect(kept, findsOneWidget);
  }
  if (state == 'loading') {
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNotNull,
    );
  }
}

void _expectField(WidgetTester tester, String state, Brightness brightness) {
  final LingTextField field = tester.widget<LingTextField>(
    find.byType(LingTextField),
  );
  final Size size = tester.getSize(find.byType(LingTextField));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  expect(find.text(field.label), findsWidgets);
  final LingPalette palette = LingPalette.of(brightness);
  final Key key = state == 'focused' ? LingMarks.ring : LingMarks.fill;
  final AnimatedContainer box = tester.widget<AnimatedContainer>(
    find.byKey(key),
  );
  final BoxDecoration decoration = box.decoration! as BoxDecoration;
  switch (state) {
    case 'default':
      expect(decoration.color, palette.surfaceContainer);
    case 'pressed':
      expect(decoration.color, isNot(palette.surfaceContainer));
    case 'focused':
      expect(find.byKey(LingMarks.ring), findsOneWidget);
    case 'disabled':
      expect(find.text(field.unavailableLabel), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      _expectDisabledSemantics(tester, find.byType(LingTextField));
    case 'loading':
      expect(find.text(field.label), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNotNull,
      );
    default:
      fail(state);
  }
}

void _expectDisabledSemantics(WidgetTester tester, Finder finder) {
  final SemanticsHandle handle = tester.ensureSemantics();
  expect(
    tester.getSemantics(finder),
    isSemantics(isEnabled: false, hasEnabledState: true),
  );
  handle.dispose();
}

String _goldenName(
  String id,
  String state,
  Brightness brightness,
  double scale,
) {
  final String scaleLabel = scale.toStringAsFixed(1);
  return '${id}_${state}_${brightness.name}_$scaleLabel.png';
}

bool _treeMentions(Directory root, String needle) {
  expect(root.existsSync(), isTrue, reason: root.path);
  for (final FileSystemEntity entity in root.listSync(
    recursive: true,
    followLinks: false,
  )) {
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
