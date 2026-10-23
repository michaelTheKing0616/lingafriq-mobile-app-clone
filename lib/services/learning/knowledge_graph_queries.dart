import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/knowledge_graph_service.dart';

/// Due and weak nodes for one learner and language.
///
/// Lower retrievability comes first. Equal recall is broken by a higher error
/// count. An empty graph is an empty result, not a missing one.
class KnowledgeGraphQueries {
  KnowledgeGraphQueries(
    this._graphs, {
    Fsrs6Scheduler? scheduler,
    this.weakRetrievability = 0.9,
  }) : _scheduler = scheduler ?? const Fsrs6Scheduler();

  final KnowledgeGraphService _graphs;
  final Fsrs6Scheduler _scheduler;
  final double weakRetrievability;

  Future<GraphQueryResult> dueAndWeak({
    required String userId,
    required String language,
    DateTime? now,
  }) async {
    if (userId.isEmpty) throw ArgumentError('user id is required');
    if (language.isEmpty) throw ArgumentError('language is required');
    final graph = await _graphs.load(userId, language);
    return rank(graph, now: now ?? DateTime.now().toUtc());
  }

  GraphQueryResult rank(KnowledgeGraph graph, {required DateTime now}) {
    final at = now.toUtc();
    final due = <KnowledgeNode>[];
    final weak = <KnowledgeNode>[];
    for (final node in graph.nodes) {
      if (isDue(node, at)) due.add(node);
      if (isWeak(node, at)) weak.add(node);
    }
    due.sort((a, b) => compare(a, b, at));
    weak.sort((a, b) => compare(a, b, at));
    final ranked = <KnowledgeNode>[];
    final seen = <String>{};
    final union = [...due, ...weak]..sort((a, b) => compare(a, b, at));
    for (final node in union) {
      if (seen.add(node.key)) ranked.add(node);
    }
    final recallByKey = {
      for (final node in graph.nodes) node.key: recallAt(node, at),
    };
    return GraphQueryResult(
      due: due,
      weak: weak,
      ranked: ranked,
      recallByKey: recallByKey,
    );
  }

  int compare(KnowledgeNode a, KnowledgeNode b, DateTime at) {
    final byRecall = recallAt(a, at).compareTo(recallAt(b, at));
    if (byRecall != 0) return byRecall;
    final byErrors = errorCount(b).compareTo(errorCount(a));
    if (byErrors != 0) return byErrors;
    return a.key.compareTo(b.key);
  }

  double recallAt(KnowledgeNode node, DateTime at) {
    final stability = node.stability;
    final last = node.lastEvidence;
    if (stability == null || stability <= 0 || last == null) return 0;
    final elapsed = at.difference(last).inSeconds / Duration.secondsPerDay;
    if (elapsed < 0) return 0;
    return _scheduler.retrievability(elapsedDays: elapsed, stability: stability);
  }

  bool isDue(KnowledgeNode node, DateTime at) {
    final last = node.lastEvidence;
    if (last == null) return true;
    final stepWait = _stepWait(node);
    if (stepWait != null) return !at.isBefore(last.add(stepWait));
    final stability = node.stability;
    if (stability == null || stability <= 0) return true;
    final days = _scheduler.intervalDays(stability);
    return !at.isBefore(last.add(Duration(days: days)));
  }

  bool isWeak(KnowledgeNode node, DateTime at) =>
      recallAt(node, at) < weakRetrievability || errorCount(node) > 0;

  int errorCount(KnowledgeNode node) =>
      node.toneErrors + node.segmentalErrors + node.wordOrderErrors + node.registerErrors;

  Duration? _stepWait(KnowledgeNode node) {
    final steps = switch (node.phase) {
      'learning' => _scheduler.learningSteps,
      'relearning' => _scheduler.relearningSteps,
      _ => null,
    };
    final step = node.step;
    if (steps == null || step == null || step < 0 || step >= steps.length) return null;
    return steps[step];
  }
}

class GraphQueryResult {
  const GraphQueryResult({
    required this.due,
    required this.weak,
    required this.ranked,
    this.recallByKey = const {},
  });

  static const empty = GraphQueryResult(due: [], weak: [], ranked: []);

  final List<KnowledgeNode> due;
  final List<KnowledgeNode> weak;
  final List<KnowledgeNode> ranked;
  final Map<String, double> recallByKey;

  bool get isEmpty => due.isEmpty && weak.isEmpty && ranked.isEmpty;
}
