import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review_checklist.json exists with 14 languages', () {
    final path = File('assets/data/review_checklist.json');
    expect(path.existsSync(), isTrue);
    final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final languages = json['languages'] as Map<String, dynamic>;
    expect(languages.length, greaterThanOrEqualTo(14));
    expect(languages['yoruba'], isNotNull);
    expect((json['checks'] as List).length, greaterThanOrEqualTo(3));
  });
}
