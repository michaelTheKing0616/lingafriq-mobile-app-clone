import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/media/transcript_view.dart';
import 'package:lingafriq/design/states/ai_unavailable_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/under_review_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

const Key _surfaceKey = ValueKey<String>('ai-review-surface');
const String _clipTitle = 'Morning greeting';

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

void _noop() {}

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

  test('sample lines are the deck lines and the sources stay on roles', () {
    final String deck = File(
      'docs/build/design/COPY_DECK.md',
    ).readAsStringSync();
    for (final String line in <String>[
      LingAiUnavailableStateCopy.whatHappened,
      LingAiUnavailableStateCopy.why,
      LingAiUnavailableStateCopy.whatToDo,
      LingAiUnavailableStateCopy.actionLabel,
    ]) {
      expect(deck, contains(line), reason: line);
    }
    expect(
      LingAiUnavailableStateCopy.whatToDo,
      contains('Polie did not speak for you'),
    );
    expect(
      LingUnderReviewStateCopy.waiting,
      'This clip is waiting for review.',
    );
    expect(LingUnderReviewStateCopy.waiting, LingTranscriptView.missingDetail);
    expect(LingUnderReviewState.playable, isFalse);

    for (final String path in <String>[
      'lib/design/states/ai_unavailable_state.dart',
      'lib/design/states/under_review_state.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('Color(0x'), isFalse, reason: path);
      expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
      expect(source.contains('AiGateway'), isFalse, reason: path);
      expect(source.toLowerCase().contains('groq'), isFalse, reason: path);
      expect(source.contains('AnimationController'), isFalse, reason: path);
    }

    final String ai = File(
      'lib/design/states/ai_unavailable_state.dart',
    ).readAsStringSync();
    for (final String field in <String>[
      'whatHappened',
      'why',
      'whatToDo',
      'actionLabel',
      'onAction',
    ]) {
      expect(ai, contains('required this.$field'));
      expect(RegExp('this\\.$field\\s*=').hasMatch(ai), isFalse);
    }
    expect(ai, contains('does not ask the tutor'));
    expect(ai, contains('LingAfriqTokens.roleLightInfo'));
    expect(ai, contains('LingAfriqTokens.roleDarkInfo'));
    expect(ai, contains('LingAfriqTokens.roleLightOnInfo'));
    expect(ai, contains('LingAfriqTokens.roleDarkOnInfo'));
    expect(ai, contains('LingButtonRole.accent'));
    expect(ai, contains('LingCueKind.info'));

    final String review = File(
      'lib/design/states/under_review_state.dart',
    ).readAsStringSync();
    expect(review, contains('required this.title'));
    expect(review.contains('LingButton'), isFalse);
    expect(review.contains("'Play'"), isFalse);
    expect(review.contains('"Play"'), isFalse);
  });

  testWidgets('unavailable tutor shows the info disc and one accent step', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    var steps = 0;
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: LingAiUnavailableState(
          whatHappened: LingAiUnavailableStateCopy.whatHappened,
          why: LingAiUnavailableStateCopy.why,
          whatToDo: LingAiUnavailableStateCopy.whatToDo,
          actionLabel: LingAiUnavailableStateCopy.actionLabel,
          onAction: () => steps++,
        ),
      ),
    );
    _expectLines(
      tester,
      whatHappened: LingAiUnavailableStateCopy.whatHappened,
      why: LingAiUnavailableStateCopy.why,
      whatToDo: LingAiUnavailableStateCopy.whatToDo,
    );
    final LingCueDisc disc = tester.widget<LingCueDisc>(
      find.byType(LingCueDisc),
    );
    expect(disc.kind, LingCueKind.info);
    expect(disc.fill, LingAfriqTokens.roleLightInfo);
    expect(disc.mark, LingAfriqTokens.roleLightOnInfo);
    expect(
      tester.getSize(find.byType(LingCueDisc)).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(find.byType(LingButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    final LingButton button = tester.widget<LingButton>(
      find.byType(LingButton),
    );
    expect(button.role, LingButtonRole.accent);
    expect(button.label, LingAiUnavailableStateCopy.actionLabel);
    expect(
      tester.getSize(find.byType(LingButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byType(LingButton));
    await tester.pump();
    expect(steps, 1);

    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: const LingAiUnavailableState(
          whatHappened: LingAiUnavailableStateCopy.whatHappened,
          why: LingAiUnavailableStateCopy.why,
          whatToDo: LingAiUnavailableStateCopy.whatToDo,
          actionLabel: LingAiUnavailableStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final LingCueDisc dark = tester.widget<LingCueDisc>(
      find.byType(LingCueDisc),
    );
    expect(dark.fill, LingAfriqTokens.roleDarkInfo);
    expect(dark.mark, LingAfriqTokens.roleDarkOnInfo);
  });

  testWidgets('the accent action does not call the AI path', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    final _Gateway gateway = _Gateway();
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: _TutorWhenUnavailable(gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.calls, 1);
    expect(find.byType(LingAiUnavailableState), findsOneWidget);
    expect(find.text(LingAiUnavailableStateCopy.whatToDo), findsOneWidget);
    expect(find.text(_Gateway.spoken), findsNothing);
    expect(find.textContaining('Polie says'), findsNothing);

    await tester.tap(find.byType(LingButton));
    await tester.pump();
    expect(gateway.calls, 1);
    expect(find.text('The lesson list is open.'), findsOneWidget);
    expect(find.byType(LingAiUnavailableState), findsNothing);
  });

  testWidgets('a clip under review shows its title and no play control', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: const LingUnderReviewState(title: _clipTitle),
      ),
    );
    expect(find.text(_clipTitle), findsOneWidget);
    expect(find.text(LingUnderReviewStateCopy.waiting), findsOneWidget);
    expect(LingUnderReviewState.playable, isFalse);
    _expectNoPlay(tester);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(_clipTitle), findsOneWidget);
    expect(
      find.bySemanticsLabel(LingUnderReviewStateCopy.waiting),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Play'), findsNothing);
    handle.dispose();

    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: const LingUnderReviewState(title: _clipTitle),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(LingUnderReviewStateCopy.waiting), findsOneWidget);
    _expectNoPlay(tester);
  });

  testWidgets('text at 200 percent wraps inside the width', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        textScale: 2,
        framed: true,
        child: const LingAiUnavailableState(
          whatHappened: LingAiUnavailableStateCopy.whatHappened,
          why: LingAiUnavailableStateCopy.why,
          whatToDo: LingAiUnavailableStateCopy.whatToDo,
          actionLabel: LingAiUnavailableStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    _expectWrap(tester, LingAiUnavailableStateCopy.whatToDo);
    expect(
      tester.getSize(find.byType(LingButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        textScale: 2,
        framed: true,
        child: const LingUnderReviewState(title: _clipTitle),
      ),
    );
    expect(tester.takeException(), isNull);
    _expectWrap(tester, LingUnderReviewStateCopy.waiting);
    _expectNoPlay(tester);
  });

  for (final (Brightness brightness, double scale) in <(Brightness, double)>[
    (Brightness.light, 1),
    (Brightness.dark, 1),
    (Brightness.light, 2),
  ]) {
    final String tone = brightness == Brightness.dark ? 'dark' : 'light';
    final String suffix = scale == 1 ? tone : '${tone}_200';
    testWidgets('ai unavailable golden $suffix', (WidgetTester tester) async {
      await _bind(tester);
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          textScale: scale,
          framed: true,
          child: const LingAiUnavailableState(
            whatHappened: LingAiUnavailableStateCopy.whatHappened,
            why: LingAiUnavailableStateCopy.why,
            whatToDo: LingAiUnavailableStateCopy.whatToDo,
            actionLabel: LingAiUnavailableStateCopy.actionLabel,
            onAction: _noop,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_surfaceKey),
        matchesGoldenFile('goldens/states/ai_unavailable_$suffix.png'),
      );
    });
    testWidgets('under review golden $suffix', (WidgetTester tester) async {
      await _bind(tester);
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          textScale: scale,
          framed: true,
          child: const LingUnderReviewState(title: _clipTitle),
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_surfaceKey),
        matchesGoldenFile('goldens/states/under_review_$suffix.png'),
      );
    });
  }
}

void _expectLines(
  WidgetTester tester, {
  required String whatHappened,
  required String why,
  required String whatToDo,
}) {
  expect(find.text(whatHappened), findsOneWidget);
  expect(find.text(why), findsOneWidget);
  expect(find.text(whatToDo), findsOneWidget);
  final SemanticsHandle handle = tester.ensureSemantics();
  expect(find.bySemanticsLabel(whatHappened), findsOneWidget);
  expect(find.bySemanticsLabel(why), findsOneWidget);
  expect(find.bySemanticsLabel(whatToDo), findsOneWidget);
  handle.dispose();
}

void _expectNoPlay(WidgetTester tester) {
  expect(find.text('Play'), findsNothing);
  expect(find.text('Play the audio'), findsNothing);
  expect(find.byType(LingButton), findsNothing);
  expect(find.byType(IconButton), findsNothing);
  expect(find.byType(TextButton), findsNothing);
  expect(find.byType(OutlinedButton), findsNothing);
  expect(find.byType(ElevatedButton), findsNothing);
  expect(find.byType(FloatingActionButton), findsNothing);
}

void _expectWrap(WidgetTester tester, String line) {
  for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
    expect(text.softWrap, isTrue);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.clip));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  }
  expect(
    tester.getSize(find.text(line)).height,
    greaterThan(LingAfriqType.bodySize * LingAfriqType.targetHeight * 2),
  );
  expect(
    tester.getSize(find.byType(SingleChildScrollView)).width,
    lessThanOrEqualTo(catalogueSurface.width),
  );
}

Future<void> _bind(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = catalogueSurface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(catalogueSurface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host({
  required Widget child,
  required Brightness brightness,
  double textScale = 1,
  bool framed = false,
}) {
  final ThemeData theme = catalogueTheme(brightness);
  final Color background = brightness == Brightness.dark
      ? LingAfriqTokens.roleDarkSurface
      : LingAfriqTokens.roleLightSurface;
  final Widget page = Padding(
    padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
    child: child,
  );
  final Widget body = framed
      ? SizedBox(
          key: _surfaceKey,
          width: catalogueSurface.width,
          height: catalogueSurface.height,
          child: ColoredBox(
            color: background,
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(child: page),
            ),
          ),
        )
      : page;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    darkTheme: theme,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (BuildContext context, Widget? built) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(backgroundColor: background, body: body),
  );
}

/// Stand-in for the tutor gateway. [reply] is the only AI path.
class _Gateway {
  int calls = 0;

  static const String spoken = 'Ẹ kú àárọ̀';

  /// Unavailable. A real gateway would return no tutor line.
  Future<String?> reply() async {
    calls++;
    return null;
  }
}

/// Paints the unavailable state when the gateway has no reply.
///
/// The button leaves the tutor and opens the lesson list. It does not
/// call [_Gateway.reply].
class _TutorWhenUnavailable extends StatefulWidget {
  const _TutorWhenUnavailable({required this.gateway});

  final _Gateway gateway;

  @override
  State<_TutorWhenUnavailable> createState() => _TutorWhenUnavailableState();
}

class _TutorWhenUnavailableState extends State<_TutorWhenUnavailable> {
  bool _unavailable = false;
  bool _leftTutor = false;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final String? reply = await widget.gateway.reply();
    if (!mounted) return;
    setState(() {
      _unavailable = reply == null;
    });
  }

  void _openLessonList() {
    setState(() {
      _unavailable = false;
      _leftTutor = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_leftTutor) {
      return const Text('The lesson list is open.');
    }
    if (!_unavailable) {
      return const SizedBox.shrink();
    }
    return LingAiUnavailableState(
      whatHappened: LingAiUnavailableStateCopy.whatHappened,
      why: LingAiUnavailableStateCopy.why,
      whatToDo: LingAiUnavailableStateCopy.whatToDo,
      actionLabel: LingAiUnavailableStateCopy.actionLabel,
      onAction: _openLessonList,
    );
  }
}
