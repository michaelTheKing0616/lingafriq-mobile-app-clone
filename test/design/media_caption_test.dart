import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/media/caption_player.dart';
import 'package:lingafriq/design/media/transcript_view.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

const String _title = 'Morning greeting';
const String _caption = 'Good morning. The greeting is spoken for this clip.';
const String _line =
    'The morning greeting is spoken once, then the village answers.';
const List<String> _lines = <String>['Good morning.', _line];
const Key _frameKey = ValueKey<String>('media-frame');
const Size _surface = Size(390, 2000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('media sources use ramp roles and plain copy', () {
    for (final String path in <String>[
      'lib/design/media/caption_player.dart',
      'lib/design/media/transcript_view.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('Color(0x'), isFalse, reason: path);
      expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
      expect(source.contains('\u2014'), isFalse, reason: path);
      expect(source.toLowerCase().contains('score'), isFalse, reason: path);
      expect(source.contains('LingPalette'), isTrue, reason: path);
      expect(source.contains('LingAfriqTokens.spacing'), isTrue, reason: path);
    }
  });

  test('a missing caption or transcript is flagged for review', () {
    final LingCaptionPlayer missing = const LingCaptionPlayer(
      title: _title,
      captionsOn: true,
      playing: false,
      onPressed: _noop,
    );
    expect(missing.flaggedForReview, isTrue);
    expect(missing.showsMissing, isTrue);
    expect(missing.showsCaption, isFalse);

    final LingCaptionPlayer ready = const LingCaptionPlayer(
      title: _title,
      caption: _caption,
      captionsOn: true,
      playing: false,
      onPressed: _noop,
    );
    expect(ready.flaggedForReview, isFalse);
    expect(ready.showsCaption, isTrue);

    final LingCaptionPlayer hidden = const LingCaptionPlayer(
      title: _title,
      caption: _caption,
      captionsOn: false,
      playing: true,
      onPressed: _noop,
    );
    expect(hidden.showsCaption, isFalse);
    expect(hidden.showsMissing, isFalse);
    expect(hidden.controlLabel, LingCaptionPlayer.pauseLabel);

    const LingTranscriptView empty = LingTranscriptView(lines: <String>[]);
    expect(empty.flaggedForReview, isTrue);
    const LingTranscriptView blank = LingTranscriptView(lines: <String>['  ']);
    expect(blank.flaggedForReview, isTrue);
    expect(blank.visibleLines, isEmpty);
    const LingTranscriptView spoken = LingTranscriptView(lines: _lines);
    expect(spoken.flaggedForReview, isFalse);
    expect(spoken.visibleLines, _lines);
  });

  testWidgets('captions on shows the line and the play control', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(_player(captionsOn: true));
    expect(find.text(_title), findsOneWidget);
    expect(find.text(_caption), findsOneWidget);
    expect(find.text(LingCaptionPlayer.playLabel), findsOneWidget);
    expect(find.text(LingCaptionPlayer.missingTitle), findsNothing);
    _expectAccent(tester, Brightness.light);
    _expectMinTap(tester);
    // captionsOn is the contract. This test passes that flag. It does not
    // depend on a live system captions channel, because that channel is
    // unavailable here. Text scale and pixel ratio are read from MediaQuery.
    _expectMediaQuery(tester, scale: 1);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(_caption), findsOneWidget);
    expect(find.bySemanticsLabel(LingCaptionPlayer.playLabel), findsOneWidget);
    handle.dispose();
  });

  testWidgets('captions off hides the line and keeps play', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(_player(captionsOn: false));
    expect(find.text(_title), findsOneWidget);
    expect(find.text(_caption), findsNothing);
    expect(find.text(LingCaptionPlayer.missingTitle), findsNothing);
    expect(find.text(LingCaptionPlayer.playLabel), findsOneWidget);
    _expectMinTap(tester);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(_caption), findsNothing);
    expect(find.bySemanticsLabel(LingCaptionPlayer.playLabel), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a missing caption is written, not left blank', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(_player(captionsOn: true, caption: null));
    expect(find.text(LingCaptionPlayer.missingTitle), findsOneWidget);
    expect(find.text(LingCaptionPlayer.missingDetail), findsOneWidget);
    expect(find.text(LingCaptionPlayer.playLabel), findsOneWidget);
    final Text detail = tester.widget<Text>(
      find.text(LingCaptionPlayer.missingDetail),
    );
    expect(detail.style?.color, LingAfriqTokens.roleLightOnSurfaceVariant);
    expect(detail.softWrap, isTrue);
    expect(detail.overflow, TextOverflow.visible);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(LingCaptionPlayer.missingTitle),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(LingCaptionPlayer.missingDetail),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the accent control says Pause while playing', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    var taps = 0;
    await tester.pumpWidget(
      _player(captionsOn: true, playing: true, onPressed: () => taps++),
    );
    expect(find.text(LingCaptionPlayer.pauseLabel), findsOneWidget);
    expect(find.text(LingCaptionPlayer.playLabel), findsNothing);
    final LingButton button = tester.widget<LingButton>(
      find.byType(LingButton),
    );
    expect(button.role, LingButtonRole.accent);
    expect(button.label, LingCaptionPlayer.pauseLabel);
    await tester.tap(find.byType(LingButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('transcript lines are selectable, wrapped, and readable', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(_transcript(_lines));
    expect(find.byType(SelectableText), findsNWidgets(_lines.length));
    expect(find.text(LingTranscriptView.missingTitle), findsNothing);
    for (final String line in _lines) {
      final SelectableText text = tester.widget<SelectableText>(
        find.widgetWithText(SelectableText, line),
      );
      expect(text.maxLines, isNull);
      expect(text.textWidthBasis, TextWidthBasis.parent);
      expect(text.style?.color, LingAfriqTokens.roleLightOnSurface);
    }
    _expectUnclipped(tester, find.byType(LingTranscriptView));
    _expectSemanticsContainer(tester, find.byType(LingTranscriptView));

    final SemanticsHandle handle = tester.ensureSemantics();
    for (final String line in _lines) {
      expect(find.bySemanticsLabel(line), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('a missing transcript is written, not left blank', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(_transcript(const <String>[]));
    expect(find.text(LingTranscriptView.missingTitle), findsOneWidget);
    expect(find.text(LingTranscriptView.missingDetail), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
    final Text detail = tester.widget<Text>(
      find.text(LingTranscriptView.missingDetail),
    );
    expect(detail.style?.color, LingAfriqTokens.roleLightOnSurfaceVariant);
    expect(detail.softWrap, isTrue);
    expect(detail.maxLines, isNull);
    expect(detail.overflow, TextOverflow.visible);
    _expectSemanticsContainer(tester, find.byType(LingTranscriptView));

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(LingTranscriptView.missingTitle),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(LingTranscriptView.missingDetail),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('captions and transcript text are not clipped at 200 percent', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;

    await tester.pumpWidget(_player(captionsOn: true, textScale: 2));
    await tester.pump();
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    _expectMediaQuery(tester, scale: 2);
    _expectWrapped(tester, find.text(_caption));
    _expectUnclipped(tester, find.byType(LingCaptionPlayer));
    _expectMinTap(tester);

    await tester.pumpWidget(_transcript(_lines, textScale: 2));
    await tester.pump();
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    _expectWrapped(tester, find.text(_line));
    _expectUnclipped(tester, find.byType(LingTranscriptView));
    for (final SelectableText text in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      expect(text.maxLines, isNull);
    }

    FlutterError.onError = previous;
  });

  testWidgets('goldens for captions and the missing transcript', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    const List<_Frame> frames = <_Frame>[
      _Frame('captions_on_light', Brightness.light, 1, _Kind.captionsOn),
      _Frame('captions_on_dark', Brightness.dark, 1, _Kind.captionsOn),
      _Frame('captions_on_light_200', Brightness.light, 2, _Kind.captionsOn),
      _Frame('captions_off_light', Brightness.light, 1, _Kind.captionsOff),
      _Frame('captions_off_dark', Brightness.dark, 1, _Kind.captionsOff),
      _Frame(
        'missing_transcript_light',
        Brightness.light,
        1,
        _Kind.missingTranscript,
      ),
      _Frame(
        'missing_transcript_dark',
        Brightness.dark,
        1,
        _Kind.missingTranscript,
      ),
      _Frame(
        'missing_transcript_light_200',
        Brightness.light,
        2,
        _Kind.missingTranscript,
      ),
    ];

    for (final _Frame frame in frames) {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      await tester.pumpWidget(_frameWidget(frame));
      await tester.pump();
      FlutterError.onError = previous;
      expect(errors, isEmpty, reason: frame.fileName);
      expect(tester.takeException(), isNull, reason: frame.fileName);
      final Size frameSize = tester.getSize(find.byKey(_frameKey));
      expect(frameSize.width, 390, reason: frame.fileName);
      expect(frameSize.height, greaterThan(48), reason: frame.fileName);
      expect(frameSize.height, lessThan(800), reason: frame.fileName);
      final BuildContext context = tester.element(find.byKey(_frameKey));
      final MediaQueryData media = MediaQuery.of(context);
      expect(media.devicePixelRatio, 1, reason: frame.fileName);
      expect(media.textScaler.scale(1), frame.scale, reason: frame.fileName);
      expect(media.size.width, 390, reason: frame.fileName);
      final LingPalette palette = LingPalette.of(frame.brightness);
      final Material? fill = frame.kind == _Kind.missingTranscript
          ? null
          : tester.widget<Material>(find.byKey(LingMarks.fill));
      if (fill != null) {
        expect(fill.color, palette.accent, reason: frame.fileName);
      }
      final String inkText = frame.kind == _Kind.missingTranscript
          ? LingTranscriptView.missingTitle
          : _title;
      final Text ink = tester.widget<Text>(find.text(inkText));
      expect(ink.style?.color, palette.onSurface, reason: frame.fileName);
      if (frame.kind == _Kind.captionsOn) {
        expect(find.text(_caption), findsOneWidget, reason: frame.fileName);
      }
      if (frame.kind == _Kind.captionsOff) {
        expect(find.text(_caption), findsNothing, reason: frame.fileName);
        expect(
          find.text(LingCaptionPlayer.playLabel),
          findsOneWidget,
          reason: frame.fileName,
        );
      }
      if (frame.kind == _Kind.missingTranscript) {
        expect(
          find.text(LingTranscriptView.missingTitle),
          findsOneWidget,
          reason: frame.fileName,
        );
        expect(
          find.text(LingTranscriptView.missingDetail),
          findsOneWidget,
          reason: frame.fileName,
        );
      }
      await expectLater(
        find.byKey(_frameKey),
        matchesGoldenFile('goldens/media/${frame.fileName}.png'),
      );
    }
  });
}

enum _Kind { captionsOn, captionsOff, missingTranscript }

class _Frame {
  const _Frame(this.fileName, this.brightness, this.scale, this.kind);

  final String fileName;
  final Brightness brightness;
  final double scale;
  final _Kind kind;
}

void _noop() {}

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Future<void> _bind(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _surface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _player({
  required bool captionsOn,
  String? caption = _caption,
  bool playing = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  VoidCallback? onPressed,
  bool framed = false,
}) {
  return _host(
    brightness: brightness,
    textScale: textScale,
    framed: framed,
    child: LingCaptionPlayer(
      title: _title,
      caption: caption,
      captionsOn: captionsOn,
      playing: playing,
      onPressed: onPressed ?? _noop,
    ),
  );
}

Widget _transcript(
  List<String> lines, {
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool framed = false,
}) {
  return _host(
    brightness: brightness,
    textScale: textScale,
    framed: framed,
    child: LingTranscriptView(lines: lines),
  );
}

Widget _frameWidget(_Frame frame) {
  switch (frame.kind) {
    case _Kind.captionsOn:
      return _player(
        captionsOn: true,
        brightness: frame.brightness,
        textScale: frame.scale,
        framed: true,
      );
    case _Kind.captionsOff:
      return _player(
        captionsOn: false,
        brightness: frame.brightness,
        textScale: frame.scale,
        framed: true,
      );
    case _Kind.missingTranscript:
      return _transcript(
        const <String>[],
        brightness: frame.brightness,
        textScale: frame.scale,
        framed: true,
      );
  }
}

Widget _host({
  required Widget child,
  required Brightness brightness,
  required double textScale,
  required bool framed,
}) {
  final LingPalette palette = LingPalette.of(brightness);
  final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: LingAfriqType.bodyFamily,
    scaffoldBackgroundColor: palette.surface,
  );
  final Widget body = framed
      ? RepaintBoundary(
          key: _frameKey,
          child: SizedBox(
            width: _surface.width,
            child: ColoredBox(
              color: palette.surface,
              child: Padding(
                padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
                child: child,
              ),
            ),
          ),
        )
      : child;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    darkTheme: theme,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (BuildContext context, Widget? built) {
      final MediaQueryData media = MediaQuery.of(context);
      return Theme(
        data: theme,
        child: MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: built ?? const SizedBox.shrink(),
        ),
      );
    },
    home: Scaffold(
      backgroundColor: palette.surface,
      body: Align(alignment: Alignment.topLeft, child: body),
    ),
  );
}

void _expectMediaQuery(WidgetTester tester, {required double scale}) {
  final BuildContext context = tester.element(find.byType(LingCaptionPlayer));
  final MediaQueryData media = MediaQuery.of(context);
  expect(media.devicePixelRatio, 1);
  expect(media.size.width, 390);
  expect(media.textScaler.scale(1), scale);
  expect(media.disableAnimations, isTrue);
}

void _expectMinTap(WidgetTester tester) {
  final Size size = tester.getSize(find.byType(LingButton));
  expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
  expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
}

void _expectAccent(WidgetTester tester, Brightness brightness) {
  final Material fill = tester.widget<Material>(find.byKey(LingMarks.fill));
  final LingPalette palette = LingPalette.of(brightness);
  expect(fill.color, palette.accent);
  expect(fill.color, isNot(palette.surface));
}

void _expectWrapped(WidgetTester tester, Finder finder) {
  final Size size = tester.getSize(finder);
  final double scale = MediaQuery.textScalerOf(tester.element(finder)).scale(1);
  final double line =
      LingAfriqType.bodySize * LingAfriqType.targetHeight * scale;
  expect(size.height, greaterThan(line));
  expect(size.width, lessThanOrEqualTo(390));
}

void _expectUnclipped(WidgetTester tester, Finder parent) {
  final Rect bounds = tester.getRect(parent);
  final Finder targets = find.descendant(
    of: parent,
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is Text || widget is SelectableText,
    ),
  );
  expect(targets, findsWidgets);
  for (final Element element in targets.evaluate()) {
    final RenderBox box = element.renderObject! as RenderBox;
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.left, greaterThanOrEqualTo(bounds.left - 0.1));
    expect(rect.top, greaterThanOrEqualTo(bounds.top - 0.1));
    expect(rect.right, lessThanOrEqualTo(bounds.right + 0.1));
    expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + 0.1));
  }
}

void _expectSemanticsContainer(WidgetTester tester, Finder host) {
  final Semantics semantics = tester.widget<Semantics>(
    find
        .descendant(
          of: host,
          matching: find.byWidgetPredicate(
            (Widget widget) => widget is Semantics && widget.container,
          ),
        )
        .first,
  );
  expect(semantics.container, isTrue);
  expect(semantics.explicitChildNodes, isTrue);
}
