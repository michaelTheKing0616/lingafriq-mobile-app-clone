import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/db/migrations/local_sql.dart';

void main() {
  test('migrations run in order and saved rows stay readable', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);

    await db.customSelect('SELECT review_due FROM vocabulary').get();
    await db.customSelect('SELECT id FROM point_and_say').get();
    await storeVocabularyPayload(db, {
      'id': 'yo-1',
      'word': 'Ẹ kú',
      'translation': 'hello',
      'language': 'yo',
      'sourceMediaId': 'media-9',
      'sourceStartMs': 100,
      'sourceEndMs': 1200,
      'nextReviewDate': '2020-01-01T00:00:00.000Z',
    });
    await storeLessonPayload(db, {
      'id': 'lesson-1',
      'title': 'Greetings',
      'content': 'Ẹ kú',
      'language': 'yo',
      'level': 'A1',
      'downloadedAt': '2020-01-01T00:00:00.000Z',
    });
    await storeProgressPayload(db, {
      'id': 'progress-1',
      'type': 'review',
      'language': 'yo',
      'completedAt': '2020-01-02T00:00:00.000Z',
    });
    await storeMediaPayload(db, {
      'url': 'https://example.test/a.opus',
      'localPath': '/tmp/a.opus',
      'mimeType': 'audio/opus',
      'cachedAt': '2020-01-01T00:00:00.000Z',
    });
    await storePointAndSayPayload(db, {
      'id': 'queue-1',
      'language': 'yo',
      'expectedText': 'Ẹ kú',
      'audioPath': '/tmp/say.m4a',
    });

    final stored = await readVocabularyPayload(db, 'yo-1');
    expect(stored?['word'], 'Ẹ kú');
    expect(stored?['sourceMediaId'], 'media-9');
    expect(stored?['sourceEndMs'], 1200);
    expect((await readPayloads(db, 'lessons')).single['title'], 'Greetings');
    expect((await readPayloads(db, 'progress')).single['type'], 'review');
    expect((await readPayloads(db, 'media_cache')).single['localPath'], '/tmp/a.opus');
    expect((await readPayloads(db, 'point_and_say')).single['expectedText'], 'Ẹ kú');
    expect(db.clearsSessionOnUpgrade, isFalse);
    expect(db.schemaVersion, LingAfriqDatabase.latestSchema);

    await applyMigrationStep(db, 2);
    await applyMigrationStep(db, 3);
    expect((await readVocabularyPayload(db, 'yo-1'))?['sourceMediaId'], 'media-9');
  });

  test('a failed step rolls the new table back', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();

    try {
      await db.transaction(() async {
        await db.customStatement('CREATE TABLE rollback_probe (id INTEGER)');
        throw StateError('migration failed');
      });
    } catch (error) {
      expect('$error', contains('migration failed'));
    }

    expect(
      db.customSelect('SELECT id FROM rollback_probe').get(),
      throwsA(predicate((error) => '$error'.contains('rollback_probe'))),
    );
  });

  test('a failed upgrade stays on the previous schema and the row stays readable', () async {
    final file = File(
      '${Directory.systemTemp.path}/lingafriq-migrate-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() async {
      if (file.existsSync()) file.deleteSync();
    });

    final v1 = _SchemaV1Database(NativeDatabase(file));
    await v1.customInsert(
      'INSERT INTO vocabulary (id, word, translation, language, payload) VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable.withString('yo-1'),
        Variable.withString('Ẹ kú'),
        Variable.withString('hello'),
        Variable.withString('yo'),
        Variable.withString(
          '{"id":"yo-1","word":"Ẹ kú","translation":"hello","language":"yo","sourceMediaId":"media-9"}',
        ),
      ],
    );
    await v1.close();

    final failing = LingAfriqDatabase(NativeDatabase(file), failAtStep: 2);
    await expectLater(
      failing.customSelect('SELECT 1').get(),
      throwsA(isA<DriftMigrationFailure>()),
    );
    await failing.close();

    final stillV1 = _SchemaV1Database(NativeDatabase(file));
    final version = await stillV1.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);
    final columns = await stillV1.customSelect('PRAGMA table_info(vocabulary)').get();
    expect(columns.any((row) => row.read<String>('name') == 'review_due'), isFalse);
    final payload = await stillV1.customSelect('SELECT payload FROM vocabulary').getSingle();
    expect(payload.read<String>('payload'), contains('media-9'));
    await stillV1.close();

    final upgraded = LingAfriqDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final stored = await readVocabularyPayload(upgraded, 'yo-1');
    expect(stored?['sourceMediaId'], 'media-9');
    final now = await upgraded.customSelect('PRAGMA user_version').getSingle();
    expect(now.read<int>('user_version'), LingAfriqDatabase.latestSchema);
    await upgraded.customSelect('SELECT id FROM point_and_say').get();
  });
}

class _SchemaV1Database extends GeneratedDatabase {
  _SchemaV1Database(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await customStatement(createLessons);
          await customStatement(createVocabulary);
          await customStatement(createProgress);
          await customStatement(createMediaCache);
        },
      );
}
