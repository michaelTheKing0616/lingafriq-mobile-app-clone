import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/knowledge_graph_service.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

void main() {
  const user = 'learner-1';
  final firstAt = DateTime.utc(2026, 1, 1);
  final secondAt = DateTime.utc(2026, 1, 2);

  test('one graph holds a lexeme, a pattern, and a phonological skill', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    await service.record(user, _evidence(id: 'lex', kind: 'lexeme', nodeId: 'bawo', at: firstAt));
    await service.record(
      user,
      _evidence(id: 'pat', kind: 'grammar_pattern', nodeId: 'ni-focus', at: firstAt),
    );
    await service.record(
      user,
      _evidence(id: 'pho', kind: 'phonological_skill', nodeId: 'low-tone', at: firstAt),
    );

    final graphs = await service.graphs(user);
    expect(graphs, hasLength(1));
    expect(graphs.single.language, 'yo');
    expect(
      graphs.single.nodes.map((node) => node.kind).toSet(),
      {
        KnowledgeKind.lexeme,
        KnowledgeKind.grammarPattern,
        KnowledgeKind.phonologicalSkill,
      },
    );
  });

  test('evidence updates strength, last evidence, and FSRS state', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    const scheduler = Fsrs6Scheduler();
    final service = KnowledgeGraphService(db, scheduler: scheduler);
    await service.record(
      user,
      _evidence(id: 'a', nodeId: 'bawo', rating: 'good', channel: 'production', at: firstAt),
    );
    await service.record(
      user,
      _evidence(
        id: 'b',
        nodeId: 'bawo',
        rating: 'again',
        channel: 'production',
        correct: false,
        at: secondAt,
      ),
    );

    final node = (await service.load(user, 'yo')).nodes.single;
    final first = scheduler.review(const MemoryState(), FsrsRating.good, firstAt);
    final second = scheduler.review(first, FsrsRating.again, secondAt);
    expect(node.stability, closeTo(second.stability!, 1e-9));
    expect(node.difficulty, closeTo(second.difficulty!, 1e-9));
    expect(node.retrievability, inInclusiveRange(0, 1));
    expect(node.lastEvidence, secondAt);
    expect(node.productionStrength, 0.5);
    expect(node.recognitionStrength, 0);
    expect(node.phase, second.phase.name);
  });

  test('only the named error counter increments', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    await service.record(
      user,
      _evidence(id: 'tone', nodeId: 'bawo', error: 'tone', correct: false, rating: 'again'),
    );
    final node = (await service.load(user, 'yo')).nodes.single;
    expect(node.errorCount(ErrorKind.tone), 1);
    expect(node.errorCount(ErrorKind.segmental), 0);
    expect(node.errorCount(ErrorKind.wordOrder), 0);
    expect(node.errorCount(ErrorKind.register), 0);

    await service.record(
      user,
      _evidence(
        id: 'order',
        nodeId: 'bawo',
        error: 'word_order',
        correct: false,
        rating: 'again',
        at: secondAt,
      ),
    );
    final again = (await service.load(user, 'yo')).nodes.single;
    expect(again.errorCount(ErrorKind.tone), 1);
    expect(again.errorCount(ErrorKind.wordOrder), 1);
    expect(again.errorCount(ErrorKind.segmental), 0);
    expect(again.errorCount(ErrorKind.register), 0);
  });

  test('rebuilding the same log matches the stored graph', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    final later = _evidence(id: 'later', nodeId: 'bawo', at: secondAt, error: 'register');
    final earlier = _evidence(id: 'earlier', nodeId: 'bawo', at: firstAt, channel: 'recognition');
    await service.record(user, later);
    await service.record(user, earlier);
    await service.record(user, earlier);

    final stored = await service.load(user, 'yo');
    final rebuilt = service.project(user, 'yo', [later, earlier, earlier]);
    expect(jsonEncode(rebuilt.toJson()), jsonEncode(stored.toJson()));
    expect(stored.nodes.single.toneErrors, 0);
    expect(stored.nodes.single.registerErrors, 1);
    expect(stored.nodes.single.recognitionAttempts, 1);
  });

  test('a stored node does not keep raw audio', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    await service.record(
      user,
      LearningEvent(
        clientEventId: 'audio',
        source: 'pronunciation_attempt',
        eventTime: firstAt,
        language: 'yo',
        payload: {
          'nodeId': 'bawo',
          'kind': 'lexeme',
          'rating': 'good',
          'channel': 'production',
          'correct': true,
          'audioBytes': 'secret-bytes',
        },
      ),
    );
    final rows = await db.customSelect('SELECT payload FROM knowledge_graph_events').get();
    expect(rows.single.read<String>('payload'), isNot(contains('secret-bytes')));
    final nodes = await db.customSelect('SELECT payload FROM knowledge_nodes').get();
    expect(nodes.single.read<String>('payload'), isNot(contains('secret-bytes')));
  });

  test('an unknown error label fails loudly', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    expect(
      () => service.record(user, _evidence(id: 'bad', nodeId: 'bawo', error: 'spelling')),
      throwsArgumentError,
    );
  });

  test('two senses of one lexeme stay two nodes', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final service = KnowledgeGraphService(db);
    await service.record(user, _evidence(id: 's1', nodeId: 'owo', sense: 'money'));
    await service.record(user, _evidence(id: 's2', nodeId: 'owo', sense: 'hand', at: secondAt));
    final graph = await service.load(user, 'yo');
    expect(graph.nodes, hasLength(2));
    expect(graph.nodes.map((node) => node.sense).toSet(), {'money', 'hand'});
  });
}

LearningEvent _evidence({
  required String id,
  required String nodeId,
  String kind = 'lexeme',
  String rating = 'good',
  String channel = 'production',
  bool correct = true,
  String? error,
  String? sense,
  DateTime? at,
  String language = 'yo',
}) {
  return LearningEvent(
    clientEventId: id,
    source: 'lesson_item',
    eventTime: at ?? DateTime.utc(2026, 1, 1),
    language: language,
    payload: {
      'nodeId': nodeId,
      'kind': kind,
      'rating': rating,
      'channel': channel,
      'correct': correct,
      if (error != null) 'error': error,
      if (sense != null) 'sense': sense,
    },
  );
}
