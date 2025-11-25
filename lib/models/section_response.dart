// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

class SectionResponse {
  final int count;
  final int? next;
  final int? previous;
  final List<Section> results;
  SectionResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  SectionResponse copyWith({
    int? count,
    int? next,
    int? previous,
    List<Section>? results,
  }) {
    return SectionResponse(
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

  factory SectionResponse.fromMap(Map<String, dynamic> map) {
    return SectionResponse(
      count: map['count']?.toInt() ?? 0,
      next: map['next']?.toInt(),
      previous: map['previous']?.toInt(),
      results: List<Section>.from(map['results']?.map((x) => Section.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory SectionResponse.fromJson(String source) => SectionResponse.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MannerismsResponse(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SectionResponse &&
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

class Section {
  final int id;
  final String name;
  final String congrats;
  final int mannerism_language;
  Section({
    required this.id,
    required this.name,
    required this.congrats,
    required this.mannerism_language,
  });

  Section copyWith({
    int? id,
    String? name,
    String? congrats,
    int? mannerism_language,
  }) {
    return Section(
      id: id ?? this.id,
      name: name ?? this.name,
      congrats: congrats ?? this.congrats,
      mannerism_language: mannerism_language ?? this.mannerism_language,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'name': name});
    result.addAll({'congrats': congrats});
    result.addAll({'mannerism_language': mannerism_language});

    return result;
  }

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      congrats: map['congrats'] ?? '',
      mannerism_language: map['mannerism_language']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Section.fromJson(String source) => Section.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Result(id: $id, name: $name, congrats: $congrats, mannerism_language: $mannerism_language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Section &&
        other.id == id &&
        other.name == name &&
        other.congrats == congrats &&
        other.mannerism_language == mannerism_language;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ congrats.hashCode ^ mannerism_language.hashCode;
  }
}
