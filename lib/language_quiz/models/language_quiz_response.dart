// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class LanguageQuizResponse {
  final int count;
  final int next;
  final int previous;
  final int totalscore;
  final List<LangaugeQuiz> results;
  LanguageQuizResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.totalscore,
  });

  LanguageQuizResponse copyWith({
    int? count,
    int? next,
    int? previous,
    int? totalscore,
    List<LangaugeQuiz>? results,
  }) {
    return LanguageQuizResponse(
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

  factory LanguageQuizResponse.fromMap(Map<String, dynamic> map, int? totalScrore) {
    return LanguageQuizResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt() ?? 0,
      previous: map['previous']?.toInt() ?? 0,
      totalscore: totalScrore ?? 0,
      results: List<LangaugeQuiz>.from(map['results']?.map((x) => LangaugeQuiz.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory LanguageQuizResponse.fromJson(String source) =>
      LanguageQuizResponse.fromMap(json.decode(source), 0);

  @override
  String toString() {
    return 'MannerismResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageQuizResponse &&
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

class LangaugeQuiz {
  final int id;
  final int score;
  final int count;
  final int? completed;
  final String name;
  final String congrats;
  final int language;
  LangaugeQuiz({
    required this.id,
    required this.score,
    required this.count,
    required this.completed,
    required this.name,
    required this.congrats,
    required this.language,
  });

  LangaugeQuiz copyWith({
    int? id,
    int? score,
    int? count,
    int? completed,
    String? name,
    String? congrats,
    int? language,
  }) {
    return LangaugeQuiz(
      id: id ?? this.id,
      score: score ?? this.score,
      count: count ?? this.count,
      completed: completed ?? this.completed,
      name: name ?? this.name,
      congrats: congrats ?? this.congrats,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'score': score});
    result.addAll({'count': count});
    if (completed != null) {
      result.addAll({'completed': completed});
    }
    result.addAll({'name': name});
    result.addAll({'congrats': congrats});
    result.addAll({'language': language});

    return result;
  }

  factory LangaugeQuiz.fromMap(Map<String, dynamic> map) {
    return LangaugeQuiz(
      id: map['id']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      count: map['count']?.toInt() ?? 0,
      completed: map['completed']?.toInt(),
      name: map['name'] ?? '',
      congrats: map['congrats'] ?? '',
      language: map['language']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory LangaugeQuiz.fromJson(String source) => LangaugeQuiz.fromMap(json.decode(source));

  @override
  String toString() {
    return 'HistoryQuiz(id: $id, score: $score, count: $count, completed: $completed, name: $name, congrats: $congrats, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LangaugeQuiz &&
        other.id == id &&
        other.score == score &&
        other.count == count &&
        other.completed == completed &&
        other.name == name &&
        other.congrats == congrats &&
        other.language == language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        score.hashCode ^
        count.hashCode ^
        completed.hashCode ^
        name.hashCode ^
        congrats.hashCode ^
        language.hashCode;
  }
}
