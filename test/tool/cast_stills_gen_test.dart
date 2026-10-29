// Regenerates the still images CastStage shows while Rive loads or when it
// cannot load (offline first frame, low-memory devices, tests).
//
//   GEN_CAST_STILLS=1 flutter test --update-goldens \
//     test/tool/cast_stills_gen_test.dart
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;
  final enabled = io.Platform.environment['GEN_CAST_STILLS'] == '1';

  testWidgets('render cast stills', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(6 * 512 * 2.0, 512 * 2.0);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final p in CastStage.stillPresets)
              SizedBox(
                key: ValueKey(p),
                width: 512,
                height: 512,
                child: RepaintBoundary(
                  child: CastStage(
                    session: CastSession(preset: p),
                    useStill: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (final p in CastStage.stillPresets) {
      await expectLater(
        find
            .descendant(
              of: find.byKey(ValueKey(p)),
              matching: find.byType(RepaintBoundary),
            )
            .first,
        matchesGoldenFile('../../assets/images/cast_still_$p.png'),
      );
    }
  }, skip: !enabled);
}
