import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

/// Projects one knowledge graph per learner and language from learning events.
///
/// Strength is correct answers divided by attempts on that channel. The same
/// events in any order rebuild the same nodes, because the fold sorts by time
/// and then client id and ignores a repeated id.
class KnowledgeGraphService {
  KnowledgeGraphService(this._db, {Fsrs6Scheduler? scheduler})
      : _scheduler = scheduler ?? const Fsrs6Scheduler();

  final LingAfriqDatabase _db;
  final Fsrs6Scheduler _scheduler;

  static const _audioKeys = {'audio', 'audioBytes', 'audioUrl'};

  Future<KnowledgeGraph> record(String userId, LearningEvent event) async {
    _requireUser(userId);
    _validate(event);
    final language = event.language!;
    await _db.transaction(() async {
      final already = await _db.customSelect(
        'SELECT client_event_id FROM knowledge_graph_events WHERE client_event_id = ?',
        variables: [Variable.withString(event.clientEventId)],
      ).get();
      if (already.isNotEmpty) return;
      await _db.customInsert(
        'INSERT INTO knowledge_graph_events '
        '(client_event_id, user_id, language, event_time, payload) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(event.clientEventId),
          Variable.withString(userId),
          Variable.withString(language),
          Variable.withInt(event.eventTime.toUtc().millisecondsSinceEpoch),
          Variable.withString(jsonEncode(_storedEvent(event))),
        ],
      );
      await _replaceNodes(userId, language, await _storedEvents(userId, language));
    });
    return load(userId, language);
  }

  Future<KnowledgeGraph> load(String userId, String language) async {
    final rows = await _db.customSelect(
      'SELECT payload FROM knowledge_nodes WHERE user_id = ? AND language = ?',
      variables: [
        Variable.withString(userId),
        Variable.withString(language),
      ],
    ).get();
    final nodes = rows.map((row) {
      final decoded = jsonDecode(row.read<String>('payload'));
      if (decoded is! Map) throw ArgumentError('knowledge node payload is not an object');
      return KnowledgeNode.fromJson(_stringMap(decoded));
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return KnowledgeGraph(userId: userId, language: language, nodes: nodes);
  }

  Future<List<KnowledgeGraph>> graphs(String userId) async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT language FROM knowledge_nodes WHERE user_id = ? ORDER BY language',
      variables: [Variable.withString(userId)],
    ).get();
    final found = <KnowledgeGraph>[];
    for (final row in rows) {
      found.add(await load(userId, row.read<String>('language')));
    }
    return found;
  }

  /// Pure fold. Used to prove a rebuild matches the rows [record] stored.
  KnowledgeGraph project(String userId, String language, List<LearningEvent> events) {
    _requireUser(userId);
    final nodes = <String, KnowledgeNode>{};
    for (final event in _orderedUnique(events)) {
      if (event.language != language) continue;
      if (!_isEvidence(event)) continue;
      final spec = _Evidence.parse(event);
      final key = nodeKey(spec.kind, spec.nodeId, spec.sense);
      nodes[key] = _advance(userId, language, nodes[key], spec, event.eventTime.toUtc());
    }
    final list = nodes.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    return KnowledgeGraph(userId: userId, language: language, nodes: list);
  }

  KnowledgeNode _advance(
    String userId,
    String language,
    KnowledgeNode? current,
    _Evidence spec,
    DateTime at,
  ) {
    final memory = current == null
        ? const MemoryState()
        : MemoryState(
            stability: current.stability,
            difficulty: current.difficulty,
            phase: FsrsPhase.values.byName(current.phase),
            step: current.step,
            lastReview: current.lastEvidence,
          );
    final updated = _scheduler.review(memory, spec.rating, at);
    final stability = updated.stability;
    final recall = stability == null
        ? 0.0
        : _scheduler.retrievability(elapsedDays: 0.0, stability: stability);
    var productionCorrect = current?.productionCorrect ?? 0;
    var productionAttempts = current?.productionAttempts ?? 0;
    var recognitionCorrect = current?.recognitionCorrect ?? 0;
    var recognitionAttempts = current?.recognitionAttempts ?? 0;
    if (spec.channel == 'production') {
      productionAttempts += 1;
      if (spec.correct) productionCorrect += 1;
    } else {
      recognitionAttempts += 1;
      if (spec.correct) recognitionCorrect += 1;
    }
    var tone = current?.toneErrors ?? 0;
    var segmental = current?.segmentalErrors ?? 0;
    var wordOrder = current?.wordOrderErrors ?? 0;
    var register = current?.registerErrors ?? 0;
    switch (spec.error) {
      case ErrorKind.tone:
        tone += 1;
      case ErrorKind.segmental:
        segmental += 1;
      case ErrorKind.wordOrder:
        wordOrder += 1;
      case ErrorKind.register:
        register += 1;
      case null:
        break;
    }
    return KnowledgeNode(
      userId: userId,
      language: language,
      nodeId: spec.nodeId,
      kind: spec.kind,
      sense: spec.sense,
      stability: stability,
      difficulty: updated.difficulty,
      retrievability: recall,
      phase: updated.phase.name,
      step: updated.step,
      lastEvidence: at,
      productionCorrect: productionCorrect,
      productionAttempts: productionAttempts,
      recognitionCorrect: recognitionCorrect,
      recognitionAttempts: recognitionAttempts,
      toneErrors: tone,
      segmentalErrors: segmental,
      wordOrderErrors: wordOrder,
      registerErrors: register,
    );
  }

  Future<void> _replaceNodes(
    String userId,
    String language,
    List<LearningEvent> events,
  ) async {
    final graph = project(userId, language, events);
    await _db.customUpdate(
      'DELETE FROM knowledge_nodes WHERE user_id = ? AND language = ?',
      variables: [
        Variable.withString(userId),
        Variable.withString(language),
      ],
    );
    for (final node in graph.nodes) {
      await _db.customInsert(
        'INSERT INTO knowledge_nodes (user_id, language, node_key, payload) VALUES (?, ?, ?, ?)',
        variables: [
          Variable.withString(userId),
          Variable.withString(language),
          Variable.withString(node.key),
          Variable.withString(jsonEncode(node.toJson())),
        ],
      );
    }
  }

  Future<List<LearningEvent>> _storedEvents(String userId, String language) async {
    final rows = await _db.customSelect(
      'SELECT payload FROM knowledge_graph_events WHERE user_id = ? AND language = ?',
      variables: [
        Variable.withString(userId),
        Variable.withString(language),
      ],
    ).get();
    return rows.map((row) {
      final decoded = jsonDecode(row.read<String>('payload'));
      if (decoded is! Map) throw ArgumentError('learning event payload is not an object');
      final json = _stringMap(decoded);
      final body = json['payload'];
      if (body is! Map) throw ArgumentError('learning event payload is not an object');
      return LearningEvent(
        clientEventId: json['clientEventId']! as String,
        source: json['source']! as String,
        eventTime: DateTime.parse(json['eventTime']! as String).toUtc(),
        language: json['language'] as String?,
        audioOptIn: json['audioOptIn'] == true,
        payload: _stringMap(body),
      );
    }).toList();
  }

  Map<String, Object?> _storedEvent(LearningEvent event) => {
        'clientEventId': event.clientEventId,
        'source': event.source,
        'eventTime': event.eventTime.toUtc().toIso8601String(),
        'language': event.language,
        'audioOptIn': event.audioOptIn,
        'payload': _withoutAudio(event.payload),
      };

  Map<String, Object?> _withoutAudio(Map<String, Object?> payload) {
    final copy = Map<String, Object?>.from(payload);
    copy.removeWhere((key, _) => _audioKeys.contains(key));
    return copy;
  }

  List<LearningEvent> _orderedUnique(List<LearningEvent> events) {
    final byId = <String, LearningEvent>{};
    for (final event in events) {
      byId.putIfAbsent(event.clientEventId, () => event);
    }
    final ordered = byId.values.toList()
      ..sort((a, b) {
        final byTime = a.eventTime.compareTo(b.eventTime);
        if (byTime != 0) return byTime;
        return a.clientEventId.compareTo(b.clientEventId);
      });
    return ordered;
  }

  bool _isEvidence(LearningEvent event) => event.payload.containsKey('nodeId');

  Map<String, Object?> _stringMap(Map raw) =>
      raw.map((key, value) => MapEntry(key.toString(), value));

  void _validate(LearningEvent event) {
    if (!learningEventSources.contains(event.source)) {
      throw ArgumentError('unknown learning event source');
    }
    if (event.clientEventId.isEmpty) {
      throw ArgumentError('client_event_id is required');
    }
    if (event.language == null || event.language!.isEmpty) {
      throw ArgumentError('language is required');
    }
    if (_isEvidence(event)) _Evidence.parse(event);
  }

  void _requireUser(String userId) {
    if (userId.isEmpty) throw ArgumentError('user id is required');
  }
}

class _Evidence {
  const _Evidence({
    required this.nodeId,
    required this.kind,
    required this.sense,
    required this.rating,
    required this.channel,
    required this.correct,
    required this.error,
  });

  final String nodeId;
  final KnowledgeKind kind;
  final String? sense;
  final FsrsRating rating;
  final String channel;
  final bool correct;
  final ErrorKind? error;

  static _Evidence parse(LearningEvent event) {
    final payload = event.payload;
    final nodeId = payload['nodeId'];
    if (nodeId is! String || nodeId.isEmpty) {
      throw ArgumentError('nodeId is required');
    }
    final kindRaw = payload['kind'];
    if (kindRaw is! String) throw ArgumentError('kind is required');
    final ratingRaw = payload['rating'];
    if (ratingRaw is! String) throw ArgumentError('rating is required');
    final channelRaw = payload['channel'];
    if (channelRaw is! String ||
        (channelRaw != 'production' && channelRaw != 'recognition')) {
      throw ArgumentError('channel must be production or recognition');
    }
    final correct = payload['correct'];
    if (correct is! bool) throw ArgumentError('correct must be true or false');
    String? sense;
    final senseRaw = payload['sense'];
    if (senseRaw != null) {
      if (senseRaw is! String) throw ArgumentError('sense must be a string');
      if (senseRaw.isNotEmpty) sense = senseRaw;
    }
    String? errorWire;
    final errorRaw = payload['error'];
    if (errorRaw != null) {
      if (errorRaw is! String) {
        throw ArgumentError('error must be a taxonomy label');
      }
      errorWire = errorRaw;
    }
    return _Evidence(
      nodeId: nodeId,
      kind: KnowledgeKind.parse(kindRaw),
      sense: sense,
      rating: _rating(ratingRaw),
      channel: channelRaw,
      correct: correct,
      error: errorWire == null ? null : ErrorKind.parse(errorWire),
    );
  }

  static FsrsRating _rating(String wire) {
    for (final rating in FsrsRating.values) {
      if (rating.name == wire) return rating;
    }
    throw ArgumentError('unknown FSRS rating: $wire');
  }
}
