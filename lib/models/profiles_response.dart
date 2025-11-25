// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lingafriq/models/profile_model.dart';

class ProfilesResponse {
  final MainResult result;
  ProfilesResponse({
    required this.result,
  });

  ProfilesResponse copyWith({
    MainResult? result,
  }) {
    return ProfilesResponse(
      result: result ?? this.result,
    );
  }

  Map<String, dynamic> toMap() {
    final json = <String, dynamic>{};

    json.addAll({'result': result.toMap()});

    return json;
  }

  factory ProfilesResponse.fromMap(Map<String, dynamic> map) {
    return ProfilesResponse(
      result: MainResult.fromMap(map['result']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfilesResponse.fromJson(String source) => ProfilesResponse.fromMap(json.decode(source));

  @override
  String toString() => 'ProfilesResponse(result: $result)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfilesResponse && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;
}

class MainResult {
  final int count;
  final String? next;
  final String? previous;
  final List<ProfileModel> results;
  MainResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  MainResult copyWith({
    int? count,
    String? next,
    String? previous,
    List<ProfileModel>? results,
  }) {
    return MainResult(
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

  factory MainResult.fromMap(Map<String, dynamic> map) {
    return MainResult(
      count: map['count']?.toInt() ?? 0,
      next: map['next'],
      previous: map['previous'],
      results: List<ProfileModel>.from(map['results']?.map((x) => ProfileModel.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory MainResult.fromJson(String source) => MainResult.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MainResult(count: $count, next: $next, previous: $previous, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MainResult &&
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
