// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class LanguageResponse {
  final int count;
  final int? next;
  final int? previous;
  final List<Language> results;
  LanguageResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  LanguageResponse copyWith({
    int? count,
    int? next,
    int? previous,
    List<Language>? results,
  }) {
    return LanguageResponse(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'count': count});
    if (next != null) {
      result.addAll({'next': next});
    }
    if (previous != null) {
      result.addAll({'previous': previous});
    }
    result.addAll({'results': results.map((x) => x.toMap()).toList()});

    return result;
  }

  factory LanguageResponse.fromMap(Map<String, dynamic> map) {
    return LanguageResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt(),
      previous: map['previous']?.toInt(),
      results: List<Language>.from(map['results']?.map((x) => Language.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory LanguageResponse.fromJson(String source) => LanguageResponse.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LanguageResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageResponse &&
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

class Language {
  final int id;
  final int total_score;
  final int total_count;
  final int completed;
  final String name;
  final String? background;
  final String Inrtoduction;
  final bool is_published;
  final bool is_featured;
  final String level_language;
  Language({
    required this.id,
    required this.total_score,
    required this.total_count,
    required this.completed,
    required this.name,
    required this.background,
    required this.Inrtoduction,
    required this.is_published,
    required this.is_featured,
    required this.level_language,
  });

  Language copyWith({
    int? id,
    int? total_score,
    int? total_count,
    int? completed,
    String? name,
    String? background,
    String? Inrtoduction,
    bool? is_published,
    bool? is_featured,
    String? level_language,
  }) {
    return Language(
      id: id ?? this.id,
      total_score: total_score ?? this.total_score,
      total_count: total_count ?? this.total_count,
      completed: completed ?? this.completed,
      name: name ?? this.name,
      background: background ?? this.background,
      Inrtoduction: Inrtoduction ?? this.Inrtoduction,
      is_published: is_published ?? this.is_published,
      is_featured: is_featured ?? this.is_featured,
      level_language: level_language ?? this.level_language,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'total_score': total_score});
    result.addAll({'total_count': total_count});
    result.addAll({'completed': completed});
    result.addAll({'name': name});
    result.addAll({'background': background});
    result.addAll({'Inrtoduction': Inrtoduction});
    result.addAll({'is_published': is_published});
    result.addAll({'is_featured': is_featured});
    result.addAll({'level_language': level_language});

    return result;
  }

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id']?.toInt() ?? 0,
      total_score: map['total_score']?.toInt() ?? 0,
      total_count: map['total_count']?.toInt() ?? 0,
      completed: map['completed']?.toInt() ?? 0,
      name: map['name'] ?? '',
      background: map['background'] ?? '',
      Inrtoduction: map['Inrtoduction'] ?? '',
      is_published: map['is_published'] ?? false,
      is_featured: map['is_featured'] ?? false,
      level_language: map['level_language'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Language.fromJson(String source) => Language.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Result(id: $id, total_score: $total_score, total_count: $total_count, completed: $completed, name: $name, background: $background, Inrtoduction: $Inrtoduction, is_published: $is_published, is_featured: $is_featured, level_language: $level_language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Language &&
        other.id == id &&
        other.total_score == total_score &&
        other.total_count == total_count &&
        other.completed == completed &&
        other.name == name &&
        other.background == background &&
        other.Inrtoduction == Inrtoduction &&
        other.is_published == is_published &&
        other.is_featured == is_featured &&
        other.level_language == level_language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        total_score.hashCode ^
        total_count.hashCode ^
        completed.hashCode ^
        name.hashCode ^
        background.hashCode ^
        Inrtoduction.hashCode ^
        is_published.hashCode ^
        is_featured.hashCode ^
        level_language.hashCode;
  }
}
