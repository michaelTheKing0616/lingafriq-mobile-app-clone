import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinned surface for design-system and Rive goldens.
const Size goldenSurface = Size(160, 72);

/// Logical pixel ratio. 1.0 keeps the stored image the same on every host.
const double goldenPixelRatio = 1.0;

/// Bundled face. The harness does not use the host font or a downloaded face.
const String goldenFontFamily = 'dosis';

/// A diff above this fraction fails the comparison.
const double goldenDiffTolerance = 0.01;

/// Compares a golden and writes `failures/` next to the test when the
/// pixel diff is above [tolerance].
class ThresholdGoldenComparator extends LocalFileComparator {
  ThresholdGoldenComparator(
    super.testFile, {
    this.tolerance = goldenDiffTolerance,
  });

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final bool passed = result.passed || result.diffPercent <= tolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    final double diff = result.diffPercent;
    result.dispose();
    throw FlutterError('$error\npixel diff $diff above $tolerance');
  }
}

/// Loads the bundled Dosis files so the golden does not follow the machine font.
Future<void> loadPinnedFont() async {
  final FontLoader loader = FontLoader(goldenFontFamily)
    ..addFont(rootBundle.load('assets/fonts/Dosis-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Dosis-Bold.ttf'));
  await loader.load();
}

/// Fixes the test surface and pixel ratio for one test.
Future<void> pinSurface(WidgetTester tester, {Size size = goldenSurface}) async {
  tester.view.devicePixelRatio = goldenPixelRatio;
  tester.view.physicalSize = Size(size.width * goldenPixelRatio, size.height * goldenPixelRatio);
  addTearDown(tester.view.reset);
}

/// Solid PNG used by the harness self-test. Not a widget golden.
Future<Uint8List> solidPng(Color color) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 4, 4), ui.Paint()..color = color);
  final ui.Image image = await recorder.endRecording().toImage(4, 4);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
