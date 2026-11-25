import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/icons/lingafriq_icons.dart';
import 'package:lingafriq/design/tokens.g.dart';

const double _width = 390;
const Key _rowKey = Key('ling-icon-row');
const Key _shotKey = Key('ling-icon-shot');

class _Frame {
  const _Frame(this.fileName, this.brightness, this.scale);

  final String fileName;
  final Brightness brightness;
  final double scale;
}

Future<void> _view(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(_width, 120);
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(const Size(_width, 120));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _icon(
  LingIconName name, {
  bool selected = false,
  bool disabled = false,
  Brightness brightness = Brightness.light,
  Key? key,
}) {
  final LingPalette palette = LingPalette.of(brightness);
  return LingIcon(
    key: key,
    name: name,
    color: palette.onSurface,
    accent: palette.accent,
    selected: selected,
    disabled: disabled,
  );
}

Widget _row(Brightness brightness, double scale) {
  final LingPalette palette = LingPalette.of(brightness);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: brightness, useMaterial3: true),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(_width, 120),
        textScaler: TextScaler.linear(scale),
        devicePixelRatio: 1,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _rowKey,
          child: ColoredBox(
            color: palette.surface,
            child: SizedBox(
              width: _width,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LingAfriqTokens.spacing8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (final LingIconName name in LingIconName.values)
                      _icon(name, brightness: brightness),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<Uint8List> _pixels(WidgetTester tester, Key key) async {
  final RenderRepaintBoundary boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(key));
  final ui.Image image = (await tester.runAsync<ui.Image>(
    () => boundary.toImage(pixelRatio: 1),
  ))!;
  final ByteData data = (await tester.runAsync<ByteData>(() async {
    final ByteData? raw = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (raw == null) {
      throw StateError('icon image has no bytes');
    }
    return raw;
  }))!;
  final Uint8List bytes = Uint8List.fromList(data.buffer.asUint8List());
  image.dispose();
  return bytes;
}

int _accentCount(Uint8List bytes) {
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    final int red = bytes[index];
    final int green = bytes[index + 1];
    final int blue = bytes[index + 2];
    final int alpha = bytes[index + 3];
    if (alpha < 20) continue;
    if (blue > red + 40 && blue > green + 40 && blue > 80) count += 1;
  }
  return count;
}

int _inkCount(Uint8List bytes) {
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    if (bytes[index] < 200 ||
        bytes[index + 1] < 200 ||
        bytes[index + 2] < 200) {
      count += 1;
    }
  }
  return count;
}

Future<Uint8List> _shot(
  WidgetTester tester,
  LingIconName name, {
  bool selected = false,
  bool disabled = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _shotKey,
            child: ColoredBox(
              color: LingAfriqTokens.roleLightSurface,
              child: _icon(name, selected: selected, disabled: disabled),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _pixels(tester, _shotKey);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inventory labels and copy keys stay one to one', () {
    expect(LingIconName.values, hasLength(14));
    expect(
      LingIconName.values.take(5).map((LingIconName name) => name.name),
      <String>['today', 'learn', 'speak', 'play', 'village'],
    );
    final Set<String> labels = <String>{};
    final Set<String> keys = <String>{};
    for (final LingIconName name in LingIconName.values) {
      final String label = lingIconLabel(name);
      final String key = lingIconCopyKey(name);
      expect(label.trim(), isNotEmpty);
      expect(key, 'icon.label.${name.name}');
      expect(labels.add(label), isTrue, reason: label);
      expect(keys.add(key), isTrue, reason: key);
    }
    expect(lingIconLabel(LingIconName.wordCard), 'Word Card');
    expect(lingIconLabel(LingIconName.loading), 'Loading');
    expect(LingIcon.disabledOpacity, lessThan(1));
    expect(LingIcon.disabledOpacity, greaterThan(0));
    expect(LingAfriqTokens.spacing24, 24);
  });

  test('icon source has no hex colour', () {
    final String source = File(
      'lib/design/icons/lingafriq_icons.dart',
    ).readAsStringSync();
    expect(source.contains('Color(0x'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
    expect(source.contains('CustomPaint'), isTrue);
    expect(source.contains('error_state'), isFalse);
  });

  testWidgets('marks differ, the ring uses accent, and loading stays still', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final Map<LingIconName, Uint8List> shots = <LingIconName, Uint8List>{};
    for (final LingIconName name in LingIconName.values) {
      final Uint8List bytes = await _shot(tester, name);
      expect(_inkCount(bytes), greaterThan(12), reason: name.name);
      expect(_accentCount(bytes), 0, reason: name.name);
      shots[name] = bytes;
      expect(
        tester.getSize(find.byType(LingIcon)),
        const Size(LingAfriqTokens.spacing24, LingAfriqTokens.spacing24),
        reason: name.name,
      );
    }
    final List<LingIconName> names = LingIconName.values;
    for (var left = 0; left < names.length; left++) {
      for (var right = left + 1; right < names.length; right++) {
        expect(
          shots[names[left]],
          isNot(equals(shots[names[right]])),
          reason: '${names[left].name} ${names[right].name}',
        );
      }
    }

    final Uint8List selected = await _shot(
      tester,
      LingIconName.today,
      selected: true,
    );
    expect(selected, isNot(equals(shots[LingIconName.today])));
    expect(_accentCount(selected), greaterThan(8));

    final Uint8List first = await _shot(tester, LingIconName.loading);
    await tester.pump(const Duration(milliseconds: 300));
    final Uint8List later = await _pixels(tester, _shotKey);
    expect(later, equals(first));
    final Uint8List reduced = await _shot(
      tester,
      LingIconName.loading,
      disableAnimations: true,
    );
    expect(reduced, equals(first));
  });

  testWidgets('semantics keep the label when disabled and when selected', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _Host(disabled: true, selected: true, name: LingIconName.lock),
        ),
      );
      expect(find.bySemanticsLabel('Lock'), findsOneWidget);
      final SemanticsNode disabled = tester.getSemantics(find.byType(LingIcon));
      expect(disabled.label, 'Lock');
      expect(disabled.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(disabled.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        LingIcon.disabledOpacity,
      );
      expect(tester.widget<LingIcon>(find.byType(LingIcon)).label, 'Lock');

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _Host(name: LingIconName.search),
        ),
      );
      final SemanticsNode enabled = tester.getSemantics(find.byType(LingIcon));
      expect(enabled.label, 'Search');
      expect(enabled.flagsCollection.isEnabled, ui.Tristate.none);
      expect(find.byType(Opacity), findsNothing);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: _Host(selected: true, name: LingIconName.today),
        ),
      );
      final SemanticsNode selected = tester.getSemantics(find.byType(LingIcon));
      expect(selected.label, 'Today');
      expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(selected.flagsCollection.isEnabled, ui.Tristate.none);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('one row has a label for every icon in light, dark, and 200%', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      const List<_Frame> frames = <_Frame>[
        _Frame('row_light', Brightness.light, 1),
        _Frame('row_dark', Brightness.dark, 1),
        _Frame('row_200', Brightness.light, 2),
      ];
      final double height =
          LingAfriqTokens.spacing8 * 2 + LingAfriqTokens.spacing24;

      for (final _Frame frame in frames) {
        final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
        final void Function(FlutterErrorDetails)? previous =
            FlutterError.onError;
        FlutterError.onError = errors.add;
        await tester.pumpWidget(_row(frame.brightness, frame.scale));
        await tester.pump();
        FlutterError.onError = previous;
        expect(errors, isEmpty, reason: frame.fileName);
        expect(tester.takeException(), isNull, reason: frame.fileName);
        expect(
          tester.getSize(find.byKey(_rowKey)),
          Size(_width, height),
          reason: frame.fileName,
        );
        expect(
          find.byType(LingIcon),
          findsNWidgets(LingIconName.values.length),
        );
        for (final LingIconName name in LingIconName.values) {
          expect(
            find.bySemanticsLabel(
              RegExp('^${RegExp.escape(lingIconLabel(name))}\$'),
            ),
            findsOneWidget,
            reason: '${frame.fileName} ${name.name}',
          );
          expect(
            tester.getSize(find.byType(LingIcon).at(name.index)),
            const Size(LingAfriqTokens.spacing24, LingAfriqTokens.spacing24),
            reason: '${frame.fileName} ${name.name}',
          );
        }
        final Uint8List row = await _pixels(tester, _rowKey);
        expect(
          row.length,
          _width.round() * height.round() * 4,
          reason: frame.fileName,
        );

        await expectLater(
          find.byKey(_rowKey),
          matchesGoldenFile('goldens/icons/${frame.fileName}.png'),
        );
      }
    } finally {
      handle.dispose();
    }
  });
}

class _Host extends StatelessWidget {
  const _Host({
    required this.name,
    this.selected = false,
    this.disabled = false,
  });

  final LingIconName name;
  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _icon(name, selected: selected, disabled: disabled);
  }
}
