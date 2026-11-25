import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/learning/knowledge_graph_queries.dart';

/// The next practice set: due and weak nodes, weakest recall first.
class SessionBuilder {
  SessionBuilder(this._queries);

  final KnowledgeGraphQueries _queries;

  Future<SessionPlan> build({
    required String userId,
    required String language,
    DateTime? now,
  }) async {
    final result = await _queries.dueAndWeak(
      userId: userId,
      language: language,
      now: now,
    );
    return SessionPlan(items: result.ranked, isEmpty: result.isEmpty);
  }
}

class SessionPlan {
  const SessionPlan({required this.items, required this.isEmpty});

  final List<KnowledgeNode> items;
  final bool isEmpty;
}
