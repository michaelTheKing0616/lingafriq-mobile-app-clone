import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_painter.dart';

/// Covers the decorative winding-path connector added to make the lesson
/// list read as one continuous serpentine path rather than a stack of
/// disconnected circles, plus its RTL-safe lane math.
void main() {
  group('pathLaneSign', () {
    test('end lane resolves to the physical right in LTR', () {
      expect(pathLaneSign(isEndLane: true, isRtl: false), 1.0);
    });

    test('start lane resolves to the physical left in LTR', () {
      expect(pathLaneSign(isEndLane: false, isRtl: false), -1.0);
    });

    test('end lane mirrors to the physical left in RTL', () {
      expect(pathLaneSign(isEndLane: true, isRtl: true), -1.0);
    });

    test('start lane mirrors to the physical right in RTL', () {
      expect(pathLaneSign(isEndLane: false, isRtl: true), 1.0);
    });
  });

  group('PathRowConnectorPainter', () {
    // `strokeWidth` is supplied explicitly in these plain (non-widget) unit
    // tests because the constructor's default falls back to a ScreenUtil
    // `.w` value, which requires a `ScreenUtilInit` ancestor that only
    // exists in the `testWidgets` cases below.
    test('repaints when the lane or travelled state changes', () {
      final a = PathRowConnectorPainter(
          fromLane: -1, toLane: 1, traveled: true, strokeWidth: 4);
      final b = PathRowConnectorPainter(
          fromLane: -1, toLane: 1, traveled: false, strokeWidth: 4);
      final c = PathRowConnectorPainter(
          fromLane: -1, toLane: -1, traveled: true, strokeWidth: 4);

      expect(a.shouldRepaint(b), isTrue);
      expect(a.shouldRepaint(c), isTrue);
      expect(a.shouldRepaint(a), isFalse);
    });

    test('paints without throwing for a degenerate (zero-size) canvas', () {
      // Guards against the connector crashing before a list row has been
      // laid out (e.g. the very first frame).
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = PathRowConnectorPainter(
          fromLane: 0, toLane: 1, traveled: true, strokeWidth: 4);
      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      recorder.endRecording();
    });
  });

  group('PathRowConnector widget', () {
    testWidgets('renders statically without an AnimationController (reduced-motion safe by construction)',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 80,
                height: 80,
                child: PathRowConnector(fromLane: -1, toLane: 1, traveled: true),
              ),
            ),
          ),
        ),
      );
      // A single pump settles immediately (no `pumpAndSettle` retry loop
      // needed) because the painter has no ticking AnimationController.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('wraps its CustomPaint in an IgnorePointer so it never steals taps',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: PathRowConnector(fromLane: 0, toLane: 0, traveled: false),
            ),
          ),
        ),
      );
      await tester.pump();

      final ignorePointerFinder = find.descendant(
        of: find.byType(PathRowConnector),
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsOneWidget);
      expect(tester.widget<IgnorePointer>(ignorePointerFinder).ignoring, isTrue);
    });
  });
}
