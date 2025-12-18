// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class HistoryResponse {
  final int count;
  final int next;
  final int previous;
  final int totalscore;
  final List<History> results;
  HistoryResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.totalscore,
  });

  HistoryResponse copyWith({
    int? count,
    int? next,
    int? previous,
    int? totalscore,
    List<History>? results,
  }) {
    return HistoryResponse(
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

  factory HistoryResponse.fromMap(Map<String, dynamic> map, int? totalScrore) {
    return HistoryResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt() ?? 0,
      previous: map['previous']?.toInt() ?? 0,
      totalscore: totalScrore ?? 0,
      results: List<History>.from(map['results']?.map((x) => History.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryResponse.fromJson(String source) =>
      HistoryResponse.fromMap(json.decode(source), 0);

  @override
  String toString() {
    return 'MannerismResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryResponse &&
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

class History {
  final int id;
  final int score;
  final int count;
  final int completed;
  final String name;
  final String congrats;
  final int history_language;
  History({
    required this.id,
    required this.score,
    required this.count,
    required this.completed,
    required this.name,
    required this.congrats,
    required this.history_language,
  });

  History copyWith({
    int? id,
    int? score,
    int? count,
    int? completed,
    String? name,
    String? congrats,
    int? history_language,
  }) {
    return History(
      id: id ?? this.id,
      score: score ?? this.score,
      count: count ?? this.count,
      completed: completed ?? this.completed,
      name: name ?? this.name,
      congrats: congrats ?? this.congrats,
      history_language: history_language ?? this.history_language,
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
    result.addAll({'history_language': history_language});

    return result;
  }

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      id: map['id']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      count: map['count']?.toInt() ?? 0,
      completed: map['completed']?.toInt() ?? 0,
      name: map['name'] ?? '',
      congrats: map['congrats'] ?? '',
      history_language: map['history_language']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory History.fromJson(String source) => History.fromMap(json.decode(source));

  @override
  String toString() {
    return 'History(id: $id, score: $score, count: $count, completed: $completed, name: $name, congrats: $congrats, history_language: $history_language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is History &&
        other.id == id &&
        other.score == score &&
        other.count == count &&
        other.completed == completed &&
        other.name == name &&
        other.congrats == congrats &&
        other.history_language == history_language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        score.hashCode ^
        count.hashCode ^
        completed.hashCode ^
        name.hashCode ^
        congrats.hashCode ^
        history_language.hashCode;
  }
}
