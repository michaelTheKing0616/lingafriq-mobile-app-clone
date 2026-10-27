import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/pitch_contour_painter.dart';

void main() {
  group('mapContourToPoints', () {
    test('maps semitones to shared vertical axis', () {
      final points = mapContourToPoints(
        semitones: [0, 6],
        minSemitone: 0,
        maxSemitone: 12,
        xStart: 0,
        xEnd: 100,
        height: 200,
      );
      expect(points, hasLength(2));
      expect(points.first.dy, 200);
      expect(points.last.dy, 100);
    });

    test('higher semitone yields lower y', () {
      final points = mapContourToPoints(
        semitones: [2, 8],
        minSemitone: 0,
        maxSemitone: 10,
        xStart: 10,
        xEnd: 90,
        height: 100,
      );
      expect(points.first.dy, greaterThan(points.last.dy));
    });
  });

  group('semitoneAxisBounds', () {
    test('pads flat contours', () {
      final bounds = semitoneAxisBounds([
        SyllableContourSegment(
          label: 'a',
          nativeSemitones: [5, 5],
          learnerSemitones: [5],
          unsure: false,
        ),
      ]);
      expect(bounds.max, greaterThan(bounds.min));
    });
  });
}
