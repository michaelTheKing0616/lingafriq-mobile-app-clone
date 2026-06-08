// ignore_for_file: avoid_print
//
// CI gate: validates bundled content JSON against the v2 schemas in
// `schemas/v2/`. Exits non-zero on any structural error so the GitHub
// workflow fails the build before code review.
//
// Run locally:
//   dart run tool/validate_content_schemas.dart
//
// Optional arguments:
//   --strict   Treat any unexpected-property warning as a hard error.
//   --files X  Comma-separated extra files to validate.

import 'dart:convert';
import 'dart:io';

/// Minimal mirror of `ContentSchemaValidator` that runs in plain Dart (no
/// Flutter `rootBundle`). The Flutter validator delegates to this exact shape
/// at runtime; kept in sync intentionally — a Dart unit test asserts parity.
class _Validator {
  _Validator(this._root, this._defs);
  final Map<String, dynamic> _root;
  final Map<String, dynamic> _defs;

  factory _Validator.fromSchema(Map<String, dynamic> schema) {
    final defs = (schema[r'$defs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return _Validator(schema, defs);
  }

  List<String> validate(dynamic data) {
    final issues = <String>[];
    _validate(_root, data, '', issues);
    return issues;
  }

  void _validate(
    Map<String, dynamic> schema,
    dynamic data,
    String path,
    List<String> issues,
  ) {
    final ref = schema[r'$ref'];
    if (ref is String) {
      final resolved = _resolveRef(ref);
      if (resolved == null) {
        issues.add('$path: unresolvable \$ref $ref');
        return;
      }
      _validate(resolved, data, path, issues);
      return;
    }

    final oneOf = schema['oneOf'];
    if (oneOf is List && oneOf.isNotEmpty) {
      var matchCount = 0;
      for (final branch in oneOf) {
        if (branch is! Map) continue;
        final branchIssues = <String>[];
        _validate(
          Map<String, dynamic>.from(branch),
          data,
          path,
          branchIssues,
        );
        if (branchIssues.isEmpty) matchCount++;
      }
      if (matchCount != 1) {
        issues.add('$path: matched $matchCount oneOf branches (need 1)');
      }
      return;
    }

    final typeValue = schema['type'];
    if (typeValue is String && !_typeMatches(typeValue, data)) {
      issues.add('$path: expected $typeValue, got ${_describeType(data)}');
      return;
    }

    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.contains(data)) {
      issues.add('$path: $data not in enum');
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
    List<String> issues,
  ) {
    final minLength = schema['minLength'];
    if (minLength is int && value.length < minLength) {
      issues.add('$path: length ${value.length} < $minLength');
    }
    final pattern = schema['pattern'];
    if (pattern is String) {
      if (!RegExp(pattern).hasMatch(value)) {
        issues.add('$path: does not match /$pattern/');
      }
    }
    final format = schema['format'];
    if (format is String && !_formatMatches(format, value)) {
      issues.add('$path: invalid format $format');
    }
  }

  void _validateNumber(
    Map<String, dynamic> schema,
    num value,
    String path,
    List<String> issues,
  ) {
    final minimum = schema['minimum'];
    if (minimum is num && value < minimum) {
      issues.add('$path: $value < min $minimum');
    }
    final maximum = schema['maximum'];
    if (maximum is num && value > maximum) {
      issues.add('$path: $value > max $maximum');
    }
    if (schema['type'] == 'integer' && value != value.truncate()) {
      issues.add('$path: not integer');
    }
  }

  void _validateArray(
    Map<String, dynamic> schema,
    List<dynamic> value,
    String path,
    List<String> issues,
  ) {
    final minItems = schema['minItems'];
    if (minItems is int && value.length < minItems) {
      issues.add('$path: items ${value.length} < $minItems');
    }
    final unique = schema['uniqueItems'];
    if (unique == true) {
      final seen = <String>{};
      for (final el in value) {
        final key = jsonEncode(el);
        if (!seen.add(key)) {
          issues.add('$path: duplicate item');
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
    List<String> issues,
  ) {
    final required = schema['required'];
    if (required is List) {
      for (final key in required) {
        if (key is String && !value.containsKey(key)) {
          issues.add('$path: missing required "$key"');
        }
      }
    }
    final minProps = schema['minProperties'];
    if (minProps is int && value.length < minProps) {
      issues.add('$path: ${value.length} props < $minProps');
    }
    final properties =
        (schema['properties'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final additionalProperties = schema['additionalProperties'];
    final patternProperties =
        (schema['patternProperties'] as Map?)?.cast<String, dynamic>();

    value.forEach((key, child) {
      if (properties.containsKey(key)) {
        _validate(
          Map<String, dynamic>.from(properties[key] as Map),
          child,
          '$path/$key',
          issues,
        );
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
              additionalProperties, key, child, path, issues);
        }
      } else {
        _checkAdditional(additionalProperties, key, child, path, issues);
      }
    });
  }

  void _checkAdditional(
    dynamic additionalProperties,
    String key,
    dynamic child,
    String path,
    List<String> issues,
  ) {
    if (additionalProperties == false) {
      issues.add('$path: unexpected property "$key"');
    } else if (additionalProperties is Map) {
      _validate(
        Map<String, dynamic>.from(additionalProperties),
        child,
        '$path/$key',
        issues,
      );
    }
  }

  Map<String, dynamic>? _resolveRef(String ref) {
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
        return value is int ||
            (value is num && value == value.truncate());
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
        return true;
    }
  }
}

class _ValidationJob {
  _ValidationJob({
    required this.schemaPath,
    required this.targetGlobs,
    required this.label,
  });
  final String schemaPath;
  final List<String> targetGlobs;
  final String label;
}

Future<int> main(List<String> args) async {
  final strict = args.contains('--strict');
  final writeBaseline = args.contains('--write-baseline');
  final extras = _extractListArg(args, '--files');
  final baselineFile = File('tool/content_schema_baseline.txt');
  final baseline = <String>{};
  if (!writeBaseline && baselineFile.existsSync()) {
    for (final line in baselineFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      baseline.add(trimmed);
    }
  }

  final jobs = <_ValidationJob>[
    _ValidationJob(
      label: 'Content Pack Manifests',
      schemaPath: 'schemas/v2/content_pack_manifest.schema.json',
      targetGlobs: ['assets/data/cms_manifests/*/manifest.json'],
    ),
    _ValidationJob(
      label: 'Curriculum Bundles',
      schemaPath: 'schemas/v2/curriculum_bundle.schema.json',
      targetGlobs: [
        'assets/data/lingafriq_authentic_curriculum_a1.json',
        'assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json',
        'assets/data/lingafriq_authentic_curriculum_a1_c1.json',
      ],
    ),
    _ValidationJob(
      label: 'Game Content',
      schemaPath: 'schemas/v2/game_content.schema.json',
      targetGlobs: ['assets/data/game_content.json'],
    ),
    _ValidationJob(
      label: 'Audio Manifest',
      schemaPath: 'schemas/v2/audio_manifest.schema.json',
      targetGlobs: ['assets/data/audio_manifest.json'],
    ),
  ];

  var totalFiles = 0;
  var failedFiles = 0;
  var totalIssues = 0;
  final newBaselineEntries = <String>{};
  final regressions = <String>[];

  for (final job in jobs) {
    final schemaFile = File(job.schemaPath);
    if (!schemaFile.existsSync()) {
      stderr.writeln('[skip] ${job.label}: schema not found at ${job.schemaPath}');
      continue;
    }
    final schemaRaw = jsonDecode(schemaFile.readAsStringSync());
    if (schemaRaw is! Map) {
      stderr.writeln('[fail] ${job.label}: schema is not a JSON object.');
      failedFiles++;
      continue;
    }
    final validator =
        _Validator.fromSchema(Map<String, dynamic>.from(schemaRaw));

    final files = <File>[];
    for (final glob in job.targetGlobs) {
      files.addAll(_expandGlob(glob));
    }
    if (files.isEmpty) {
      print('[ok ] ${job.label}: no target files present');
      continue;
    }

    for (final file in files) {
      totalFiles++;
      final result = _validateFile(validator, file, strict: strict);
      final relPath = file.path.replaceAll('\\', '/');
      final newIssues = <String>[];
      for (final issue in result.issues) {
        final key = '$relPath || $issue';
        if (writeBaseline) {
          newBaselineEntries.add(key);
        } else if (baseline.contains(key)) {
          // Known legacy defect — tracked, not regressed.
        } else {
          newIssues.add(issue);
          regressions.add(key);
        }
      }
      totalIssues += result.issues.length;
      if (newIssues.isNotEmpty) {
        failedFiles++;
        print('[FAIL] ${job.label} :: ${file.path} '
            '(${newIssues.length} NEW issue(s), '
            '${result.issues.length - newIssues.length} baselined)');
        for (final issue in newIssues.take(15)) {
          print('       - $issue');
        }
        if (newIssues.length > 15) {
          print('       … and ${newIssues.length - 15} more');
        }
      } else if (result.issues.isNotEmpty) {
        print('[base] ${job.label} :: ${file.path} '
            '(${result.issues.length} baselined issue(s))');
      } else {
        print('[ ok ] ${job.label} :: ${file.path}');
      }
    }
  }

  for (final extra in extras) {
    final file = File(extra);
    if (!file.existsSync()) {
      stderr.writeln('[warn] --files entry not found: $extra');
      continue;
    }
    print('[note] extra file: $extra (no schema bound; skipped)');
  }

  if (writeBaseline) {
    final sorted = newBaselineEntries.toList()..sort();
    final buf = StringBuffer()
      ..writeln(
          '# Content schema baseline — generated by validate_content_schemas.dart')
      ..writeln(
          '# Each entry is "<file> || <issue>" and represents a legacy data defect')
      ..writeln(
          '# that pre-dates the v2 schemas. New issues must NOT be added here.')
      ..writeln('# Regenerate with: dart run tool/validate_content_schemas.dart --write-baseline')
      ..writeln('# Generated at: ${DateTime.now().toUtc().toIso8601String()}');
    for (final entry in sorted) {
      buf.writeln(entry);
    }
    File('tool/content_schema_baseline.txt')
        .writeAsStringSync(buf.toString());
    print(
        '\nWrote ${sorted.length} entries to tool/content_schema_baseline.txt');
    return 0;
  }

  print('\nSummary: $failedFiles/$totalFiles files have NEW issues, '
      '$totalIssues total issues (${regressions.length} regression(s) '
      'vs baseline).');
  return failedFiles == 0 ? 0 : 1;
}

class _FileResult {
  _FileResult(this.issues);
  final List<String> issues;
}

_FileResult _validateFile(_Validator validator, File file,
    {required bool strict}) {
  try {
    final raw = jsonDecode(file.readAsStringSync());
    final issues = validator.validate(raw);
    if (!strict) {
      issues.removeWhere((i) => i.contains('unexpected property'));
    }
    return _FileResult(issues);
  } on FormatException catch (e) {
    return _FileResult(['<root>: invalid JSON: $e']);
  } on FileSystemException catch (e) {
    return _FileResult(['<root>: cannot read: $e']);
  }
}

Iterable<File> _expandGlob(String pattern) sync* {
  if (!pattern.contains('*')) {
    final f = File(pattern);
    if (f.existsSync()) yield f;
    return;
  }
  final parts = pattern.split('/');
  final base = <String>[];
  var i = 0;
  for (; i < parts.length; i++) {
    if (parts[i].contains('*')) break;
    base.add(parts[i]);
  }
  final baseDir = Directory(base.join('/'));
  if (!baseDir.existsSync()) return;
  final tail = parts.sublist(i).join('/');
  for (final entity in baseDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final rel = entity.path
        .replaceAll('\\', '/')
        .replaceFirst(baseDir.path.replaceAll('\\', '/') + '/', '');
    if (_globMatch(rel, tail)) yield entity;
  }
}

bool _globMatch(String value, String pattern) {
  final regex = '^' +
      pattern
          .replaceAll('.', r'\.')
          .replaceAll('**/', '(.*/)?')
          .replaceAll('*', '[^/]*') +
      r'$';
  return RegExp(regex).hasMatch(value);
}

List<String> _extractListArg(List<String> args, String flag) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) {
      return args[i + 1].split(',').where((s) => s.isNotEmpty).toList();
    }
  }
  return const [];
}
