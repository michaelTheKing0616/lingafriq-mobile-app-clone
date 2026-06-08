import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/core/content/content_schema_validator.dart';

void main() {
  group('ContentSchemaValidator — basic types', () {
    test('accepts conformant string', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'string',
        'minLength': 2,
      });
      expect(v.validate('hi').isValid, isTrue);
    });

    test('rejects too-short string', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'string',
        'minLength': 5,
      });
      final result = v.validate('hi');
      expect(result.isValid, isFalse);
      expect(result.issues.single.message, contains('length'));
    });

    test('rejects wrong primitive type', () {
      final v = ContentSchemaValidator.fromSchema({'type': 'integer'});
      final result = v.validate('not an int');
      expect(result.isValid, isFalse);
      expect(result.issues.single.message, contains('expected type "integer"'));
    });
  });

  group('ContentSchemaValidator — objects', () {
    test('enforces required props', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'object',
        'required': ['id', 'title'],
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
        },
      });
      final result = v.validate({'id': 'x'});
      expect(result.isValid, isFalse);
      expect(result.issues.single.message, contains('missing required property "title"'));
    });

    test('rejects unexpected props when additionalProperties == false', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'id': {'type': 'string'},
        },
      });
      final result = v.validate({'id': 'x', 'extra': 1});
      expect(result.isValid, isFalse);
      expect(result.issues.single.message, contains('unexpected property "extra"'));
    });

    test('allows extra props when additionalProperties is missing', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
        },
      });
      expect(v.validate({'id': 'x', 'extra': 1}).isValid, isTrue);
    });
  });

  group('ContentSchemaValidator — arrays and refs', () {
    test('resolves \$ref against \$defs', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'object',
        'properties': {
          'entries': {
            'type': 'array',
            'items': {r'$ref': r'#/$defs/entry'},
          },
        },
        r'$defs': {
          'entry': {
            'type': 'object',
            'required': ['id'],
            'properties': {
              'id': {'type': 'string'},
            },
          },
        },
      });
      final result = v.validate({
        'entries': [
          {'id': 'ok'},
          {'missing': 'id'},
        ],
      });
      expect(result.isValid, isFalse);
      expect(result.issues.single.path, '/entries/1');
    });

    test('uniqueItems flags duplicates', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'array',
        'uniqueItems': true,
        'items': {'type': 'string'},
      });
      final result = v.validate(['A1', 'A2', 'A1']);
      expect(result.isValid, isFalse);
      expect(result.issues.first.message, contains('duplicate'));
    });
  });

  group('ContentSchemaValidator — formats and patterns', () {
    test('format: date-time round trips', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'string',
        'format': 'date-time',
      });
      expect(v.validate('2026-05-26T12:00:00Z').isValid, isTrue);
      expect(v.validate('not a date').isValid, isFalse);
    });

    test('pattern sha256', () {
      final v = ContentSchemaValidator.fromSchema({
        'type': 'string',
        'pattern': r'^[0-9a-f]{64}$',
      });
      final good = 'a' * 64;
      expect(v.validate(good).isValid, isTrue);
      expect(v.validate('zz').isValid, isFalse);
    });
  });

  group('ContentSchemaValidator — oneOf', () {
    test('matches exactly one branch', () {
      final v = ContentSchemaValidator.fromSchema({
        'oneOf': [
          {'type': 'integer'},
          {'type': 'string'},
        ],
      });
      expect(v.validate(42).isValid, isTrue);
      expect(v.validate('hello').isValid, isTrue);
      expect(v.validate(3.14).isValid, isFalse);
    });
  });
}
