// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class HistoryQuizLessonModel {
  final int id;
  final String title;
  final int score;
  final String types;
  final String? dateTime;
  final bool? completed;
  final int? completed_by;
  final dynamic otherData;
  HistoryQuizLessonModel({
    required this.id,
    required this.title,
    required this.score,
    required this.types,
    required this.dateTime,
    required this.completed,
    required this.completed_by,
    required this.otherData,
  });

  HistoryQuizLessonModel copyWith({
    int? id,
    String? title,
    int? score,
    String? types,
    String? dateTime,
    bool? completed,
    int? completed_by,
    dynamic otherData,
  }) {
    return HistoryQuizLessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      score: score ?? this.score,
      types: types ?? this.types,
      dateTime: dateTime ?? this.dateTime,
      completed: completed ?? this.completed,
      completed_by: completed_by ?? this.completed_by,
      otherData: otherData ?? this.otherData,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'title': title});
    result.addAll({'score': score});
    result.addAll({'types': types});
    result.addAll({'dateTime': dateTime});
    if (completed != null) {
      result.addAll({'completed': completed});
    }
    if (completed_by != null) {
      result.addAll({'completed_by': completed_by});
    }
    result.addAll({'otherData': otherData});

    return result;
  }

  factory HistoryQuizLessonModel.fromMap(Map<String, dynamic> map) {
    return HistoryQuizLessonModel(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      score: map['score']?.toInt() ?? 0,
      types: map['types'] ?? '',
      dateTime: map['dateTime'] ?? '',
      completed: map['completed'],
      completed_by: map['completed_by']?.toInt(),
      otherData: map['otherData'],
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryQuizLessonModel.fromJson(String source) =>
      HistoryQuizLessonModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SectionHistoryModel(id: $id, title: $title, score: $score, types: $types, dateTime: $dateTime, completed: $completed, completed_by: $completed_by, otherData: $otherData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryQuizLessonModel &&
        other.id == id &&
        other.title == title &&
        other.score == score &&
        other.types == types &&
        other.dateTime == dateTime &&
        other.completed == completed &&
        other.completed_by == completed_by &&
        other.otherData == otherData;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        score.hashCode ^
        types.hashCode ^
        dateTime.hashCode ^
        completed.hashCode ^
        completed_by.hashCode ^
        otherData.hashCode;
  }

  DateTime get date => DateTime.parse(dateTime ?? DateTime.now().toString());

  bool get isQuiz => types == 'History Instant Quiz' || types == "History Long Quiz";
  bool get isTutorial => types == 'Tutorial';
  bool get isWordQuiz => types == 'History Word Quiz';
}
