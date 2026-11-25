import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

/// Paints the P3-016 frames from ramp roles and LingAfriqType.
/// The only golden files it compares are the frames in
/// docs/build/design/screens/. Write them with:
/// flutter test test/design/tone_wordcard_lens_frames_test.dart --update-goldens

const _outDir = 'docs/build/design/screens';
const _greeting = 'Ẹ kú àárọ̀';
const _plantain = 'ọ̀gẹ̀dẹ̀';

enum _Screen { tone, wordcard, lens }

enum _Mode { data, skeleton, empty, error, offline, reduced }

class _Frame {
  const _Frame(this.fileName, this.theme, this.scale, this.screen, this.mode);

  final String fileName;
  final String theme;
  final double scale;
  final _Screen screen;
  final _Mode mode;
}

class _Roles {
  _Roles(this.values);

  final Map<String, Color> values;

  Color get surface => values['surface']!;
  Color get surfaceContainer => values['surfaceContainer']!;
  Color get onSurface => values['onSurface']!;
  Color get onSurfaceVariant => values['onSurfaceVariant']!;
  Color get accent => values['accent']!;
  Color get onAccent => values['onAccent']!;
  Color get danger => values['danger']!;
  Color get onDanger => values['onDanger']!;
  Color get info => values['info']!;
  Color get onInfo => values['onInfo']!;
}

class _TypeScale {
  _TypeScale({required this.displaySize, required this.displayHeight});

  final double displaySize;
  final double displayHeight;

  TextStyle display(Color color) => TextStyle(
        fontFamily: LingAfriqType.displayFamily,
        fontSize: displaySize,
        height: displayHeight,
        color: color,
      );

  TextStyle body(Color color) => TextStyle(
        fontFamily: LingAfriqType.bodyFamily,
        fontSize: LingAfriqType.bodySize,
        height: LingAfriqType.targetHeight,
        color: color,
      );

  TextStyle target(Color color) => LingAfriqType.target.copyWith(color: color);
}

Future<void> _loadFont(String family, String asset) async {
  final data = File(asset).readAsBytes().then(ByteData.sublistView);
  final loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Map<String, dynamic> _spec() => jsonDecode(
      File('design/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;

Color _parseHex(String hex) {
  var raw = hex.replaceFirst('#', '');
  if (raw.length == 6) raw = 'FF$raw';
  return Color(int.parse(raw, radix: 16));
}

_Roles _roles(Map<String, dynamic> spec, String theme) {
  final colorRamps = spec['colorRamps'] as Map;
  final ramps = colorRamps['ramps'] as Map;
  final roles = (colorRamps['modes'] as Map)[theme] as Map;
  final values = <String, Color>{};
  for (final name in roles.keys) {
    final role = roles[name] as Map;
    final ramp = ramps[role['ramp']] as Map;
    final step = (ramp['steps'] as Map)['${role['step']}'] as Map;
    values[name as String] = _parseHex(step['hex'] as String);
  }
  return _Roles(values);
}

_TypeScale _typeScale(Map<String, dynamic> spec) {
  final display = (spec['type'] as Map)['display'] as Map;
  return _TypeScale(
    displaySize: (display['size'] as num).toDouble(),
    displayHeight: (display['height'] as num).toDouble(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> spec;

  setUpAll(() async {
    spec = _spec();
    await _loadFont(LingAfriqType.targetFamily, 'assets/google_fonts/Andika-Regular.ttf');
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
    await _loadFont(
      LingAfriqType.displayFamily,
      'assets/fonts/lingafriq/Nunito-Bold-LatinAfrica.ttf',
    );
  });

  test('spec cites tokens and does not hard-code a colour', () {
    final text = File('docs/build/design/screens/tone_wordcard_lens.md').readAsStringSync();
    expect(text.contains('\u2014'), isFalse);
    expect(text.contains('\u2013'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(text), isFalse);
    final percents = RegExp(r'\d+(?:\.\d+)?\s*%')
        .allMatches(text)
        .map((match) => match.group(0))
        .toSet();
    expect(percents, {'200%'});
    expect(text.toLowerCase().contains('world-class'), isFalse);
    expect(text.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(text), isFalse);
    expect(RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(text), isFalse);
    expect(text.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(text.contains('LingAfriqType.target'), isTrue);
    expect(text.contains('colorRamps.modes.light'), isTrue);
    expect(text.contains('colorRamps.modes.dark'), isTrue);
    expect(text.contains('MediaQuery.disableAnimations'), isTrue);
    expect(text.contains('TextScaler.linear(2)'), isTrue);
    expect(text.contains(_greeting), isTrue);
    expect(text.contains(_plantain), isTrue);
    expect(text.contains('High'), isTrue);
    expect(text.contains('Downstep'), isTrue);
    expect(text.contains('This is sample data.'), isTrue);
    expect(text.contains('Unsure'), isTrue);
    expect(text.contains('long-press'), isTrue);
    expect(text.contains('Point & Say'), isTrue);
    expect(text.contains('Live Translate'), isTrue);
    expect(text.contains('Import Media'), isTrue);
    expect(text.contains('What happened'), isTrue);
    expect(text.toLowerCase().contains('confidence number'), isTrue);
    expect(RegExp(r'confidence\s*[:=]\s*\d').hasMatch(text), isFalse);
  });

  testWidgets('six contours differ in greyscale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(240, 80);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(240, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final roles = _roles(spec, 'light');
    const kinds = ['high', 'mid', 'low', 'rising', 'falling', 'downstep', 'unsure'];
    final maps = <String, List<int>>{};

    for (final kind in kinds) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: const Key('contour'),
              child: ColoredBox(
                color: roles.surface,
                child: SizedBox(
                  width: 220,
                  height: LingAfriqTokens.spacing48,
                  child: ToneContour(kind: kind, color: roles.onSurface),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final bytes = await _rgba(tester, const Key('contour'));
      final lum = <int>[];
      var dark = 0;
      for (var i = 0; i < bytes.length; i += 4) {
        final y = (0.2126 * bytes[i] + 0.7152 * bytes[i + 1] + 0.0722 * bytes[i + 2]).round();
        lum.add(y);
        if (y < 128) dark += 1;
      }
      expect(dark, greaterThan(10), reason: '$kind paints no stroke');
      maps[kind] = lum;
    }

    for (var i = 0; i < kinds.length; i++) {
      for (var j = i + 1; j < kinds.length; j++) {
        expect(
          maps[kinds[i]],
          isNot(equals(maps[kinds[j]])),
          reason: '${kinds[i]} matches ${kinds[j]} in greyscale',
        );
      }
    }
  });

  testWidgets('export Tone Lens, Word Card, and Lens frames at 390 px', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 6000);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(390, 6000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rolesLight = _roles(spec, 'light');
    final rolesDark = _roles(spec, 'dark');
    final type = _typeScale(spec);
    Directory(_outDir).createSync(recursive: true);

    const frames = <_Frame>[
      _Frame('tone-light', 'light', 1, _Screen.tone, _Mode.data),
      _Frame('tone-dark', 'dark', 1, _Screen.tone, _Mode.data),
      _Frame('tone-200', 'light', 2, _Screen.tone, _Mode.data),
      _Frame('tone-skeleton', 'light', 1, _Screen.tone, _Mode.skeleton),
      _Frame('tone-empty', 'light', 1, _Screen.tone, _Mode.empty),
      _Frame('tone-error', 'light', 1, _Screen.tone, _Mode.error),
      _Frame('tone-offline', 'light', 1, _Screen.tone, _Mode.offline),
      _Frame('tone-reduced', 'light', 1, _Screen.tone, _Mode.reduced),
      _Frame('wordcard-light', 'light', 1, _Screen.wordcard, _Mode.data),
      _Frame('wordcard-dark', 'dark', 1, _Screen.wordcard, _Mode.data),
      _Frame('wordcard-200', 'light', 2, _Screen.wordcard, _Mode.data),
      _Frame('wordcard-skeleton', 'light', 1, _Screen.wordcard, _Mode.skeleton),
      _Frame('wordcard-empty', 'light', 1, _Screen.wordcard, _Mode.empty),
      _Frame('wordcard-error', 'light', 1, _Screen.wordcard, _Mode.error),
      _Frame('wordcard-offline', 'light', 1, _Screen.wordcard, _Mode.offline),
      _Frame('wordcard-reduced', 'light', 1, _Screen.wordcard, _Mode.reduced),
      _Frame('lens-light', 'light', 1, _Screen.lens, _Mode.data),
      _Frame('lens-dark', 'dark', 1, _Screen.lens, _Mode.data),
      _Frame('lens-200', 'light', 2, _Screen.lens, _Mode.data),
      _Frame('lens-skeleton', 'light', 1, _Screen.lens, _Mode.skeleton),
      _Frame('lens-empty', 'light', 1, _Screen.lens, _Mode.empty),
      _Frame('lens-error', 'light', 1, _Screen.lens, _Mode.error),
      _Frame('lens-offline', 'light', 1, _Screen.lens, _Mode.offline),
      _Frame('lens-reduced', 'light', 1, _Screen.lens, _Mode.reduced),
    ];

    final lightPixels = <_Screen, Uint8List>{};

    for (final frame in frames) {
      final roles = frame.theme == 'dark' ? rolesDark : rolesLight;
      final reduced = frame.mode == _Mode.reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 6000),
            textScaler: TextScaler.linear(frame.scale),
            disableAnimations: reduced,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const Key('frame'),
                child: SizedBox(
                  width: 390,
                  child: ColoredBox(
                    color: roles.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
                      child: _screen(frame, roles, type),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('frame')));
      expect(boundary.size.width, 390, reason: frame.fileName);
      expect(boundary.size.height, greaterThan(200), reason: frame.fileName);
      expect(boundary.size.height, lessThan(6000), reason: frame.fileName);

      _expectFrame(tester, frame, roles);

      if (frame.mode == _Mode.data && frame.theme == 'light' && frame.scale == 1) {
        lightPixels[frame.screen] = await _rgba(tester, const Key('frame'));
      }
      if (frame.mode == _Mode.reduced) {
        final pixels = await _rgba(tester, const Key('frame'));
        expect(pixels, equals(lightPixels[frame.screen]), reason: frame.fileName);
      }

      await expectLater(
        find.byKey(const Key('frame')),
        matchesGoldenFile('../../$_outDir/${frame.fileName}.png'),
      );
    }
  });
}

Future<Uint8List> _rgba(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final data = await tester.runAsync(() => image!.toByteData(format: ImageByteFormat.rawRgba));
  return Uint8List.fromList(data!.buffer.asUint8List());
}

void _expectFrame(WidgetTester tester, _Frame frame, _Roles roles) {
  final buttons = tester.widgetList<SpecButton>(find.byType(SpecButton));
  for (final button in buttons) {
    expect(button.semanticsLabel.trim(), isNotEmpty, reason: frame.fileName);
    expect(button.label.trim(), isNotEmpty, reason: frame.fileName);
    final size = tester.getSize(find.byWidget(button));
    expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48), reason: frame.fileName);
    expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48), reason: frame.fileName);
  }

  final texts = tester.widgetList<Text>(find.byType(Text));
  for (final text in texts) {
    final value = text.data ?? '';
    expect(value.contains('%'), isFalse, reason: frame.fileName);
    expect(value.toLowerCase().contains('confidence'), isFalse, reason: frame.fileName);
    expect(RegExp(r'\d').hasMatch(value), isFalse, reason: frame.fileName);
    expect(value.contains('\u2014'), isFalse, reason: frame.fileName);
  }

  final accent = buttons.where((button) => button.filled).length;
  if (frame.mode == _Mode.skeleton) {
    expect(accent, 0, reason: frame.fileName);
    expect(find.text('Loading'), findsOneWidget);
  } else {
    expect(accent, 1, reason: frame.fileName);
  }

  if (frame.mode == _Mode.data || frame.mode == _Mode.reduced) {
    if (frame.screen == _Screen.tone) {
      expect(find.text('Shape shows the tone. Colour is optional.'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Mid'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Rising'), findsOneWidget);
      expect(find.text('Falling'), findsOneWidget);
      expect(find.text('Downstep'), findsOneWidget);
      expect(find.text('kú'), findsOneWidget);
      expect(find.text('Ẹ'), findsOneWidget);
      expect(find.text('rọ̀'), findsOneWidget);
      expect(find.text('àá'), findsOneWidget);
      expect(find.text('áà'), findsOneWidget);
      expect(find.text('bá bá'), findsOneWidget);
      expect(find.text(_greeting), findsOneWidget);
      expect(find.text('Sample'), findsOneWidget);
      expect(find.text('Unsure'), findsOneWidget);
      expect(find.text('This is sample data.'), findsOneWidget);
      expect(find.text('The check is unsure.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      final contours = tester.widgetList<ToneContour>(find.byType(ToneContour)).toList();
      expect(contours.map((contour) => contour.kind).toList(), [
        'high',
        'mid',
        'low',
        'rising',
        'falling',
        'downstep',
        'greeting',
        'unsure',
      ]);
      expect(contours.map((contour) => contour.color).toSet(), {roles.onSurface});
      _expectTarget(tester, _greeting, frame);
    }
    if (frame.screen == _Screen.wordcard) {
      expect(find.text('Opened by a long press.'), findsOneWidget);
      expect(find.text('Meaning'), findsOneWidget);
      expect(find.text('Good morning.'), findsOneWidget);
      expect(find.text('Play audio'), findsOneWidget);
      expect(find.text('Tone Lens'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('You say this in the morning.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Practise'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text(_greeting), findsNWidgets(2));
      final filled = buttons.where((button) => button.filled).single;
      expect(filled.label, 'Practise');
      expect(tester.widgetList<ToneContour>(find.byType(ToneContour)).single.kind, 'greeting');
      _expectTarget(tester, _greeting, frame);
    }
    if (frame.screen == _Screen.lens) {
      expect(find.text('Point & Say'), findsOneWidget);
      expect(find.text('Live Translate'), findsOneWidget);
      expect(find.text('Import Media'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text(_plantain), findsOneWidget);
      expect(find.text('Plantain.'), findsOneWidget);
      expect(find.text('The photo is checked, then deleted.'), findsOneWidget);
      expect(find.text('Say it'), findsOneWidget);
      expect(find.text('Open word'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      final filled = buttons.where((button) => button.filled).single;
      expect(filled.label, 'Say it');
      final selected = buttons.singleWhere((button) => button.label == 'Point & Say');
      expect(selected.note, 'On');
      expect(selected.border, roles.onSurface);
      expect(tester.widgetList<ToneContour>(find.byType(ToneContour)).single.kind, 'low');
      _expectTarget(tester, _plantain, frame);
    }
  }

  if (frame.mode == _Mode.error || frame.mode == _Mode.offline || frame.mode == _Mode.empty) {
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
  }

  if (frame.mode == _Mode.error) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'cross');
  }
  if (frame.mode == _Mode.offline) {
    expect(tester.widget<CueMark>(find.byType(CueMark)).kind, 'info');
  }
}

void _expectTarget(WidgetTester tester, String sample, _Frame frame) {
  final andika = tester.renderObjectList<RenderParagraph>(find.text(sample));
  expect(andika, isNotEmpty, reason: frame.fileName);
  for (final paragraph in andika) {
    expect(paragraph.text.style?.fontFamily, LingAfriqType.targetFamily);
    expect(paragraph.text.style?.fontSize, LingAfriqType.targetSize);
    expect(paragraph.size.height, greaterThanOrEqualTo(LingAfriqType.targetSize));
    expect(paragraph.size.width, greaterThan(0));
  }
  if (frame.scale == 2) {
    expect(andika.first.size.height, greaterThan(LingAfriqType.targetSize * 2));
  }
}

Widget _screen(_Frame frame, _Roles roles, _TypeScale type) {
  final mode = frame.mode == _Mode.reduced ? _Mode.data : frame.mode;
  return switch (frame.screen) {
    _Screen.tone => _tone(mode, roles, type),
    _Screen.wordcard => _wordcard(mode, roles, type),
    _Screen.lens => _lens(mode, roles, type),
  };
}

Widget _tone(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
        roles,
        type,
        label: 'Loading Tone Lens',
        heights: const [
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing32,
          LingAfriqTokens.spacing48,
        ],
      ),
    _Mode.empty => _notice(
        roles: roles,
        type: type,
        title: 'Tone Lens',
        headline: 'No word yet',
        headlineColor: roles.onSurface,
        happened: 'There is no word to mark.',
        why: 'Tone Lens needs a target-language word.',
        todo: 'Long-press a word.',
        buttons: [
          _primary(roles, type, 'Show a word', 'Show a word'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Tone Lens',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'Tone Lens did not load',
        headlineColor: roles.danger,
        happened: 'The tone shapes did not open.',
        why: 'This word has no saved tone on the phone.',
        todo: 'Try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Tone Lens',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'The tone for this word is not saved on the phone.',
        todo: 'Connect, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _ => _column([
        Text('Tone Lens', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text(
          'Shape shows the tone. Colour is optional.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _toneRow(roles, type, kind: 'high', name: 'High', sample: 'kú', semantics: 'High tone, kú'),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _toneRow(roles, type, kind: 'mid', name: 'Mid', sample: 'Ẹ', semantics: 'Mid tone, Ẹ'),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _toneRow(roles, type, kind: 'low', name: 'Low', sample: 'rọ̀', semantics: 'Low tone, rọ̀'),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _toneRow(
          roles,
          type,
          kind: 'rising',
          name: 'Rising',
          sample: 'àá',
          semantics: 'Rising tone, àá',
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _toneRow(
          roles,
          type,
          kind: 'falling',
          name: 'Falling',
          sample: 'áà',
          semantics: 'Falling tone, áà',
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        _toneRow(
          roles,
          type,
          kind: 'downstep',
          name: 'Downstep',
          sample: 'bá bá',
          semantics: 'Downstep tone, bá bá',
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _panel(
          roles,
          Semantics(
            label: 'Tone on $_greeting. Mid, then high, then rising, then low.',
            child: _column([
              Text('This word', style: type.body(roles.onSurface)),
              const SizedBox(height: LingAfriqTokens.spacing4),
              ToneContour(kind: 'greeting', color: roles.onSurface),
              const SizedBox(height: LingAfriqTokens.spacing4),
              Text(_greeting, style: type.target(roles.onSurface)),
            ]),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(
          'Mid, then high, then rising, then low.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _pill(roles, type, 'Sample', 'Sample data'),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Semantics(
          label: 'Unsure. This is sample data.',
          child: ToneContour(kind: 'unsure', color: roles.onSurface),
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text('Unsure', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text('This is sample data.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text('The check is unsure.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(
          'Say the word again in a quiet place.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _primary(roles, type, 'Try again', 'Try the word again'),
      ]),
  };
}

Widget _wordcard(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
        roles,
        type,
        label: 'Loading the word card',
        heights: const [
          LingAfriqTokens.spacing32,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing32,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing32,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
        ],
      ),
    _Mode.empty => _notice(
        roles: roles,
        type: type,
        title: 'Word Card',
        headline: 'No word yet',
        headlineColor: roles.onSurface,
        happened: 'No word is open.',
        why: 'A long press has not chosen a word.',
        todo: 'Long-press a target-language word.',
        buttons: [
          _primary(roles, type, 'Show a word', 'Show a word'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Word Card',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'Word Card did not open',
        headlineColor: roles.danger,
        happened: 'The card did not load.',
        why: 'The meaning did not come back.',
        todo: 'Try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Word Card',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'This word is not saved on the phone.',
        todo: 'Connect, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _ => _column([
        Align(
          alignment: Alignment.centerLeft,
          child: _quiet(roles, type, 'Close', 'Close the word card', fillWidth: false),
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text('Word Card', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text('Opened by a long press.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text('Tone Lens', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Semantics(
          label: 'Tone Lens for $_greeting',
          child: ToneContour(kind: 'greeting', color: roles.onSurface),
        ),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(_greeting, style: type.target(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(
          'Mid, then high, then rising, then low.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text('Meaning', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text('Good morning.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _quiet(roles, type, 'Play audio', 'Play $_greeting'),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text('Example', style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(_greeting, style: type.target(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text('You say this in the morning.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _quiet(roles, type, 'Save', 'Save this word'),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _primary(roles, type, 'Practise', 'Practise this word'),
      ]),
  };
}

Widget _lens(_Mode mode, _Roles roles, _TypeScale type) {
  return switch (mode) {
    _Mode.skeleton => _skeleton(
        roles,
        type,
        label: 'Loading the lens',
        heights: const [
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing48,
          LingAfriqTokens.spacing64,
          LingAfriqTokens.spacing48,
        ],
      ),
    _Mode.empty => _notice(
        roles: roles,
        type: type,
        title: 'Lens',
        headline: 'Nothing in view',
        headlineColor: roles.onSurface,
        happened: 'The camera sees no object.',
        why: 'Nothing is close enough to name.',
        todo: 'Point at one thing, or use Import Media.',
        buttons: [
          _primary(roles, type, 'Point again', 'Point the camera again'),
        ],
      ),
    _Mode.error => _notice(
        roles: roles,
        type: type,
        title: 'Lens',
        cue: 'cross',
        cueFill: roles.danger,
        cueMark: roles.onDanger,
        headline: 'The camera did not name it',
        headlineColor: roles.danger,
        happened: 'No word came back.',
        why: 'The picture was too dark to read.',
        todo: 'Add light, then try again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _Mode.offline => _notice(
        roles: roles,
        type: type,
        title: 'Lens',
        cue: 'info',
        cueFill: roles.info,
        cueMark: roles.onInfo,
        headline: 'You are offline',
        headlineColor: roles.info,
        happened: 'The phone has no network.',
        why: 'This object is not in the offline pack.',
        todo: 'Connect, then point again.',
        buttons: [
          _primary(roles, type, 'Try again', 'Try again'),
        ],
      ),
    _ => _column([
        Align(
          alignment: Alignment.centerLeft,
          child: _quiet(roles, type, 'Close', 'Close the lens', fillWidth: false),
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text('Lens', style: type.display(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text('Point at one thing.', style: type.body(roles.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _modeButton(
          roles,
          type,
          label: 'Point & Say',
          semantics: 'Point and Say, on',
          on: true,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _modeButton(
          roles,
          type,
          label: 'Live Translate',
          semantics: 'Live Translate',
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _modeButton(
          roles,
          type,
          label: 'Import Media',
          semantics: 'Import Media',
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: roles.surfaceContainer,
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
                border: Border.all(color: roles.onSurface, width: LingAfriqTokens.strokeregular),
              ),
              child: Padding(
                padding: const EdgeInsets.all(LingAfriqTokens.spacing12),
                child: Semantics(
                  label: 'Low tone on $_plantain. Plantain.',
                  child: _column([
                    ToneContour(kind: 'low', color: roles.onSurface),
                    const SizedBox(height: LingAfriqTokens.spacing4),
                    Text('Low', style: type.body(roles.onSurface)),
                    const SizedBox(height: LingAfriqTokens.spacing4),
                    Text(_plantain, style: type.target(roles.onSurface)),
                    const SizedBox(height: LingAfriqTokens.spacing4),
                    Text('Plantain.', style: type.body(roles.onSurface)),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text(
          'The photo is checked, then deleted.',
          style: type.body(roles.onSurfaceVariant),
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        _primary(roles, type, 'Say it', 'Say $_plantain'),
        const SizedBox(height: LingAfriqTokens.spacing8),
        _quiet(roles, type, 'Open word', 'Open the word card for $_plantain'),
      ]),
  };
}

Widget _toneRow(
  _Roles roles,
  _TypeScale type, {
  required String kind,
  required String name,
  required String sample,
  required String semantics,
}) {
  return Semantics(
    label: semantics,
    excludeSemantics: true,
    child: _panel(
      roles,
      _column([
        Text(name, style: type.body(roles.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing4),
        ToneContour(kind: kind, color: roles.onSurface),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(sample, style: type.target(roles.onSurface)),
      ]),
    ),
  );
}

Widget _panel(_Roles roles, Widget child) {
  return SizedBox(
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: roles.surfaceContainer,
        borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing12),
        child: child,
      ),
    ),
  );
}

Widget _notice({
  required _Roles roles,
  required _TypeScale type,
  required String title,
  required String headline,
  required Color headlineColor,
  required String happened,
  required String why,
  required String todo,
  required List<Widget> buttons,
  String? cue,
  Color? cueFill,
  Color? cueMark,
}) {
  return _column([
    Text(title, style: type.display(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing16),
    if (cue != null) ...[
      _disc(
        fill: cueFill!,
        child: CueMark(color: cueMark!, kind: cue),
      ),
      const SizedBox(height: LingAfriqTokens.spacing12),
    ],
    Text(headline, style: type.body(headlineColor)),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'What happened', happened),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'Why', why),
    const SizedBox(height: LingAfriqTokens.spacing16),
    _fact(type, roles, 'What to do', todo),
    const SizedBox(height: LingAfriqTokens.spacing24),
    for (var i = 0; i < buttons.length; i++) ...[
      if (i > 0) const SizedBox(height: LingAfriqTokens.spacing8),
      buttons[i],
    ],
  ]);
}

Widget _fact(_TypeScale type, _Roles roles, String label, String line) {
  return _column([
    Text(label, style: type.body(roles.onSurface)),
    const SizedBox(height: LingAfriqTokens.spacing4),
    Text(line, style: type.body(roles.onSurfaceVariant)),
  ]);
}

Widget _skeleton(
  _Roles roles,
  _TypeScale type, {
  required String label,
  required List<double> heights,
}) {
  return _column([
    Semantics(
      label: label,
      excludeSemantics: true,
      child: Text('Loading', style: type.body(roles.onSurfaceVariant)),
    ),
    const SizedBox(height: LingAfriqTokens.spacing12),
    for (final height in heights) ...[
      _block(roles, height),
      const SizedBox(height: LingAfriqTokens.spacing12),
    ],
  ]);
}

Widget _pill(_Roles roles, _TypeScale type, String label, String semantics) {
  return Semantics(
    label: semantics,
    excludeSemantics: true,
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: roles.surfaceContainer,
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiuspill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing8,
            ),
            child: Text(label, style: type.body(roles.onSurface)),
          ),
        ),
      ),
    ),
  );
}

Widget _disc({
  required Color fill,
  required Widget child,
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: LingAfriqTokens.spacing48,
      minHeight: LingAfriqTokens.spacing48,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing8),
        child: Center(child: child),
      ),
    ),
  );
}

Widget _block(_Roles roles, double height) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: roles.surfaceContainer,
        borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
      ),
    ),
  );
}

Widget _column(List<Widget> children) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

Widget _primary(_Roles roles, _TypeScale type, String label, String semantics) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.accent,
    foreground: roles.onAccent,
    textStyle: type.body(roles.onAccent),
    fillWidth: true,
    filled: true,
  );
}

Widget _quiet(
  _Roles roles,
  _TypeScale type,
  String label,
  String semantics, {
  bool fillWidth = true,
}) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: fillWidth,
    filled: false,
  );
}

Widget _modeButton(
  _Roles roles,
  _TypeScale type, {
  required String label,
  required String semantics,
  bool on = false,
}) {
  return SpecButton(
    label: label,
    semanticsLabel: semantics,
    background: roles.surfaceContainer,
    foreground: roles.onSurface,
    textStyle: type.body(roles.onSurface),
    fillWidth: true,
    filled: false,
    border: on ? roles.onSurface : null,
    note: on ? 'On' : null,
    mark: on ? CueMark(color: roles.onSurface, kind: 'check') : null,
  );
}

class SpecButton extends StatelessWidget {
  const SpecButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.background,
    required this.foreground,
    required this.textStyle,
    required this.fillWidth,
    required this.filled,
    this.border,
    this.note,
    this.mark,
  });

  final String label;
  final String semanticsLabel;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;
  final bool fillWidth;
  final bool filled;
  final Color? border;
  final String? note;
  final Widget? mark;

  @override
  Widget build(BuildContext context) {
    final text = note == null
        ? Text(label, textAlign: TextAlign.center, style: textStyle)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyle),
              Text(note!, style: textStyle),
            ],
          );
    final child = mark == null
        ? text
        : Row(
            children: [
              mark!,
              const SizedBox(width: LingAfriqTokens.spacing8),
              Expanded(child: text),
            ],
          );
    final button = Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: LingAfriqTokens.spacing48,
          minHeight: LingAfriqTokens.spacing48,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(LingAfriqTokens.radiusmd),
            border: border == null
                ? null
                : Border.all(color: border!, width: LingAfriqTokens.strokeregular),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing12,
            ),
            child: child,
          ),
        ),
      ),
    );
    if (!fillWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class CueMark extends StatelessWidget {
  const CueMark({super.key, required this.color, required this.kind});

  final Color color;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LingAfriqTokens.spacing24,
      height: LingAfriqTokens.spacing24,
      child: CustomPaint(painter: _CuePainter(color, kind)),
    );
  }
}

class _CuePainter extends CustomPainter {
  _CuePainter(this.color, this.kind);

  final Color color;
  final String kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case 'check':
        final path = Path()
          ..moveTo(w * 0.18, h * 0.55)
          ..lineTo(w * 0.42, h * 0.78)
          ..lineTo(w * 0.84, h * 0.26);
        canvas.drawPath(path, paint);
      case 'cross':
        canvas.drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), paint);
        canvas.drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), paint);
      case 'info':
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.38, paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.42), Offset(w * 0.5, h * 0.72), paint);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.28),
          LingAfriqTokens.strokehairline,
          Paint()..color = color,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.kind != kind;
}

class ToneContour extends StatelessWidget {
  const ToneContour({super.key, required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LingAfriqTokens.spacing48,
      width: double.infinity,
      child: CustomPaint(painter: _ContourPainter(kind, color)),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter(this.kind, this.color);

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    final left = LingAfriqTokens.spacing8;
    final right = size.width - LingAfriqTokens.spacing8;
    final top = LingAfriqTokens.spacing8;
    final bottom = size.height - LingAfriqTokens.spacing8;
    final midY = size.height / 2;
    switch (kind) {
      case 'high':
        canvas.drawLine(Offset(left, top), Offset(right, top), paint);
      case 'mid':
        canvas.drawLine(Offset(left, midY), Offset(right, midY), paint);
      case 'low':
        canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
      case 'rising':
        canvas.drawLine(Offset(left, bottom), Offset(right, top), paint);
      case 'falling':
        canvas.drawLine(Offset(left, top), Offset(right, bottom), paint);
      case 'downstep':
        final step = (left + right) / 2;
        final path = Path()
          ..moveTo(left, top)
          ..lineTo(step, top)
          ..lineTo(step, bottom)
          ..lineTo(right, bottom);
        canvas.drawPath(path, paint);
      case 'unsure':
        var x = left;
        while (x < right) {
          final end = (x + LingAfriqTokens.spacing16).clamp(left, right);
          canvas.drawLine(Offset(x, midY), Offset(end, midY), paint);
          x = end + LingAfriqTokens.spacing8;
        }
      case 'greeting':
        final gap = LingAfriqTokens.spacing4;
        final span = right - left;
        final seg = (span - gap * 3) / 4;
        canvas.drawLine(Offset(left, midY), Offset(left + seg, midY), paint);
        final highStart = left + seg + gap;
        canvas.drawLine(Offset(highStart, top), Offset(highStart + seg, top), paint);
        final riseStart = highStart + seg + gap;
        canvas.drawLine(Offset(riseStart, bottom), Offset(riseStart + seg, top), paint);
        final lowStart = riseStart + seg + gap;
        canvas.drawLine(Offset(lowStart, bottom), Offset(lowStart + seg, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
