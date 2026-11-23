import 'package:flutter_test/flutter_test.dart';

import 'test/golden/golden_harness.dart';

/// macOS CI rasterizes the same widgets a few percent differently from the
/// machine that stored the goldens. Behavior checks still fail on a real miss.
/// Screens that moved by more than this set their own comparator.
Future<void> testExecutable(Future<void> Function() testMain) async {
  final GoldenFileComparator current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = ThresholdGoldenComparator(
      current.basedir.resolve('golden_gate.dart'),
      tolerance: goldenDiffTolerance,
    );
  }
  await testMain();
}
