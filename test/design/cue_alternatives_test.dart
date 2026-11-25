import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/bundled_fonts.dart';
import 'package:lingafriq/design/a11y/cue_alternatives.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';
import 'package:lingafriq/design/typography.dart';

const Key _frameKey = Key('cue-alternative-frame');

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

const Map<LingCueName, String> _labels = <LingCueName, String>{
  LingCueName.correct: 'That is right.',
  LingCueName.incorrect: 'Try that again.',
  LingCueName.hint: 'Here is a hint.',
  LingCueName.microphoneOpen: 'Microphone open.',
  LingCueName.microphoneClose: 'Microphone closed.',
};

const Map<LingCueName, String> _hapticTypes = <LingCueName, String>{
  LingCueName.correct: 'HapticFeedbackType.successNotification',
  LingCueName.incorrect: 'HapticFeedbackType.mediumImpact',
  LingCueName.hint: 'HapticFeedbackType.lightImpact',
  LingCueName.microphoneOpen: 'HapticFeedbackType.lightImpact',
  LingCueName.microphoneClose: 'HapticFeedbackType.selectionClick',
};

final List<Object?> _haptics = <Object?>[];

void _mockHaptics(WidgetTester tester) {
  _haptics.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        _haptics.add(call.arguments);
      }
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

Future<void> _load(String family, String asset) async {
  final ByteData data = ByteData.sublistView(await File(asset).readAsBytes());
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(data));
  await loader.load();
}

Future<void> _view(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 800);
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(const Size(390, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host({
  required Widget child,
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool disableAnimations = false,
  bool greyscale = false,
}) {
  final Color background = brightness == Brightness.dark
      ? LingAfriqTokens.roleDarkSurface
      : LingAfriqTokens.roleLightSurface;
  Widget body = ColoredBox(
    color: background,
    child: Padding(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      child: child,
    ),
  );
  if (greyscale) {
    body = ColorFiltered(colorFilter: _greyscale, child: body);
  }
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 800),
      textScaler: TextScaler.linear(scale),
      disableAnimations: disableAnimations,
    ),
    child: Theme(
      data: ThemeData(brightness: brightness, useMaterial3: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: background,
          child: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: _frameKey,
              child: SizedBox(width: 390, child: body),
            ),
          ),
        ),
      ),
    ),
  );
}

Color _fill(LingCueName cue, {required bool dark}) {
  return switch (cue) {
    LingCueName.correct =>
      dark ? LingAfriqTokens.roleDarkSuccess : LingAfriqTokens.roleLightSuccess,
    LingCueName.incorrect =>
      dark ? LingAfriqTokens.roleDarkDanger : LingAfriqTokens.roleLightDanger,
    LingCueName.hint =>
      dark ? LingAfriqTokens.roleDarkInfo : LingAfriqTokens.roleLightInfo,
    LingCueName.microphoneOpen =>
      dark ? LingAfriqTokens.roleDarkAccent : LingAfriqTokens.roleLightAccent,
    LingCueName.microphoneClose =>
      dark
          ? LingAfriqTokens.roleDarkSurfaceContainer
          : LingAfriqTokens.roleLightSurfaceContainer,
  };
}

class _Shot {
  const _Shot(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
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
  final _Shot shot = _Shot(
    Uint8List.fromList(data.buffer.asUint8List()),
    image.width,
    image.height,
  );
  image.dispose();
  return shot;
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
  });

  test('cue file uses ramp roles and keeps numbers out of the pitch path', () {
    final String source = File('lib/design/a11y/cue_alternatives.dart')
        .readAsStringSync();
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
    expect(source.contains('LingAfriqTokens.roleLightSuccess'), isTrue);
    expect(source.contains('LingAfriqTokens.roleDarkSuccess'), isTrue);
    expect(source.contains('LingAfriqTokens.roleLightDanger'), isTrue);
    expect(source.contains('LingAfriqTokens.roleDarkDanger'), isTrue);
    expect(source.contains('LingAfriqTokens.roleLightInfo'), isTrue);
    expect(source.contains('LingAfriqTokens.roleDarkInfo'), isTrue);
    expect(source.contains('LingAfriqTokens.roleLightAccent'), isTrue);
    expect(source.contains('LingAfriqTokens.roleDarkAccent'), isTrue);
    expect(source.contains('LingAfriqTokens.roleLightOnSurface'), isTrue);
    expect(source.contains('LingAfriqTokens.roleDarkOnSurface'), isTrue);
    expect(source.contains('ToneLens'), isTrue);
    expect(LingCueAlternatives.greetingContours, <ToneContourKind>[
      ToneContourKind.mid,
      ToneContourKind.high,
      ToneContourKind.rising,
      ToneContourKind.low,
    ]);
    expect(
      LingCueAlternatives.pitchLabel,
      'Tone on Ẹ kú àárọ̀. Mid, then high, then rising, then low.',
    );
    expect(RegExp(r'\d').hasMatch(LingCueAlternatives.pitchLabel), isFalse);
  });

  testWidgets('visual shows when sound is off', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _view(tester);
    for (final LingCueName cue in LingCueName.values) {
      var sounds = 0;
      await tester.pumpWidget(
        _host(
          child: LingCueAlternatives(
            cue: cue,
            hapticsEnabled: false,
            soundEnabled: false,
            onSound: () => sounds += 1,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(LingCueAlternatives.visualCue), findsOneWidget);
      expect(find.byKey(LingCueAlternatives.mark), findsOneWidget);
      expect(find.text(_labels[cue]!), findsOneWidget);
      expect(find.bySemanticsLabel(_labels[cue]!), findsOneWidget);
      expect(cue.spokenLabel, _labels[cue]);
      expect(sounds, 0);
      expect(find.byType(ToneLens), findsNothing);
      expect(find.byKey(LingCueAlternatives.pitch), findsNothing);
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.byKey(LingCueAlternatives.visualCue),
      );
      expect(
        (box.decoration as BoxDecoration).color,
        _fill(cue, dark: false),
        reason: cue.mapName,
      );
    }

    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: const LingCueAlternatives(
          cue: LingCueName.incorrect,
          hapticsEnabled: false,
        ),
      ),
    );
    await tester.pump();
    final DecoratedBox dark = tester.widget<DecoratedBox>(
      find.byKey(LingCueAlternatives.visualCue),
    );
    expect(
      (dark.decoration as BoxDecoration).color,
      LingAfriqTokens.roleDarkDanger,
    );
    expect(find.text('Try that again.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('haptic fires only when haptics are on', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    await _view(tester);
    for (final LingCueName cue in LingCueName.values) {
      _haptics.clear();
      await tester.pumpWidget(
        _host(
          disableAnimations: true,
          child: LingCueAlternatives(
            key: ValueKey<LingCueName>(cue),
            cue: cue,
            hapticsEnabled: true,
            soundEnabled: false,
          ),
        ),
      );
      await tester.pump();
      expect(_haptics, <Object?>[_hapticTypes[cue]], reason: cue.mapName);
    }

    _haptics.clear();
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const LingCueAlternatives(
          key: ValueKey<String>('haptics-off'),
          cue: LingCueName.correct,
          hapticsEnabled: false,
          soundEnabled: false,
        ),
      ),
    );
    await tester.pump();
    expect(_haptics, isEmpty);
    expect(find.byKey(LingCueAlternatives.visualCue), findsOneWidget);
  });

  testWidgets('hearing-impaired path shows ToneLens and no sound callback', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _view(tester);
    var sounds = 0;
    await tester.pumpWidget(
      _host(
        child: LingCueAlternatives(
          cue: LingCueName.correct,
          hapticsEnabled: false,
          soundEnabled: true,
          hearingImpaired: true,
          onSound: () => sounds += 1,
        ),
      ),
    );
    await tester.pump();
    expect(sounds, 0);
    expect(find.byType(ToneLens), findsOneWidget);
    expect(find.byKey(LingCueAlternatives.pitch), findsOneWidget);
    expect(find.byKey(LingCueAlternatives.visualCue), findsOneWidget);
    expect(find.text('That is right.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(LingCueAlternatives.pitchLabel),
      findsOneWidget,
    );
    expect(find.text(LingCueAlternatives.greeting), findsOneWidget);

    final ToneLens lens = tester.widget<ToneLens>(find.byType(ToneLens));
    expect(lens.word, LingCueAlternatives.greeting);
    expect(lens.contours, LingCueAlternatives.greetingContours);
    expect(lens.source, ToneSource.orthography);
    expect(lens.unverified, isFalse);
    final ToneContour contour = tester.widget<ToneContour>(
      find.byType(ToneContour),
    );
    expect(contour.color, LingAfriqTokens.roleLightOnSurface);
    expect(contour.kinds, LingCueAlternatives.greetingContours);

    for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
      final String data = text.data ?? text.textSpan?.toPlainText() ?? '';
      expect(RegExp(r'\d').hasMatch(data), isFalse, reason: data);
    }

    await tester.pumpWidget(
      _host(
        child: LingCueAlternatives(
          cue: LingCueName.hint,
          hapticsEnabled: false,
          soundEnabled: true,
          hearingImpaired: false,
          onSound: () => sounds += 1,
        ),
      ),
    );
    await tester.pump();
    expect(sounds, 1);
    expect(find.byType(ToneLens), findsNothing);
    expect(find.text('Here is a hint.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('greyscale contour still has one stroke colour', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    await tester.pumpWidget(
      _host(
        greyscale: true,
        disableAnimations: true,
        child: const LingCueAlternatives(
          cue: LingCueName.correct,
          hapticsEnabled: false,
          hearingImpaired: true,
        ),
      ),
    );
    await tester.pump();

    final ToneContour contour = tester.widget<ToneContour>(
      find.byType(ToneContour),
    );
    expect(contour.color, LingAfriqTokens.roleLightOnSurface);
    expect(contour.background, LingAfriqTokens.roleLightSurfaceContainer);
    expect(contour.kinds, LingCueAlternatives.greetingContours);
    expect(contour.unverified, isFalse);

    final Rect mark = tester.getRect(find.byKey(ToneContour.markKey));
    final Rect frame = tester.getRect(find.byKey(_frameKey));
    final _Shot shot = await _shot(tester, _frameKey);
    expect(shot.width, 390);

    final int left = (mark.left - frame.left)
        .round()
        .clamp(0, shot.width - 1)
        .toInt();
    final int top = (mark.top - frame.top)
        .round()
        .clamp(0, shot.height - 1)
        .toInt();
    final int right = (mark.right - frame.left)
        .round()
        .clamp(left + 1, shot.width)
        .toInt();
    final int bottom = (mark.bottom - frame.top)
        .round()
        .clamp(top + 1, shot.height)
        .toInt();

    var darkest = 255;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final int i = (y * shot.width + x) * 4;
        final int r = shot.bytes[i];
        final int g = shot.bytes[i + 1];
        final int b = shot.bytes[i + 2];
        expect(r, g, reason: 'pixel $x,$y is not one grey');
        expect(g, b, reason: 'pixel $x,$y is not one grey');
        if (r < darkest) darkest = r;
      }
    }
    var strokeCount = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final int r = shot.bytes[(y * shot.width + x) * 4];
        if (r <= darkest + 1) strokeCount += 1;
      }
    }
    expect(darkest, lessThan(80));
    expect(strokeCount, greaterThan(10));
  });

  testWidgets('200 percent text does not clip the spoken label', (
    WidgetTester tester,
  ) async {
    await _view(tester);
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(
      _host(
        scale: 2,
        disableAnimations: true,
        child: const LingCueAlternatives(
          cue: LingCueName.microphoneClose,
          hapticsEnabled: false,
          hearingImpaired: true,
        ),
      ),
    );
    await tester.pump();
    FlutterError.onError = previous;
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Microphone closed.'), findsOneWidget);
    expect(find.text(LingCueAlternatives.greeting), findsOneWidget);

    final Rect cue = tester.getRect(find.byKey(LingCueAlternatives.visualCue));
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text('Microphone closed.'),
    );
    final Offset origin = paragraph.localToGlobal(Offset.zero);
    final Rect glyph = origin & paragraph.size;
    expect(cue.left, lessThanOrEqualTo(glyph.left + 0.1));
    expect(cue.top, lessThanOrEqualTo(glyph.top + 0.1));
    expect(cue.right, greaterThanOrEqualTo(glyph.right - 0.1));
    expect(cue.bottom, greaterThanOrEqualTo(glyph.bottom - 0.1));
  });
}
