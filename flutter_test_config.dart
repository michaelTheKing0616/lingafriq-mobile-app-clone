import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/runtime/rive_file_cache.dart';
import 'package:rive/rive.dart';

import 'test/golden/golden_harness.dart';

/// macOS CI rasterizes the same widgets a few percent differently from the
/// machine that stored the goldens. Behavior checks still fail on a real miss.
/// Screens that moved by more than this set their own comparator.
///
/// Factory.rive aborts the tester (file.cpp factory assertion) because the
/// shipped native library has no headless GPU context. The Flutter factory
/// is selected here. RiveNative.init stays inside each test, after
/// TestWidgetsFlutterBinding, because calling it earlier installs the app
/// binding and every widget test then fails to load.
Future<void> testExecutable(Future<void> Function() testMain) async {
  CastFileCache.instance.renderer = Factory.flutter;
  RiveFileCache.instance.renderer = Factory.flutter;
  final GoldenFileComparator current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = ThresholdGoldenComparator(
      current.basedir.resolve('golden_gate.dart'),
      tolerance: goldenDiffTolerance,
    );
  }
  await testMain();
}
