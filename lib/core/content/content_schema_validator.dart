import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A single schema validation issue.
@immutable
class SchemaIssue {
  /// JSON-pointer style path, e.g. `/manifest/lessons/0/title`.
  final String path;
  final String message;
  const SchemaIssue(this.path, this.message);

  @override
  String toString() => '${path.isEmpty ? '<root>' : path}: $message';
}

/// Validation outcome.
@immutable
class SchemaValidationResult {
  final bool isValid;
  final List<SchemaIssue> issues;
  const SchemaValidationResult(this.isValid, this.issues);

  factory SchemaValidationResult.ok() =>
      const SchemaValidationResult(true, <SchemaIssue>[]);

  factory SchemaValidationResult.errors(List<SchemaIssue> issues) =>
      SchemaValidationResult(issues.isEmpty, List.unmodifiable(issues));

  /// Human-friendly multi-line summary suitable for logs / CI output.
  String summarize({int maxLines = 25}) {
    if (isValid) return 'OK';
    final lines = <String>['${issues.length} issue(s):'];
    for (final i in issues.take(maxLines)) {
      lines.add('  - $i');
    }
    if (issues.length > maxLines) {
      lines.add('  … and ${issues.length - maxLines} more');
    }
    return lines.join('\n');
  }
}

/// A pure-Dart JSON Schema validator implementing the subset of Draft
/// 2020-12 used by LingAfriq content schemas.
///
/// Supported keywords:
///   - `type` (object/array/string/integer/number/boolean/null)
///   - `required`, `properties`, `additionalProperties`,
///     `patternProperties`, `minProperties`
///   - `items`, `minItems`, `uniqueItems`
///   - `enum`, `pattern` (RegExp), `minLength`, `maxLength`,
///     `minimum`, `maximum`
///   - `format` (`date-time`, `uri`)
///   - `$ref` (local refs into `#/$defs/...` only)
///   - `oneOf`
///
/// This implementation is intentionally dependency-free so it can run both
/// inside the Flutter app (debug/runtime checks) and from `dart` CLI scripts
/// (CI gate). For the full Draft 2020-12 surface use `package:json_schema` in
/// the authoring backend instead — that pipeline is server-side.
class ContentSchemaValidator {
  ContentSchemaValidator._(this._root, this._defs);

  final Map<String, dynamic> _root;
  final Map<String, dynamic> _defs;

  /// Builds a validator from a parsed JSON Schema document.
  factory ContentSchemaValidator.fromSchema(Map<String, dynamic> schema) {
    final defs = (schema[r'$defs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return ContentSchemaValidator._(schema, defs);
  }

  /// Builds a validator from a raw JSON-encoded schema string.
  factory ContentSchemaValidator.fromJsonString(String jsonString) {
    final parsed = jsonDecode(jsonString);
    if (parsed is! Map) {
      throw ArgumentError('Schema must be a JSON object.');
    }
    return ContentSchemaValidator.fromSchema(
      Map<String, dynamic>.from(parsed),
    );
  }

  /// Loads and parses a schema from a bundled asset. Throws if the asset is
  /// missing or malformed.
  static Future<ContentSchemaValidator> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return ContentSchemaValidator.fromJsonString(raw);
  }

  /// Validates [data] against the root schema. Always non-throwing.
  SchemaValidationResult validate(dynamic data) {
    final issues = <SchemaIssue>[];
    _validate(_root, data, '', issues);
    return SchemaValidationResult.errors(issues);
  }

  // ---- internal ----

  void _validate(
    Map<String, dynamic> schema,
    dynamic data,
    String path,
    List<SchemaIssue> issues,
  ) {
    // $ref resolution
    final ref = schema[r'$ref'];
    if (ref is String) {
      final resolved = _resolveRef(ref);
      if (resolved == null) {
        issues.add(SchemaIssue(path, 'unresolvable $ref: $ref'));
        return;
      }
      _validate(resolved, data, path, issues);
      return;
    }

    // oneOf
    final oneOf = schema['oneOf'];
    if (oneOf is List && oneOf.isNotEmpty) {
      var matchCount = 0;
      List<SchemaIssue>? lastBranchIssues;
      for (final branch in oneOf) {
        if (branch is! Map) continue;
        final branchIssues = <SchemaIssue>[];
        _validate(
          Map<String, dynamic>.from(branch),
          data,
          path,
          branchIssues,
        );
        if (branchIssues.isEmpty) {
          matchCount++;
        } else {
          lastBranchIssues = branchIssues;
        }
      }
      if (matchCount != 1) {
        if (matchCount == 0 && lastBranchIssues != null) {
          issues.add(SchemaIssue(
            path,
            'did not match any oneOf branch (last branch issues: '
            '${lastBranchIssues.take(2).join('; ')})',
          ));
        } else if (matchCount > 1) {
          issues.add(SchemaIssue(
            path,
            'matched $matchCount oneOf branches (must match exactly one)',
          ));
        }
      }
      // oneOf shortcircuits remaining keyword checks (matches JSON Schema).
      return;
    }

    // type
    final typeValue = schema['type'];
    if (typeValue is String && !_typeMatches(typeValue, data)) {
      issues.add(SchemaIssue(
        path,
        'expected type "$typeValue", got ${_describeType(data)}',
      ));
      return;
    }

    // enum
    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.contains(data)) {
      issues.add(SchemaIssue(
        path,
        'value $data not in enum ${enumValues.take(8).toList()}',
      ));
    }

    if (data is String) {
      _validateString(schema, data, path, issues);
    } else if (data is num) {
      _validateNumber(schema, data, path, issues);
    } else if (data is List) {
      _validateArray(schema, data, path, issues);
    } else if (data is Map) {
      _validateObject(
        schema,
        Map<String, dynamic>.from(data),
        path,
        issues,
      );
    }
  }

  void _validateString(
    Map<String, dynamic> schema,
    String value,
    String path,
    List<SchemaIssue> issues,
  ) {
    final minLength = schema['minLength'];
    if (minLength is int && value.length < minLength) {
      issues.add(SchemaIssue(
        path,
        'string length ${value.length} < minLength $minLength',
      ));
    }
    final maxLength = schema['maxLength'];
    if (maxLength is int && value.length > maxLength) {
      issues.add(SchemaIssue(
        path,
        'string length ${value.length} > maxLength $maxLength',
      ));
    }
    final pattern = schema['pattern'];
    if (pattern is String) {
      try {
        if (!RegExp(pattern).hasMatch(value)) {
          issues.add(SchemaIssue(
            path,
            'value does not match pattern /$pattern/',
          ));
        }
      } on FormatException {
        // Invalid pattern in schema is reported, but does not block.
        issues.add(SchemaIssue(path, 'invalid regex pattern in schema'));
      }
    }
    final format = schema['format'];
    if (format is String) {
      if (!_formatMatches(format, value)) {
        issues.add(SchemaIssue(path, 'invalid format "$format"'));
      }
    }
  }

  void _validateNumber(
    Map<String, dynamic> schema,
    num value,
    String path,
    List<SchemaIssue> issues,
  ) {
    final minimum = schema['minimum'];
    if (minimum is num && value < minimum) {
      issues.add(SchemaIssue(path, 'value $value < minimum $minimum'));
    }
    final maximum = schema['maximum'];
    if (maximum is num && value > maximum) {
      issues.add(SchemaIssue(path, 'value $value > maximum $maximum'));
    }
    if (schema['type'] == 'integer' && value != value.truncate()) {
      issues.add(SchemaIssue(path, 'expected integer, got $value'));
    }
  }

  void _validateArray(
    Map<String, dynamic> schema,
    List<dynamic> value,
    String path,
    List<SchemaIssue> issues,
  ) {
    final minItems = schema['minItems'];
    if (minItems is int && value.length < minItems) {
      issues.add(SchemaIssue(
        path,
        'array length ${value.length} < minItems $minItems',
      ));
    }
    final unique = schema['uniqueItems'];
    if (unique == true) {
      final seen = <String>{};
      for (final el in value) {
        final key = jsonEncode(el);
        if (!seen.add(key)) {
          issues.add(SchemaIssue(path, 'duplicate item: $el'));
          break;
        }
      }
    }
    final items = schema['items'];
    if (items is Map) {
      final itemSchema = Map<String, dynamic>.from(items);
      for (var i = 0; i < value.length; i++) {
        _validate(itemSchema, value[i], '$path/$i', issues);
      }
    }
  }

  void _validateObject(
    Map<String, dynamic> schema,
    Map<String, dynamic> value,
    String path,
    List<SchemaIssue> issues,
  ) {
    final required = schema['required'];
    if (required is List) {
      for (final key in required) {
        if (key is String && !value.containsKey(key)) {
          issues.add(SchemaIssue(path, 'missing required property "$key"'));
        }
      }
    }
    final minProps = schema['minProperties'];
    if (minProps is int && value.length < minProps) {
      issues.add(SchemaIssue(
        path,
        'object has ${value.length} props < minProperties $minProps',
      ));
    }
    final properties =
        (schema['properties'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final additionalProperties = schema['additionalProperties'];
    final patternProperties =
        (schema['patternProperties'] as Map?)?.cast<String, dynamic>();

    value.forEach((key, child) {
      if (properties.containsKey(key)) {
        final childSchema =
            Map<String, dynamic>.from(properties[key] as Map);
        _validate(childSchema, child, '$path/$key', issues);
      } else if (patternProperties != null) {
        var matched = false;
        for (final entry in patternProperties.entries) {
          if (RegExp(entry.key).hasMatch(key)) {
            matched = true;
            _validate(
              Map<String, dynamic>.from(entry.value as Map),
              child,
              '$path/$key',
              issues,
            );
            break;
          }
        }
        if (!matched) {
          _checkAdditional(
            additionalProperties,
            key,
            child,
            path,
            issues,
          );
        }
      } else {
        _checkAdditional(
          additionalProperties,
          key,
          child,
          path,
          issues,
        );
      }
    });
  }

  void _checkAdditional(
    dynamic additionalProperties,
    String key,
    dynamic child,
    String path,
    List<SchemaIssue> issues,
  ) {
    if (additionalProperties == false) {
      issues.add(SchemaIssue(path, 'unexpected property "$key"'));
    } else if (additionalProperties is Map) {
      _validate(
        Map<String, dynamic>.from(additionalProperties),
        child,
        '$path/$key',
        issues,
      );
    }
    // additionalProperties == true (or missing) → permit silently.
  }

  Map<String, dynamic>? _resolveRef(String ref) {
    // Only local refs of form #/$defs/<name> are supported. External or
    // pointer-style refs are rejected at validation time.
    const prefix = r'#/$defs/';
    if (!ref.startsWith(prefix)) return null;
    final key = ref.substring(prefix.length);
    final raw = _defs[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  bool _typeMatches(String type, dynamic value) {
    switch (type) {
      case 'object':
        return value is Map;
      case 'array':
        return value is List;
      case 'string':
        return value is String;
      case 'integer':
        return value is int || (value is num && value == value.truncate());
      case 'number':
        return value is num;
      case 'boolean':
        return value is bool;
      case 'null':
        return value == null;
      default:
        return true;
    }
  }

  String _describeType(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) return 'object';
    if (value is List) return 'array';
    if (value is String) return 'string';
    if (value is bool) return 'boolean';
    if (value is int) return 'integer';
    if (value is num) return 'number';
    return value.runtimeType.toString();
  }

  bool _formatMatches(String format, String value) {
    switch (format) {
      case 'date-time':
        return DateTime.tryParse(value) != null;
      case 'uri':
        final uri = Uri.tryParse(value);
        return uri != null && uri.hasScheme;
      default:
        return true; // unknown formats pass (forward compatible)
    }
  }
}
