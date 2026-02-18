/// Represents an atomic, testable skill in the language learning curriculum.
///
/// Each skill is the smallest unit of knowledge that can be independently
/// assessed and tracked. Skills form a directed acyclic graph (DAG) via
/// their prerequisites, enabling dependency-aware curriculum sequencing.
class SkillNode {
  /// Unique identifier for this skill (e.g., "hausa_implosive_b").
  final String id;

  /// Human-readable name for display.
  final String name;

  /// Detailed description of what this skill covers.
  final String description;

  /// The linguistic domain this skill belongs to.
  final SkillType type;

  /// The primary modality through which this skill is practiced.
  final SkillModality modality;

  /// IDs of skills that must be mastered before this one is unlocked.
  final List<String> prerequisites;

  /// The language this skill belongs to (ISO 639-3 code, e.g., "hau" for Hausa).
  final String languageCode;

  /// Base difficulty rating, normalized to [0, 1].
  /// Used as a prior before learner-specific data is available.
  final double baseDifficulty;

  /// CEFR level this skill corresponds to (A1-C2).
  final CefrLevel cefrLevel;

  /// Tags for filtering and grouping (e.g., "tone", "noun-class", "greeting").
  final List<String> tags;

  /// BKT parameters tuned for this specific skill type.
  /// If null, default BKT parameters are used.
  final Map<String, double>? bktParamsOverride;

  const SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.modality,
    required this.languageCode,
    this.prerequisites = const [],
    this.baseDifficulty = 0.5,
    this.cefrLevel = CefrLevel.a1,
    this.tags = const [],
    this.bktParamsOverride,
  });

  /// Whether this skill has no prerequisites and can be started immediately.
  bool get isRootSkill => prerequisites.isEmpty;

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: SkillType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SkillType.lexical,
      ),
      modality: SkillModality.values.firstWhere(
        (m) => m.name == json['modality'],
        orElse: () => SkillModality.mixed,
      ),
      languageCode: json['languageCode'] as String,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      baseDifficulty: (json['baseDifficulty'] as num?)?.toDouble() ?? 0.5,
      cefrLevel: CefrLevel.values.firstWhere(
        (l) => l.name == json['cefrLevel'],
        orElse: () => CefrLevel.a1,
      ),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bktParamsOverride: (json['bktParamsOverride'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'modality': modality.name,
        'languageCode': languageCode,
        'prerequisites': prerequisites,
        'baseDifficulty': baseDifficulty,
        'cefrLevel': cefrLevel.name,
        'tags': tags,
        if (bktParamsOverride != null) 'bktParamsOverride': bktParamsOverride,
      };

  @override
  String toString() => 'SkillNode($id, $type, $modality)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkillNode && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Linguistic domain classification for skills.
enum SkillType {
  /// Vocabulary — words, phrases, and their meanings.
  lexical,

  /// Sounds, tones, and pronunciation patterns.
  phonetic,

  /// Word formation — prefixes, suffixes, noun classes, conjugation.
  morphological,

  /// Sentence structure — word order, clause formation.
  syntactic,

  /// Meaning and context — idioms, connotation, nuance.
  semantic,

  /// Social language use — formality, politeness, context-appropriate speech.
  pragmatic,
}

/// The primary modality through which a skill is practiced.
enum SkillModality {
  /// Hearing and understanding spoken language.
  listening,

  /// Producing spoken language.
  speaking,

  /// Reading written text.
  reading,

  /// Producing written text.
  writing,

  /// Skill practiced through multiple modalities.
  mixed,
}

/// CEFR (Common European Framework of Reference) proficiency levels.
enum CefrLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  /// Numeric index for comparison (A1=0, C2=5).
  int get index => CefrLevel.values.indexOf(this);

  /// Whether this level is at or above [other].
  bool isAtLeast(CefrLevel other) => index >= other.index;

  String get displayName {
    switch (this) {
      case CefrLevel.a1:
        return 'A1 - Beginner';
      case CefrLevel.a2:
        return 'A2 - Elementary';
      case CefrLevel.b1:
        return 'B1 - Intermediate';
      case CefrLevel.b2:
        return 'B2 - Upper Intermediate';
      case CefrLevel.c1:
        return 'C1 - Advanced';
      case CefrLevel.c2:
        return 'C2 - Proficient';
    }
  }
}
