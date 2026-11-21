import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/bundled_fonts.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';
import 'package:lingafriq/design/typography.dart';

const String _greeting = 'Ẹ kú àárọ̀';
const List<ToneContourKind> _greetingTones = <ToneContourKind>[
  ToneContourKind.mid,
  ToneContourKind.high,
  ToneContourKind.rising,
  ToneContourKind.low,
];
const String _greetingLabel =
    'Tone on Ẹ kú àárọ̀. Mid, then high, then rising, then low.';
const String _unverifiedLabel = 'Tone on Ẹ kú àárọ̀. The tone is not checked.';

const Color _ink = Color.fromARGB(255, 92, 92, 92);
const Color _paper = Color.fromARGB(255, 208, 208, 208);
const double _shapeWidth = 220;
const Key _frameKey = Key('tone-lens-frame');

const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

const List<String> _hosts = <String>[
  'lesson',
  'chat',
  'game',
  'persona',
  'dictionary',
];

class _Shot {
  const _Shot(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

class _Frame {
  const _Frame(
    this.fileName,
    this.brightness,
    this.scale,
    this.greyscale,
    this.unverified,
  );

  final String fileName;
  final Brightness brightness;
  final double scale;
  final bool greyscale;
  final bool unverified;
}

Future<void> _load(String family, String asset) async {
  final ByteData data = ByteData.sublistView(await File(asset).readAsBytes());
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(data));
  await loader.load();
}

Future<void> _view(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<_Shot> _shot(WidgetTester tester, Key key) async {
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
      throw StateError('contour image has no bytes');
    }
    return raw;
  }))!;
  final Uint8List bytes = Uint8List.fromList(data.buffer.asUint8List());
  final _Shot shot = _Shot(bytes, image.width, image.height);
  image.dispose();
  return shot;
}

/// Identical bytes fail this check. That is the pairwise rule.
void _expectShapesDiffer(Uint8List a, Uint8List b, String reason) {
  expect(a.length, b.length, reason: reason);
  expect(a, isNot(equals(b)), reason: reason);
}

bool _pixelInk(_Shot shot, int x, int y) {
  final int i = (y * shot.width + x) * 4;
  return shot.bytes[i] < 160;
}

int _inkCount(_Shot shot) {
  var count = 0;
  for (var i = 0; i < shot.bytes.length; i += 4) {
    if (shot.bytes[i] < 160) count += 1;
  }
  return count;
}

int _inkRuns(_Shot shot) {
  var bestRow = 0;
  var best = -1;
  for (var y = 0; y < shot.height; y++) {
    var dark = 0;
    for (var x = 0; x < shot.width; x++) {
      if (_pixelInk(shot, x, y)) dark += 1;
    }
    if (dark > best) {
      best = dark;
      bestRow = y;
    }
  }
  var runs = 0;
  var inside = false;
  for (var x = 0; x < shot.width; x++) {
    final bool ink = _pixelInk(shot, x, bestRow);
    if (ink && !inside) {
      runs += 1;
      inside = true;
    } else if (!ink) {
      inside = false;
    }
  }
  return runs;
}

void _expectGrey(_Shot shot) {
  final Uint8List bytes = shot.bytes;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i] != bytes[i + 1] || bytes[i + 1] != bytes[i + 2]) {
      fail('pixel ${i ~/ 4} is not one grey');
    }
  }
}

Future<_Shot> _paintShape(
  WidgetTester tester, {
  required List<ToneContourKind> kinds,
  bool unverified = false,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _shapeWidth,
          child: ToneContour(
            color: _ink,
            background: _paper,
            kinds: kinds,
            unverified: unverified,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final _Shot shot = await _shot(tester, ToneContour.markKey);
  expect(shot.width, _shapeWidth);
  expect(shot.height, LingAfriqTokens.spacing48);
  return shot;
}

Widget _host({
  required Widget child,
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 800),
      textScaler: TextScaler.linear(scale),
      disableAnimations: disableAnimations,
    ),
    child: Theme(
      data: ThemeData(brightness: brightness, useMaterial3: true),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
}

Widget _lens({
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool unverified = false,
  bool greyscale = false,
  bool disableAnimations = false,
  ToneSource source = ToneSource.orthography,
  List<ToneContourKind> contours = _greetingTones,
  String word = _greeting,
}) {
  final Color page = brightness == Brightness.dark
      ? LingAfriqTokens.roleDarkSurface
      : LingAfriqTokens.roleLightSurface;
  Widget body = ColoredBox(
    color: page,
    child: Padding(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      child: ToneLens(
        word: word,
        contours: contours,
        source: source,
        unverified: unverified,
      ),
    ),
  );
  if (greyscale) {
    body = ColorFiltered(colorFilter: _greyscale, child: body);
  }
  return _host(
    brightness: brightness,
    scale: scale,
    disableAnimations: disableAnimations,
    child: Align(
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        key: _frameKey,
        child: SizedBox(width: 390, child: body),
      ),
    ),
  );
}

void _expectUnclippedRect(Rect bounds, RenderBox start) {
  RenderObject? node = start;
  while (node != null) {
    final bool clips =
        node is RenderClipRect ||
        node is RenderClipRRect ||
        node is RenderClipPath ||
        node is RenderClipOval;
    if (clips && node is RenderBox) {
      final Rect clip = node.localToGlobal(Offset.zero) & node.size;
      expect(clip.left, lessThanOrEqualTo(bounds.left + 0.1));
      expect(clip.top, lessThanOrEqualTo(bounds.top + 0.1));
      expect(clip.right, greaterThanOrEqualTo(bounds.right - 0.1));
      expect(clip.bottom, greaterThanOrEqualTo(bounds.bottom - 0.1));
    }
    node = node.parent;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    configureBundledFonts();
    await _load(
      LingAfriqType.targetFamily,
      'assets/google_fonts/Andika-Regular.ttf',
    );
    await _load(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
    await _load(
      'NotoSansEthiopic',
      'assets/fonts/lingafriq/NotoSansEthiopic-Regular.ttf',
    );
    await _load(
      'NotoSansNKo',
      'assets/fonts/lingafriq/NotoSansNKo-Regular.ttf',
    );
    await _load(
      'NotoSansTifinagh',
      'assets/fonts/lingafriq/NotoSansTifinagh-Regular.ttf',
    );
    await _load(
      'NotoSansAdlam',
      'assets/fonts/lingafriq/NotoSansAdlam-Regular.ttf',
    );
  });

  test('source is orthography or validatedAudio, with no score field', () {
    expect(ToneSource.values, <ToneSource>[
      ToneSource.orthography,
      ToneSource.validatedAudio,
    ]);
    expect(ToneContourKind.values.length, 6);
    final String lens = File(
      'lib/design/tone_lens/tone_lens.dart',
    ).readAsStringSync();
    final String contour = File(
      'lib/design/tone_lens/tone_contour.dart',
    ).readAsStringSync();
    final RegExp ctor = RegExp(r'const ToneLens\(\{([\s\S]*?)\}\);');
    final String params = ctor.firstMatch(lens)!.group(1)!;
    expect(params.contains('required this.word'), isTrue);
    expect(params.contains('required this.contours'), isTrue);
    expect(params.contains('required this.source'), isTrue);
    expect(params.contains('this.unverified'), isTrue);
    expect(RegExp(r'\b(int|double|num)\b').hasMatch(params), isFalse);
    for (final String source in <String>[lens, contour]) {
      expect(
        RegExp(r'\bscore\b', caseSensitive: false).hasMatch(source),
        isFalse,
      );
      expect(
        RegExp(r'\bconfidence\b', caseSensitive: false).hasMatch(source),
        isFalse,
      );
      expect(source.contains('Color(0x'), isFalse);
      expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
      expect(
        RegExp(r'TextPainter|ParagraphBuilder|drawParagraph').hasMatch(source),
        isFalse,
      );
      expect(RegExp(r'''['"]\d+['"]''').hasMatch(source), isFalse);
    }
    expect(lens.contains('LingAfriqTokens.roleLightSurface'), isTrue);
    expect(lens.contains('LingAfriqTokens.roleDarkSurface'), isTrue);
    expect(lens.contains('LingAfriqTokens.roleLightSurfaceContainer'), isTrue);
    expect(lens.contains('LingAfriqTokens.roleDarkOnSurface'), isTrue);
    expect(contour.contains('LingAfriqTokens.strokeregular'), isTrue);
    expect(contour.contains('LingAfriqTokens.spacing48'), isTrue);
    expect(contour.contains('LingAfriqTokens.spacing16'), isTrue);
    expect(contour.contains('LingAfriqTokens.spacing8'), isTrue);
    expect(contour.contains('AnimationController'), isFalse);
  });

  testWidgets('six shapes differ pairwise when painted with one grey', (
    tester,
  ) async {
    await _view(tester, const Size(240, 80));
    final Map<ToneContourKind, _Shot> shots = <ToneContourKind, _Shot>{};
    for (final ToneContourKind kind in ToneContourKind.values) {
      final _Shot shot = await _paintShape(
        tester,
        kinds: <ToneContourKind>[kind],
      );
      _expectGrey(shot);
      expect(_inkCount(shot), greaterThan(10), reason: kind.name);
      shots[kind] = shot;
    }

    final _Shot highAgain = await _paintShape(
      tester,
      kinds: const <ToneContourKind>[ToneContourKind.high],
    );
    expect(highAgain.bytes, equals(shots[ToneContourKind.high]!.bytes));
    expect(
      () => _expectShapesDiffer(
        shots[ToneContourKind.high]!.bytes,
        shots[ToneContourKind.high]!.bytes,
        'identical high',
      ),
      throwsA(isA<TestFailure>()),
    );

    final List<ToneContourKind> kinds = ToneContourKind.values;
    for (var i = 0; i < kinds.length; i++) {
      for (var j = i + 1; j < kinds.length; j++) {
        _expectShapesDiffer(
          shots[kinds[i]]!.bytes,
          shots[kinds[j]]!.bytes,
          '${kinds[i].name} matches ${kinds[j].name}',
        );
      }
    }
  });

  testWidgets('unverified dashes are not the solid mid line', (tester) async {
    await _view(tester, const Size(240, 80));
    final _Shot mid = await _paintShape(
      tester,
      kinds: const <ToneContourKind>[ToneContourKind.mid],
    );
    final _Shot broken = await _paintShape(
      tester,
      kinds: const <ToneContourKind>[ToneContourKind.mid],
      unverified: true,
    );
    _expectGrey(mid);
    _expectGrey(broken);
    _expectShapesDiffer(mid.bytes, broken.bytes, 'unverified matches mid');
    expect(_inkRuns(mid), 1);
    expect(_inkRuns(broken), greaterThan(1));
  });

  testWidgets('five hosts paint the same contour pixels', (tester) async {
    await _view(tester, const Size(390, 800));
    const List<Color> chrome = <Color>[
      LingAfriqTokens.roleLightAccent,
      LingAfriqTokens.roleLightSurfaceContainer,
      LingAfriqTokens.roleDarkSurface,
      LingAfriqTokens.roleLightOnSurfaceVariant,
      LingAfriqTokens.roleDarkSurfaceContainer,
    ];
    Uint8List? baseline;
    var baselineWidth = 0;
    for (var i = 0; i < _hosts.length; i++) {
      await tester.pumpWidget(
        _host(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 390,
              child: ColoredBox(
                color: chrome[i],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(LingAfriqTokens.spacing8),
                      child: Text(_hosts[i]),
                    ),
                    const ToneLens(
                      word: _greeting,
                      contours: _greetingTones,
                      source: ToneSource.orthography,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(_hosts[i]), findsOneWidget);
      final _Shot mark = await _shot(tester, ToneContour.markKey);
      expect(mark.height, LingAfriqTokens.spacing48, reason: _hosts[i]);
      expect(_inkCount(mark), greaterThan(10), reason: _hosts[i]);
      if (baseline == null) {
        baseline = mark.bytes;
        baselineWidth = mark.width;
      } else {
        expect(mark.width, baselineWidth, reason: _hosts[i]);
        expect(mark.bytes, equals(baseline), reason: _hosts[i]);
      }
    }
    expect(baseline, isNotNull);
  });

  testWidgets('orthography and validated audio use the same stroke', (
    tester,
  ) async {
    await _view(tester, const Size(390, 800));
    final Map<ToneSource, Uint8List> bytes = <ToneSource, Uint8List>{};
    for (final ToneSource source in ToneSource.values) {
      await tester.pumpWidget(_lens(source: source));
      await tester.pump();
      final ToneLens lens = tester.widget<ToneLens>(find.byType(ToneLens));
      expect(lens.source, source);
      expect(lens.unverified, isFalse);
      bytes[source] = (await _shot(tester, ToneContour.markKey)).bytes;
    }
    expect(
      bytes[ToneSource.orthography],
      equals(bytes[ToneSource.validatedAudio]),
    );
  });

  testWidgets('semantics label reads the tone sequence', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _view(tester, const Size(390, 800));
    await tester.pumpWidget(_lens());
    expect(find.bySemanticsLabel(_greetingLabel), findsOneWidget);
    expect(find.text(_greeting), findsOneWidget);

    await tester.pumpWidget(
      _lens(
        word: 'kú',
        contours: const <ToneContourKind>[ToneContourKind.high],
      ),
    );
    expect(find.bySemanticsLabel('Tone on kú. High.'), findsOneWidget);

    await tester.pumpWidget(
      _lens(
        word: 'áà',
        contours: const <ToneContourKind>[
          ToneContourKind.falling,
          ToneContourKind.downstep,
        ],
      ),
    );
    expect(
      find.bySemanticsLabel('Tone on áà. Falling, then downstep.'),
      findsOneWidget,
    );

    await tester.pumpWidget(_lens(unverified: true));
    expect(find.bySemanticsLabel(_unverifiedLabel), findsOneWidget);
    expect(find.bySemanticsLabel(_greetingLabel), findsNothing);
    handle.dispose();
  });

  testWidgets('the renderer paints no number', (tester) async {
    await _view(tester, const Size(390, 800));
    await tester.pumpWidget(_lens());
    await tester.pumpWidget(_lens(unverified: true));
    for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
      final String data = text.data ?? text.textSpan?.toPlainText() ?? '';
      expect(RegExp(r'\d').hasMatch(data), isFalse, reason: data);
    }
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp(r'\d')), findsNothing);
    handle.dispose();
  });

  testWidgets('200 percent text does not clip the diacritics', (tester) async {
    await _view(tester, const Size(390, 800));
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(_lens(scale: 2));
    await tester.pump();
    FlutterError.onError = previous;
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);

    expect(
      tester.getSize(find.byKey(ToneContour.markKey)).height,
      LingAfriqTokens.spacing48,
    );
    final Text word = tester.widget<Text>(find.text(_greeting));
    expect(word.style?.fontFamily, LingAfriqType.targetFamily);
    expect(word.overflow, TextOverflow.visible);

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text(_greeting),
    );
    final double minLine =
        LingAfriqType.targetSize * LingAfriqType.targetHeight * 2;
    expect(paragraph.size.height, greaterThanOrEqualTo(minLine - 0.01));
    final List<TextBox> tight = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: _greeting.length),
      boxHeightStyle: ui.BoxHeightStyle.tight,
    );
    expect(tight, isNotEmpty);
    expect(
      paragraph.getFullHeightForCaret(const ui.TextPosition(offset: 0)),
      greaterThanOrEqualTo(minLine - 0.01),
    );
    final Rect lens = tester.getRect(find.byType(ToneLens));
    final Offset origin = paragraph.localToGlobal(Offset.zero);
    for (final TextBox box in tight) {
      final Rect glyph = Rect.fromLTRB(
        origin.dx + box.left,
        origin.dy + box.top,
        origin.dx + box.right,
        origin.dy + box.bottom,
      );
      expect(lens.left, lessThanOrEqualTo(glyph.left + 0.1));
      expect(lens.top, lessThanOrEqualTo(glyph.top + 0.1));
      expect(lens.right, greaterThanOrEqualTo(glyph.right - 0.1));
      expect(lens.bottom, greaterThanOrEqualTo(glyph.bottom - 0.1));
      _expectUnclippedRect(glyph, paragraph);
    }
  });

  testWidgets('reduced motion leaves the contour already drawn', (
    tester,
  ) async {
    await _view(tester, const Size(390, 800));
    await tester.pumpWidget(_lens());
    final _Shot first = await _shot(tester, ToneContour.markKey);
    await tester.pump(const Duration(milliseconds: 300));
    final _Shot later = await _shot(tester, ToneContour.markKey);
    expect(later.bytes, equals(first.bytes));
    expect(_inkCount(first), greaterThan(10));

    await tester.pumpWidget(_lens(disableAnimations: true));
    final _Shot reduced = await _shot(tester, ToneContour.markKey);
    expect(reduced.bytes, equals(first.bytes));
  });

  testWidgets('goldens for the greeting and the unverified mark', (
    tester,
  ) async {
    await _view(tester, const Size(390, 800));
    const List<_Frame> frames = <_Frame>[
      _Frame('greeting_light', Brightness.light, 1, false, false),
      _Frame('greeting_dark', Brightness.dark, 1, false, false),
      _Frame('greeting_greyscale', Brightness.light, 1, true, false),
      _Frame('greeting_200', Brightness.light, 2, false, false),
      _Frame('unverified_light', Brightness.light, 1, false, true),
      _Frame('unverified_dark', Brightness.dark, 1, false, true),
      _Frame('unverified_greyscale', Brightness.light, 1, true, true),
      _Frame('unverified_200', Brightness.light, 2, false, true),
    ];

    for (final _Frame frame in frames) {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      await tester.pumpWidget(
        _lens(
          brightness: frame.brightness,
          scale: frame.scale,
          greyscale: frame.greyscale,
          unverified: frame.unverified,
        ),
      );
      await tester.pump();
      FlutterError.onError = previous;
      expect(errors, isEmpty, reason: frame.fileName);
      expect(tester.takeException(), isNull, reason: frame.fileName);

      final Size size = tester.getSize(find.byKey(_frameKey));
      expect(size.width, 390, reason: frame.fileName);
      expect(
        size.height,
        greaterThan(LingAfriqTokens.spacing48),
        reason: frame.fileName,
      );
      expect(size.height, lessThan(800), reason: frame.fileName);
      expect(
        tester.getSize(find.byKey(ToneContour.markKey)).height,
        LingAfriqTokens.spacing48,
        reason: frame.fileName,
      );
      expect(find.text(_greeting), findsOneWidget, reason: frame.fileName);

      if (frame.greyscale) {
        final _Shot frameShot = await _shot(tester, _frameKey);
        _expectGrey(frameShot);
      }

      await expectLater(
        find.byKey(_frameKey),
        matchesGoldenFile('goldens/tone_lens/${frame.fileName}.png'),
      );
    }
  });
}
