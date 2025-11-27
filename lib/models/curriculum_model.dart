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
    title: map['title'] ?? '',
    generatedAt: DateTime.parse(map['generated_at'] ?? DateTime.now().toIso8601String()),
    languages: List<String>.from(map['languages'] ?? []),
    levels: List<String>.from(map['levels'] ?? []),
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
    type: map['type'] ?? '',
    items: List<String>.from(map['items'] ?? []),
  );
}

class CurriculumLesson {
  final String id;
  final String title;
  final List<String> vocab;
  final List<CurriculumExercise> exercises;
  final bool isCompleted;
  final double progress;

  CurriculumLesson({
    required this.id,
    required this.title,
    required this.vocab,
    required this.exercises,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory CurriculumLesson.fromMap(Map<String, dynamic> map) => CurriculumLesson(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    vocab: List<String>.from(map['vocab'] ?? []),
    exercises: (map['exercises'] as List?)
            ?.map((e) => CurriculumExercise.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    isCompleted: map['isCompleted'] ?? false,
    progress: (map['progress'] ?? 0.0).toDouble(),
  );
}

class CurriculumUnit {
  final int unit;
  final String title;
  final List<CurriculumLesson> lessons;
  final bool isCompleted;
  final double progress;

  CurriculumUnit({
    required this.unit,
    required this.title,
    required this.lessons,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory CurriculumUnit.fromMap(Map<String, dynamic> map) => CurriculumUnit(
    unit: map['unit'] ?? 0,
    title: map['title'] ?? '',
    lessons: (map['lessons'] as List?)
            ?.map((e) => CurriculumLesson.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    isCompleted: map['isCompleted'] ?? false,
    progress: (map['progress'] ?? 0.0).toDouble(),
  );

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

  factory CurriculumLevel.fromMap(Map<String, dynamic> map) => CurriculumLevel(
    level: map['level'] ?? '',
    units: (map['units'] as List?)
            ?.map((e) => CurriculumUnit.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    isCompleted: map['isCompleted'] ?? false,
    progress: (map['progress'] ?? 0.0).toDouble(),
  );

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
    final meta = CurriculumMeta.fromMap(map['meta'] as Map<String, dynamic>);
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

