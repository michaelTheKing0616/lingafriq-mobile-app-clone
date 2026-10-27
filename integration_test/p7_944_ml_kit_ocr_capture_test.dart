import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:integration_test/integration_test.dart';

/// Device-only capture for P7-944. Run with RECORD_P7_944_LEDGER=1 on iOS/Android.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final record = Platform.environment['RECORD_P7_944_LEDGER'] == '1';
  if (!record) {
    test('skipped unless RECORD_P7_944_LEDGER=1 on a mobile device', () {},
        skip: true);
    return;
  }

  test('capture ML Kit Latin OCR into ledger', () async {
    final fixtures = jsonDecode(
      await File('assets/data/lens/ocr_diacritic_fixtures.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final runs = <Map<String, String>>[];

    for (final fixture in fixtures['fixtures'] as List<dynamic>) {
      final map = fixture as Map<String, dynamic>;
      final imagePath = map['image_asset'] as String;
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      expect(recognized.text.trim(), isNotEmpty,
          reason: 'OCR result should produce text for ${map['id']}');
      runs.add({
        'fixture_id': map['id'] as String,
        'ml_kit_text': recognized.text.trim(),
      });
    }
    await recognizer.close();
    expect(runs, hasLength((fixtures['fixtures'] as List<dynamic>).length));

    stdout.writeln(jsonEncode({
      'platform': Platform.operatingSystem,
      'runs': runs,
    }));
  });
}
