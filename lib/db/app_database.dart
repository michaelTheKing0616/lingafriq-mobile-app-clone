import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'migrations/local_sql.dart';

/// A schema step failed. The surrounding transaction is rolled back and
/// SQLite `user_version` is left on the previous schema.
class DriftMigrationFailure implements Exception {
  const DriftMigrationFailure({
    required this.fromVersion,
    required this.toVersion,
    required this.cause,
  });

  final int fromVersion;
  final int toVersion;
  final Object cause;

  @override
  String toString() =>
      'DriftMigrationFailure($fromVersion -> $toVersion): $cause';
}

/// Drift is the local database. A version change does not clear the session.
class LingAfriqDatabase extends GeneratedDatabase {
  LingAfriqDatabase(super.executor, {this.failAtStep});

  LingAfriqDatabase.memory({this.failAtStep}) : super(NativeDatabase.memory());

  static const int latestSchema = 3;

  /// Test-only. When set, that step writes a probe row and then fails.
  final int? failAtStep;

  @override
  int get schemaVersion => latestSchema;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await transaction(() async {
            await applyMigrationStep(this, 1);
            await applyMigrationStep(this, 2);
            await applyMigrationStep(this, 3);
          });
        },
        onUpgrade: (migrator, from, to) async {
          try {
            await transaction(() async {
              for (var version = from + 1; version <= to; version++) {
                if (failAtStep == version) {
                  await customStatement(
                    'CREATE TABLE migration_probe (id INTEGER)',
                  );
                  throw StateError('migration failed');
                }
                await applyMigrationStep(this, version);
              }
            });
          } catch (error) {
            throw DriftMigrationFailure(
              fromVersion: from,
              toVersion: to,
              cause: error,
            );
          }
        },
      );

  /// An app update keeps the signed-in session. This stays false on purpose.
  bool get clearsSessionOnUpgrade => false;
}

Future<void> applyMigrationStep(GeneratedDatabase db, int version) async {
  switch (version) {
    case 1:
      await db.customStatement(createLessons);
      await db.customStatement(createVocabulary);
      await db.customStatement(createProgress);
      await db.customStatement(createMediaCache);
      break;
    case 2:
      final columns = await db.customSelect('PRAGMA table_info(vocabulary)').get();
      final hasReviewDue = columns.any((row) => row.read<String>('name') == 'review_due');
      if (!hasReviewDue) {
        await db.customStatement(addReviewDue);
      }
      break;
    case 3:
      await db.customStatement(createPointAndSay);
      break;
    default:
      throw StateError('missing migration to schema $version');
  }
}

int? reviewDueMillis(Map<String, dynamic> row) {
  final raw = row['nextReviewDate'];
  if (raw is String) return DateTime.tryParse(raw)?.millisecondsSinceEpoch;
  return null;
}

Future<void> storeVocabularyPayload(
  LingAfriqDatabase db,
  Map<String, dynamic> row,
) async {
  final payload = jsonEncode(row);
  await db.customInsert(
    'INSERT INTO vocabulary (id, word, translation, language, payload, review_due) '
    'VALUES (?, ?, ?, ?, ?, ?) '
    'ON CONFLICT(id) DO UPDATE SET '
    'word = excluded.word, translation = excluded.translation, '
    'language = excluded.language, payload = excluded.payload, '
    'review_due = excluded.review_due',
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

Future<void> storeLessonPayload(LingAfriqDatabase db, Map<String, dynamic> row) async {
  await _upsertPayload(db, 'lessons', 'id', '${row['id']}', row);
}

Future<void> storeProgressPayload(LingAfriqDatabase db, Map<String, dynamic> row) async {
  await _upsertPayload(db, 'progress', 'id', '${row['id']}', row);
}

Future<void> storeMediaPayload(LingAfriqDatabase db, Map<String, dynamic> row) async {
  await _upsertPayload(db, 'media_cache', 'url', '${row['url']}', row);
}

Future<void> storePointAndSayPayload(LingAfriqDatabase db, Map<String, dynamic> row) async {
  await _upsertPayload(db, 'point_and_say', 'id', '${row['id']}', row);
}

Future<void> deleteLocalRow(
  LingAfriqDatabase db,
  String table,
  String idColumn,
  String id,
) async {
  _assertTable(table);
  await db.customUpdate(
    'DELETE FROM $table WHERE $idColumn = ?',
    variables: [Variable.withString(id)],
  );
}

Future<Map<String, Object?>?> readVocabularyPayload(LingAfriqDatabase db, String id) async {
  final rows = await readPayloads(db, 'vocabulary', whereColumn: 'id', whereValue: id);
  if (rows.isEmpty) return null;
  return rows.single;
}

Future<List<Map<String, Object?>>> readPayloads(
  LingAfriqDatabase db,
  String table, {
  String? whereColumn,
  String? whereValue,
}) async {
  _assertTable(table);
  final query = whereColumn == null
      ? 'SELECT payload FROM $table'
      : 'SELECT payload FROM $table WHERE $whereColumn = ?';
  final rows = await db.customSelect(
    query,
    variables: whereColumn == null ? const [] : [Variable.withString(whereValue ?? '')],
  ).get();
  return rows.map((row) {
    final decoded = jsonDecode(row.read<String>('payload'));
    return Map<String, Object?>.from(decoded as Map);
  }).toList();
}

Future<void> _upsertPayload(
  LingAfriqDatabase db,
  String table,
  String idColumn,
  String id,
  Map<String, dynamic> row,
) async {
  _assertTable(table);
  await db.customInsert(
    'INSERT INTO $table ($idColumn, payload) VALUES (?, ?) '
    'ON CONFLICT($idColumn) DO UPDATE SET payload = excluded.payload',
    variables: [
      Variable.withString(id),
      Variable.withString(jsonEncode(row)),
    ],
  );
}

void _assertTable(String table) {
  const allowed = {'lessons', 'vocabulary', 'progress', 'media_cache', 'point_and_say'};
  if (!allowed.contains(table)) {
    throw ArgumentError('unknown local table $table');
  }
}
