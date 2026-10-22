import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'migrations/local_sql.dart';

/// Drift is the local database. A version change does not clear the session.
class LingAfriqDatabase extends GeneratedDatabase {
  LingAfriqDatabase(super.executor);

  LingAfriqDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await applyMigrationStep(this, 1);
          await applyMigrationStep(this, 2);
        },
        onUpgrade: (migrator, from, to) async {
          for (var version = from + 1; version <= to; version++) {
            await applyMigrationStep(this, version);
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
      await db.customStatement(addReviewDue);
      break;
    default:
      throw StateError('missing migration to schema $version');
  }
}

Future<void> storeVocabularyPayload(
  LingAfriqDatabase db,
  Map<String, dynamic> row,
) async {
  final payload = jsonEncode(row);
  await db.customInsert(
    'INSERT INTO vocabulary (id, word, translation, language, payload, review_due) VALUES (?, ?, ?, ?, ?, ?)',
    variables: [
      Variable.withString('${row['id']}'),
      Variable.withString('${row['word']}'),
      Variable.withString('${row['translation']}'),
      Variable.withString('${row['language']}'),
      Variable.withString(payload),
      Variable<int>(row['sourceEndMs'] as int?),
    ],
  );
}

Future<Map<String, Object?>?> readVocabularyPayload(LingAfriqDatabase db, String id) async {
  final rows = await db.customSelect(
    'SELECT payload FROM vocabulary WHERE id = ?',
    variables: [Variable.withString(id)],
  ).get();
  if (rows.isEmpty) return null;
  final decoded = jsonDecode(rows.single.read<String>('payload'));
  return Map<String, Object?>.from(decoded as Map);
}
