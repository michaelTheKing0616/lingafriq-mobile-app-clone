import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/telemetry_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('Telemetry Service Tests', () {
    test('Telemetry service initialization', () {
      final container = ProviderContainer();
      final telemetry = container.read(telemetryServiceProvider);
      
      expect(telemetry, isNotNull);
    });

    test('Engagement tracking', () async {
      final container = ProviderContainer();
      final telemetry = container.read(telemetryServiceProvider);
      
      // Track engagement (will fail without user, but tests structure)
      await telemetry.trackEngagement(
        eventType: 'feature_usage',
        feature: 'test_feature',
        metadata: {'test': 'data'},
      );
      
      final stats = telemetry.getEngagementStats();
      expect(stats['interaction_counts'], isNotNull);
    });

    test('Polie performance tracking', () async {
      final container = ProviderContainer();
      final telemetry = container.read(telemetryServiceProvider);
      
      await telemetry.trackPoliePerformance(
        mode: 'tutor',
        language: 'yoruba',
        responseTimeMs: 1500,
        tokenCount: 250,
        diacriticsCorrected: true,
        modelUsed: 'llama-3.1-70b',
        confidence: 0.95,
      );
      
      // Verify event was added to pending
      final stats = telemetry.getEngagementStats();
      expect(stats['pending_events'], greaterThan(0));
    });

    test('Game session tracking', () async {
      final container = ProviderContainer();
      final telemetry = container.read(telemetryServiceProvider);
      
      await telemetry.trackGameSession(
        gameType: 'proverb_unlocker',
        language: 'yoruba',
        durationMs: 120000,
        accuracy: 0.85,
        score: 8,
        turns: 10,
      );
      
      final stats = telemetry.getEngagementStats();
      expect(stats['pending_events'], greaterThan(0));
    });

    test('Session management', () {
      final container = ProviderContainer();
      final telemetry = container.read(telemetryServiceProvider);
      
      final sessionId = 'test_session_123';
      telemetry.startSession(sessionId);
      
      final stats = telemetry.getEngagementStats();
      expect(stats['active_sessions'], 1);
      
      telemetry.endSession(sessionId);
      
      final statsAfter = telemetry.getEngagementStats();
      expect(statsAfter['active_sessions'], 0);
    });
  });
}


