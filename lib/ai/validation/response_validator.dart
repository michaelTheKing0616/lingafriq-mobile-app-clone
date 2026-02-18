import 'dart:convert';

/// Strict JSON schema enforcement for AI responses.
///
/// The AI must output valid JSON matching predefined schemas.
/// Invalid responses are rejected — never silently accepted.
/// This ensures deterministic, reproducible tutor behavior.
class ResponseValidator {
  ResponseValidator._();

  /// Validates and parses a raw AI response string.
  ///
  /// Throws [AiResponseValidationError] if:
  /// - Response is not valid JSON
  /// - Required fields are missing
  /// - Field types are incorrect
  /// - Values are out of allowed range
  static Map<String, dynamic> validateTutorFeedback(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<bool>(json, 'wasCorrect');
    _requireField<num>(json, 'partialCredit', min: 0.0, max: 1.0);
    _requireField<String>(json, 'nextAction', allowedValues: [
      'retrySameItem',
      'nextItemSameDifficulty',
      'downgradeToEasier',
      'upgradeToHarder',
      'practicePrerequisite',
      'endSession',
    ]);

    // Optional fields — validate types if present
    _optionalField<String>(json, 'diagnosis');
    _optionalField<String>(json, 'microExplanation');
    _optionalField<num>(json, 'diagnosisConfidence', min: 0.0, max: 1.0);
    _optionalListField<String>(json, 'detectedErrors');

    // Enforce explanation length constraint
    final explanation = json['microExplanation'] as String?;
    if (explanation != null) {
      final sentenceCount = _countSentences(explanation);
      if (sentenceCount > 3) {
        throw AiResponseValidationError(
          'microExplanation exceeds 3 sentences (got $sentenceCount). '
          'AI must be concise.',
        );
      }
    }

    return json;
  }

  /// Validates a turn generation response from AI.
  static Map<String, dynamic> validateTurnGeneration(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<String>(json, 'prompt');

    if (json.containsKey('expected')) {
      final expected = json['expected'];
      if (expected is! Map<String, dynamic>) {
        throw AiResponseValidationError(
          'Field "expected" must be a JSON object, got ${expected.runtimeType}',
        );
      }
    }

    _optionalListField<String>(json, 'errorFocus');
    _optionalField<num>(json, 'timeLimitSeconds');

    return json;
  }

  /// Validates a roleplay response from AI.
  static Map<String, dynamic> validateRoleplayResponse(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<String>(json, 'dialogue');
    _requireField<String>(json, 'nextPrompt');
    _optionalField<String>(json, 'correction');
    _optionalField<String>(json, 'branchReason');
    _optionalListField<String>(json, 'detectedErrors');
    _optionalField<bool>(json, 'scenarioComplete');

    return json;
  }

  /// Validates a historical roleplay response (persona speech + teaching + citations).
  static Map<String, dynamic> validateHistoricalRoleplayResponse(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<String>(json, 'speech_text');
    _optionalField<String>(json, 'emotion_tone');
    _optionalField<String>(json, 'conversation_state');
    _optionalField<String>(json, 'next_state');
    _optionalListField<String>(json, 'closure_options');

    if (json.containsKey('teaching_points') && json['teaching_points'] != null) {
      final list = json['teaching_points'] as List;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        _optionalField<String>(item, 'type');
        _optionalField<String>(item, 'content');
      }
    }

    if (json.containsKey('historical_citations') && json['historical_citations'] != null) {
      final list = json['historical_citations'] as List;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        _optionalField<String>(item, 'source');
        _optionalField<String>(item, 'relevance');
      }
    }

    return json;
  }

  /// Validates a translation justification response.
  static Map<String, dynamic> validateTranslationResponse(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<String>(json, 'translation');
    _optionalField<String>(json, 'justification');
    _optionalListField<Map>(json, 'alternatives');
    _optionalField<String>(json, 'nuanceExplanation');
    _optionalListField<String>(json, 'detectedErrors');

    return json;
  }

  /// Validates a grammar analysis response.
  static Map<String, dynamic> validateGrammarResponse(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<bool>(json, 'isCorrect');
    _optionalField<String>(json, 'rule');
    _optionalField<String>(json, 'correction');
    _optionalField<String>(json, 'explanation');
    _optionalListField<String>(json, 'detectedErrors');

    return json;
  }

  /// Validates a review mode response.
  static Map<String, dynamic> validateReviewResponse(String rawResponse) {
    final json = _parseJson(rawResponse);

    _requireField<bool>(json, 'wasCorrect');
    _requireField<String>(json, 'nextAction');
    _optionalField<num>(json, 'partialCredit', min: 0.0, max: 1.0);
    _optionalField<String>(json, 'hint');
    _optionalField<bool>(json, 'shouldStop');

    return json;
  }

  /// Attempts to extract JSON from a response that may contain prose.
  ///
  /// Tries in order:
  /// 1. Direct JSON parse
  /// 2. Extract first JSON object from markdown code block
  /// 3. Extract first { ... } block
  static Map<String, dynamic> _parseJson(String rawResponse) {
    final trimmed = rawResponse.trim();

    // 1. Direct parse
    try {
      final result = jsonDecode(trimmed);
      if (result is Map<String, dynamic>) return result;
    } catch (_) {}

    // 2. Extract from markdown code block
    final codeBlockMatch = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```').firstMatch(trimmed);
    if (codeBlockMatch != null) {
      try {
        final result = jsonDecode(codeBlockMatch.group(1)!.trim());
        if (result is Map<String, dynamic>) return result;
      } catch (_) {}
    }

    // 3. Extract first { ... } block
    final braceStart = trimmed.indexOf('{');
    final braceEnd = trimmed.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      try {
        final result = jsonDecode(trimmed.substring(braceStart, braceEnd + 1));
        if (result is Map<String, dynamic>) return result;
      } catch (_) {}
    }

    throw AiResponseValidationError(
      'AI response is not valid JSON. Raw response: '
      '${trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed}',
    );
  }

  static void _requireField<T>(
    Map<String, dynamic> json,
    String field, {
    double? min,
    double? max,
    List<String>? allowedValues,
  }) {
    if (!json.containsKey(field)) {
      throw AiResponseValidationError('Required field "$field" is missing');
    }

    final value = json[field];
    if (value is! T) {
      throw AiResponseValidationError(
        'Field "$field" must be $T, got ${value.runtimeType}',
      );
    }

    if (min != null && value is num && value < min) {
      throw AiResponseValidationError(
        'Field "$field" must be >= $min, got $value',
      );
    }
    if (max != null && value is num && value > max) {
      throw AiResponseValidationError(
        'Field "$field" must be <= $max, got $value',
      );
    }
    if (allowedValues != null && value is String && !allowedValues.contains(value)) {
      throw AiResponseValidationError(
        'Field "$field" must be one of $allowedValues, got "$value"',
      );
    }
  }

  static void _optionalField<T>(
    Map<String, dynamic> json,
    String field, {
    double? min,
    double? max,
  }) {
    if (!json.containsKey(field) || json[field] == null) return;

    final value = json[field];
    if (value is! T) {
      throw AiResponseValidationError(
        'Field "$field" must be $T if present, got ${value.runtimeType}',
      );
    }

    if (min != null && value is num && value < min) {
      throw AiResponseValidationError(
        'Field "$field" must be >= $min, got $value',
      );
    }
    if (max != null && value is num && value > max) {
      throw AiResponseValidationError(
        'Field "$field" must be <= $max, got $value',
      );
    }
  }

  static void _optionalListField<T>(Map<String, dynamic> json, String field) {
    if (!json.containsKey(field) || json[field] == null) return;

    if (json[field] is! List) {
      throw AiResponseValidationError(
        'Field "$field" must be a List if present, got ${json[field].runtimeType}',
      );
    }
  }

  static int _countSentences(String text) {
    return RegExp(r'[.!?]+\s*').allMatches(text).length;
  }
}

/// Thrown when an AI response fails schema validation.
class AiResponseValidationError implements Exception {
  final String message;
  const AiResponseValidationError(this.message);

  @override
  String toString() => 'AiResponseValidationError: $message';
}
