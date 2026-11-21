import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/rtl_support.dart';
import 'package:lingafriq/design/icons/lingafriq_icons.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';

const List<String> _tabs = <String>['Today', 'Learn', 'Speak'];
const String _latin = 'kedu';
const String _arabic = 'سلام';
const String _ajami = 'ٻاو';
const List<ToneContourKind> _contours = <ToneContourKind>[
  ToneContourKind.rising,
  ToneContourKind.downstep,
  ToneContourKind.low,
];
const Size _surface = Size(390, 640);
const Color _ink = LingAfriqTokens.roleLightOnSurface;
const Color _paper = LingAfriqTokens.roleLightSurface;
const Color _accent = LingAfriqTokens.roleLightAccent;

class _Shot {
  const _Shot(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

Future<void> _view(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _surface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _app({
  required Widget child,
  Locale? locale,
  String? targetText,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
    builder: (BuildContext context, Widget? home) {
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: home!,
      );
    },
    home: LingRtlScope(
      locale: locale,
      targetText: targetText,
      child: Scaffold(
        backgroundColor: _paper,
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
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
      throw StateError('rtl image has no bytes');
    }
    return raw;
  }))!;
  final Uint8List bytes = Uint8List.fromList(data.buffer.asUint8List());
  final _Shot shot = _Shot(bytes, image.width, image.height);
  image.dispose();
  return shot;
}

int _inkCount(_Shot shot) {
  var count = 0;
  for (var index = 0; index < shot.bytes.length; index += 4) {
    if (shot.bytes[index] < 200 ||
        shot.bytes[index + 1] < 200 ||
        shot.bytes[index + 2] < 200) {
      count += 1;
    }
  }
  return count;
}

bool _symmetric(_Shot shot) {
  for (var y = 0; y < shot.height; y++) {
    for (var x = 0; x < shot.width ~/ 2; x++) {
      final int left = (y * shot.width + x) * 4;
      final int right = (y * shot.width + (shot.width - 1 - x)) * 4;
      for (var channel = 0; channel < 4; channel++) {
        if (shot.bytes[left + channel] != shot.bytes[right + channel]) {
          return false;
        }
      }
    }
  }
  return true;
}

void _expectMirror(_Shot ltr, _Shot rtl) {
  expect(ltr.width, rtl.width);
  expect(ltr.height, rtl.height);
  expect(_symmetric(ltr), isFalse);
  expect(rtl.bytes, isNot(equals(ltr.bytes)));
  var maxDelta = 0;
  for (var y = 0; y < ltr.height; y++) {
    for (var x = 0; x < ltr.width; x++) {
      final int from = (y * ltr.width + x) * 4;
      final int to = (y * ltr.width + (ltr.width - 1 - x)) * 4;
      for (var channel = 0; channel < 4; channel++) {
        final int delta = (rtl.bytes[to + channel] - ltr.bytes[from + channel])
            .abs();
        if (delta > maxDelta) maxDelta = delta;
      }
    }
  }
  // Antialiasing can round a mirrored edge by a few levels.
  expect(maxDelta, lessThanOrEqualTo(4));
}

List<String> _focusOrder(WidgetTester tester) {
  final List<FocusTraversalOrder> nodes = tester
      .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
      .toList();
  nodes.sort((FocusTraversalOrder a, FocusTraversalOrder b) {
    final double left = (a.order as NumericFocusOrder).order;
    final double right = (b.order as NumericFocusOrder).order;
    return left.compareTo(right);
  });
  return nodes
      .map(
        (FocusTraversalOrder node) =>
            (node.child.key! as ValueKey<String>).value,
      )
      .toList();
}

List<String> _visualOrder(WidgetTester tester) {
  final List<String> labels = List<String>.of(_tabs);
  labels.sort((String a, String b) {
    final double left = tester.getTopLeft(find.byKey(LingTabRow.tabKey(a))).dx;
    final double right = tester.getTopLeft(find.byKey(LingTabRow.tabKey(b))).dx;
    return left.compareTo(right);
  });
  return labels;
}

Future<List<String>> _pumpTabs(
  WidgetTester tester, {
  Locale? locale,
  String? targetText,
}) async {
  await tester.pumpWidget(
    _app(
      locale: locale,
      targetText: targetText,
      child: const LingTabRow(labels: _tabs),
    ),
  );
  await tester.pump();
  final List<String> focus = _focusOrder(tester);
  final List<String> visual = _visualOrder(tester);
  expect(focus, visual);
  expect(focus, hasLength(_tabs.length));
  return focus;
}

Future<_Shot> _pumpContour(WidgetTester tester, String word) async {
  await tester.pumpWidget(
    _app(
      targetText: word,
      child: SizedBox(
        width: LingAfriqTokens.spacing48 * 4,
        child: LingRtlToneLens(
          word: word,
          contours: _contours,
          source: ToneSource.orthography,
        ),
      ),
    ),
  );
  await tester.pump();
  return _shot(tester, LingRtlToneLens.contourKey);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rtl files skip the em dash and hex colours', () {
    final String library = File(
      'lib/design/a11y/rtl_support.dart',
    ).readAsStringSync();
    final String spec = File('test/goldens/rtl_test.dart').readAsStringSync();
    expect(library.runes.contains(8212), isFalse);
    expect(spec.runes.contains(8212), isFalse);
    expect(library.contains('0x'), isFalse);
    expect(library.contains('#'), isFalse);
    expect(library.contains('Color('), isFalse);
    expect(lingDirectionalIcons, <LingDirectionalIcon>[
      LingDirectionalIcon.backChevron,
    ]);
    expect(lingNonDirectionalIcons, <LingIconName>[
      LingIconName.search,
      LingIconName.check,
      LingIconName.warning,
    ]);
  });

  test('arabic locales and ajami text read right to left', () {
    expect(lingLocaleReadsRtl(const Locale('en')), isFalse);
    expect(lingLocaleReadsRtl(const Locale('ar')), isTrue);
    expect(lingLocaleReadsRtl(const Locale('ar', 'MA')), isTrue);
    expect(
      lingLocaleReadsRtl(
        const Locale.fromSubtags(languageCode: 'ha', scriptCode: 'Arab'),
      ),
      isTrue,
    );
    expect(lingTargetReadsRtl(_latin), isFalse);
    expect(lingTargetReadsRtl(_arabic), isTrue);
    expect(lingTargetReadsRtl(_ajami), isTrue);
    expect(lingTargetReadsRtl(lingAjamiLetters), isTrue);
    expect(
      LingRtlScope.directionFor(locale: const Locale('en')),
      TextDirection.ltr,
    );
    expect(
      LingRtlScope.directionFor(locale: const Locale('ar')),
      TextDirection.rtl,
    );
    expect(LingRtlScope.directionFor(targetText: _ajami), TextDirection.rtl);
  });

  testWidgets('tab order stays left to right and reverses in rtl', (
    WidgetTester tester,
  ) async {
    await _view(tester);

    final List<String> ltr = await _pumpTabs(
      tester,
      locale: const Locale('en'),
    );
    expect(
      Directionality.of(tester.element(find.byType(LingTabRow))),
      TextDirection.ltr,
    );
    expect(ltr, _tabs);

    final List<String> arabic = await _pumpTabs(
      tester,
      locale: const Locale('ar'),
    );
    expect(
      Directionality.of(tester.element(find.byType(LingTabRow))),
      TextDirection.rtl,
    );
    expect(arabic, _tabs.reversed.toList());

    final List<String> ajami = await _pumpTabs(
      tester,
      locale: const Locale('en'),
      targetText: _ajami,
    );
    expect(
      Directionality.of(tester.element(find.byType(LingTabRow))),
      TextDirection.rtl,
    );
    expect(ajami, _tabs.reversed.toList());
    expect(ajami, ltr.reversed.toList());
  });

  testWidgets('arabic and ajami samples mirror the tone lens contour', (
    WidgetTester tester,
  ) async {
    await _view(tester);

    final _Shot latin = await _pumpContour(tester, _latin);
    expect(_inkCount(latin), greaterThan(12));
    expect(
      Directionality.of(tester.element(find.text(_latin))),
      TextDirection.ltr,
    );
    expect(
      tester.getSize(find.byKey(LingRtlToneLens.contourKey)).height,
      LingAfriqTokens.spacing48,
    );

    final _Shot arabic = await _pumpContour(tester, _arabic);
    expect(
      Directionality.of(tester.element(find.text(_arabic))),
      TextDirection.rtl,
    );
    _expectMirror(latin, arabic);

    final _Shot ajami = await _pumpContour(tester, _ajami);
    expect(
      Directionality.of(tester.element(find.text(_ajami))),
      TextDirection.rtl,
    );
    expect(ajami.bytes, equals(arabic.bytes));
    _expectMirror(latin, ajami);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        toneLensLabel(word: _ajami, contours: _contours, unverified: false),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a latin sample keeps a left to right contour in arabic', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final _Shot latin = await _pumpContour(tester, _latin);
    await tester.pumpWidget(
      _app(
        locale: const Locale('ar'),
        child: const SizedBox(
          width: LingAfriqTokens.spacing48 * 4,
          child: LingRtlToneLens(
            word: _latin,
            contours: _contours,
            source: ToneSource.validatedAudio,
          ),
        ),
      ),
    );
    await tester.pump();
    final LingRtlToneLens lens = tester.widget<LingRtlToneLens>(
      find.byType(LingRtlToneLens),
    );
    expect(lens.source, ToneSource.validatedAudio);
    expect(lens.word, _latin);
    final _Shot insideArabic = await _shot(tester, LingRtlToneLens.contourKey);
    expect(insideArabic.bytes, equals(latin.bytes));
    expect(
      Directionality.of(tester.element(find.text(_latin))),
      TextDirection.ltr,
    );
  });

  testWidgets('search check and warning keep their painting in rtl', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    for (final LingIconName name in lingNonDirectionalIcons) {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: LingRtlFixedIcon(name: name, color: _ink, accent: _accent),
        ),
      );
      await tester.pump();
      final _Shot ltr = await _shot(tester, LingRtlFixedIcon.paintKey(name));

      await tester.pumpWidget(
        _app(
          locale: const Locale('ar'),
          child: LingRtlFixedIcon(name: name, color: _ink, accent: _accent),
        ),
      );
      await tester.pump();
      final _Shot rtl = await _shot(tester, LingRtlFixedIcon.paintKey(name));

      expect(_inkCount(ltr), greaterThan(12), reason: name.name);
      expect(rtl.width, ltr.width, reason: name.name);
      expect(rtl.height, ltr.height, reason: name.name);
      expect(rtl.bytes, equals(ltr.bytes), reason: name.name);
    }
  });

  testWidgets('the back chevron mirrors and fixed marks do not', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    Future<_Shot> chevron(Locale locale) async {
      await tester.pumpWidget(
        _app(
          locale: locale,
          child: const LingRtlBackChevron(
            color: _ink,
            background: _paper,
            semanticsLabel: 'Back',
          ),
        ),
      );
      await tester.pump();
      return _shot(tester, LingRtlBackChevron.paintKey);
    }

    final _Shot ltr = await chevron(const Locale('en'));
    final _Shot rtl = await chevron(const Locale('ar'));
    expect(_inkCount(ltr), greaterThan(8));
    _expectMirror(ltr, rtl);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('200 percent text does not clip the tab or the sample', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(
      _app(
        locale: const Locale('ar'),
        textScale: 2,
        targetText: _ajami,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LingTabRow(labels: _tabs),
            SizedBox(
              width: LingAfriqTokens.spacing48 * 4,
              child: LingRtlToneLens(
                word: _ajami,
                contours: _contours,
                source: ToneSource.orthography,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    FlutterError.onError = previous;
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.overflow, TextOverflow.visible);
      expect(text.maxLines, isNull);
    }
    expect(
      tester.getSize(find.byKey(LingRtlToneLens.contourKey)).height,
      LingAfriqTokens.spacing48,
    );
  });
}
