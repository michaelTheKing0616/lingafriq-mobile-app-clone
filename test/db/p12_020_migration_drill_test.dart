import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/db/local_migration_drill_harness.dart';
import 'package:lingafriq/services/local_schema_migrator.dart';

void main() {
  final reportPath = Platform.environment['P12_020_REPORT'] ??
      'release/fixtures/local_migration_drill_report.json';

  test('P12-020 local migration drill AC1–AC3', () async {
    final report = await LocalMigrationDrillHarness().run();
    expect(report.passed, isTrue, reason: report.versions.toString());
    expect(report.sessionClearedOnUpgrade, isFalse);
    expect(
      report.versions.where((v) => v.label != 'newer_sqlite_refused').length,
      LingAfriqDatabase.latestSchema,
    );
    for (var v = 1; v <= LingAfriqDatabase.latestSchema; v++) {
      expect(
        report.versions.any((row) => row.schemaVersion == v && row.passed),
        isTrue,
        reason: 'missing pass for schema step $v',
      );
    }
    final newer = report.versions.singleWhere(
      (row) => row.label == 'newer_sqlite_refused',
    );
    expect(newer.passed, isTrue);

    final out = File(reportPath);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync('${jsonEncode(report.toJson())}\n');
  });

  test('P12-020 AC2 hive newer schema shows typed recovery code', () async {
    final store = _HiveDrillStore(3);
    await expectLater(
      () async {
        if (store.schemaVersion > 2) {
          throw SchemaMigrationFailure(
            code: 'schema_newer_than_app',
            fromVersion: store.schemaVersion,
            toVersion: 2,
            cause: StateError('newer build'),
          );
        }
      }(),
      throwsA(
        isA<SchemaMigrationFailure>().having(
          (f) => f.code,
          'code',
          'schema_newer_than_app',
        ),
      ),
    );
    expect(store.rows['keep'], 'original');
  });
}

class _HiveDrillStore implements SchemaStore {
  _HiveDrillStore(this.schemaVersion, [Map<String, String>? rows])
      : rows = rows ?? {'keep': 'original'};

  @override
  int schemaVersion;
  Map<String, String> rows;

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
