import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_data_model.dart';

/// Typed onboarding answers. Persistence is jsonEncode of this model.
class OnboardingAnswers {
  const OnboardingAnswers(this.values);

  static const schema = <String, String>{
    'proficiency_language': 'string',
    'learning_language': 'string',
    'age_category': 'string',
    'learning_reasons': 'stringList',
    'primary_goal': 'string',
    'learning_style': 'string',
    'daily_duration_minutes': 'int',
    'preferred_time_of_day': 'string',
    'reminders_enabled': 'bool',
    'app_tone': 'string',
    'gamification_level': 'string',
  };

  final Map<String, Object?> values;

  String encode() => jsonEncode(values);

  OnboardingAnswers merge(OnboardingAnswers newer) {
    return OnboardingAnswers({...values, ...newer.values});
  }

  OnboardingData toOnboardingData() {
    return OnboardingData(
      ageCategory: values['age_category'] as String?,
      learningReasons: List<String>.from(
        values['learning_reasons'] as List? ?? const <String>[],
      ),
      selectedLanguage: values['learning_language'] as String?,
      primaryGoal: values['primary_goal'] as String?,
      learningStyle: values['learning_style'] as String?,
      dailyDurationMinutes: values['daily_duration_minutes'] as int?,
      preferredTimeOfDay: values['preferred_time_of_day'] as String?,
      remindersEnabled: values['reminders_enabled'] as bool?,
      appTone: values['app_tone'] as String?,
      gamificationLevel: values['gamification_level'] as String?,
    );
  }

  static Future<OnboardingMigration> migrate(SharedPreferences prefs) async {
    final data = prefs.getString('onboarding_data');
    if (data == null || data.trim().isEmpty) {
      return OnboardingMigration(
        reask: prefs.getStringList('onboarding_reask') ?? const <String>[],
      );
    }
    try {
      final loaded = OnboardingAnswers.read(data);
      if (!loaded.legacyProvider && loaded.migrated) {
        await prefs.setString('onboarding_data', loaded.answers.encode());
      }
      if (loaded.reask.isNotEmpty) {
        await prefs.setStringList('onboarding_reask', loaded.reask);
        return OnboardingMigration(reask: loaded.reask);
      }
      return OnboardingMigration(
        reask: prefs.getStringList('onboarding_reask') ?? const <String>[],
      );
    } on OnboardingDecodeException catch (error) {
      await prefs.setStringList('onboarding_reask', error.fields);
      return OnboardingMigration(reask: error.fields, error: error);
    }
  }

  static String encodeStored(String? previous, Map<String, dynamic> data) {
    final incoming = OnboardingAnswers.fromScreenMap(data);
    if (previous == null || previous.trim().isEmpty) return incoming.encode();
    try {
      final loaded = OnboardingAnswers.read(previous);
      if (loaded.legacyProvider) return incoming.encode();
      return loaded.answers.merge(incoming).encode();
    } on OnboardingDecodeException {
      return incoming.encode();
    }
  }

  static OnboardingAnswers fromScreenMap(Map<String, dynamic> data) {
    final values = <String, Object?>{};
    for (final entry in schema.entries) {
      if (!data.containsKey(entry.key)) continue;
      final parsed = _coerce(entry.value, data[entry.key]);
      if (parsed != null) values[entry.key] = parsed;
    }
    return OnboardingAnswers(values);
  }

  static OnboardingLoad read(String raw) {
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) {
        throw const FormatException('onboarding JSON was not an object');
      }
      final map = Map<String, dynamic>.from(decoded);
      if (_isLegacyProviderJson(map)) {
        return OnboardingLoad.legacy();
      }
      return _fromTypedMap(map, migrated: false);
    } on OnboardingDecodeException {
      rethrow;
    } catch (error) {
      if (trimmed.startsWith('{') && trimmed.endsWith('}') && !trimmed.contains('"')) {
        return _fromMapToString(trimmed);
      }
      throw OnboardingDecodeException(
        fields: schema.keys.toList(),
        cause: error,
      );
    }
  }

  static bool _isLegacyProviderJson(Map<String, dynamic> map) {
    return map.containsKey('ageCategory') ||
        map.containsKey('learningReasons') ||
        map.containsKey('selectedLanguage');
  }

  static OnboardingLoad _fromTypedMap(
    Map<String, dynamic> map, {
    required bool migrated,
  }) {
    final values = <String, Object?>{};
    final reask = <String>[];
    for (final entry in schema.entries) {
      if (!map.containsKey(entry.key) || map[entry.key] == null) continue;
      final parsed = _coerce(entry.value, map[entry.key]);
      if (parsed == null) {
        reask.add(entry.key);
      } else {
        values[entry.key] = parsed;
      }
    }
    return OnboardingLoad(
      answers: OnboardingAnswers(values),
      reask: reask,
      migrated: migrated,
    );
  }

  static OnboardingLoad _fromMapToString(String raw) {
    final tokens = _scanMapToString(raw);
    final values = <String, Object?>{};
    final reask = <String>[];
    for (final entry in schema.entries) {
      if (!tokens.containsKey(entry.key)) continue;
      final parsed = _coerceToken(entry.value, tokens[entry.key]!);
      if (parsed == null) {
        reask.add(entry.key);
      } else {
        values[entry.key] = parsed;
      }
    }
    return OnboardingLoad(
      answers: OnboardingAnswers(values),
      reask: reask,
      migrated: true,
    );
  }

  static Map<String, String> _scanMapToString(String raw) {
    final inner = raw.trim().substring(1, raw.trim().length - 1).trim();
    final result = <String, String>{};
    if (inner.isEmpty) return result;
    var index = 0;
    while (index < inner.length) {
      final colon = inner.indexOf(':', index);
      if (colon < 0) {
        throw FormatException('unparsed onboarding text near $index');
      }
      final key = inner.substring(index, colon).trim();
      var cursor = colon + 1;
      while (cursor < inner.length && inner[cursor] == ' ') {
        cursor += 1;
      }
      late final String token;
      if (cursor < inner.length && (inner[cursor] == '[' || inner[cursor] == '{')) {
        final open = inner[cursor];
        final close = open == '[' ? ']' : '}';
        var depth = 0;
        var end = cursor;
        for (; end < inner.length; end += 1) {
          if (inner[end] == open) depth += 1;
          if (inner[end] == close) {
            depth -= 1;
            if (depth == 0) {
              end += 1;
              break;
            }
          }
        }
        token = inner.substring(cursor, end).trim();
        index = end;
        if (index < inner.length && inner[index] == ',') index += 1;
      } else {
        final comma = inner.indexOf(',', cursor);
        if (comma < 0) {
          token = inner.substring(cursor).trim();
          index = inner.length;
        } else {
          token = inner.substring(cursor, comma).trim();
          index = comma + 1;
        }
      }
      while (index < inner.length && inner[index] == ' ') {
        index += 1;
      }
      result[key] = token;
    }
    return result;
  }

  static Object? _coerce(String kind, Object? value) {
    switch (kind) {
      case 'string':
        return value is String && value.isNotEmpty ? value : null;
      case 'int':
        return value is int ? value : null;
      case 'bool':
        return value is bool ? value : null;
      case 'stringList':
        if (value is! List || value.any((item) => item is! String)) return null;
        return List<String>.from(value);
      default:
        return null;
    }
  }

  static Object? _coerceToken(String kind, String token) {
    if (token == 'null') return null;
    switch (kind) {
      case 'string':
        return token.isEmpty ? null : token;
      case 'int':
        return int.tryParse(token);
      case 'bool':
        if (token == 'true') return true;
        if (token == 'false') return false;
        return null;
      case 'stringList':
        if (!token.startsWith('[') || !token.endsWith(']')) return null;
        final body = token.substring(1, token.length - 1).trim();
        if (body.isEmpty) return <String>[];
        return body.split(',').map((part) => part.trim()).toList();
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is OnboardingAnswers && jsonEncode(values) == jsonEncode(other.values);
  }

  @override
  int get hashCode => jsonEncode(values).hashCode;
}

class OnboardingMigration {
  const OnboardingMigration({required this.reask, this.error});

  final List<String> reask;
  final OnboardingDecodeException? error;
}

class OnboardingLoad {
  const OnboardingLoad({
    required this.answers,
    required this.reask,
    required this.migrated,
    this.legacyProvider = false,
  });

  const OnboardingLoad.legacy()
      : answers = const OnboardingAnswers({}),
        reask = const [],
        migrated = false,
        legacyProvider = true;

  final OnboardingAnswers answers;
  final List<String> reask;
  final bool migrated;
  final bool legacyProvider;
}

class OnboardingDecodeException implements Exception {
  const OnboardingDecodeException({
    required this.fields,
    required this.cause,
  });

  final String code = 'onboarding_decode_failed';
  final List<String> fields;
  final Object cause;

  @override
  String toString() => '$code: ${fields.join(', ')} ($cause)';
}
