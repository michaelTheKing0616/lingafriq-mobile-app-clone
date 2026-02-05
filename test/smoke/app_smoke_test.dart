import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for critical app flows.
///
/// Recommended manual smoke flows (run against a live backend):
/// 1. Login → Dashboard → open one lesson → complete tutorial/quiz.
/// 2. Login → Dashboard → open one quiz (instant or word) → complete.
/// 3. Onboarding (skip or complete) → Login.
///
/// Expand with integration_test or golden tests when CI supports them.

void main() {
  group('App smoke', () {
    test('placeholder passes', () {
      expect(true, isTrue);
    });
  });
}
