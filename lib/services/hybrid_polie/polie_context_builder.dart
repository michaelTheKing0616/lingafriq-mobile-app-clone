import 'package:lingafriq/models/learner/knowledge_node.dart';
import 'package:lingafriq/services/learning/knowledge_graph_queries.dart';

/// Weak items Polie may mention. The learner id and raw audio stay out.
class PolieContextBuilder {
  PolieContextBuilder({this.maxWeakItems = 5}) {
    if (maxWeakItems < 1) {
      throw ArgumentError('maxWeakItems must be at least 1');
    }
  }

  final int maxWeakItems;

  PolieContext build(GraphQueryResult result, {required String language}) {
    if (language.isEmpty) throw ArgumentError('language is required');
    final items = result.weak.take(maxWeakItems).map((node) => _item(node, result)).toList();
    return PolieContext(language: language, items: items, maxWeakItems: maxWeakItems);
  }

  PolieStruggle _item(KnowledgeNode node, GraphQueryResult result) {
    return PolieStruggle(
      nodeId: node.nodeId,
      kind: node.kind.wire,
      sense: node.sense,
      struggle: _struggle(node),
      retrievability: result.recallByKey[node.key] ?? node.retrievability,
    );
  }

  String _struggle(KnowledgeNode node) {
    const order = ['tone', 'segmental', 'word_order', 'register'];
    final counts = [
      node.toneErrors,
      node.segmentalErrors,
      node.wordOrderErrors,
      node.registerErrors,
    ];
    var best = 'recall';
    var bestCount = 0;
    for (var i = 0; i < order.length; i++) {
      if (counts[i] > bestCount) {
        best = order[i];
        bestCount = counts[i];
      }
    }
    return best;
  }
}

class PolieContext {
  const PolieContext({
    required this.language,
    required this.items,
    required this.maxWeakItems,
  });

  final String language;
  final List<PolieStruggle> items;
  final int maxWeakItems;

  bool get isEmpty => items.isEmpty;

  Map<String, Object?> toJson() => {
        'language': language,
        'maxWeakItems': maxWeakItems,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class PolieStruggle {
  const PolieStruggle({
    required this.nodeId,
    required this.kind,
    required this.sense,
    required this.struggle,
    required this.retrievability,
  });

  final String nodeId;
  final String kind;
  final String? sense;
  final String struggle;
  final double retrievability;

  String get promptLine {
    final label = sense == null ? nodeId : '$nodeId ($sense)';
    return 'learner struggles with $struggle on $label; recycle it';
  }

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'kind': kind,
        'sense': sense,
        'struggle': struggle,
        'retrievability': retrievability,
        'promptLine': promptLine,
      };
}
