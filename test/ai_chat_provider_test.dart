import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

void main() {
  group('WER Tests', () {
    test('Perfect match', () {
      final provider = GroqChatProvider();
      final wer = provider.wordErrorRate('hello world', 'hello world');
      expect(wer, 0.0);
    });

    test('One word wrong', () {
      final provider = GroqChatProvider();
      final wer = provider.wordErrorRate('hello world', 'hello there');
      expect(wer, 0.5);
    });

    test('All words wrong', () {
      final provider = GroqChatProvider();
      final wer = provider.wordErrorRate('hello world', 'goodbye friend');
      expect(wer, 1.0);
    });

    test('Empty reference', () {
      final provider = GroqChatProvider();
      final wer = provider.wordErrorRate('', 'hello world');
      expect(wer, 1.0);
    });
  });

  group('CEFR Mapping Tests', () {
    test('Score 0 maps to A1', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(0), 'A1');
    });

    test('Score 19 maps to A1', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(19), 'A1');
    });

    test('Score 20 maps to A2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(20), 'A2');
    });

    test('Score 40 maps to A2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(40), 'A2');
    });

    test('Score 55 maps to B1', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(55), 'B1');
    });

    test('Score 60 maps to B2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(60), 'B2');
    });

    test('Score 70 maps to B2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(70), 'B2');
    });

    test('Score 85 maps to C1', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(85), 'C1');
    });

    test('Score 90 maps to C2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(90), 'C2');
    });

    test('Score 100 maps to C2', () {
      final provider = GroqChatProvider();
      expect(provider.mapScoreToCEFR(100), 'C2');
    });
  });

  group('Grammar Parser Tests', () {
    test('Parse valid JSON response', () {
      final jsonStr = '''
      {
        "corrected": "hello world",
        "errors": [
          {
            "type": "spelling",
            "original": "helo",
            "correction": "hello",
            "explanation": "Missing letter"
          }
        ],
        "score": 0.8
      }
      ''';

      final json = jsonDecode(jsonStr);
      expect(json['corrected'], 'hello world');
      expect(json['errors'], isA<List>());
      expect(json['errors'].length, 1);
      expect(json['score'], 0.8);
    });

    test('Parse empty errors', () {
      final jsonStr = '''
      {
        "corrected": "hello world",
        "errors": [],
        "score": 1.0
      }
      ''';

      final json = jsonDecode(jsonStr);
      expect(json['corrected'], 'hello world');
      expect(json['errors'], isEmpty);
      expect(json['score'], 1.0);
    });
  });
}

