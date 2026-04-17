import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/heritage_milestone_service.dart';

void main() {
  group('HeritageMilestoneService.milestonesPayloadFromPackManifestJson', () {
    test('returns null for empty or invalid input', () {
      expect(HeritageMilestoneService.milestonesPayloadFromPackManifestJson(null), isNull);
      expect(HeritageMilestoneService.milestonesPayloadFromPackManifestJson(''), isNull);
      expect(HeritageMilestoneService.milestonesPayloadFromPackManifestJson('not-json'), isNull);
      expect(HeritageMilestoneService.milestonesPayloadFromPackManifestJson('{}'), isNull);
      expect(HeritageMilestoneService.milestonesPayloadFromPackManifestJson('[]'), isNull);
    });

    test('maps manifest entries and normalizes completed flag', () {
      final raw = jsonEncode([
        {'id': 'first-spoken-sentence', 'title': 'A', 'description': 'D1'},
        {'id': 'family-call', 'title': 'B', 'description': 'D2', 'completed': true},
      ]);
      final payload = HeritageMilestoneService.milestonesPayloadFromPackManifestJson(raw)!;
      expect(payload['success'], true);
      expect(payload['source'], 'pack_manifest');
      final list = payload['milestones'] as List<dynamic>;
      expect(list.length, 2);
      expect(list[0]['completed'], false);
      expect(list[1]['completed'], true);
    });

    test('skips non-map elements in array', () {
      final raw = jsonEncode([
        'skip',
        {'id': 'x', 'title': 'T'},
      ]);
      final payload = HeritageMilestoneService.milestonesPayloadFromPackManifestJson(raw)!;
      final list = payload['milestones'] as List<dynamic>;
      expect(list.length, 1);
      expect(list[0]['id'], 'x');
    });
  });
}
