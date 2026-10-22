import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';

void main() {
  test('migrations run in order and a saved row stays readable', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);

    await db.customSelect('SELECT review_due FROM vocabulary').get();
    await storeVocabularyPayload(db, {
      'id': 'yo-1',
      'word': 'Ẹ kú',
      'translation': 'hello',
      'language': 'yo',
      'sourceMediaId': 'media-9',
      'sourceEndMs': 1200,
    });

    final stored = await readVocabularyPayload(db, 'yo-1');
    expect(stored?['word'], 'Ẹ kú');
    expect(stored?['sourceMediaId'], 'media-9');
    expect(db.clearsSessionOnUpgrade, isFalse);
    expect(db.schemaVersion, 2);
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
}
