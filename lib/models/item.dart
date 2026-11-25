/// One exercise in the item bank. A draft is stored and is not served.
class ContentItem {
  const ContentItem({
    required this.id,
    required this.language,
    required this.type,
    required this.stimulusRefs,
    required this.stimulusText,
    required this.correct,
    required this.variants,
    required this.diacriticInsensitive,
    required this.distractors,
    required this.irtA,
    required this.irtB,
    required this.skillTags,
    required this.reviewStatus,
  });

  static const types = {
    'listen_and_choose',
    'tone_identification',
    'picture_matching',
    'dictation',
    'sentence_building',
    'speaking_prompt',
    'short_conversation',
    'multiple_choice',
  };

  final String id;
  final String language;
  final String type;
  final List<String> stimulusRefs;
  final String? stimulusText;
  final String correct;
  final List<String> variants;
  final bool diacriticInsensitive;
  final List<ItemDistractor> distractors;
  final double irtA;
  final double irtB;
  final List<String> skillTags;
  final String reviewStatus;

  bool get isServable => reviewStatus == 'approved';

  /// The answer event records the item and the graph nodes named by its skill tags.
  Map<String, Object?> answerLink() => {
        'itemId': id,
        'nodeIds': skillTags,
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'language': language,
        'type': type,
        'stimulus': {
          'refs': stimulusRefs,
          if (stimulusText != null) 'text': stimulusText,
        },
        'answer': {
          'correct': correct,
          'variants': variants,
          'matching': {'diacritic_insensitive': diacriticInsensitive},
        },
        if (distractors.isNotEmpty)
          'distractors': distractors.map((item) => item.toJson()).toList(),
        'irt': {'a': irtA, 'b': irtB},
        'skill_tags': skillTags,
        'review': {'status': reviewStatus},
      };

  factory ContentItem.parse(Map<String, Object?> json) {
    final id = _string(json, 'id');
    final language = _string(json, 'language');
    final type = _string(json, 'type');
    if (!types.contains(type)) throw ArgumentError('unknown item type: $type');
    final stimulus = _map(json, 'stimulus');
    final refs = _stringList(stimulus, 'refs');
    if (refs.isEmpty) throw ArgumentError('stimulus.refs is required');
    final answer = _map(json, 'answer');
    final matching = _map(answer, 'matching');
    final insensitive = matching['diacritic_insensitive'];
    if (insensitive is! bool) {
      throw ArgumentError('answer.matching.diacritic_insensitive is required');
    }
    final irt = _map(json, 'irt');
    final a = irt['a'];
    final b = irt['b'];
    if (a is! num || a <= 0) throw ArgumentError('irt.a must be greater than 0');
    if (b is! num) throw ArgumentError('irt.b is required');
    final tags = _stringList(json, 'skill_tags');
    if (tags.isEmpty) throw ArgumentError('skill_tags is required');
    final review = _map(json, 'review');
    final statusRaw = review['status'];
    if (statusRaw != 'draft' && statusRaw != 'approved') {
      throw ArgumentError('review.status must be draft or approved');
    }
    final status = statusRaw as String;
    final distractors = _distractors(json['distractors']);
    if (type == 'multiple_choice' && distractors.isEmpty) {
      throw ArgumentError('multiple_choice requires a rationale on every distractor');
    }
    return ContentItem(
      id: id,
      language: language,
      type: type,
      stimulusRefs: refs,
      stimulusText: stimulus['text'] as String?,
      correct: _string(answer, 'correct'),
      variants: answer['variants'] == null ? const [] : _stringList(answer, 'variants'),
      diacriticInsensitive: insensitive,
      distractors: distractors,
      irtA: a.toDouble(),
      irtB: b.toDouble(),
      skillTags: tags,
      reviewStatus: status,
    );
  }
}

class ItemDistractor {
  const ItemDistractor({required this.text, required this.rationale});

  final String text;
  final String rationale;

  Map<String, Object?> toJson() => {'text': text, 'rationale': rationale};
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw ArgumentError('$key is required');
  return value;
}

Map<String, Object?> _map(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw ArgumentError('$key is required');
  return value.map((entry, item) => MapEntry(entry.toString(), item));
}

List<String> _stringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw ArgumentError('$key is required');
  final strings = <String>[];
  for (final item in value) {
    if (item is! String || item.isEmpty) throw ArgumentError('$key is required');
    strings.add(item);
  }
  return strings;
}

List<ItemDistractor> _distractors(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List) throw ArgumentError('distractors must be a list');
  return raw.map((item) {
    if (item is! Map) throw ArgumentError('distractor rationale is required');
    final text = item['text'];
    final rationale = item['rationale'];
    if (text is! String || text.isEmpty || rationale is! String || rationale.isEmpty) {
      throw ArgumentError('distractor rationale is required');
    }
    return ItemDistractor(text: text, rationale: rationale);
  }).toList();
}
