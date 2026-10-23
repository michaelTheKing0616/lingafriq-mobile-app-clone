import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';

import 'helpers/mock_backend.dart';

/// A named step failed. CI shows this name.
class StepFailure implements Exception {
  StepFailure(this.step, this.cause);

  final String step;
  final Object cause;

  @override
  String toString() => 'step:$step $cause';
}

Future<T> step<T>(String name, Future<T> Function() body) async {
  try {
    return await body();
  } catch (error) {
    if (error is StepFailure) rethrow;
    throw StepFailure(name, error);
  }
}

void main() {
  test('onboarding, first lesson, and sync', () async {
    final directory = await Directory.systemTemp.createTemp('p2-022-');
    final file = File('${directory.path}/lingafriq.sqlite');
    final backend = MockLearningBackend();
    await backend.start();
    addTearDown(() async {
      await backend.close();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final log = LearningEventLog();
    await step('onboarding', () async {
      final db = LingAfriqDatabase(NativeDatabase(file));
      await storeProgressPayload(db, {
        'id': 'onboarding',
        'complete': true,
        'language': 'yoruba',
      });
      await db.close();
    });

    await step('first_lesson', () async {
      final db = LingAfriqDatabase(NativeDatabase(file));
      await storeLessonPayload(db, {'id': 'lesson-1', 'language': 'yoruba', 'title': 'Greetings'});
      await storeProgressPayload(db, {
        'id': 'lesson-1',
        'complete': true,
        'offline': true,
      });
      log.apply(LearningEvent(
        clientEventId: 'lesson-1-complete',
        source: 'lesson_item',
        eventTime: DateTime.utc(2026, 1, 2),
        language: 'yoruba',
      ));
      log.apply(LearningEvent(
        clientEventId: 'onboarding-complete',
        source: 'lesson_item',
        eventTime: DateTime.utc(2026, 1, 1),
        language: 'yoruba',
      ));
      final payload = jsonEncode({'events': log.orderedForSync()});
      await db.customInsert(
        'INSERT INTO outbox (id, idempotency_key, state, next_attempt_at, attempts, payload) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString('outbox-1'),
          Variable.withString('learning_event:fresh-install'),
          Variable.withString('pending'),
          Variable<int>(0),
          Variable.withInt(0),
          Variable.withString(payload),
        ],
      );
      await db.close();
    });

    await step('persist', () async {
      final db = LingAfriqDatabase(NativeDatabase(file));
      final onboarding = await readPayloads(db, 'progress', whereColumn: 'id', whereValue: 'onboarding');
      final lesson = await readPayloads(db, 'progress', whereColumn: 'id', whereValue: 'lesson-1');
      expect(onboarding.single['complete'], isTrue);
      expect(lesson.single['offline'], isTrue);
      final queued = await db.customSelect(
        'SELECT payload FROM outbox WHERE idempotency_key = ?',
        variables: [Variable.withString('learning_event:fresh-install')],
      ).get();
      expect(queued, hasLength(1));
      await db.close();
    });

    await step('sync', () async {
      final client = HttpClient();
      Future<Map<String, dynamic>> post() async {
        final request = await client.postUrl(backend.eventsUri);
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode({'events': log.orderedForSync()})));
        final response = await request.close();
        final raw = await utf8.decoder.bind(response).join();
        if (response.statusCode != 200) {
          throw StateError('status ${response.statusCode} $raw');
        }
        return jsonDecode(raw) as Map<String, dynamic>;
      }

      final first = await post();
      final second = await post();
      client.close(force: true);
      expect(first['applied'], 2);
      expect(second['applied'], 0);
      expect(backend.events.length, 2);
      expect(backend.events.keys.toList(), ['onboarding-complete', 'lesson-1-complete']);

      final db = LingAfriqDatabase(NativeDatabase(file));
      await db.customUpdate(
        'DELETE FROM outbox WHERE idempotency_key = ?',
        variables: [Variable.withString('learning_event:fresh-install')],
      );
      final left = await db.customSelect('SELECT id FROM outbox').get();
      expect(left, isEmpty);
      await db.close();
    });
  });
}
