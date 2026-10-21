import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/local_schema_migrator.dart';

class _MemoryStore implements SchemaStore {
  _MemoryStore(this.schemaVersion, this.rows);

  @override
  int schemaVersion;
  Map<String, String> rows;
  int stepCalls = 0;

  @override
  Future<void> setSchemaVersion(int version) async {
    schemaVersion = version;
  }

  @override
  Map<String, Object?> snapshot() => {
        'schemaVersion': schemaVersion,
        'rows': Map<String, String>.from(rows),
      };

  @override
  Future<void> restore(Map<String, Object?> snapshot) async {
    schemaVersion = snapshot['schemaVersion'] as int? ?? 0;
    rows = Map<String, String>.from(snapshot['rows'] as Map);
  }
}

void main() {
  test('P1-033_AC2_semver_reset_is_deleted', () {
    final source = File('lib/providers/auth_provider.dart').readAsStringSync();
    expect(source.contains('lastSeenSemver'), isFalse);
    expect(source.contains('App semver changed'), isFalse);
    expect(source.contains('PackageInfo'), isFalse);
  });

  test('P1-033_AC3_ordered_migrations_run_once', () async {
    final store = _MemoryStore(0, {'keep': 'original'});
    final seen = <int>[];
    final migrator = LocalSchemaMigrator(
      targetVersion: 2,
      steps: {
        1: (store) async {
          seen.add(1);
          (store as _MemoryStore).rows['a'] = '1';
        },
        2: (store) async {
          seen.add(2);
          (store as _MemoryStore).rows['b'] = '2';
        },
      },
    );
    await migrator.migrate(store);
    expect(seen, [1, 2]);
    expect(store.schemaVersion, 2);

    await migrator.migrate(store);
    expect(seen, [1, 2]);
    expect(store.rows['keep'], 'original');
  });

  test('P1-033_AC4_failed_migration_restores_original_data', () async {
    final store = _MemoryStore(1, {'keep': 'original'});
    final migrator = LocalSchemaMigrator(
      targetVersion: 2,
      steps: {
        2: (store) async {
          (store as _MemoryStore).rows['keep'] = 'changed';
          throw StateError('disk');
        },
      },
    );
    await expectLater(
      migrator.migrate(store),
      throwsA(
        isA<SchemaMigrationFailure>()
            .having((failure) => failure.code, 'code', 'schema_migration_failed')
            .having((failure) => failure.recoveryMessage, 'message', contains('left unchanged')),
      ),
    );
    expect(store.schemaVersion, 1);
    expect(store.rows['keep'], 'original');
  });
}
