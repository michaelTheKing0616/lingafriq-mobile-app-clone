// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class LessonResponse {
  final int count;
  final int next;
  final int previous;
  final int totalscore;
  final List<Lesson> results;
  LessonResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.totalscore,
  });

  LessonResponse copyWith({
    int? count,
    int? next,
    int? previous,
    int? totalscore,
    List<Lesson>? results,
  }) {
    return LessonResponse(
      count: count ?? this.count,
      totalscore: totalscore ?? this.totalscore,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'count': count});
    result.addAll({'next': next});
    result.addAll({'previous': previous});
    result.addAll({'results': results.map((x) => x.toMap()).toList()});

    return result;
  }

  factory LessonResponse.fromMap(Map<String, dynamic> map, int? totalScrore) {
    return LessonResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt() ?? 0,
      previous: map['previous']?.toInt() ?? 0,
      totalscore: totalScrore ?? 0,
      results: List<Lesson>.from(map['results']?.map((x) => Lesson.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory LessonResponse.fromJson(String source) => LessonResponse.fromMap(json.decode(source), 0);

  @override
  String toString() {
    return 'MannerismResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LessonResponse &&
        other.count == count &&
        other.next == next &&
        other.previous == previous &&
        listEquals(other.results, results);
  }

  @override
  int get hashCode {
    return count.hashCode ^ next.hashCode ^ previous.hashCode ^ results.hashCode;
  }
}

class Lesson {
  final int id;
  final int score;
  final int count;
  final int completed;
  final String name;
  final String congrats;
  final int lessons_language;
  Lesson({
    required this.id,
    required this.score,
    required this.count,
    required this.completed,
    required this.name,
    required this.congrats,
    required this.lessons_language,
  });

  Lesson copyWith({
    int? id,
    int? score,
    int? count,
    int? completed,
    String? name,
    String? congrats,
    int? lessons_language,
  }) {
    return Lesson(
      id: id ?? this.id,
      score: score ?? this.score,
      count: count ?? this.count,
      completed: completed ?? this.completed,
      name: name ?? this.name,
      congrats: congrats ?? this.congrats,
      lessons_language: lessons_language ?? this.lessons_language,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'score': score});
    result.addAll({'count': count});
    result.addAll({'completed': completed});
    result.addAll({'name': name});
    result.addAll({'congrats': congrats});
    result.addAll({'lessons_language': lessons_language});

    return result;
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      count: map['count']?.toInt() ?? 0,
      completed: map['completed']?.toInt() ?? 0,
      name: map['name'] ?? '',
      congrats: map['congrats'] ?? '',
      lessons_language: map['lessons_language']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Lesson.fromJson(String source) => Lesson.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Lesson(id: $id, score: $score, count: $count, completed: $completed, name: $name, congrats: $congrats, lessons_language: $lessons_language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Lesson &&
        other.id == id &&
        other.score == score &&
        other.count == count &&
        other.completed == completed &&
        other.name == name &&
        other.congrats == congrats &&
        other.lessons_language == lessons_language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        score.hashCode ^
        count.hashCode ^
        completed.hashCode ^
        name.hashCode ^
        congrats.hashCode ^
        lessons_language.hashCode;
  }
}
