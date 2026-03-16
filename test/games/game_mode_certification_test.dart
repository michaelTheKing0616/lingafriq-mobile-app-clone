import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/game_provider.dart';

void main() {
  group('GameModeCertification', () {
    test('passed is true only when all gates are satisfied', () {
      final now = DateTime.now();
      final passing = GameModeCertification(
        gameType: 'tone_trainer',
        sessionId: 'sess_1',
        launchTelemetrySent: true,
        turnTelemetrySent: true,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: now,
      );
      expect(passing.passed, isTrue);

      final failing = GameModeCertification(
        gameType: 'tone_trainer',
        sessionId: 'sess_2',
        launchTelemetrySent: true,
        turnTelemetrySent: false,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: now,
      );
      expect(failing.passed, isFalse);
    });

    test('toJson includes derived passed flag', () {
      final certification = GameModeCertification(
        gameType: 'wordmatch_audio',
        sessionId: 'sess_3',
        launchTelemetrySent: true,
        turnTelemetrySent: true,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: DateTime.parse('2026-03-16T00:00:00.000Z'),
      );

      final json = certification.toJson();
      expect(json['game_type'], 'wordmatch_audio');
      expect(json['session_id'], 'sess_3');
      expect(json['passed'], isTrue);
      expect(json['completion_telemetry_sent'], isTrue);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/game_provider.dart';

void main() {
  group('GameModeCertification', () {
    test('passed is true only when all gates are satisfied', () {
      final now = DateTime.now();
      final passing = GameModeCertification(
        gameType: 'tone_trainer',
        sessionId: 'sess_1',
        launchTelemetrySent: true,
        turnTelemetrySent: true,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: now,
      );
      expect(passing.passed, isTrue);

      final failing = GameModeCertification(
        gameType: 'tone_trainer',
        sessionId: 'sess_2',
        launchTelemetrySent: true,
        turnTelemetrySent: false,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: now,
      );
      expect(failing.passed, isFalse);
    });

    test('toJson includes derived passed flag', () {
      final certification = GameModeCertification(
        gameType: 'wordmatch_audio',
        sessionId: 'sess_3',
        launchTelemetrySent: true,
        turnTelemetrySent: true,
        completionTelemetrySent: true,
        hasTurns: true,
        completed: true,
        updatedAt: DateTime.parse('2026-03-16T00:00:00.000Z'),
      );

      final json = certification.toJson();
      expect(json['game_type'], 'wordmatch_audio');
      expect(json['session_id'], 'sess_3');
      expect(json['passed'], isTrue);
      expect(json['completion_telemetry_sent'], isTrue);
    });
  });
}
