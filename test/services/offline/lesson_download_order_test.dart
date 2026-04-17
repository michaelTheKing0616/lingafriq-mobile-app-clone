import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/lesson_download_service.dart';

void main() {
  group('LessonDownloadService.orderedLessonsForPackDownload', () {
    test('orders heritage-linked first, then dialect match, then rest', () {
      final raw = <dynamic>[
        {'id': '3', 'dialectTags': ['yo-lagos']},
        {
          'id': '1',
          'heritageMilestoneId': 'first-spoken-sentence',
          'dialectTags': ['standard'],
        },
        {'id': '2'},
      ];
      final o = LessonDownloadService.orderedLessonsForPackDownload(raw, 'yo-lagos');
      expect(o.map((e) => e['id']).toList(), ['1', '3', '2']);
    });

    test('within heritage tier, dialect-matching lessons come first', () {
      final raw = <dynamic>[
        {
          'id': '10',
          'heritageMilestoneId': 'family-call',
          'dialectTags': ['standard'],
        },
        {
          'id': '11',
          'heritageMilestoneId': 'first-spoken-sentence',
          'dialectTags': ['yo-lagos'],
        },
      ];
      final o = LessonDownloadService.orderedLessonsForPackDownload(raw, 'yo-lagos');
      expect(o.map((e) => e['id']).toList(), ['11', '10']);
    });
  });
}
