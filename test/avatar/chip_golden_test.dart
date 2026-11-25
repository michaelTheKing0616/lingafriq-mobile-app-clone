import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // rootBundle caches string futures; one settled in an earlier test's
  // zone never resumes under this test's fake clock, so start fresh.
  setUp(rootBundle.clear);

  setUpAll(() async {
    await RiveNative.init();
    CastFileCache.instance.renderer = Factory.flutter;
    await CastFileCache.instance.load(); // warm the decoded .riv in real time
  });

  for (final size in [32.0, 48.0, 64.0]) {
    testWidgets('chip golden at ${size.toInt()} px', (tester) async {
      final session = CastSession(preset: 'Polie');
      addTearDown(session.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Center(
                child: RepaintBoundary(
                  key: const Key('chip-golden'),
                  child: CastChip(session: session, size: size),
                ),
              ),
            ),
          ),
        ),
      );
      await _untilRive(tester);
      expect(find.byType(RiveWidget), findsOneWidget);
      expect(tester.getSize(find.byType(CastChip)), Size.square(size));
      final golden =
          'goldens/${io.Platform.operatingSystem}/chip_${size.toInt()}.png';
      if (autoUpdateGoldenFiles ||
          io.File('test/avatar/$golden').existsSync()) {
        await expectLater(
          find.byKey(const Key('chip-golden')),
          matchesGoldenFile(golden),
        );
      }
    });
  }

  testWidgets('expression change is announced', (tester) async {
    final session = CastSession(preset: 'Polie');
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(home: CastStage(session: session)));
    expect(find.bySemanticsLabel('Polie looks neutral'), findsOneWidget);
    session.onPersonaEmotion('proud');
    session.onMic(true);
    await tester.pump();
    expect(
      find.bySemanticsLabel('Polie looks proud and is listening'),
      findsOneWidget,
    );
  });

  testWidgets('offscreen chip pauses its controller', (tester) async {
    final session = CastSession(preset: 'Polie');
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 400),
                  CastChip(session: session, size: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await _untilRive(tester);
    final widget = tester.widget<RiveWidget>(find.byType(RiveWidget));
    expect(widget.controller.active, isFalse);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    expect(
      tester.widget<RiveWidget>(find.byType(RiveWidget)).controller.active,
      isTrue,
    );
  });
}

Future<void> _untilRive(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    // Let real-time asset futures settle; the fake clock cannot run them.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(RiveWidget).evaluate().isNotEmpty) return;
  }
  fail('CharacterChip did not produce a RiveWidget');
}
