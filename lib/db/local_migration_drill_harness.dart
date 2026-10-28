import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_database.dart';
import 'migrations/local_sql.dart';
import 'schema_version_policy.dart';

/// P12-020: rehearse upgrade paths and newer-schema refusal without touching prod files.
class LocalMigrationDrillHarness {
  LocalMigrationDrillHarness({this.latestSchema = LingAfriqDatabase.latestSchema});

  final int latestSchema;

  static const drillVocabularyId = 'drill-yo-1';
  static final Map<String, dynamic> drillVocabularyRow = {
    'id': drillVocabularyId,
    'word': 'Ẹ kú',
    'translation': 'hello',
    'language': 'yo',
    'sourceMediaId': 'media-drill-9',
    'sourceStartMs': 100,
    'sourceEndMs': 1200,
    'nextReviewDate': '2020-01-01T00:00:00.000Z',
  };

  Future<LocalMigrationDrillReport> run() async {
    final versions = <MigrationVersionResult>[];
    for (var target = 1; target <= latestSchema; target++) {
      versions.add(await _exerciseUpgradeFrom(target - 1));
    }
    versions.add(await _exerciseNewerSqliteSchema());
    final passed = versions.every((row) => row.passed);
    return LocalMigrationDrillReport(
      testedAt: DateTime.now().toUtc(),
      latestSchema: latestSchema,
      passed: passed,
      versions: versions,
      sessionClearedOnUpgrade: false,
    );
  }

  Future<MigrationVersionResult> _exerciseUpgradeFrom(int fromVersion) async {
    final label = fromVersion == 0
        ? 'create→$latestSchema'
        : '$fromVersion→$latestSchema';
    final file = File(
      '${Directory.systemTemp.path}/lingafriq-drill-$fromVersion-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    try {
      if (fromVersion == 0) {
        final db = LingAfriqDatabase(NativeDatabase(file));
        await db.customSelect('SELECT 1').get();
        await storeVocabularyPayload(db, drillVocabularyRow);
        await db.close();
      } else {
        final partial = _SchemaCapDatabase(NativeDatabase(file), fromVersion);
        await partial.customSelect('SELECT 1').get();
        await _seedVocabulary(partial, drillVocabularyRow, partial.maxVersion);
        await partial.close();
      }

      final upgraded = LingAfriqDatabase(NativeDatabase(file));
      await upgraded.customSelect('SELECT 1').get();
      final stored = await readVocabularyPayload(upgraded, drillVocabularyId);
      final versionRow =
          await upgraded.customSelect('PRAGMA user_version').getSingle();
      final userVersion = versionRow.read<int>('user_version');
      final sessionOk = !upgraded.clearsSessionOnUpgrade;
      await upgraded.close();

      final ok = stored?['sourceMediaId'] == 'media-drill-9' &&
          userVersion == latestSchema &&
          sessionOk;
      return MigrationVersionResult(
        schemaVersion: fromVersion + 1,
        label: label,
        passed: ok,
        detail: ok ? null : 'payload or user_version mismatch',
      );
    } catch (error) {
      return MigrationVersionResult(
        schemaVersion: fromVersion + 1,
        label: label,
        passed: false,
        detail: '$error',
      );
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }

  Future<MigrationVersionResult> _exerciseNewerSqliteSchema() async {
    const futureVersion = LingAfriqDatabase.latestSchema + 1;
    final file = File(
      '${Directory.systemTemp.path}/lingafriq-drill-newer-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    try {
      final seed = _SchemaCapDatabase(NativeDatabase(file), latestSchema);
      await seed.customSelect('SELECT 1').get();
      await _seedVocabulary(seed, drillVocabularyRow, latestSchema);
      final payloadBefore = await _readRawPayloadFromDb(seed, drillVocabularyId);
      await seed.customStatement('PRAGMA user_version = $futureVersion');
      await seed.close();

      try {
        final db = LingAfriqDatabase(NativeDatabase(file));
        await db.customSelect('SELECT 1').get();
        await db.close();
        return MigrationVersionResult(
          schemaVersion: futureVersion,
          label: 'newer_sqlite_refused',
          passed: false,
          detail: 'expected open refusal for newer schema',
        );
      } catch (_) {
        final payloadAfter = _readSqlitePayload(file, drillVocabularyId);
        final versionAfter = _readSqliteUserVersion(file);
        final ok = payloadBefore == payloadAfter &&
            payloadBefore.contains('media-drill-9') &&
            versionAfter == futureVersion;
        return MigrationVersionResult(
          schemaVersion: futureVersion,
          label: 'newer_sqlite_refused',
          passed: ok,
          detail: ok ? null : 'sqlite payload or user_version was mutated',
        );
      }
    } catch (error) {
      return MigrationVersionResult(
        schemaVersion: futureVersion,
        label: 'newer_sqlite_refused',
        passed: false,
        detail: '$error',
      );
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }

  Future<void> _seedVocabulary(
    GeneratedDatabase db,
    Map<String, dynamic> row,
    int schemaAtSeed,
  ) async {
    final payload = jsonEncode(row);
    if (schemaAtSeed < 2) {
      await db.customInsert(
        'INSERT INTO vocabulary (id, word, translation, language, payload) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withString('${row['id']}'),
          Variable.withString('${row['word']}'),
          Variable.withString('${row['translation']}'),
          Variable.withString('${row['language']}'),
          Variable.withString(payload),
        ],
      );
      return;
    }
    await db.customInsert(
      'INSERT INTO vocabulary (id, word, translation, language, payload, review_due) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString('${row['id']}'),
        Variable.withString('${row['word']}'),
        Variable.withString('${row['translation']}'),
        Variable.withString('${row['language']}'),
        Variable.withString(payload),
        Variable<int>(reviewDueMillis(row)),
      ],
    );
  }

  Future<String> _readRawPayloadFromDb(GeneratedDatabase db, String id) async {
    final row = await db.customSelect(
      'SELECT payload FROM vocabulary WHERE id = ?',
      variables: [Variable.withString(id)],
    ).getSingleOrNull();
    return row?.read<String>('payload') ?? '';
  }

  String _readSqlitePayload(File file, String id) {
    final db = sqlite3.open(file.path);
    try {
      final rows = db.select(
        'SELECT payload FROM vocabulary WHERE id = ?',
        [id],
      );
      if (rows.isEmpty) return '';
      return rows.first.columnAt(0) as String;
    } finally {
      db.dispose();
    }
  }

  int _readSqliteUserVersion(File file) {
    final db = sqlite3.open(file.path);
    try {
      final rows = db.select('PRAGMA user_version');
      return rows.first.columnAt(0) as int;
    } finally {
      db.dispose();
    }
  }
}

class LocalMigrationDrillReport {
  LocalMigrationDrillReport({
    required this.testedAt,
    required this.latestSchema,
    required this.passed,
    required this.versions,
    required this.sessionClearedOnUpgrade,
  });

  final DateTime testedAt;
  final int latestSchema;
  final bool passed;
  final List<MigrationVersionResult> versions;
  final bool sessionClearedOnUpgrade;

  Map<String, dynamic> toJson() => {
        'card': 'P12-020',
        'tested_at': testedAt.toIso8601String(),
        'latest_schema': latestSchema,
        'passed': passed,
        'session_cleared_on_upgrade': sessionClearedOnUpgrade,
        'versions': versions.map((v) => v.toJson()).toList(),
      };
}

class MigrationVersionResult {
  MigrationVersionResult({
    required this.schemaVersion,
    required this.label,
    required this.passed,
    this.detail,
  });

  final int schemaVersion;
  final String label;
  final bool passed;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'label': label,
        'passed': passed,
        if (detail != null) 'detail': detail,
      };
}

class _SchemaCapDatabase extends GeneratedDatabase {
  _SchemaCapDatabase(super.executor, this.maxVersion);

  final int maxVersion;

  @override
  int get schemaVersion => maxVersion;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          for (var step = 1; step <= maxVersion; step++) {
            await applyMigrationStep(this, step);
          }
        },
      );
}

