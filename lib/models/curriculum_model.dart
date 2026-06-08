import 'dart:convert';

class CurriculumMeta {
  final String title;
  final DateTime generatedAt;
  final List<String> languages;
  final List<String> levels;

  CurriculumMeta({
    required this.title,
    required this.generatedAt,
    required this.languages,
    required this.levels,
  });

  factory CurriculumMeta.fromMap(Map<String, dynamic> map) => CurriculumMeta(
    title: (map['title'] as String?) ?? '',
    generatedAt: DateTime.tryParse((map['generated_at'] as String?) ?? '') ?? DateTime.now(),
    languages: List<String>.from((map['languages'] as List<dynamic>?) ?? []),
    levels: List<String>.from((map['levels'] as List<dynamic>?) ?? []),
  );
}

class CurriculumMcqItem {
  final String id;
  final String question;
  final List<String> options;
  final String answer;

  const CurriculumMcqItem({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  factory CurriculumMcqItem.fromMap(Map<String, dynamic> map) => CurriculumMcqItem(
        id: (map['id'] as String?) ?? '',
        question: (map['question'] as String?) ?? '',
        options: List<String>.from((map['options'] as List<dynamic>?) ?? []),
        answer: (map['answer'] as String?) ?? '',
      );
}

class CurriculumExercise {
  final String type;
  final List<String> items;

  CurriculumExercise({
    required this.type,
    required this.items,
  });

  factory CurriculumExercise.fromMap(Map<String, dynamic> map) => CurriculumExercise(
    type: (map['type'] as String?) ?? '',
    items: List<String>.from((map['items'] as List<dynamic>?) ?? []),
  );
}

class CurriculumVocab {
  final String word;
  final String meaning;
  final String? pos; // part of speech
  final String? example;
  final String? pronunciation;

  CurriculumVocab({
    required this.word,
    required this.meaning,
    this.pos,
    this.example,
    this.pronunciation,
  });

  factory CurriculumVocab.fromMap(Map<String, dynamic> map) => CurriculumVocab(
    word: (map['word'] as String?) ?? '',
    meaning: (map['meaning'] as String?) ?? '',
    pos: map['pos'] as String?,
    example: map['example'] as String?,
    pronunciation: map['pronunciation'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'word': word,
    'meaning': meaning,
    if (pos != null) 'pos': pos,
    if (example != null) 'example': example,
    if (pronunciation != null) 'pronunciation': pronunciation,
  };
}

/// A single scene inside a dialogue (e.g. "At the market", "Closing the deal").
class CurriculumDialogueScene {
  final String label;
  final List<Map<String, String>> script;

  CurriculumDialogueScene({required this.label, required this.script});

  factory CurriculumDialogueScene.fromMap(Map<String, dynamic> map) =>
      CurriculumDialogueScene(
        label: (map['label'] as String?) ?? '',
        script: ((map['script'] as List<dynamic>?) ?? [])
            .map((e) => Map<String, String>.from((e is Map) ? Map.from(e) : {}))
            .toList(),
      );
}

class CurriculumDialogue {
  /// Flat script across all scenes (kept for backward compatibility with older
  /// renderers and v3 bundles which only shipped a flat list).
  final List<Map<String, String>> script;

  /// Optional structured scenes (v4 bundles). May be empty for legacy bundles,
  /// in which case the flat [script] is the single source of truth.
  final List<CurriculumDialogueScene> scenes;

  /// Optional summary label for the dialogue's primary scene/setting.
  final String? scene;

  /// Convenience: total number of turns across all scenes.
  final int turnCount;

  final String? notes;
  final String? culturalContext;

  CurriculumDialogue({
    required this.script,
    this.scenes = const [],
    this.scene,
    this.notes,
    this.culturalContext,
    int? turnCount,
  }) : turnCount = turnCount ?? script.length;

  factory CurriculumDialogue.fromMap(Map<String, dynamic> map) {
    final scenesRaw = (map['scenes'] as List<dynamic>?) ?? const [];
    final scenes = scenesRaw
        .whereType<Map>()
        .map((m) => CurriculumDialogueScene.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    final script = ((map['script'] as List<dynamic>?) ?? [])
        .map((e) => Map<String, String>.from((e is Map) ? Map.from(e) : {}))
        .toList();
    final emittedTurnCount = map['turn_count'];
    return CurriculumDialogue(
      script: script,
      scenes: scenes,
      scene: map['scene'] as String?,
      notes: map['notes'] as String?,
      culturalContext: (map['cultural_context'] as String?) ??
          (map['culturalContext'] as String?),
      turnCount: emittedTurnCount is int ? emittedTurnCount : script.length,
    );
  }
}

class CurriculumLesson {
  final String id;
  final String title;
  final List<dynamic> vocab; // Can be List<String> or List<CurriculumVocab>
  final List<CurriculumExercise> exercises;
  final List<String>? grammar;
  final CurriculumDialogue? dialogue;
  final int? durationMin;
  final bool isCompleted;
  final double progress;
  final String? objective;
  final String? culturalNotes;
  final String? polieRoleplayPrompt;
  final String? polieRoleplayPersona;

  CurriculumLesson({
    required this.id,
    required this.title,
    required this.vocab,
    required this.exercises,
    this.grammar,
    this.dialogue,
    this.durationMin,
    this.isCompleted = false,
    this.progress = 0.0,
    this.objective,
    this.culturalNotes,
    this.polieRoleplayPrompt,
    this.polieRoleplayPersona,
  });

  factory CurriculumLesson.fromMap(Map<String, dynamic> map) {
    final vocabList = (map['vocab'] as List<dynamic>?) ?? [];
    final vocab = vocabList.map((v) {
      if (v is String) return v;
      if (v is Map) return CurriculumVocab.fromMap(Map<String, dynamic>.from(v));
      return v;
    }).toList();

    final progressVal = map['progress'];
    final progress = progressVal is num
        ? progressVal.toDouble()
        : (double.tryParse(progressVal?.toString() ?? '0') ?? 0.0);

    final roleplay = map['polie_roleplay'] is Map
        ? Map<String, dynamic>.from(map['polie_roleplay'] as Map)
        : null;

    return CurriculumLesson(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      vocab: vocab,
      exercises: ((map['exercises'] as List<dynamic>?) ?? [])
          .map((e) => CurriculumExercise.fromMap(Map<String, dynamic>.from((e is Map) ? e : {})))
          .toList(),
      grammar: map['grammar'] != null ? List<String>.from((map['grammar'] as List<dynamic>?) ?? []) : null,
      dialogue: map['dialogue'] != null && map['dialogue'] is Map
          ? CurriculumDialogue.fromMap(Map<String, dynamic>.from(map['dialogue'] as Map))
          : null,
      durationMin: (map['duration_min'] ?? map['durationMin']) is int
          ? (map['duration_min'] ?? map['durationMin']) as int?
          : int.tryParse((map['duration_min'] ?? map['durationMin'])?.toString() ?? ''),
      isCompleted: map['isCompleted'] as bool? ?? false,
      progress: progress,
      objective: map['objective'] as String?,
      culturalNotes: map['cultural_notes'] as String?,
      polieRoleplayPrompt: roleplay?['prompt'] as String?,
      polieRoleplayPersona: roleplay?['persona'] as String?,
    );
  }

  // Helper to get vocab as strings
  List<String> get vocabStrings {
    return vocab.map((v) {
      if (v is String) return v;
      if (v is CurriculumVocab) return v.word;
      return v.toString();
    }).toList();
  }

  // Helper to get vocab as objects
  List<CurriculumVocab> get vocabObjects {
    return vocab.map((v) {
      if (v is CurriculumVocab) return v;
      if (v is String) return CurriculumVocab(word: v, meaning: '');
      if (v is Map) return CurriculumVocab.fromMap(v as Map<String, dynamic>);
      return CurriculumVocab(word: v.toString(), meaning: '');
    }).toList();
  }
}

class CurriculumUnit {
  final int unit;
  final String title;
  final List<CurriculumLesson> lessons;
  final List<CurriculumMcqItem> unitQuiz;
  final bool isCompleted;
  final double progress;

  CurriculumUnit({
    required this.unit,
    required this.title,
    required this.lessons,
    this.unitQuiz = const [],
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory CurriculumUnit.fromMap(Map<String, dynamic> map) {
    final progressVal = map['progress'];
    final progress = progressVal is num
        ? progressVal.toDouble()
        : (double.tryParse(progressVal?.toString() ?? '0') ?? 0.0);
    final quizRaw = map['unit_quiz'];
    final quizItems = quizRaw is Map
        ? List<CurriculumMcqItem>.from(
            ((quizRaw['items'] as List<dynamic>?) ?? [])
                .whereType<Map>()
                .map((e) => CurriculumMcqItem.fromMap(Map<String, dynamic>.from(e))),
          )
        : const <CurriculumMcqItem>[];

    return CurriculumUnit(
      unit: (map['unit'] is int)
          ? (map['unit'] as int?) ?? 0
          : (int.tryParse((map['unit'] ?? 0).toString()) ?? 0),
      title: (map['title'] as String?) ?? '',
      lessons: ((map['lessons'] as List<dynamic>?) ?? [])
          .map((e) => CurriculumLesson.fromMap(Map<String, dynamic>.from((e is Map) ? e : {})))
          .toList(),
      unitQuiz: quizItems,
      isCompleted: map['isCompleted'] as bool? ?? false,
      progress: progress,
    );
  }

  double get calculatedProgress {
    if (lessons.isEmpty) return 0.0;
    final completed = lessons.where((l) => l.isCompleted).length;
    return completed / lessons.length;
  }
}

class CurriculumLevel {
  final String level;
  final List<CurriculumUnit> units;
  final bool isCompleted;
  final double progress;

  CurriculumLevel({
    required this.level,
    required this.units,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory CurriculumLevel.fromMap(Map<String, dynamic> map) {
    final progressVal = map['progress'];
    final progress = progressVal is num
        ? progressVal.toDouble()
        : (double.tryParse(progressVal?.toString() ?? '0') ?? 0.0);
    return CurriculumLevel(
      level: (map['level'] as String?) ?? '',
      units: ((map['units'] as List<dynamic>?) ?? [])
          .map((e) => CurriculumUnit.fromMap(Map<String, dynamic>.from((e is Map) ? e : {})))
          .toList(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      progress: progress,
    );
  }

  double get calculatedProgress {
    if (units.isEmpty) return 0.0;
    final totalProgress = units.fold<double>(0.0, (sum, unit) => sum + unit.calculatedProgress);
    return totalProgress / units.length;
  }
}

class Curriculum {
  final CurriculumMeta meta;
  final Map<String, Map<String, List<CurriculumUnit>>> languages;

  Curriculum({
    required this.meta,
    required this.languages,
  });

  factory Curriculum.fromMap(Map<String, dynamic> map) {
    final metaMap = map['meta'];
    final meta = metaMap is Map
        ? CurriculumMeta.fromMap(Map<String, dynamic>.from(metaMap))
        : CurriculumMeta(title: '', generatedAt: DateTime.now(), languages: [], levels: []);
    final languagesMap = <String, Map<String, List<CurriculumUnit>>>{};

    if (map['languages'] != null) {
      (map['languages'] as Map).forEach((langKey, langData) {
        final levelsMap = <String, List<CurriculumUnit>>{};
        if (langData is Map) {
          langData.forEach((levelKey, levelData) {
            if (levelData is List) {
              levelsMap[levelKey] = levelData
                  .map((e) => CurriculumUnit.fromMap(e as Map<String, dynamic>))
                  .toList();
            }
          });
        }
        languagesMap[langKey] = levelsMap;
      });
    }

    return Curriculum(
      meta: meta,
      languages: languagesMap,
    );
  }

  factory Curriculum.fromJson(String json) => Curriculum.fromMap(jsonDecode(json));
  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() => {
    'meta': {
      'title': meta.title,
      'generated_at': meta.generatedAt.toIso8601String(),
      'languages': meta.languages,
      'levels': meta.levels,
    },
    'languages': languages.map((key, value) => MapEntry(
          key,
          value.map((levelKey, units) => MapEntry(
                levelKey,
                units.map((u) => _unitToMap(u)).toList(),
              )),
        )),
  };

  Map<String, dynamic> _unitToMap(CurriculumUnit unit) => {
    'unit': unit.unit,
    'title': unit.title,
    'lessons': unit.lessons.map((l) => _lessonToMap(l)).toList(),
  };

  Map<String, dynamic> _lessonToMap(CurriculumLesson lesson) => {
    'id': lesson.id,
    'title': lesson.title,
    'vocab': lesson.vocab,
    'exercises': lesson.exercises.map((e) => _exerciseToMap(e)).toList(),
  };

  Map<String, dynamic> _exerciseToMap(CurriculumExercise exercise) => {
    'type': exercise.type,
    'items': exercise.items,
  };
}

