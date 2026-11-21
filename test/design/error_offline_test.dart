import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

const Key _surfaceKey = ValueKey<String>('error-offline-surface');

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
      LingErrorStateCopy.whatHappened,
      LingErrorStateCopy.why,
      LingErrorStateCopy.whatToDo,
      LingErrorStateCopy.actionLabel,
      LingOfflineStateCopy.whatHappened,
      LingOfflineStateCopy.why,
      LingOfflineStateCopy.whatToDo,
    ]) {
      expect(deck, contains(line), reason: line);
    }
    for (final String path in <String>[
      'lib/design/states/error_state.dart',
      'lib/design/states/offline_state.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('Color(0x'), isFalse, reason: path);
      expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
      expect(source.contains('%'), isFalse, reason: path);
      expect(
        source.toLowerCase().contains('confidence'),
        isFalse,
        reason: path,
      );
    }
    final String error = File(
      'lib/design/states/error_state.dart',
    ).readAsStringSync();
    final String offline = File(
      'lib/design/states/offline_state.dart',
    ).readAsStringSync();
    for (final String field in <String>[
      'whatHappened',
      'why',
      'whatToDo',
      'actionLabel',
      'onAction',
    ]) {
      expect(error, contains('required this.$field'));
      expect(RegExp('this\\.$field\\s*=').hasMatch(error), isFalse);
    }
    for (final String field in <String>[
      'whatHappened',
      'why',
      'whatToDo',
      'queuedActions',
    ]) {
      expect(offline, contains('required this.$field'));
      expect(RegExp('this\\.$field\\s*=').hasMatch(offline), isFalse);
    }
    expect(error, contains('LingAfriqTokens.roleLightDanger'));
    expect(error, contains('LingAfriqTokens.roleDarkDanger'));
    expect(error, contains('LingAfriqTokens.roleLightOnDanger'));
    expect(error, contains('LingAfriqTokens.roleDarkOnDanger'));
    expect(offline, contains('LingAfriqTokens.roleLightInfo'));
    expect(offline, contains('LingAfriqTokens.roleDarkInfo'));
    expect(offline, contains('LingAfriqTokens.roleLightOnInfo'));
    expect(offline, contains('LingAfriqTokens.roleDarkOnInfo'));
  });

  test('queue count is a sentence and zero waits for nothing', () {
    expect(
      LingOfflineState.queuedActionsLine(0),
      LingOfflineStateCopy.nothingWaiting,
    );
    expect(
      LingOfflineState.queuedActionsLine(1),
      '1 action will send when you connect.',
    );
    expect(
      LingOfflineState.queuedActionsLine(2),
      '2 actions will send when you connect.',
    );
    expect(LingOfflineState.queuedActionsLine(2).contains('%'), isFalse);
    expect(
      LingOfflineState.queuedActionsLine(
        2,
      ).toLowerCase().contains('confidence'),
      isFalse,
    );
    expect(() => LingOfflineState.queuedActionsLine(-1), throwsArgumentError);
  });

  testWidgets('a thrown plan shows the error and hides the stale line', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    final _PlanRepository repository = _PlanRepository();
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: _PlanReader(repository: repository, generation: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_PlanRepository.ready), findsOneWidget);
    expect(find.byType(LingErrorState), findsNothing);

    repository.fail = true;
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: _PlanReader(repository: repository, generation: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text(_PlanRepository.ready), findsNothing);
    expect(find.textContaining('repository failed closed'), findsNothing);
    expect(find.text(LingErrorStateCopy.whatHappened), findsOneWidget);
    expect(find.text(LingErrorStateCopy.why), findsOneWidget);
    expect(find.text(LingErrorStateCopy.whatToDo), findsOneWidget);
  });

  testWidgets('error disc, lines, and one accent button', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    var taps = 0;
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: LingErrorState(
          whatHappened: LingErrorStateCopy.whatHappened,
          why: LingErrorStateCopy.why,
          whatToDo: LingErrorStateCopy.whatToDo,
          actionLabel: LingErrorStateCopy.actionLabel,
          onAction: () => taps++,
        ),
      ),
    );
    _expectLines(
      tester,
      whatHappened: LingErrorStateCopy.whatHappened,
      why: LingErrorStateCopy.why,
      whatToDo: LingErrorStateCopy.whatToDo,
    );
    final LingCueDisc disc = tester.widget<LingCueDisc>(
      find.byType(LingCueDisc),
    );
    expect(disc.kind, LingCueKind.cross);
    expect(disc.fill, LingAfriqTokens.roleLightDanger);
    expect(disc.mark, LingAfriqTokens.roleLightOnDanger);
    expect(
      tester.getSize(find.byType(LingCueDisc)).width,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(LingCueDisc)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byType(LingButton), findsOneWidget);
    final LingButton button = tester.widget<LingButton>(
      find.byType(LingButton),
    );
    expect(button.role, LingButtonRole.accent);
    expect(button.label, LingErrorStateCopy.actionLabel);
    expect(
      tester.getSize(find.byType(LingButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byType(LingButton));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: const LingErrorState(
          whatHappened: LingErrorStateCopy.whatHappened,
          why: LingErrorStateCopy.why,
          whatToDo: LingErrorStateCopy.whatToDo,
          actionLabel: LingErrorStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final LingCueDisc dark = tester.widget<LingCueDisc>(
      find.byType(LingCueDisc),
    );
    expect(dark.fill, LingAfriqTokens.roleDarkDanger);
    expect(dark.mark, LingAfriqTokens.roleDarkOnDanger);
  });

  testWidgets('offline disc shows the queue sentence', (
    WidgetTester tester,
  ) async {
    await _bind(tester);
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: const LingOfflineState(
          whatHappened: LingOfflineStateCopy.whatHappened,
          why: LingOfflineStateCopy.why,
          whatToDo: LingOfflineStateCopy.whatToDo,
          queuedActions: 2,
          actionLabel: LingOfflineStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    _expectLines(
      tester,
      whatHappened: LingOfflineStateCopy.whatHappened,
      why: LingOfflineStateCopy.why,
      whatToDo: LingOfflineStateCopy.whatToDo,
    );
    expect(find.text('2 actions will send when you connect.'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('confidence'), findsNothing);
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
    expect(
      tester.widget<LingButton>(find.byType(LingButton)).role,
      LingButtonRole.accent,
    );

    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: const LingOfflineState(
          whatHappened: LingOfflineStateCopy.whatHappened,
          why: LingOfflineStateCopy.why,
          whatToDo: LingOfflineStateCopy.whatToDo,
          queuedActions: 0,
        ),
      ),
    );
    expect(find.text(LingOfflineStateCopy.nothingWaiting), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byType(LingButton), findsNothing);

    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: const LingOfflineState(
          whatHappened: LingOfflineStateCopy.whatHappened,
          why: LingOfflineStateCopy.why,
          whatToDo: LingOfflineStateCopy.whatToDo,
          queuedActions: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 action will send when you connect.'), findsOneWidget);
    final LingCueDisc dark = tester.widget<LingCueDisc>(
      find.byType(LingCueDisc),
    );
    expect(dark.fill, LingAfriqTokens.roleDarkInfo);
    expect(dark.mark, LingAfriqTokens.roleDarkOnInfo);
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
        child: const LingErrorState(
          whatHappened: LingErrorStateCopy.whatHappened,
          why: LingErrorStateCopy.why,
          whatToDo: LingErrorStateCopy.whatToDo,
          actionLabel: LingErrorStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    _expectWrap(tester, LingErrorStateCopy.why);
    expect(
      tester.getSize(find.byType(LingButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        textScale: 2,
        framed: true,
        child: const LingOfflineState(
          whatHappened: LingOfflineStateCopy.whatHappened,
          why: LingOfflineStateCopy.why,
          whatToDo: LingOfflineStateCopy.whatToDo,
          queuedActions: 2,
          actionLabel: LingOfflineStateCopy.actionLabel,
          onAction: _noop,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    _expectWrap(tester, LingOfflineStateCopy.why);
  });

  for (final (Brightness brightness, double scale) in <(Brightness, double)>[
    (Brightness.light, 1),
    (Brightness.dark, 1),
    (Brightness.light, 2),
  ]) {
    final String suffix = '${brightness.name}_${scale.toStringAsFixed(1)}';
    testWidgets('error golden $suffix', (WidgetTester tester) async {
      await _bind(tester);
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          textScale: scale,
          framed: true,
          child: const LingErrorState(
            whatHappened: LingErrorStateCopy.whatHappened,
            why: LingErrorStateCopy.why,
            whatToDo: LingErrorStateCopy.whatToDo,
            actionLabel: LingErrorStateCopy.actionLabel,
            onAction: _noop,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_surfaceKey),
        matchesGoldenFile('../goldens/lingErrorState_sample_$suffix.png'),
      );
    });
    testWidgets('offline golden $suffix', (WidgetTester tester) async {
      await _bind(tester);
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          textScale: scale,
          framed: true,
          child: const LingOfflineState(
            whatHappened: LingOfflineStateCopy.whatHappened,
            why: LingOfflineStateCopy.why,
            whatToDo: LingOfflineStateCopy.whatToDo,
            queuedActions: 2,
            actionLabel: LingOfflineStateCopy.actionLabel,
            onAction: _noop,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_surfaceKey),
        matchesGoldenFile('../goldens/lingOfflineState_sample_$suffix.png'),
      );
    });
  }

  group('swallowed error lint', () {
    test('an empty catch fails', () {
      final ProcessResult result = _lintSource('''
void load() {
  try {
    read();
  } catch (e) {
  }
}
''');
      expect(result.exitCode, 1, reason: result.stdout.toString());
      expect(result.stdout.toString(), contains('no-swallowed-errors: fail'));
      expect(result.stdout.toString(), contains('empty-catch'));
    });

    test('a comment or a print that continues fails', () {
      final ProcessResult comment = _lintSource('''
void load() {
  try {
    read();
  } catch (e) {
    // fall through
  }
}
''');
      expect(comment.exitCode, 1, reason: comment.stdout.toString());
      expect(comment.stdout.toString(), contains('comment-only'));

      final ProcessResult printed = _lintSource('''
void load() {
  try {
    read();
  } catch (e) {
    print(e);
  }
}
''');
      expect(printed.exitCode, 1, reason: printed.stdout.toString());
      expect(printed.stdout.toString(), contains('print-continue'));

      final ProcessResult debugPrint = _lintSource('''
void load() {
  while (true) {
    try {
      read();
    } catch (e) {
      debugPrint('\$e');
      continue;
    }
  }
}
''');
      expect(debugPrint.exitCode, 1, reason: debugPrint.stdout.toString());
      expect(debugPrint.stdout.toString(), contains('print-continue'));
    });

    test('a rethrow or an error state passes', () {
      final ProcessResult thrown = _lintSource('''
void load() {
  try {
    read();
  } catch (e) {
    rethrow;
  }
}
''');
      expect(thrown.exitCode, 0, reason: thrown.stdout.toString());
      expect(thrown.stdout.toString(), contains('0 new'));

      final ProcessResult shown = _lintSource('''
Widget load() {
  try {
    return Text(read());
  } catch (e) {
    return LingErrorState(
      whatHappened: 'The plan did not open.',
      why: 'The lesson list did not come back.',
      whatToDo: 'Try again.',
      actionLabel: 'Try again',
      onAction: retry,
    );
  }
}
''');
      expect(shown.exitCode, 0, reason: shown.stdout.toString());

      final ProcessResult quoted = _lintSource(
        "const sample = '''\n"
        'catch (e) {}\n'
        "''';\n"
        'void load() {\n'
        '  try {\n'
        '    read();\n'
        '  } catch (e) {\n'
        '    rethrow;\n'
        '  }\n'
        '}\n',
      );
      expect(quoted.exitCode, 0, reason: quoted.stdout.toString());
    });

    test('an existing catch in the diff does not fail', () {
      final Directory dir = Directory.systemTemp.createTempSync(
        'no-swallow-diff',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final File oldCatch = File('${dir.path}/old.diff')
        ..writeAsStringSync('''
diff --git a/lib/old.dart b/lib/old.dart
--- a/lib/old.dart
+++ b/lib/old.dart
@@ -4,6 +4,7 @@
 void keep() {
   try {
     load();
   } catch (e) {
     // fall through
   }
+  final int added = 1;
 }
''');
      final ProcessResult kept = Process.runSync('python3', <String>[
        'scripts/lint/no_swallowed_errors.py',
        '--diff-file',
        oldCatch.path,
      ]);
      expect(kept.exitCode, 0, reason: kept.stdout.toString());

      final File added = File('${dir.path}/added.diff')
        ..writeAsStringSync('''
diff --git a/lib/new_catch.dart b/lib/new_catch.dart
--- a/lib/new_catch.dart
+++ b/lib/new_catch.dart
@@ -8,0 +9,4 @@
+  try {
+    load();
+  } catch (e) {
+  }
''');
      final ProcessResult fresh = Process.runSync('python3', <String>[
        'scripts/lint/no_swallowed_errors.py',
        '--diff-file',
        added.path,
      ]);
      expect(fresh.exitCode, 1, reason: fresh.stdout.toString());
      expect(
        fresh.stdout.toString(),
        contains('empty-catch lib/new_catch.dart:11'),
      );
    });
  });
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

class _PlanRepository {
  bool fail = false;

  static const String ready = 'Morning greetings are ready.';

  Future<String> load() async {
    if (fail) {
      throw StateError('repository failed closed');
    }
    return ready;
  }
}

class _PlanReader extends StatefulWidget {
  const _PlanReader({required this.repository, required this.generation});

  final _PlanRepository repository;
  final int generation;

  @override
  State<_PlanReader> createState() => _PlanReaderState();
}

class _PlanReaderState extends State<_PlanReader> {
  Object? _error;
  String? _plan;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(covariant _PlanReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) {
      _read();
    }
  }

  Future<void> _read() async {
    try {
      final String plan = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _plan = null;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return LingErrorState(
        whatHappened: LingErrorStateCopy.whatHappened,
        why: LingErrorStateCopy.why,
        whatToDo: LingErrorStateCopy.whatToDo,
        actionLabel: LingErrorStateCopy.actionLabel,
        onAction: () {
          _read();
        },
      );
    }
    final String? plan = _plan;
    if (plan == null) {
      return const SizedBox.shrink();
    }
    return Text(plan);
  }
}

ProcessResult _lintSource(String source) {
  final Directory dir = Directory.systemTemp.createTempSync('no-swallow');
  final File file = File('${dir.path}/fixture.dart')..writeAsStringSync(source);
  final ProcessResult result = Process.runSync('python3', <String>[
    'scripts/lint/no_swallowed_errors.py',
    '--fixture-file',
    file.path,
  ]);
  dir.deleteSync(recursive: true);
  return result;
}
