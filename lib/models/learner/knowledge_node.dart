/// One learner-knowledge node. Strength is correct attempts over attempts for that channel.
class KnowledgeNode {
  const KnowledgeNode({
    required this.userId,
    required this.language,
    required this.nodeId,
    required this.kind,
    required this.sense,
    required this.stability,
    required this.difficulty,
    required this.retrievability,
    required this.phase,
    required this.step,
    required this.lastEvidence,
    required this.productionCorrect,
    required this.productionAttempts,
    required this.recognitionCorrect,
    required this.recognitionAttempts,
    required this.toneErrors,
    required this.segmentalErrors,
    required this.wordOrderErrors,
    required this.registerErrors,
  });

  final String userId;
  final String language;
  final String nodeId;
  final KnowledgeKind kind;
  final String? sense;
  final double? stability;
  final double? difficulty;
  final double retrievability;
  final String phase;
  final int? step;
  final DateTime? lastEvidence;
  final int productionCorrect;
  final int productionAttempts;
  final int recognitionCorrect;
  final int recognitionAttempts;
  final int toneErrors;
  final int segmentalErrors;
  final int wordOrderErrors;
  final int registerErrors;

  String get key => nodeKey(kind, nodeId, sense);

  double get productionStrength =>
      productionAttempts == 0 ? 0 : productionCorrect / productionAttempts;

  double get recognitionStrength =>
      recognitionAttempts == 0 ? 0 : recognitionCorrect / recognitionAttempts;

  int errorCount(ErrorKind kind) {
    switch (kind) {
      case ErrorKind.tone:
        return toneErrors;
      case ErrorKind.segmental:
        return segmentalErrors;
      case ErrorKind.wordOrder:
        return wordOrderErrors;
      case ErrorKind.register:
        return registerErrors;
    }
  }

  Map<String, Object?> toJson() => {
        'userId': userId,
        'language': language,
        'nodeId': nodeId,
        'kind': kind.wire,
        'sense': sense,
        'stability': stability,
        'difficulty': difficulty,
        'retrievability': retrievability,
        'phase': phase,
        'step': step,
        'lastEvidence': lastEvidence?.toUtc().toIso8601String(),
        'productionCorrect': productionCorrect,
        'productionAttempts': productionAttempts,
        'recognitionCorrect': recognitionCorrect,
        'recognitionAttempts': recognitionAttempts,
        'toneErrors': toneErrors,
        'segmentalErrors': segmentalErrors,
        'wordOrderErrors': wordOrderErrors,
        'registerErrors': registerErrors,
      };

  static KnowledgeNode fromJson(Map<String, Object?> json) {
    return KnowledgeNode(
      userId: json['userId']! as String,
      language: json['language']! as String,
      nodeId: json['nodeId']! as String,
      kind: KnowledgeKind.parse(json['kind']! as String),
      sense: json['sense'] as String?,
      stability: (json['stability'] as num?)?.toDouble(),
      difficulty: (json['difficulty'] as num?)?.toDouble(),
      retrievability: (json['retrievability'] as num).toDouble(),
      phase: json['phase']! as String,
      step: (json['step'] as num?)?.toInt(),
      lastEvidence: json['lastEvidence'] == null
          ? null
          : DateTime.parse(json['lastEvidence']! as String).toUtc(),
      productionCorrect: (json['productionCorrect'] as num).toInt(),
      productionAttempts: (json['productionAttempts'] as num).toInt(),
      recognitionCorrect: (json['recognitionCorrect'] as num).toInt(),
      recognitionAttempts: (json['recognitionAttempts'] as num).toInt(),
      toneErrors: (json['toneErrors'] as num).toInt(),
      segmentalErrors: (json['segmentalErrors'] as num).toInt(),
      wordOrderErrors: (json['wordOrderErrors'] as num).toInt(),
      registerErrors: (json['registerErrors'] as num).toInt(),
    );
  }
}

/// One graph for one learner and one language.
class KnowledgeGraph {
  const KnowledgeGraph({
    required this.userId,
    required this.language,
    required this.nodes,
  });

  final String userId;
  final String language;
  final List<KnowledgeNode> nodes;

  Map<String, Object?> toJson() => {
        'userId': userId,
        'language': language,
        'nodes': nodes.map((node) => node.toJson()).toList(),
      };
}

enum KnowledgeKind {
  lexeme('lexeme'),
  grammarPattern('grammar_pattern'),
  phonologicalSkill('phonological_skill'),
  pragmaticSkill('pragmatic_skill'),
  canDo('can_do');

  const KnowledgeKind(this.wire);
  final String wire;

  static KnowledgeKind parse(String wire) {
    for (final kind in values) {
      if (kind.wire == wire) return kind;
    }
    throw ArgumentError('unknown knowledge node kind: $wire');
  }
}

enum ErrorKind {
  tone('tone'),
  segmental('segmental'),
  wordOrder('word_order'),
  register('register');

  const ErrorKind(this.wire);
  final String wire;

  static ErrorKind parse(String wire) {
    for (final kind in values) {
      if (kind.wire == wire) return kind;
    }
    throw ArgumentError(
      'unknown error label: $wire. Use tone, segmental, word_order, or register.',
    );
  }
}

String nodeKey(KnowledgeKind kind, String nodeId, String? sense) =>
    '${kind.wire}|$nodeId|${sense ?? ''}';
