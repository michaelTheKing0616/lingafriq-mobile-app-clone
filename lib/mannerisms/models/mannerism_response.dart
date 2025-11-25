// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class MannerismResponse {
  final int count;
  final int next;
  final int previous;
  final int totalscore;
  final List<Mannerism> results;
  MannerismResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
    required this.totalscore,
  });

  MannerismResponse copyWith({
    int? count,
    int? next,
    int? previous,
    int? totalscore,
    List<Mannerism>? results,
  }) {
    return MannerismResponse(
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

  factory MannerismResponse.fromMap(Map<String, dynamic> map, int? totalScrore) {
    return MannerismResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt() ?? 0,
      previous: map['previous']?.toInt() ?? 0,
      totalscore: totalScrore ?? 0,
      results: List<Mannerism>.from(map['results']?.map((x) => Mannerism.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory MannerismResponse.fromJson(String source) =>
      MannerismResponse.fromMap(json.decode(source), 0);

  @override
  String toString() {
    return 'MannerismResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MannerismResponse &&
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

class Mannerism {
  final int id;
  final int score;
  final int count;
  final int completed;
  final String name;
  final String congrats;
  final int mannerism_language;
  Mannerism({
    required this.id,
    required this.score,
    required this.count,
    required this.completed,
    required this.name,
    required this.congrats,
    required this.mannerism_language,
  });

  Mannerism copyWith({
    int? id,
    int? score,
    int? count,
    int? completed,
    String? name,
    String? congrats,
    int? mannerism_language,
  }) {
    return Mannerism(
      id: id ?? this.id,
      score: score ?? this.score,
      count: count ?? this.count,
      completed: completed ?? this.completed,
      name: name ?? this.name,
      congrats: congrats ?? this.congrats,
      mannerism_language: mannerism_language ?? this.mannerism_language,
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
    result.addAll({'mannerism_language': mannerism_language});

    return result;
  }

  factory Mannerism.fromMap(Map<String, dynamic> map) {
    return Mannerism(
      id: map['id']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      count: map['count']?.toInt() ?? 0,
      completed: map['completed']?.toInt() ?? 0,
      name: map['name'] ?? '',
      congrats: map['congrats'] ?? '',
      mannerism_language: map['mannerism_language']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Mannerism.fromJson(String source) => Mannerism.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Mannerism(id: $id, score: $score, count: $count, completed: $completed, name: $name, congrats: $congrats, mannerism_language: $mannerism_language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Mannerism &&
        other.id == id &&
        other.score == score &&
        other.count == count &&
        other.completed == completed &&
        other.name == name &&
        other.congrats == congrats &&
        other.mannerism_language == mannerism_language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        score.hashCode ^
        count.hashCode ^
        completed.hashCode ^
        name.hashCode ^
        congrats.hashCode ^
        mannerism_language.hashCode;
  }
}
