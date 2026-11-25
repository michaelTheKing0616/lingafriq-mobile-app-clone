import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/hybrid_polie/polie_context_builder.dart';
import 'package:lingafriq/services/learning/knowledge_graph_queries.dart';
import 'package:lingafriq/services/learning/knowledge_graph_service.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';
import 'package:lingafriq/services/learning/session_builder.dart';

void main() {
  final now = DateTime.utc(2026, 1, 10);

  test('due and weak nodes are ranked by recall, then error count', () {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final queries = KnowledgeGraphQueries(KnowledgeGraphService(db));
    final graph = KnowledgeGraph(
      userId: 'learner-secret',
      language: 'yo',
      nodes: [
        _node(id: 'strong', stability: 40, errors: 0, at: DateTime.utc(2026, 1, 9)),
        _node(id: 'tied-more', stability: 2, errors: 4, at: DateTime.utc(2026, 1, 1)),
        _node(id: 'tied-less', stability: 2, errors: 1, at: DateTime.utc(2026, 1, 1)),
        _node(id: 'fresh', stability: 30, errors: 2, at: DateTime.utc(2026, 1, 9, 23)),
      ],
    );

    final result = queries.rank(graph, now: now);
    expect(result.ranked.map((node) => node.nodeId).toList(), [
      'tied-more',
      'tied-less',
      'fresh',
    ]);
    expect(result.due.map((node) => node.nodeId), containsAll(['tied-more', 'tied-less']));
    expect(result.weak.map((node) => node.nodeId), isNot(contains('strong')));
  });

  test('the session builder returns that same ranked list', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final graphs = KnowledgeGraphService(db);
    final queries = KnowledgeGraphQueries(graphs);
    final builder = SessionBuilder(queries);
    await graphs.record('learner-1', _event('old', 'bawo', DateTime.utc(2026, 1, 1)));
    await graphs.record(
      'learner-1',
      _event('err', 'ile', DateTime.utc(2026, 1, 9), error: 'tone', correct: false, rating: 'again'),
    );

    final plan = await builder.build(userId: 'learner-1', language: 'yo', now: now);
    final direct = await queries.dueAndWeak(userId: 'learner-1', language: 'yo', now: now);
    expect(plan.isEmpty, isFalse);
    expect(plan.items.map((node) => node.key), direct.ranked.map((node) => node.key));
    for (var i = 1; i < plan.items.length; i++) {
      final previous = queries.recallAt(plan.items[i - 1], now);
      final current = queries.recallAt(plan.items[i], now);
      expect(previous, lessThanOrEqualTo(current));
    }
  });

  test('Polie context keeps the configured weak items and no learner id', () {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final queries = KnowledgeGraphQueries(KnowledgeGraphService(db));
    final graph = KnowledgeGraph(
      userId: 'learner-secret',
      language: 'yo',
      nodes: [
        _node(id: 'a', stability: 2, errors: 3, at: DateTime.utc(2026, 1, 1)),
        _node(id: 'b', stability: 2, errors: 1, at: DateTime.utc(2026, 1, 1)),
        _node(id: 'c', stability: 3, errors: 1, at: DateTime.utc(2026, 1, 2)),
      ],
    );
    final context = PolieContextBuilder(maxWeakItems: 2).build(
      queries.rank(graph, now: now),
      language: 'yo',
    );

    expect(context.items, hasLength(2));
    expect(context.items.map((item) => item.nodeId), ['a', 'b']);
    expect(context.items.first.struggle, 'tone');
    expect(context.items.first.promptLine, contains('recycle it'));
    final encoded = jsonEncode(context.toJson());
    expect(encoded, isNot(contains('learner-secret')));
    expect(encoded, isNot(contains('audio')));
  });

  test('an empty graph is an explicit empty result', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final queries = KnowledgeGraphQueries(KnowledgeGraphService(db));
    final plan = await SessionBuilder(queries).build(userId: 'learner-1', language: 'yo', now: now);
    final result = await queries.dueAndWeak(userId: 'learner-1', language: 'yo', now: now);
    final context = PolieContextBuilder().build(result, language: 'yo');

    expect(result.isEmpty, isTrue);
    expect(result.due, isEmpty);
    expect(result.weak, isEmpty);
    expect(plan.isEmpty, isTrue);
    expect(plan.items, isEmpty);
    expect(context.isEmpty, isTrue);
  });
}

KnowledgeNode _node({
  required String id,
  required double stability,
  required int errors,
  required DateTime at,
}) {
  return KnowledgeNode(
    userId: 'learner-secret',
    language: 'yo',
    nodeId: id,
    kind: KnowledgeKind.lexeme,
    sense: null,
    stability: stability,
    difficulty: 5,
    retrievability: 1,
    phase: 'review',
    step: null,
    lastEvidence: at,
    productionCorrect: 1,
    productionAttempts: 1,
    recognitionCorrect: 0,
    recognitionAttempts: 0,
    toneErrors: errors,
    segmentalErrors: 0,
    wordOrderErrors: 0,
    registerErrors: 0,
  );
}

LearningEvent _event(
  String id,
  String nodeId,
  DateTime at, {
  String? error,
  bool correct = true,
  String rating = 'good',
}) {
  return LearningEvent(
    clientEventId: id,
    source: 'lesson_item',
    eventTime: at,
    language: 'yo',
    payload: {
      'nodeId': nodeId,
      'kind': 'lexeme',
      'rating': rating,
      'channel': 'production',
      'correct': correct,
      if (error != null) 'error': error,
    },
  );
}
