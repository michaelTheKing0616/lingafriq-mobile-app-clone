import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_content_models.dart';

void main() {
  final assetPath = File(
    'assets/data/game_content.json',
  );

  test('game_content.json exists and parses', () {
    expect(assetPath.existsSync(), isTrue, reason: 'Run tools/generate_lingafriq_content.py');
    final raw = assetPath.readAsStringSync();
    final data = GameContentData.fromRawJson(raw);
    expect(data.words.length, greaterThan(400));
    expect(data.proverbs.length, greaterThan(40));
    expect(data.scenarios.length, greaterThan(100));
    expect(data.grammarDrills.length, greaterThan(80));
    expect(data.liarLiarRounds.length, greaterThan(30));
    for (final lang in [
      'yoruba',
      'hausa',
      'igbo',
      'swahili',
      'zulu',
      'xhosa',
      'wolof',
      'pidgin',
    ]) {
      expect(
        data.words.where((w) => w.language == lang).length,
        greaterThan(20),
        reason: 'words for $lang',
      );
      expect(
        data.scenarios.where((s) => s.language == lang).length,
        greaterThan(10),
        reason: 'scenarios for $lang',
      );
    }
  });

  test('audio manifest exists', () {
    final path = File('assets/data/audio_manifest.json');
    expect(path.existsSync(), isTrue);
    final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final entries = json['entries'] as List;
    expect(entries.length, greaterThan(400));
  });

  test('authentic curriculum asset parses', () {
    final path = File('assets/data/lingafriq_authentic_curriculum_a1.json');
    expect(path.existsSync(), isTrue);
    final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final languages = json['languages'] as Map<String, dynamic>;
    expect(languages.containsKey('yoruba'), isTrue);
    final yorubaA1 = languages['yoruba']['A1'] as List;
    expect(yorubaA1.length, greaterThanOrEqualTo(5));
    final firstLesson = (yorubaA1.first as Map)['lessons'] as List;
    final vocab = (firstLesson.first as Map)['vocab'] as List;
    final firstWord = (vocab.first as Map)['word'] as String;
    expect(firstWord.contains('Yor_word'), isFalse);
    final dialogue = (firstLesson.first as Map)['dialogue'] as Map;
    final script = dialogue['script'] as List;
    expect(script.length, greaterThanOrEqualTo(2));
    expect((script[1] as Map)['translation'], isNot('Response'));
  });

  test('A1–C1 curriculum bundle parses', () {
    final path = File('assets/data/lingafriq_authentic_curriculum_a1_c1.json');
    expect(path.existsSync(), isTrue);
    final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final levels = List<String>.from((json['meta'] as Map)['levels'] as List);
    expect(levels, containsAll(['A1', 'A2', 'B1', 'B2', 'C1']));
    for (final lang in [
      'yoruba',
      'hausa',
      'swahili',
      'afrikaans',
      'amharic',
      'twi',
      'somali',
    ]) {
      final block = json['languages'][lang] as Map<String, dynamic>?;
      expect(block, isNotNull, reason: lang);
      for (final level in ['A2', 'B1', 'B2', 'C1']) {
        expect((block![level] as List).length, greaterThanOrEqualTo(2), reason: '$lang $level');
      }
    }
  });

  test('cms manifests bundled per language', () {
    for (final id in ['1', '9', '12']) {
      final path = File('assets/data/cms_manifests/$id/manifest.json');
      expect(path.existsSync(), isTrue, reason: 'cms id $id');
      final manifest = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
      final total = (manifest['manifest'] as Map?)?['totalLessons'] as int? ??
          manifest['totalLessons'] as int?;
      expect(total, greaterThan(20));
    }
  });
}
