import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../learning/learner_model/learner_skill_state.dart';

/// Exception thrown when a learning-engine safety assertion fails in debug mode.
class LearningEngineSafetyViolation implements Exception {
  final String message;
  final Map<String, dynamic> context;

  const LearningEngineSafetyViolation(this.message, [this.context = const {}]);

  @override
  String toString() =>
      'LearningEngineSafetyViolation: $message ${context.isNotEmpty ? context : ""}';
}

/// CHUNK 0 runtime assertions for the learning engine.
///
/// In debug mode: throws [LearningEngineSafetyViolation] on assertion failure.
/// In release mode: logs via [dev.log] and does not crash.
class RuntimeSafety {
  static RuntimeSafety? _instance;
  static RuntimeSafety get instance => _instance ??= RuntimeSafety._();

  RuntimeSafety._();

  /// Asserts that learner state changed when an update was expected.
  /// Throws in debug if before and after are effectively unchanged.
  void assertLearnerUpdate(
    String learnerId,
    String skillId,
    LearnerSkillState before,
    LearnerSkillState after,
  ) {
    final unchanged = before.mastery == after.mastery &&
        before.totalAttempts == after.totalAttempts &&
        before.successfulAttempts == after.successfulAttempts;

    if (!unchanged) return;

    final msg =
        'Learner update expected change but state unchanged: $learnerId / $skillId';
    if (kDebugMode) {
      throw LearningEngineSafetyViolation(msg, {
        'learnerId': learnerId,
        'skillId': skillId,
        'masteryBefore': before.mastery,
        'masteryAfter': after.mastery,
        'totalAttemptsBefore': before.totalAttempts,
        'totalAttemptsAfter': after.totalAttempts,
      });
    }
    dev.log(msg, name: 'RuntimeSafety.assertLearnerUpdate', level: 900);
  }

  /// Asserts that the raw AI response is valid JSON.
  void assertAiResponseValid(String rawResponse) {
    try {
      jsonDecode(rawResponse);
    } catch (e) {
      final msg = 'AI response is not valid JSON: ${e.toString()}';
      if (kDebugMode) {
        throw LearningEngineSafetyViolation(msg, {
          'rawResponseLength': rawResponse.length,
          'error': e.toString(),
        });
      }
      dev.log(msg, name: 'RuntimeSafety.assertAiResponseValid', level: 900);
    }
  }

  /// Asserts that pronunciation confidences are not all exactly 0.0 or 1.0.
  void assertPronunciationNotBinary(List<double> confidences) {
    if (confidences.isEmpty) return;

    final allZero = confidences.every((c) => c == 0.0);
    final allOne = confidences.every((c) => c == 1.0);
    if (!allZero && !allOne) return;

    final msg =
        'Pronunciation confidences are binary (all 0.0 or all 1.0); expected continuous values.';
    if (kDebugMode) {
      throw LearningEngineSafetyViolation(msg, {
        'count': confidences.length,
        'allZero': allZero,
        'allOne': allOne,
      });
    }
    dev.log(msg, name: 'RuntimeSafety.assertPronunciationNotBinary', level: 900);
  }

  /// Warns if the same input produced different outputs (non-determinism).
  void assertDeterminism(String input, String output1, String output2) {
    if (output1 == output2) return;

    final msg = 'Determinism violation: same input produced different outputs.';
    if (kDebugMode) {
      throw LearningEngineSafetyViolation(msg, {
        'inputLength': input.length,
        'output1Length': output1.length,
        'output2Length': output2.length,
      });
    }
    dev.log(msg, name: 'RuntimeSafety.assertDeterminism', level: 800);
  }

  /// Structured log for learner state changes.
  void logLearnerStateChange({
    required String learnerId,
    required String skillId,
    required double masteryBefore,
    required double masteryAfter,
    required String trigger,
  }) {
    dev.log(
      'Learner state change: $learnerId / $skillId mastery $masteryBefore -> $masteryAfter (trigger: $trigger)',
      name: 'RuntimeSafety.logLearnerStateChange',
      level: 500,
    );
  }

  /// Structured log for AI interactions.
  void logAiInteraction({
    required String mode,
    required String promptSummary,
    required String responseSummary,
    required bool validationPassed,
  }) {
    dev.log(
      'AI interaction: mode=$mode validationPassed=$validationPassed',
      name: 'RuntimeSafety.logAiInteraction',
      level: 500,
    );
  }
}
