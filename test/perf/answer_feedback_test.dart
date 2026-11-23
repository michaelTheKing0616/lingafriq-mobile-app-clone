import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/feedback/answer_feedback.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

const Size _frame = Size(390, 640);
const Key _surfaceKey = ValueKey<String>('answer-feedback-surface');

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

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Future<void> _bind(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _frame;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(_frame);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host({
  required Widget child,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
  bool framed = false,
}) {
  final Color background = brightness == Brightness.dark
      ? LingAfriqTokens.roleDarkSurface
      : LingAfriqTokens.roleLightSurface;
  final Widget body = framed
      ? SizedBox(
          key: _surfaceKey,
          width: _frame.width,
          height: _frame.height,
          child: ColoredBox(
            color: background,
            child: Align(
              alignment: Alignment.topCenter,
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
    theme: ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      fontFamily: LingAfriqType.bodyFamily,
    ),
    builder: (BuildContext context, Widget? built) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(backgroundColor: background, body: body),
  );
}

Widget _pair({required bool hapticsEnabled, required bool soundEnabled}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      LingAnswerFeedback(
        correct: true,
        hapticsEnabled: hapticsEnabled,
        soundEnabled: soundEnabled,
      ),
      const SizedBox(height: LingAfriqTokens.spacing16),
      LingAnswerFeedback(
        correct: false,
        hapticsEnabled: hapticsEnabled,
        soundEnabled: soundEnabled,
      ),
    ],
  );
}

void _expectBudget(int measured) {
  // The failure message names the milliseconds measured on the test binding.
  // This is not a physical phone.
  if (measured > LingAfriqTokens.motionProductFast) {
    fail('scheduled start $measured ms');
  }
  expect(
    measured,
    lessThanOrEqualTo(LingAfriqTokens.motionProductFast),
    reason: 'scheduled start $measured ms',
  );
}

int _bindingStart(
  WidgetTester tester,
  LingAnswerFeedbackTiming timing,
  DateTime tap,
) {
  final int fromBinding = tester.binding.clock
      .now()
      .difference(tap)
      .inMilliseconds;
  final int recorded = timing.scheduledStartMs;
  return fromBinding > recorded ? fromBinding : recorded;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('answer feedback uses the fast token and plain copy', () {
    expect(LingAfriqTokens.motionProductFast, 160);
    expect(LingAnswerFeedbackCopy.correct, 'That is right.');
    expect(LingAnswerFeedbackCopy.incorrect, 'Try that again.');
    const List<String> lines = <String>[
      LingAnswerFeedbackCopy.correct,
      LingAnswerFeedbackCopy.incorrect,
    ];
    final List<String> banned = File('scripts/copy/banned_words.txt')
        .readAsLinesSync()
        .map((String line) => line.trim().toLowerCase())
        .where((String line) => line.isNotEmpty)
        .toList();
    final String source = File(
      'lib/design/feedback/answer_feedback.dart',
    ).readAsStringSync();
    final String lower = source.toLowerCase();
    for (final String word in banned) {
      expect(lower.contains(word), isFalse, reason: word);
    }
    expect(source.contains('\u2014'), isFalse);
    expect(lower.contains('confidence'), isFalse);
    expect(RegExp(r'\bscore\b').hasMatch(lower), isFalse);
    expect(source.contains('%'), isFalse);
    expect(source.contains('Color(0x'), isFalse);
    expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
    for (final String line in lines) {
      expect(line.contains('\u2014'), isFalse);
      expect(RegExp(r'\d').hasMatch(line), isFalse);
      expect(line.contains('%'), isFalse);
    }
  });

  testWidgets('scheduled start on the test binding stays within 160 ms', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    var sounds = 0;
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        child: LingAnswerFeedback(
          correct: true,
          hapticsEnabled: true,
          soundEnabled: true,
          onSound: () => sounds++,
        ),
      ),
    );
    final LingAnswerFeedbackState state = tester.state(
      find.byType(LingAnswerFeedback),
    );
    final DateTime tap = tester.binding.clock.now();
    final LingAnswerFeedbackTiming timing = state.schedule();
    await tester.pump();
    expect(timing.tappedAt, tap);
    expect(timing.hapticAt, tap);
    expect(timing.soundAt, tap);
    expect(timing.visualAt, tap);
    expect(sounds, 1);
    expect(_haptics, <Object?>['HapticFeedbackType.successNotification']);
    final int measured = _bindingStart(tester, timing, tap);
    _expectBudget(measured);
    expect(find.byKey(LingAnswerFeedback.visualCue), findsOneWidget);
    expect(find.text(LingAnswerFeedbackCopy.correct), findsOneWidget);
  });

  testWidgets('visual cue shows when haptic and sound are off', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    var sounds = 0;
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        child: LingAnswerFeedback(
          correct: false,
          hapticsEnabled: false,
          soundEnabled: false,
          onSound: () => sounds++,
        ),
      ),
    );
    final LingAnswerFeedbackTiming timing = tester
        .state<LingAnswerFeedbackState>(find.byType(LingAnswerFeedback))
        .schedule();
    await tester.pump();
    expect(timing.hapticElapsedMs, isNull);
    expect(timing.soundElapsedMs, isNull);
    _expectBudget(timing.visualElapsedMs);
    expect(sounds, 0);
    expect(_haptics, isEmpty);
    expect(find.byKey(LingAnswerFeedback.visualCue), findsOneWidget);
    expect(find.byKey(LingAnswerFeedback.mark), findsOneWidget);
    expect(find.text(LingAnswerFeedbackCopy.incorrect), findsOneWidget);
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.byKey(LingAnswerFeedback.visualCue),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      LingAfriqTokens.roleLightDanger,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('correct uses the success role and incorrect uses danger', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: _pair(hapticsEnabled: true, soundEnabled: false),
      ),
    );
    for (final LingAnswerFeedbackState state
        in tester.stateList<LingAnswerFeedbackState>(
          find.byType(LingAnswerFeedback),
        )) {
      state.schedule();
    }
    await tester.pump();
    final List<DecoratedBox> boxes = tester
        .widgetList<DecoratedBox>(find.byKey(LingAnswerFeedback.visualCue))
        .toList();
    expect(
      (boxes[0].decoration as BoxDecoration).color,
      LingAfriqTokens.roleDarkSuccess,
    );
    expect(
      (boxes[1].decoration as BoxDecoration).color,
      LingAfriqTokens.roleDarkDanger,
    );
    expect(_haptics, <Object?>[
      'HapticFeedbackType.successNotification',
      'HapticFeedbackType.mediumImpact',
    ]);
    expect(find.text(LingAnswerFeedbackCopy.correct), findsOneWidget);
    expect(find.text(LingAnswerFeedbackCopy.incorrect), findsOneWidget);
  });

  testWidgets('reduced motion keeps the cue and the fast duration', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const LingAnswerFeedback(
          correct: true,
          hapticsEnabled: false,
          soundEnabled: false,
        ),
      ),
    );
    tester
        .state<LingAnswerFeedbackState>(find.byType(LingAnswerFeedback))
        .schedule();
    await tester.pump();
    expect(find.byKey(LingAnswerFeedback.visualCue), findsOneWidget);
    expect(find.text(LingAnswerFeedbackCopy.correct), findsOneWidget);
    final TweenAnimationBuilder<double> motion = tester
        .widget<TweenAnimationBuilder<double>>(
          find.byType(TweenAnimationBuilder<double>),
        );
    expect(
      motion.duration,
      const Duration(milliseconds: LingAfriqTokens.motionProductFast),
    );
    final Tween<double> tween = motion.tween;
    expect(tween.begin, tween.end);
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(LingAnswerFeedbackCopy.correct),
      findsOneWidget,
    );
    handle.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('200 percent text does not clip the cue', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        textScale: 2,
        framed: true,
        child: _pair(hapticsEnabled: false, soundEnabled: false),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final double line = LingAfriqType.bodySize * 2 * LingAfriqType.targetHeight;
    for (final String copy in <String>[
      LingAnswerFeedbackCopy.correct,
      LingAnswerFeedbackCopy.incorrect,
    ]) {
      final Size size = tester.getSize(find.text(copy));
      expect(size.height, greaterThanOrEqualTo(line - 1), reason: copy);
      expect(size.width, lessThanOrEqualTo(_frame.width));
      final Text text = tester.widget<Text>(find.text(copy));
      expect(text.softWrap, isTrue);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.clip));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
  });

  testWidgets('light, dark, and 200 percent goldens', (
    WidgetTester tester,
  ) async {
    _mockHaptics(tester);
    await _bind(tester);
    const List<(String, Brightness, double)> frames =
        <(String, Brightness, double)>[
          ('goldens/answer_feedback_light.png', Brightness.light, 1),
          ('goldens/answer_feedback_dark.png', Brightness.dark, 1),
          ('goldens/answer_feedback_200.png', Brightness.light, 2),
        ];
    for (final (String path, Brightness brightness, double scale) in frames) {
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          textScale: scale,
          framed: true,
          child: _pair(hapticsEnabled: false, soundEnabled: false),
        ),
      );
      await tester.pump(
        const Duration(milliseconds: LingAfriqTokens.motionProductFast),
      );
      for (final LingAnswerFeedbackState state
          in tester.stateList<LingAnswerFeedbackState>(
            find.byType(LingAnswerFeedback),
          )) {
        state.schedule();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(find.byKey(_surfaceKey), matchesGoldenFile(path));
    }
  });
}
